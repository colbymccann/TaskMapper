//
//  TaskViewScreen.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/23/24.
//

import SwiftUI
import MapKit

struct TaskViewScreen: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State var editMode: Bool = false
    @ObservedObject var task: MyTask
    @State var mapPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    ))
    @State private var notUsed = false
    @State private var location: MKMapItem?
    
    private var taskLocationRegion: MKCoordinateRegion {
        return MKCoordinateRegion(
            center: task.taskLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    if editMode {
                        TextField("Name", text: $task.taskTitle)
                        TextField("Description", text: $task.taskDesc)
                    } else {
                        Text(task.taskTitle)
                        Text(task.taskDesc)
                    }
                }
                Section(header: Text("Location")) {
                    if editMode {
                        NavigationLink(destination: MapPickerView(position: $mapPosition, returnedLocation: $location, hasPickedLocation: $notUsed)){
                                VStack {
                                    Map(position: $mapPosition, interactionModes: []) {
                                        Marker(task.taskLocationIdea, systemImage:"mappin", coordinate: task.taskLocation!)

                                    }
                                    .onAppear {
                                        mapPosition = .region(taskLocationRegion)
                                    }
                                    .frame(height: 300)
                                    VStack {
                                        Text(task.taskLocationIdea)
                                        HStack {
                                            Text(task.taskLocationSubThoroughfare)
                                            Text(task.taskLocationThoroughfare)
                                        }
                                        HStack {
                                            Text(task.taskLocationLocality)
                                            Text(task.taskLocationAdministrativeArea)
                                        }
                                    }
                                    
                                     

                                }
                            }
                    } else {
                        VStack {
                            Map(position: $mapPosition, interactionModes: []) {
                                Marker(task.taskLocationIdea, systemImage:"mappin", coordinate: task.taskLocation!)

                            }
                            .onAppear {
                                mapPosition = .region(taskLocationRegion)
                            }
                            .frame(height: 300)
                            VStack {
                                Text(task.taskLocationIdea)
                                HStack {
                                    Text(task.taskLocationSubThoroughfare)
                                    Text(task.taskLocationThoroughfare)
                                }
                                HStack {
                                    Text(task.taskLocationLocality)
                                    Text(task.taskLocationAdministrativeArea)
                                }
                            }
                            
                             

                        }
                    }

                }
            }
            
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            editMode.toggle()
                            if editMode {
//                                print("inside")
//                                print(location)
                                if location != nil {
//                                    print(location!)
//                                    print("anme")
//                                    print(location!.name)
                                    task.taskLocationIdea = location!.name ?? "No Name"
                                    task.taskLocationSubThoroughfare = location?.placemark.subThoroughfare ?? ""
                                    task.taskLocationThoroughfare = location?.placemark.thoroughfare ?? ""
                                    task.taskLocationLocality = location?.placemark.locality ?? ""
                                    task.taskLocationAdministrativeArea = location?.placemark.administrativeArea ?? ""
                                    task.taskLocationPostalCode = location?.placemark.postalCode ?? ""
                                    task.taskLocationCountry = location?.placemark.country ?? ""
                                    task.taskLocation =  CLLocationCoordinate2D(latitude: location?.placemark.coordinate.latitude ?? 0.0, longitude:  location?.placemark.coordinate.longitude ?? 0.0)
                                    dataController.queueSave()
                                }

                            }
                        }
                        
                    }) {
                        if editMode {
                            Text("Save")
                        } else {
                            Text("Edit")
                        }
                    }
                    
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !editMode {
                        
                        Button(action: {
                            withAnimation {
                                dismiss()
                            }
                            
                        }) {
                            Text("Dismiss")
                        }
                    }
                    
                    
                }
                
            }
        }
        
        .padding()
        
        
    }
}

struct TaskViewScreen_Previews: PreviewProvider {
    static var previews: some View {
        return TaskViewScreen(editMode: false, task: .example).environmentObject(DataController.preview)
            .environmentObject(LocationManager())
    }
}
