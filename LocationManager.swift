//
//  LocationManager.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/14/24.
//

import Foundation
import CoreLocation
import MapKit

struct SearchCompletions: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    var url: URL?
}

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let location: CLLocationCoordinate2D
    let name: String

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    @Published var locationManager = CLLocationManager()
    @Published var completer = MKLocalSearchCompleter()
    @Published var completions = [SearchCompletions]()
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ) {
        didSet {
            completer.region = region
        }
    }
    @Published var currentSearchResults: [SearchResult] = []
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        self.completer.delegate = self
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func update(queryFragment: String) {
            completer.resultTypes = .pointOfInterest
            completer.queryFragment = queryFragment
        }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map { completion in
                    // Get the private _mapItem property
                    let mapItem = completion.value(forKey: "_mapItem") as? MKMapItem

                    return .init(
                        title: completion.title,
                        subTitle: completion.subtitle,
                        url: mapItem?.url
                    )
                }
    }
    
    func search(with query: String, coordinate: CLLocationCoordinate2D? = nil) async throws -> [SearchResult] {
        let mapKitRequest = MKLocalSearch.Request()
        mapKitRequest.naturalLanguageQuery = query
        mapKitRequest.resultTypes = .pointOfInterest
        if let coordinate {
            mapKitRequest.region = .init(.init(origin: .init(coordinate), size: .init(width: 1, height: 1)))
        }
        let search = MKLocalSearch(request: mapKitRequest)

        let response = try await search.start()

        return response.mapItems.compactMap { mapItem in
            guard let location = mapItem.placemark.location?.coordinate else { return nil }
            let name = mapItem.name ?? ""
            return .init(location: location, name: name)
        }
    }
    
    static func getAddress(location: CLLocationCoordinate2D, completion: @escaping (CLPlacemark?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in 
            if let error = error {
                print("Error during reverse geocoding: \(error.localizedDescription)")
                return
            }
            if let placemark = placemarks?.first {
                completion(placemark)
            } else {
                completion(nil)
            }
        }
        
    }
}
