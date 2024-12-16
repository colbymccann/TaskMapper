//
//  TravelingSalesmanWithMapKit.swift
//  TaskMapper
//
//  Created by Colby McCann on 10/18/24.
//

import MapKit
import SwiftUICore
class TravelingSalesmanWithMapKit {
    static func runNumEpisodes( env: inout DeliveryEnvironment, agent: inout DeliveryQAgent, pointsOrder: inout [Int], numEpisodes: Int = 1000) -> [Double] {
        var rewards: [Double] = []
        var reward: Double = 0.0
        for _ in (0..<numEpisodes) {
            (env, agent, reward) = runEpisode(env: env, agent: agent)
            pointsOrder = env.steps
            rewards.append(reward)
        }

        return rewards
    }
    
    static func runNumEpisodesWithProgress(
            env: inout DeliveryEnvironment,
            agent: inout DeliveryQAgent,
            pointsOrder: inout [Int],
            numEpisodes: Int = 1000,
            progressUpdater: @escaping (Int) -> Void
        ) async -> [Double] {
            var rewards: [Double] = []
            var reward: Double = 0.0

            for episode in 0..<numEpisodes {
                (env, agent, reward) = runEpisode(env: env, agent: agent)
                pointsOrder = env.steps
                rewards.append(reward)
                progressUpdater(episode)
                await Task.yield()  // Allow UI to update
            }

            return rewards
    }
    
    static func runEpisode(env: DeliveryEnvironment, agent: DeliveryQAgent) -> (DeliveryEnvironment, DeliveryQAgent, Double) {
        var step = env.reset()
        agent.resetMemory()
        var episodeReward = 0.0
        var index = 0
        while index < env.numStops {
            agent.rememberState(state: step)
            var action = agent.act(stepRow: step)
            var nextStep: Int
            var reward: Double
            var done: Bool
            (nextStep, reward, done) = env.step(destination: action)
            reward = -reward
            agent.train(stepRow: step, action: action, reward: reward, nextStepRow: nextStep)
            episodeReward += reward
            step = nextStep
            index += 1
            if done {
                break
            }
        }
        return (env, agent, episodeReward)
    }
    
    class DeliveryEnvironment {
        private var dataController: DataController
        private var locationManager: LocationManager
        var numStops: Int
        var actionSpace: Int
        var observationSpace: Int
        var tasks: [MyTask]
        var locations: [CLLocationCoordinate2D]
        var qStops : [[Double]]?
        var steps: [Int] = []
        

        init (dataController: DataController, locationManager: LocationManager) {
            self.dataController = dataController
            self.locationManager = locationManager
            var numTasks = dataController.getTasksLength()
            self.numStops = numTasks
            self.tasks = dataController.tasksList.sorted()
            if locationManager.userLocation != nil {
                locations = [locationManager.userLocation!]
                numStops += 1
            } else {
                locations = []
            }
            self.actionSpace = numStops
            self.observationSpace = numStops
            for task in tasks {
                if task.taskLocation != nil {
                    var location = task.taskLocation!
                    locations.append(location)
                }
            }
            self.qStops = generateQStops(for: locations)
        }
        

        func calculateTravelTime(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (TimeInterval) -> Void) {
            let sourcePlacemark = MKPlacemark(coordinate: start)
            let destinationPlacemark = MKPlacemark(coordinate: destination)
            print("source")
            print(sourcePlacemark)
            print("dest")
            print(destinationPlacemark)
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: sourcePlacemark)
            request.destination = MKMapItem(placemark: destinationPlacemark)
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            
            directions.calculate { response, error in
                guard let response = response else {
                    print("Error calculating directions: \(error?.localizedDescription ?? "Unknown error")")
                    completion(0) // Return distance 0 in case of error
                    return
                }
                
                // Get the total distance from the first route
                let travelTime = response.routes.first?.expectedTravelTime ?? 0
                completion(travelTime)
            }
        }
        
