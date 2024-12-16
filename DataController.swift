//
//  DataController.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/23/24.
//

import CoreData
import SwiftUI
import MapKit

class DataController: ObservableObject {
    var container: NSPersistentContainer!
    let sampleLocationData: [[String:Any]] = [
        [
            "name": "Harvard University",
            "location": CLLocationCoordinate2D(latitude: 42.37286670,longitude: -71.11845360),
            "country": "United States",
            "subThoroughFare": "1350",
            "thoroughFare": "Massachusetts Ave",
            "locality": "Cambridge",
            "postalCode": "02138",
            "administrativeArea": "MA"
        ],
        [
            "name": "Massachusetts Institute of Technology",
            "location": CLLocationCoordinate2D(latitude: 42.35994920,longitude: -71.09268060),
            "country": "United States",
            "subThoroughFare": "105",
            "thoroughFare": "Massachusetts Ave",
            "locality": "Cambridge",
            "postalCode": "02139",
            "administrativeArea": "MA"
        ],
        [
            "name": "Northeastern University",
            "location": CLLocationCoordinate2D(latitude: 42.33982470, longitude: -71.08809610),
            "country": "United States",
            "subThoroughFare": "346",
            "thoroughFare": "Huntington Ave",
            "locality": "Boston",
            "postalCode": "02115",
            "administrativeArea": "MA"
        ],
        [
            "name": "Tufts University",
            "location": CLLocationCoordinate2D(latitude: 42.34656950, longitude: -71.08677170),
            "country": "United States",
            "subThoroughFare": "419",
            "thoroughFare": "Boston Ave",
            "locality": "Medford",
            "postalCode": "02155",
            "administrativeArea": "MA"
        ],
        [
            "name": "Boston University",
            "location": CLLocationCoordinate2D(latitude: 42.34960710, longitude: -71.09975910),
            "country": "United States",
            "subThoroughFare": "595",
            "thoroughFare": "Commonwealth Ave",
            "locality": "Boston",
            "postalCode": "02215",
            "administrativeArea": "MA"
        ],
        [
            "name": "Boston College",
            "location": CLLocationCoordinate2D(latitude: 42.33602440,longitude: -71.16924050),
            "country": "United States",
            "subThoroughFare": "21",
            "thoroughFare": "Campanella Way",
            "locality": "Newton",
            "postalCode": "02467",
            "administrativeArea": "MA"
        ],
        [
            "name": "Brandeis University",
            "location": CLLocationCoordinate2D(latitude: 42.36505100, longitude: -71.25969700),
            "country": "United States",
            "subThoroughFare": "415",
            "thoroughFare": "South St",
            "locality": "Waltham",
            "postalCode": "02453",
            "administrativeArea": "MA"
        ],
        [
            "name": "Berkelee College of Music",
            "location": CLLocationCoordinate2D(latitude: 42.34656950,longitude: -71.08677170),
            "country": "United States",
            "subThoroughFare": "10",
            "thoroughFare": "Belvidere St",
            "locality": "Boston",
            "postalCode": "02115",
            "administrativeArea": "MA"
        ],
        [
            "name": "Babson College",
            "location": CLLocationCoordinate2D(latitude: 42.29897700,longitude: -71.26508300),
            "country": "United States",
            "subThoroughFare": "10",
            "thoroughFare": "Babson College Dr",
            "locality": "Wellesley Hills",
            "postalCode": "02481",
            "administrativeArea": "MA"
        ],
        [
            "name": "Olin College of Engineering",
            "location": CLLocationCoordinate2D(latitude: 42.29332610,longitude: -71.26341820),
            "country": "United States",
            "subThoroughFare": "1000",
            "thoroughFare": "Olin Way",
            "locality": "Needham",
            "postalCode": "02492",
            "administrativeArea": "MA"
        ],
        [
            "name": "Olin College of Engineering",
            "location": CLLocationCoordinate2D(latitude: 42.29332610,longitude: -71.26341820),
            "country": "United States",
            "subThoroughFare": "1000",
            "thoroughFare": "Olin Way",
            "locality": "Needham",
            "postalCode": "02492",
            "administrativeArea": "MA"
        ],
        [
            "name": "University of Massachusetts",
            "location": CLLocationCoordinate2D(latitude: 42.31276360,longitude: -71.03864800),
            "country": "United States",
            "subThoroughFare": "425",
            "thoroughFare": "University Dr N",
            "locality": "Boston",
            "postalCode": "02115",
            "administrativeArea": "MA"
        ]
    ]
    
    private var saveTask: Task<Void, Error>?
    @Published var selectedTask: MyTask?
    @Published var tasksList: [MyTask] = []
    
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Main")
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )
        
        if inMemory {
                container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }

            #if DEBUG
            if CommandLine.arguments.contains("enable-testing") {
                self.deleteAll()
                UIView.setAnimationsEnabled(false)
            }
            #endif
        }
        fetchTasks()
    }
    
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "Main", withExtension: "momd") else {
            fatalError("Failed to locate model file.")
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load model file.")
        }

        return managedObjectModel
    }()
    
    func save() {
        saveTask?.cancel()
        fetchTasks()
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }

    func queueSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try await Task.sleep(for: .seconds(3))
            save()
        }
    }
    
    func delete(_ object: NSManagedObject) {
        objectWillChange.send()
        container.viewContext.delete(object)
        save()
    }
    
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }

    func deleteAll() {
        let request1: NSFetchRequest<NSFetchRequestResult> = MyTask.fetchRequest()
        delete(request1)
//
        let request2: NSFetchRequest<NSFetchRequestResult> = MyTaskList.fetchRequest()
        delete(request2)
//
        save()
    }
    
    func createSampleData() {
        let viewContext = container.viewContext
        for location in sampleLocationData {
            let task = MyTask(context: viewContext)
            task.taskID = UUID()
            task.taskTitle = "Go to \(location["name"]!)"
            task.taskDesc = "Sample desc \(location["name"]!)"
            task.taskLocationIdea = "\(location["name"]!)"
            task.taskLocation = location["location"] as? CLLocationCoordinate2D ?? CLLocationCoordinate2D(latitude: 0.0,longitude: 0.0)
            task.taskLocationCountry = location["country"] as? String ?? ""
            task.taskLocationLocality = location["locality"] as? String ?? ""
            task.taskLocationThoroughfare = location["thoroughFare"] as? String ?? ""
            task.taskLocationPostalCode = location["postalCode"] as? String ?? ""
            task.taskLocationSubThoroughfare = location["subThoroughFare"] as? String ?? ""
            task.taskLocationAdministrativeArea = location["administrativeArea"] as? String ?? ""
            task.isCompleted = false
        }
        try? viewContext.save()
    }
    
    func fetchTasks() {
        let request = MyTask.fetchRequest()
        tasksList = (try? container.viewContext.fetch(request)) ?? []
    }
    
    func getTasksLength() -> Int {
        return tasksList.count
    }
    
    func toggleCompleted(task: MyTask) {
        objectWillChange.send()
        task.isCompleted.toggle()
        save()
    }

    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        dataController.fetchTasks()
        return dataController
    }()
}

public extension NSManagedObject {

    convenience init(usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }
}
