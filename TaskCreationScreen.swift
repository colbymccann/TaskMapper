//
//  TaskCreationScreen.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/14/24.
//

import SwiftUI
import CoreData
import MapKit

struct TaskCreationScreen: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var taskLocationIdea: String = "nothing yet"
    @State private var taskAddress: String = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var hasPickedLocation = false
    @State private var location: MKMapItem?
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Name", text: $taskName)
                    TextField("Description", text: $taskDescription)
                    
                }
                Section(header: Text("Location")) {
                    if hasPickedLocation {
                        NavigationLink(destination: MapPickerView(position: $position, returnedLocation: $location, hasPickedLocation: $hasPickedLocation)){
                            VStack {
                                Map(position: $position, interactionModes: []) {
                                    Marker(location!.name!, systemImage:"mappin", coordinate: location!.placemark.location!.coordinate)

                                }
                                .frame(height: 300)
                                VStack {
                                    Text(location?.name ?? "No Name")
                                    HStack {
                                        Text(location?.placemark.subThoroughfare ?? "")
                                        Text(location?.placemark.thoroughfare ?? "")
                                    }
                                    HStack {
                                        Text(location?.placemark.locality ?? "")
                                        Text(location?.placemark.administrativeArea ?? "")
                                    }
                                }
                                
                                 

                            }
                        }
                    } else {
                        NavigationLink(destination: MapPickerView( position: $position, returnedLocation: $location, hasPickedLocation: $hasPickedLocation)) {
                            VStack {
                                Map(position: $position, interactionModes: []) {
                                    
                                }
                                .frame(height: 300)
                                Text("Pick a location above")
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("New Task", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                   dismiss()
                },
                trailing: Button("Save") {
                    let newTask = MyTask(context: dataController.container.viewContext)
                    newTask.taskID = UUID.init()
                    newTask.taskTitle = taskName
                    newTask.taskDesc = taskDescription
                    newTask.taskLocationIdea = location?.name ?? "No Name"
                    newTask.taskLocationSubThoroughfare = location?.placemark.subThoroughfare ?? ""
                    newTask.taskLocationThoroughfare = location?.placemark.thoroughfare ?? ""
                    newTask.taskLocationLocality = location?.placemark.locality ?? ""
                    newTask.taskLocationAdministrativeArea = location?.placemark.administrativeArea ?? ""
                    newTask.taskLocationPostalCode = location?.placemark.postalCode ?? ""
                    newTask.taskLocationCountry = location?.placemark.country ?? ""
                    newTask.taskLocation =  CLLocationCoordinate2D(latitude: location?.placemark.coordinate.latitude ?? 0.0, longitude:  location?.placemark.coordinate.longitude ?? 0.0)
                    dataController.queueSave()
                    dismiss()
                }.disabled(taskName.isEmpty) // Disable save if no name
            )
        }
    }

}


#Preview {
    TaskCreationScreen().environmentObject(LocationManager())
}
