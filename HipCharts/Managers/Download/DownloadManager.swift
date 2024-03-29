//
//  DownloadManager.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Combine
import Foundation
import MapKit
import CoreLocation
import Turf

enum DownloadStatus {
    case downloading(progress: Float)
    case failed(DisplayError)
    case complete
    
    var isCompleted: Bool {
        if case .complete = self {
            return true
        }
        return false
    }
}

let maxConcurrentRequests = 20
private func defaultURLSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.urlCache = nil
//    config.timeoutIntervalForRequest = 10
    config.httpMaximumConnectionsPerHost = maxConcurrentRequests
    return .init(configuration: config)
}

private let downloadAreasDefaultsKey = "DownloadAreasData"
private let diskQueue = DispatchQueue(label: "Disk Queue", qos: .utility)

class DownloadManager {
    let downloadedAreas = CurrentValueSubject<[DownloadArea], Never>([])
    let cacheReady = CurrentValueSubject<Bool, Never>(false)
    
    private let fileManager: FileManager
    private let urlSession: URLSession
    private let defaults: UserDefaults
    private let downloadedTiles = CurrentValueSubject<Set<TilePath>, Never>([])
    private let downloadsByAreaId =
        CurrentValueSubject<[UUID: (CurrentValueSubject<DownloadStatus, Never>, AnyCancellable)], Never>([:])
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    private var cancellables = CancellableSet()
        
