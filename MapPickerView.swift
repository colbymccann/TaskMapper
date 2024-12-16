//
//  MapPickerView.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/14/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapPickerView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.presentationMode) var presentationMode
    @Binding var position:  MapCameraPosition
    @State private var isSheetPresented: Bool = true
    @State private var searchResults = [SearchResult]()
    @State private var selectedLocation: SearchResult?
    @State private var mapCenterCoordinate: CLLocationCoordinate2D?
    @State var showSaveButton = false
    @Binding var returnedLocation: MKMapItem?
    @Binding var hasPickedLocation: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Map(position: $position, interactionModes: [.pan, .zoom, .rotate], selection: $selectedLocation) {
                    ForEach(searchResults) { result in
                        Marker(result.name, systemImage:"mappin", coordinate: result.location)
                        .tag(result)
                    }
                    if selectedLocation != nil {
                        Marker(selectedLocation!.name, systemImage:"mappin", coordinate: selectedLocation!.location)
                    } else if returnedLocation != nil {
                        Marker(returnedLocation!.name!, systemImage: "mappin", coordinate: returnedLocation!.placemark.coordinate)
                    }
                    UserAnnotation()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onMapCameraChange { context in
                    mapCenterCoordinate = context.region.center
                    locationManager.region = context.region
                }
                .onChange(of: selectedLocation) {
                    handleSelectedLocationChange(selectedLocation)
                }
                .onChange(of: searchResults) {
                    selectedLocation = nil
                }
                
                .sheet(isPresented: $isSheetPresented) {
                    SheetView(searchResults: $searchResults, selectedLocation: $selectedLocation, mapCenterCoordinate: $mapCenterCoordinate)
                }
            }
            if showSaveButton {
                
                Button(action: {
                    LocationManager.getAddress(location: selectedLocation!.location) { mark in
                        if let mark = mark {
                            let myMark = MKPlacemark(placemark: mark)
                            returnedLocation = MKMapItem(placemark: myMark)
                            hasPickedLocation = true
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    
                }) {
                    Text("Save")
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        
    }
    
    private func handleSelectedLocationChange(_ newValue: SearchResult?) {
        searchResults = [SearchResult]()
        if newValue == nil {
            showSaveButton = false
        } else {
            print("here's the location")
            LocationManager.getAddress(location: newValue!.location) { mark in
                if let mark = mark {
                    let myMark = MKPlacemark(placemark: mark)
                    returnedLocation = MKMapItem(placemark: myMark)
                    print("here's the location")
                    print(returnedLocation!)
                    print("name: \(returnedLocation!.name)")
                    print("location: \(myMark.location)")
                    print("country: \(myMark.country)" )
                    print("subThoroughFare: \(myMark.subThoroughfare)")
                    print("thoroughFare: \(myMark.thoroughfare)")
                    print("locality: \(myMark.locality)")
                    print("postalCode: \(myMark.postalCode)")
                    print("administrativeArea: \(myMark.administrativeArea)")

                }
            }
            mapCenterCoordinate = newValue?.location
            showSaveButton = true
            position = .region(MKCoordinateRegion(
                center: newValue!.location,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }
        
}



#Preview {
    @Previewable @State var fakeMK: MKMapItem?
    @Previewable @State var fakePosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Previewable @State var hasPickedLocation = false
    MapPickerView(position: $fakePosition, returnedLocation: $fakeMK, hasPickedLocation: $hasPickedLocation).environmentObject(LocationManager())
}
