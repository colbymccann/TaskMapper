//
//  TravelingSalesman.swift
//  TaskMapper
//
//  Created by Colby McCann on 10/2/24.
//


import Foundation
import SwiftUI
import CoreML
//import PlaygroundSupport

struct TravelingSalesmanStruct {
    @State var points: [CGPoint] = []
    @State var pointsOrder: [Int] = []
    @State private var isAnimating = false
    @State private var currentLineIndex = 0
    func runThings () {
        var numStops = 50
        var maxBox = 300
        var env = TravelingSalesman.DeliveryEnvironment(numStops: numStops, maxBox: 300)
        var agent = TravelingSalesman.DeliveryQAgent(statesSize: numStops, actionsSize: numStops)
        TravelingSalesman.runNumEpisodes(env: &env, agent: &agent, pointsOrder: &pointsOrder)
        points = env.points
    }
}
    
    
//    var body: some View {
//            VStack {
//                ZStack {
//                    // Draw the points
//                    ForEach(0..<points.count, id: \.self) { index in
//                        Circle()
//                            .fill(Color.red)
//                            .frame(width: 10, height: 10)
//                            .position(points[index])
//                            .opacity(isAnimating ? 1 : 0)
//                            .animation(.easeIn(duration: 0.5), value: isAnimating)
//                        
//                        if index == pointsOrder.first {
//                            Text("START")
//                                .font(.caption)
//                                .foregroundColor(.black)
//                                .position(x: points[index].x + 20, y: points[index].y - 10)
//                                .opacity(isAnimating ? 1 : 0)
//                        }
//                    }
//                    
//                    // Draw the dashed lines
//                    Path { path in
//                        if pointsOrder.count > 1 {
//                            for i in 0..<points.count {
//                                let startIndex = pointsOrder[i]
//                                let endIndex = pointsOrder[(i + 1) % pointsOrder.count]
//                                path.move(to: points[startIndex])
//                                path.addLine(to: points[endIndex])
//                            }
//                        }
//                    }
//                    .stroke(.blue, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [5]))
//                    
//                }
//                .frame(width: 300, height: 300)
//                .border(Color.gray, width: 1)
//                
//                Button("Run") {
//                    withAnimation {
//                        isAnimating = true
//                        self.runThings()
//                    }
//                }
//                .padding()
//            }
//        }
//}

class TravelingSalesman {
    static private var maxRuns: Int = 50
    
    static func createTrainingData(numRuns: Int = 1000, pointsOrder: inout [Int]) {
        var bigArray = TravelingSalesman.createCSVColumns()
        for _ in 0..<numRuns {
            var numStops = Int.random(in: 10...maxRuns)
            var env = TravelingSalesman.DeliveryEnvironment(numStops: numStops, maxBox: 300)
            var agent = TravelingSalesman.DeliveryQAgent(statesSize: env.observationSpace, actionsSize: env.actionSpace)
            var rewards = TravelingSalesman.runNumEpisodes(env: &env, agent: &agent, pointsOrder: &pointsOrder)
            TravelingSalesman.addRunToCSV(bigArray: &bigArray, env: env, agent: agent)
        }
        do {
            try TravelingSalesman.writeCSVToFile(array: bigArray, fileName: "noDistanceValidation.csv")
        } catch {
            
        }
    }
    
    private static func convertArrayToCSV(_ array: [[Any]]) -> String {
        return array.map { row in
            row.map { "\($0)" }.joined(separator: ",")
        }.joined(separator: "\n")
    }
    
    static func normalizePoints(points: [CGPoint]) -> [CGPoint] {
        guard let maxX = points.map({ $0.x }).max(),
              let maxY = points.map({ $0.y }).max() else {
            return points // Return the original points if the array is empty
        }
        
        var newPoints = points.map { point in
            let normalizedX = (point.x) / (maxX)
            let normalizedY = (point.y) / (maxY)
            return CGPoint(x: normalizedX, y: normalizedY)
        }
        while newPoints.count < maxRuns {
            newPoints.append(CGPoint(x:0,y:0))
        }
        return newPoints
    }
    
