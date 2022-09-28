////
////  SwiftUI+UserDefaults.swift
////  FreeCharts
////
////  Created by Fish Sticks on 9/18/22.
////
//
//import Foundation
//import Combine
//import SwiftUI
//
//
//final class PublisherObservableObject: ObservableObject {
//    
//    var subscriber: AnyCancellable?
//    
//    init(publisher: AnyPublisher<Void, Never>) {
//        subscriber = publisher.sink(receiveValue: { [weak self] _ in
//            self?.objectWillChange.send()
//        })
//    }
//}
//
//final class Preferences {
//    
//    static let standard = Preferences(userDefaults: .standard)
//    fileprivate let userDefaults: UserDefaults
//    
//    /// Sends through the changed key path whenever a change occurs.
//    var preferencesChangedSubject = PassthroughSubject<AnyKeyPath, Never>()
//    
//    init(userDefaults: UserDefaults) {
//        self.userDefaults = userDefaults
//    }
//    
//    @UserDefault("should_show_hello_world")
//    var shouldShowHelloWorld: Bool = false
//}
//
//@propertyWrapper
//struct Preference<Value>: DynamicProperty {
//    
//    @ObservedObject private var preferencesObserver: PublisherObservableObject
//    private let keyPath: ReferenceWritableKeyPath<Preferences, Value>
//    private let preferences: Preferences
//    
//    init(_ keyPath: ReferenceWritableKeyPath<Preferences, Value>, preferences: Preferences = .standard) {
//        self.keyPath = keyPath
//        self.preferences = preferences
//        let publisher = preferences
//            .preferencesChangedSubject
//            .filter { changedKeyPath in
//                changedKeyPath == keyPath
//            }.map { _ in () }
//            .eraseToAnyPublisher()
//        self.preferencesObserver = .init(publisher: publisher)
//    }
//
//    var wrappedValue: Value {
//        get { preferences[keyPath: keyPath] }
//        nonmutating set { preferences[keyPath: keyPath] = newValue }
//    }
//
//    var projectedValue: Binding<Value> {
//        Binding(
//            get: { wrappedValue },
//            set: { wrappedValue = $0 }
//        )
//    }
//}
