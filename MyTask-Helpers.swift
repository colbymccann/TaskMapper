//
//  Task.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/9/24.
//
import SwiftUI
import Foundation
import CoreData
import MapKit
extension MyTask {
    
    var taskTitle: String {
        get { title ?? ""}
        set { title = newValue}
    }
    
    var taskDesc: String {
        get { desc ?? ""}
        set { desc = newValue}
    }

    var taskLocationIdea: String {
        get { locationIdea ?? ""}
        set { locationIdea = newValue}
    }
    
    var taskLocation: CLLocationCoordinate2D? {
        get {CLLocationCoordinate2D(latitude: lat, longitude: lon)}
        set {
            lat = newValue!.latitude
            lon = newValue!.longitude
        }
    }
    
    var taskLocationSubThoroughfare: String {
        get { locationSubThoroughfare ?? ""}
        set { locationSubThoroughfare = newValue}
    }
    
    var taskLocationThoroughfare: String {
        get { locationThoroughfare ?? ""}
        set { locationThoroughfare = newValue}
    }
    
    var taskLocationLocality: String {
        get { locationLocality ?? ""}
        set { locationLocality = newValue}
    }
    
    var taskLocationAdministrativeArea: String {
        get { locationAdministrativeArea ?? ""}
        set { locationAdministrativeArea = newValue}
    }
    
    var taskLocationPostalCode: String {
        get { locationPostalCode ?? ""}
        set { locationPostalCode = newValue}
    }
    
    var taskLocationCountry: String {
        get { locationCountry ?? ""}
        set { locationCountry = newValue}
    }
    
    var taskID: UUID {
        get { myID ?? UUID.init()}
        set { myID = newValue}
    }
    
    var completedColor: Color {
        if isCompleted {
            return Color(red: 169/255, green: 169/255, blue: 169/255)
        } else {
            return .blue
        }
    }
    
    static var example: MyTask {
        let controller = DataController.preview
        let viewContext = controller.container.viewContext
        var sampleTask = MyTask(usedContext: viewContext)
        sampleTask.taskID = UUID.init()
        sampleTask.taskTitle = "Sample Task"
        sampleTask.taskDesc = "This is a sample task"
        sampleTask.taskLocationIdea = "Union Square"
        sampleTask.locationCountry = "United States"
        sampleTask.taskLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        return sampleTask
    }
}

extension MyTask: Comparable {
    public static func < (lhs: MyTask, rhs: MyTask) -> Bool {
        let left = lhs.taskTitle.localizedLowercase
        let right = rhs.taskTitle.localizedLowercase
        
        if left == right {
            return left < right
        } else {
            return left < right
        }
    }
    
    public static func == (lhs: MyTask, rhs: MyTask) -> Bool {
        lhs.taskID == rhs.taskID
    }
}
