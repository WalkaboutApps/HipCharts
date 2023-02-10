//
//  TileLoader.swift
//  HipCharts
//
//  Created by Fish Sticks on 2/7/23.
//

import Foundation
import CoreLocation
import Combine

class TileLoader {
    let mapRegion = PassthroughSubject<MapRegionChangeEvent, Never>()
    private let queue = DispatchQueue(label: "TileLoader", qos: .default)
    private let session = URLSession(configuration: .ephemeral)
    private var latestZoomLevel: Int?
    private var cancellables = [AnyCancellable]()
    private let activeTasks = CurrentValueSubject<[LoadRequest: URLSessionTask], Never>([:])

    var isLoading: AnyPublisher<Bool, Never> {
        activeTasks.map {
            $0.first { (key: LoadRequest, value: URLSessionTask) in
                value.state == .running
            } != nil
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    init() {
        bind()
    }
    
    func load(_ request: LoadRequest, completion: @escaping (Data?, Error?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.latestZoomLevel = request.zoomLevel
            let task = self.session.dataTask(with: .init(url: request.url)) { [weak self] data, response, error in
                self?.queue.async { [weak self] in
                    self?.activeTasks.value.removeValue(forKey: request)
                    completion(data, error)
                }
            }
            task.resume()
            self.activeTasks.value[request] = task
        }
    }
    
    private func bind() {
        // cancel loads of tiles if zoom level has changed or if tile is too far from current map region.
        mapRegion
            .receive(on: queue)
            .sink { [weak self] event in
                self?.activeTasks.value.forEach({ key, value in
                    if self?.latestZoomLevel != key.zoomLevel,
                       !event.region.contains(key.coordinate,
                                              buffer: .init(latitude: event.region.span.latitudeDelta,
                                                            longitude: event.region.span.longitudeDelta)) {
                        value.cancel()
                    }
                })
        }
            .store(in: &cancellables)
    }
}

extension TileLoader {
    struct LoadRequest: Hashable {
        let url: URL
        let coordinate: CLLocationCoordinate2D
        let zoomLevel: Int
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
        }
    }
}
