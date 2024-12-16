//
//  TaskList.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/13/24.
//

import Foundation
extension MyTaskList {
    var taskList: [MyTask] {
        get {
            let tasks = myTasks?.allObjects as? [MyTask] ?? []
            return tasks
        }
        set {
            myTasks = NSSet(array: newValue)
        }
        
    }
}

extension MyTaskList: Sequence {
    public func makeIterator() -> some IteratorProtocol {
        taskList.makeIterator()
    }
}
