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

struct DownloadArea: Codable {
    enum Status: Codable {
        case downloading, complete
        case failed(errorString: String)
    }
    let id: UUID
    var name: String?
    let region: MKCoordinateRegion
    var status: Status
    var sizeBytes: Int?
}

private func defaultURLSession() -> URLSession {
    let config = URLSessionConfiguration.default
    config.httpMaximumConnectionsPerHost = 10
    return .init(configuration: config)
}

private let downloadAreasDefaultsKey = "DownloadAreasData"

class DownloadManager {
    let downloadedAreas = CurrentValueSubject<[DownloadArea], Never>([])
    let cacheReady = CurrentValueSubject<Bool, Never>(false)
    
    private let fileManager: FileManager
    private let urlSession: URLSession
    private let defaults: UserDefaults
    private let downloadedTiles = CurrentValueSubject<Set<TilePath>, Never>([])
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
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.initializeInBackgroundQueue()
        }
    }
    
    func writeToStore() {
        defaults.setCodable(downloadedAreas.value, forKey: downloadAreasDefaultsKey)
    }
    
    @discardableResult
    func download(region: MKCoordinateRegion,
                  refreshCachedFiles: Bool = true) -> Result<DownloadArea, DisplayError> {
        let r = getTileCacheDir()
        guard case .success(let downloadDir) = r else {
            return .failure(r.error!)
        }
        
        let area = DownloadArea(id: UUID(), region: region, status: .downloading)
        
        let neededTiles = neededTiles(region: region)
        let overlay = ChartTileOverlay(fontSize: .medium)
        Publishers.MergeMany(neededTiles.map { [unowned self] (tilePath) -> AnyPublisher<TilePath, DisplayError> in
            let to = downloadFileURL(downloadDir: downloadDir, tilePath: tilePath)
            if !refreshCachedFiles && fileManager.fileExists(atPath: to.path) {
                return Just(tilePath)
                    .setFailureType(to: DisplayError.self)
                    .eraseToAnyPublisher()
            }
            return self.downloadTile(from: overlay.url(forTilePath: tilePath), to: to)
                .retry(3)
                .map { tilePath }
                .eraseToAnyPublisher()
        })
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
                // todo Display global error
                logger.log("Download Area failed: \(error)")
                self?.updateDownloadAreaStatuses(event: .failed((area.id, error)))
            } else {
                self?.updateDownloadAreaStatuses(event: .complete(area.id))
            }
        }, receiveValue: {
            [weak self] in self?.downloadedTiles.value.insert($0)
        })
        .store(in: &cancellables)
        
        downloadedAreas.value.append(area)
        
        return .success(area)
    }
    
    func downloadProgressPublisher(area: DownloadArea) -> AnyPublisher<Float?, Never> {
        if case .downloading = area.status {
            let needed = neededTiles(region: area.region)
            return downloadedTiles
                .map { downloadedTiles in
                    let downloaded = needed.filter { downloadedTiles.contains($0) }
                    return Float(downloaded.count) / Float(needed.count)
                }
                .eraseToAnyPublisher()
        }
        return Just(nil).eraseToAnyPublisher()
    }
    
    func getTile(path: TilePath) -> Data? {
        guard downloadedTiles.value.contains(path),
            case .success(let dir) = getTileCacheDir() else {
            return nil
        }
        return try? Data(contentsOf: downloadFileURL(downloadDir: dir, tilePath: path))
    }
    
    // MARK: - Initialize
    
    private func initializeInBackgroundQueue() {
        
        // load list of downloaded tiles from documents directory.
        var tilePaths = Set<TilePath>()
        if case .success(let url) = self.getTileCacheDir() {
            do {
                let files = try self.fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                tilePaths = Set(files.compactMap { tilePath(downloadFileURL: $0) })
            } catch {
                logger.log("Unable to read cache directory.")
            }
        } else {
            logger.log("Unable to read cache directory. \(self.getTileCacheDir().error?.debugDescription ?? "null")")
        }
        
        // load areas
        var areas = [DownloadArea]()
        if let loadedAreas: [DownloadArea] = defaults.codable(forKey: downloadAreasDefaultsKey) {
            // Verify that area status matches files
            areas = loadedAreas.map { area in
                let neededTiles = neededTiles(region: area.region)
                
                let count = neededTiles.count
                let total = calculateAreaFileSizeBytes(area: area)
                let average = Float(total) / Float(count)
                logger.log("Average files size in bytes: \(average)")
                
                switch area.status {
                case .downloading:
                    var updated = area
                    updated.status = neededTiles.allSatisfy(tilePaths.contains) ?
                        .complete : .failed(errorString: "Download interupted")
                    if updated.sizeBytes == nil {
                        updated.sizeBytes = calculateAreaFileSizeBytes(area: area)
                    }
                    return updated
                case .complete:
                    var updated = area
                    updated.status = neededTiles.allSatisfy(tilePaths.contains) ?
                        .complete : .failed(errorString: "Download removed")
                    return updated
                case .failed(errorString: let errorString):
                    var updated = area
                    updated.status = neededTiles.allSatisfy(tilePaths.contains) ?
                        .complete : .failed(errorString: errorString)
                    if updated.sizeBytes == nil {
                        updated.sizeBytes = calculateAreaFileSizeBytes(area: area)
                    }
                    return updated
                }
            }
        }
        
        DispatchQueue.main.async {
            self.downloadedTiles.send(tilePaths)
            self.downloadedAreas.value = areas
            self.cacheReady.send(true)
        }
    }
    
    
    // MARK: - Download
    
    private func updateDownloadAreaStatuses(event: UpdateEvent) {
        downloadedAreas.value = downloadedAreas.value.map { area in
            switch (area.status) {
            case .downloading:
                switch event {
                case .failed(let (id, error)) where id == area.id:
                    var updated = area
                    updated.status = .failed(errorString: "\(error)")
                    return updated
                case .complete(let id) where id == area.id:
                    var updated = area
                    updated.status = .complete
                    updated.sizeBytes = calculateAreaFileSizeBytes(area: area)
                    return updated
                default:
                    return area
                }
                
            // failed and complete areas currently do not have mutations (until delete.... and update....)
            case .failed, .complete:
                return area
            }
        }
    }
    
    let diskQueue = DispatchQueue(label: "Disk Queue", qos: .background)
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
            .tryMap { (data: Data, fileURL: URL) in
                try data.write(to: fileURL)
                var fileURL = fileURL
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try fileURL.setResourceValues(values)
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
            return neededTiles(region: area.region)
                .map { (tile) -> Int in
                    let url = downloadFileURL(downloadDir: downloadDir, tilePath: tile)
                    let bytes = try? fileManager.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? UInt64
                    return Int(bytes ?? 0)
                }
                .reduce(0) { $0 + $1 }
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


func neededTiles(region: MKCoordinateRegion,
                 zRange: ClosedRange<Int> = ChartTileOverlay.minimumZ ... ChartTileOverlay.maximumZ) -> Set<TilePath> {
    Set(zRange.flatMap { (z) -> [MKTileOverlayPath] in
        let topLeft = tilePath(region.northWest, zoom: z)
        let bottomRight = tilePath(region.southEast, zoom: z)
        return (topLeft.x ... bottomRight.x).flatMap { x in
            (topLeft.y ... bottomRight.y).map {
                MKTileOverlayPath(x: x, y: $0, z: z)
            }
        }
    })
}

private func tilePath(_ coordinate: CLLocationCoordinate2D, zoom: Int) -> TilePath {
    let lat_rad = Float(coordinate.latitude) * .pi / 180
    let n = pow(2, Float(zoom))
    let xtile = Int((Float(coordinate.longitude) + 180.0) / 360.0 * n)
    let ytile = Int((1.0 - asinh(tan(lat_rad)) / .pi) / 2.0 * n)
    return .init(x: xtile, y: ytile, z: zoom, contentScaleFactor: 1)
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