    static func writeCSVToFile (array: [[String]], fileName: String) throws {
        let csvString = TravelingSalesman.convertArrayToCSV(array)

        // Save the CSV to a file
        let fileName = fileName
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(fileURL.path)")
        } catch {
            print("Error writing CSV file: \(error)")
        }
    }
    
    static func createCSVColumns() -> [[String]] {
        var columnNames: [String] = []
        for num in 0..<maxRuns {
            var columnName1 = "xcoord\(num)"
            var columnName2 = "ycoord\(num)"
            columnNames.append(columnName1)
            columnNames.append(columnName2)
        }
        columnNames.append("currentStop")
        columnNames.append("nextStop")
        var bigArray: [[String]] = [columnNames]
        return bigArray
    }
    
    static func addRunToCSV(bigArray: inout [[String]], env: TravelingSalesman.DeliveryEnvironment, agent: TravelingSalesman.DeliveryQAgent) {
        var numPoints = env.points.count
        var nextMap: [Int:Int] = [:]
        for index in 0..<env.steps.count-1 {
            nextMap[env.steps[index]] = env.steps[index+1]
        }
        nextMap[env.steps[env.steps.count-1]] = env.steps[0]
        var newPoints = normalizePoints(points: env.points)
        let newSteps: [Int] = {
            (inputList: [Int], desiredLength: Int) -> [Int] in
            if inputList.count >= desiredLength {
                return Array(inputList.prefix(desiredLength))
            } else {
                let padding = Array(repeating: -1, count: desiredLength - inputList.count)
                return inputList + padding
            }
        }(env.steps, maxRuns)
        for num in 0..<maxRuns{
            var dataArray: [String] = []
            for num2 in 0..<maxRuns{
                dataArray.append(newPoints[num2].x.description)
                dataArray.append(newPoints[num2].y.description)
            }
            var currentPoint: String
            var nextPoint: String
            if num >= numPoints {
                currentPoint = "-1"
                nextPoint = "-1"
            } else {
                currentPoint = newSteps[num].description
                nextPoint = nextMap[env.steps[num]]!.description
            }
            dataArray.append(currentPoint)
            dataArray.append(nextPoint)
            bigArray.append(dataArray)
        }
    }

    
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
        var numStops: Int
        var maxBox: Int
        var actionSpace: Int
        var observationSpace: Int
        var points : [CGPoint]
        var qStops : [[Double]]?
        var steps: [Int] = []
        

        init (numStops: Int = 10, maxBox: Int = 300, points: [CGPoint] = [] ) {
            self.numStops = numStops
            self.actionSpace = numStops
            self.maxBox = maxBox
            self.observationSpace = numStops
            if points == [] {
                self.points = (0..<numStops).map { _ in
                    CGPoint(x: CGFloat.random(in: 0...CGFloat(maxBox)), y: CGFloat.random(in: 0...CGFloat(maxBox)))
                }
            } else {
                self.points = points
            }
            self.qStops = generateQStops(for: self.points)
        }
        
        func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
            return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
        }
        
        func generateQStops(for points: [CGPoint]) -> [[Double]] {
            let n = points.count
            var qStops = Array(repeating: Array(repeating: 0.0, count: n), count: n) // Initialize a 2D array of zeros

            for i in 0..<n {
                for j in 0..<n {
                    if i != j { // Avoid calculating distance to self
                        var distance = CGPointDistanceSquared(from: points[i], to: points[j])
//                        var randomMultiplier = Double.random(in: (0.85...1.20))
                        var randomMultiplier = 1.0
                        qStops[i][j] = distance * randomMultiplier
                    } else {
                        qStops[i][j] = 0.0 // Distance to self is 0
                    }
                }
            }

            return qStops
        }
        
        func reset() -> Int {
            steps = []
            var first_stop = Int.random(in: 0..<numStops)
            steps.append(first_stop)
            return first_stop
        }
        
        func step(destination: Int) -> (newState: Int,reward: Double,done: Bool){
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


extension Range where Element: Hashable {
    func random(without excluded:[Element]) -> Element {
        let valid = Set(self).subtracting(Set(excluded))
        let random = Int(arc4random_uniform(UInt32(valid.count)))
        return Array(valid)[random]
    }
}



//PlaygroundPage.current.setLiveView(ContentView())