        func generateQStops(for locations: [CLLocationCoordinate2D]) -> [[CLLocationDistance]] {
            let n = locations.count
            var qStops = Array(repeating: Array(repeating: TimeInterval(0.0), count: n), count: n) // Initialize a 2D array of zeros

            for i in 0..<n {
                for j in 0..<n {
                    if i != j { // Avoid calculating distance to self
                        qStops[i][j] = locations[i].distance(to: locations[j])
                    } else {
                        qStops[i][j] = 0.0 // TravelTime to self is 0
                    }
                }
            }

            return qStops
        }
        
        func reset() -> Int {
            steps = []
            steps.append(0)
            return 0
        }
        
        func step(destination: Int) -> (newState: Int, reward: Double,done: Bool){
            var state = getState()
            var newState = destination
            var reward = qStops![state][newState]

            steps.append(destination)
            var done = steps.count == numStops

            return (newState,reward,done)
        }
        
        func getState() -> Int{
            steps.last!
        }
                
    }
    class QAgent {
        var statesSize: Int
        var actionsSize: Int
        var epsilon: Double
        var epsilonMin: Double
        var epsilonDecay: Double
        var gamma: Double
        var learningRate: Double
        var Q: [[Double]]
        
        init(statesSize: Int, actionsSize: Int, epsilon: Double = 1.0,
             epsilonMin: Double = 0.01, epsilonDecay: Double = 0.999, gamma: Double = 0.95, learningRate: Double = 0.8) {
            self.statesSize = statesSize
            self.actionsSize = actionsSize
            self.epsilon = epsilon
            self.epsilonMin = epsilonMin
            self.epsilonDecay = epsilonDecay
            self.gamma = gamma
            self.learningRate = learningRate
            self.Q = QAgent.buildModel(statesSize: statesSize,actionsSize: actionsSize)
        }
        
        static func buildModel(statesSize: Int, actionsSize: Int) -> [[Double]] {
            var returned: [[Double]] = []
            for x in 0..<statesSize {
                var miniList: [Double] = []
                for _ in 0..<actionsSize {
                    miniList.append(0)
                }
                returned.append(miniList)
            }
            return returned
        }
        
        func train(stepRow: Int, action: Int, reward: Double, nextStepRow: Int) {
            var levelOne = (gamma * Q[nextStepRow].max()!)
            var levelTwo = reward + levelOne
            var levelThree = learningRate * levelTwo
            var levelFour = levelThree - Q[stepRow][action]
            Q[stepRow][action] = Q[stepRow][action] + levelFour
            if epsilon > epsilonMin {
                epsilon *= epsilonDecay
            }
        }
        
        func act(stepRow: Int) -> Int {
            var q = Q[stepRow]
            var action: Int
            if Double.random(in: 0..<1) > epsilon {
                if let maxIndex = q.enumerated().max(by: { $0.element < $1.element })?.offset {
                    action = maxIndex
                } else {
                    action = Int.random(in: 0..<actionsSize)
                }
            } else {
                action = Int.random(in: 0..<actionsSize)
            }
            return action
        }
                    
    }
    
    class DeliveryQAgent: QAgent {
        var statesMemory: [Int] = []
        init (statesSize: Int, actionsSize: Int) {
            super.init(statesSize: statesSize, actionsSize: actionsSize)
        }
        
        func rememberState(state: Int) {
            statesMemory.append(state)
        }
        
        func resetMemory() {
            statesMemory = []
        }
        
        override func act(stepRow: Int) -> Int {
            var q = Q[stepRow]
            for state in statesMemory {
                q[state] = -Double.infinity
            }
            var action: Int
            if Double.random(in: 0..<1.0) > epsilon {
                if let maxIndex = q.enumerated().max(by: { $0.element < $1.element })?.offset {
                    action = maxIndex
                } else {
                    action = Int.random(in: 0..<actionsSize)
                }
            } else {
                action = (0..<actionsSize).random(without: statesMemory)
            }
            return action
        }
    }
}


extension CLLocationCoordinate2D {

    func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
        MKMapPoint(self).distance(to: MKMapPoint(to))
    }

}