    init(fileManager: FileManager = .default,
         urlSession: URLSession = defaultURLSession(),
         defaults: UserDefaults = .standard) {
        self.fileManager = fileManager
        self.urlSession = urlSession
        self.defaults = defaults
        
        downloadedAreas
            .dropFirst()
            .sink { [weak self] _ in self?.writeToStore() }
            .store(in: &cancellables)
        
        // Ask the system for extra time when actively downloading chats
        downloadsByAreaId
            .sink { [unowned self] downloadsByAreaId in
                if downloadsByAreaId.count > 0, backgroundTaskId == nil {
                    self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Chart Downloads") {
                        if let id = self.backgroundTaskId {
                            self.backgroundTaskId = nil
                            UIApplication.shared.endBackgroundTask(id)
                        }
                    }
                } else if downloadsByAreaId.count == 0, let backgroundTaskId = self.backgroundTaskId {
                    self.backgroundTaskId = nil
                    UIApplication.shared.endBackgroundTask(backgroundTaskId)
                }
            }
            .store(in: &cancellables)
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            self?.initializeInBackgroundQueue()
        }
    }
    
    func writeToStore() {
        defaults.setCodable(downloadedAreas.value, forKey: downloadAreasDefaultsKey)
    }
    
    func createAndDownloadNewArea(region: MKCoordinateRegion,
                                  customPolygon: Polygon?,
                                  name: String?,
                                  chartOptions: MapState.Options.Chart) {
        let area = DownloadArea(id: UUID(), name: name, region: region, customPolygon: customPolygon)
        downloadedAreas.value.insert(area, at: 0)
        download(area: area, chartOptions: chartOptions)
    }
    
    func download(area: DownloadArea,
                  chartOptions: MapState.Options.Chart,
                  refreshCachedFiles: Bool = true) {
        let r = getTileCacheDir()
        guard case .success(let downloadDir) = r else {
            return
        }
        
        var completedTiles = Set<TilePath>()
        let overlay = ChartTileOverlay(options: chartOptions)
        
        let subject = CurrentValueSubject<DownloadStatus, Never>(.downloading(progress: 0))
        let cancellable = Just(())
            .receive(on: DispatchQueue.global(qos: .default))
            .flatMap { () -> AnyPublisher<(TilePath, Int), Never> in
                let tiles = neededTiles(area: area)
                return tiles.publisher
                    .map { ($0, tiles.count) }
                    .eraseToAnyPublisher()
            }
            .setFailureType(to: DisplayError.self)
            .receive(on: diskQueue)
            .flatMap(maxPublishers: .max(maxConcurrentRequests)) { (tilePath: TilePath, totalCount: Int) -> AnyPublisher<(TilePath, Int), DisplayError> in
                let to = downloadFileURL(downloadDir: downloadDir, tilePath: tilePath)
                if !refreshCachedFiles && self.fileManager.fileExists(atPath: to.path) {
                    return Just((tilePath, totalCount))
                        .setFailureType(to: DisplayError.self)
                        .eraseToAnyPublisher()
                }
                return self.downloadTile(from: overlay.url(forTilePath: tilePath), to: to)
                    .retry(3)
                    .map { (tilePath, totalCount) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .map { (tile: TilePath, totalCount: Int) -> Float in
                completedTiles.insert(tile)
                return Float(completedTiles.count) / Float(totalCount)
            }
            .eraseToAnyPublisher()
            .flatMap { [weak self] (progress: Float) -> AnyPublisher<Float, DisplayError> in
                // side effect on download completion
                if progress == 1, let self = self {
                    return self.completeDownload(area: area)
                        .map { progress }
                        .setFailureType(to: DisplayError.self)
                        .eraseToAnyPublisher()
                }
                return Just(progress)
                    .setFailureType(to: DisplayError.self)
                    .eraseToAnyPublisher()
            }
            .map { DownloadStatus.downloading(progress: $0) }
            .catch { Just(.failed($0)) }
            .subscribe(subject)
        
        downloadsByAreaId.value[area.id] = (subject, cancellable)
    }
    
    func downloadProgressPublisher(area: DownloadArea) -> AnyPublisher<DownloadStatus, Never> {
        downloadsByAreaId
            .flatMap { (downloadsByAreaId) -> AnyPublisher<DownloadStatus, Never> in
                if let download = downloadsByAreaId[area.id] {
                    return download.0.eraseToAnyPublisher()
                }
                return Just(
                    area.date == nil ? .failed(DisplayError(displayString: "Download Interupted")) : .complete
                ).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getTile(path: TilePath) -> Data? {
        guard downloadedTiles.value.contains(path),
            case .success(let dir) = getTileCacheDir() else {
            return nil
        }
        return try? Data(contentsOf: downloadFileURL(downloadDir: dir, tilePath: path))
    }
    
    func cancelDownload(area: DownloadArea) {
        downloadsByAreaId.value.removeValue(forKey: area.id)
    }
    
    func deleteDownload(area: DownloadArea) -> AnyPublisher<Void, DisplayError> {
        cancelDownload(area: area)
        return downloadedAreas.first()
            .receive(on: DispatchQueue.global(qos: .default))
            .tryMap { (downloadedAreas) -> (URL, Set<TilePath>) in
                let r = self.getTileCacheDir()
                guard case .success(let downloadDir) = r else {
                    throw r.error!
                }
                
                var tilesToRemove = Set(neededTiles(area: area))
                downloadedAreas
                    .filter { $0.id != area.id }
                    .forEach {
                        neededTiles(area: $0).forEach { tilesToRemove.remove($0) }
                    }
                return (downloadDir, tilesToRemove)
            }
            .receive(on: diskQueue)
            .tryMap { (downloadDir, tilesToRemove) in
                try tilesToRemove.forEach {
                    let url = downloadFileURL(downloadDir: downloadDir, tilePath: $0)
                    if self.fileManager.fileExists(atPath: url.path) {
                        try self.fileManager.removeItem(at: url)
                    }
                }
                
                return tilesToRemove
            }
            .catch {
                Fail(error: DisplayError(anyError: $0, defaultDisplayString: "Failed to remove downloaded area"))
            }
            .receive(on: DispatchQueue.main)
            .map { (removedTiles: Set<TilePath>) -> Void in 
                self.downloadedAreas.value.removeAll { $0.id == area.id }
                self.downloadedTiles.value = self.downloadedTiles.value.subtracting(removedTiles)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Initialize
    
    private func loadTilePathsOfCachedFilesOnBackgroundQueue() -> Result<Set<TilePath>, DisplayError> {
        // load list of downloaded tiles from documents directory.
        return self.getTileCacheDir().flatMap { url in
            do {
                let files = try self.fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                return .success(Set(files.compactMap { tilePath(downloadFileURL: $0) }))
            } catch {
                return .failure(.init(anyError: error, defaultDisplayString: "Failed to read contents of cache dir."))
            }
        }
    }
    
    private func initializeInBackgroundQueue() {
        var tilePaths = Set<TilePath>()
        switch loadTilePathsOfCachedFilesOnBackgroundQueue() {
        case .success(let paths):
            tilePaths = paths
        case .failure(let error):
            logger.log("Download Manager init failed: \(error)")
        }
        
        // load areas
        let areas: [DownloadArea] = defaults.codable(forKey: downloadAreasDefaultsKey) ?? []
//            areas = loadedAreas
//                .map { area in
//                let neededTiles = neededTiles(region: area.region)
//                let count = neededTiles.count
//                let total = calculateAreaFileSizeBytes(area: area)
//                let average = Float(total) / Float(count)
//                logger.log("Average files size in bytes: \(average)")
//            }
        
        
        DispatchQueue.main.async {
            self.downloadedTiles.send(tilePaths)
            self.downloadedAreas.value = areas
            self.cacheReady.send(true)
            // TODO re-enable in a way that does not block disk queue at startup
//            self.purgeStrayCacheFiles()
        }
    }
    
    
    // MARK: - Download
    
    private func completeDownload(area completedArea: DownloadArea) -> AnyPublisher<Void, Never> {
        Just(completedArea)
            .receive(on: diskQueue)
            .map { completedArea in
                var updated = completedArea
                updated.sizeBytes = self.calculateAreaFileSizeBytes(area: completedArea)
                updated.date = Date()
                return updated
            }
            .receive(on: DispatchQueue.main)
            .map { [weak self] completedArea in
                guard let self = self else { return }
                self.downloadedAreas.value = self.downloadedAreas.value.map {
                    $0.id == completedArea.id ? completedArea : $0
                }
                self.downloadsByAreaId.value.removeValue(forKey: completedArea.id)
            }
            .eraseToAnyPublisher()
    }
    
    private func downloadTile(from: URL, to: URL) -> AnyPublisher<Void, DisplayError> {
        urlSession.dataTaskPublisher(for: from)
            .receive(on: diskQueue)
            .tryMap { (data: Data, response: URLResponse) in
                if let error = response.httpError(data: data) {
                    throw error
                }
                return (data, to)
            }
            .mapError {
                DisplayError(anyError: $0,
                             defaultDisplayString: "Somthing has gone wrong with this request, please try again.")
            }
            .tryMap { [weak self] (data: Data, fileURL: URL) in
                try data.write(to: fileURL)
                var fileURL = fileURL
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try fileURL.setResourceValues(values)
                guard self?.fileManager.fileExists(atPath: fileURL.path) == true else {
                    throw DisplayError(displayString: "Failed to save tile: \(fileURL.lastPathComponent)")
                }
            }
            .mapError {
                DisplayError(anyError: $0,
                             defaultDisplayString: "Unable to save to documents directory.")
            }
            .eraseToAnyPublisher()
    }
    
    private func getTileCacheDir() -> Result<URL, DisplayError> {
        guard let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.log("Unable to find documents directory!!!!")
            return .failure(DisplayError(displayString: "Unable to access app documents directory."))
        }
        let url = docsDir.appendingPathComponent("tileCache")
        
        // create directory if neeeded
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                return .failure(DisplayError(anyError: error,
                                             defaultDisplayString: "Unable to create cache directory." ))
            }
        }
        
        return .success(url)
    }
    
    private func calculateAreaFileSizeBytes(area: DownloadArea) -> Int {
        guard case .success(let downloadDir) = getTileCacheDir() else { return 0 }
            return neededTiles(area: area)
                .map { (tile) -> Int in
                    let url = downloadFileURL(downloadDir: downloadDir, tilePath: tile)
                    let bytes = try? fileManager.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? UInt64
                    return Int(bytes ?? 0)
                }
                .reduce(0) { $0 + $1 }
    }
    
    // MARK: - Cleanup
    
    private func purgeStrayCacheFiles() {
        downloadedAreas.first()
            .receive(on: diskQueue)
            .tryMap { [weak self] areas in
                guard let self = self, case .success(let dir) = self.getTileCacheDir() else {
                    throw self?.getTileCacheDir().error ?? .init(displayString: "Failed to get cache dir")
                }
                let allTiles = areas.flatMap { neededTiles(area: $0) }
                var cleanedCount = 0
                try self.fileManager.contentsOfDirectory(atPath: dir.path).forEach { path in
                    let url = dir.appendingPathComponent(path)
                    guard let tilePath = tilePath(downloadFileURL: url) else {
                        logger.log("Failed to create tile path for file in cache dir: \(path). Skipping...")
                        return
                    }
                    if !allTiles.contains(tilePath) {
                        do {
                            try self.fileManager.removeItem(at: url)
                            cleanedCount += 1
                        } catch {
                            logger.log("Failed to remove file in cache dir: \(path): \(error). Skipping...")
                        }
                    }
                }
                
                var tilePaths = Set<TilePath>()
                switch self.loadTilePathsOfCachedFilesOnBackgroundQueue() {
                case .success(let paths):
                    tilePaths = paths
                case .failure(let error):
                    throw error
                }
                
                return tilePaths
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    logger.log("Failed to clean cache Dir: \(error)")
                }
            }, receiveValue: { (remainingTiles: Set<TilePath>) -> Void in
                self.downloadedTiles.value = remainingTiles
                logger.log("Finished cleaning stray tiles from cache dir.")
            })
            .store(in: &cancellables)
    }
}

extension DownloadManager {
    enum UpdateEvent {
        case failed((UUID, Error))
        case complete(UUID)
    }
}

private func downloadFileURL(downloadDir: URL, tilePath: TilePath) -> URL {
    downloadDir.appendingPathComponent("\(tilePath.z)-\(tilePath.x)-\(tilePath.y).png")
}

private func tilePath(downloadFileURL: URL) -> TilePath? {
    guard let splits = downloadFileURL.lastPathComponent.split(separator: ".").first?.split(separator: "-"),
        splits.count == 3,
          let y = Int(splits[2]),
          let x = Int(splits[1]),
          let z = Int(splits[0]) else {
        return nil
    }
    return .init(x: x, y: y, z: z)
}

// MARK: - Notes

/*
 https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
 def deg2num(lat_deg, lon_deg, zoom):
   lat_rad = math.radians(lat_deg)
   n = 2.0 ** zoom
   xtile = int((lon_deg + 180.0) / 360.0 * n)
   ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
   return (xtile, ytile)
 */

