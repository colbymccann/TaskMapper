//
//  TaskMapperApp.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/9/24.
//

import SwiftUI

@main
struct TaskMapperApp: App {
    @StateObject var dataController = DataController()
    @StateObject var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
}
