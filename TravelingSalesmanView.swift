//
//  TravelingSalesmanView.swift
//  TaskMapper
//
//  Created by Colby McCann on 10/22/24.
//

import SwiftUI
import MapKit

struct TravelingSalesmanView: View {
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var locationManager: LocationManager
    @State private var progress: Double = 0.0
    @State private var totalEpisodes: Int = 1000
    @State private var rewards: [Double] = []
    @State private var calculationDone = true
    @State private var env: TravelingSalesmanWithMapKit.DeliveryEnvironment?

    var body: some View {
        VStack {
            Spacer()
            ProgressView(value: progress, total: 1.0)
                .padding()

            Button("Run Simulation") {
                Task {
                    env = await runSimulation()
                }
            }
            Spacer()
            Button("Export to Apple Maps"){
                if env != nil {
                    var locationOrder = env!.steps
                    var locations: [MKMapItem] = []
                    var sortedLocations: [MKMapItem] = []
                    if locationManager.userLocation != nil {
                        var item = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.userLocation!))
                        item.name = "Current Location"
                        locations.append(item)
                    }
                    for location in dataController.tasksList.sorted() {
                        var item = MKMapItem(placemark: MKPlacemark(coordinate: location.taskLocation!))
                        item.name = location.taskLocationIdea
                        locations.append(item)
                    }
                    for point in locationOrder {
                        sortedLocations.append(locations[point])
                    }
                    let launchOptions = [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ]
                    MKMapItem.openMaps(with: sortedLocations, launchOptions: launchOptions)
                }
            }.disabled(!calculationDone)
            
        }
    }

    func runSimulation() async -> TravelingSalesmanWithMapKit.DeliveryEnvironment {
        var numStates: Int
        var pointsOrder: [Int] = []
        if locationManager.userLocation != nil {
            numStates = dataController.getTasksLength() + 1
        } else {
            numStates = dataController.getTasksLength()
        }
        var env = TravelingSalesmanWithMapKit.DeliveryEnvironment(dataController: dataController, locationManager: locationManager)
        var agent = TravelingSalesmanWithMapKit.DeliveryQAgent(statesSize: numStates, actionsSize:numStates)
//        TravelingSalesmanWithMapKit.runNumEpisodes(env: &env, agent: &agent, pointsOrder: &pointsOrder)

        rewards = await TravelingSalesmanWithMapKit.runNumEpisodesWithProgress(
            env: &env,
            agent: &agent,
            pointsOrder: &pointsOrder,
            numEpisodes: totalEpisodes,
            progressUpdater: { episode in
                DispatchQueue.main.async {
                    progress = Double(episode) / Double(totalEpisodes)
                }
            }
        )
        calculationDone = true
        return env
    }
}

#Preview {
    TravelingSalesmanView().environmentObject(DataController.preview)
        .environmentObject(LocationManager())
}
