//
//  User.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import Foundation
import UIKit

class User {
    
    var email: String
    var profilePhoto: UIImage
    var projects: [Project]?
    
    init(email: String, profilePhoto: UIImage, projects: [Project]? = nil) {
        self.email = email
        self.profilePhoto = profilePhoto
        self.projects = projects
    }
    
    convenience init(email: String, profilePhoto: UIImage) {
        self.init(email: email, profilePhoto: profilePhoto, projects: nil)
    }
    
    
}

class Project {
    var projectID: String
    var title: String
    var category: String
    var designNotes: String?
    var deadline: String
    var budget: Double
    var totalSpent = 0.00
    var tasks: [Task]?
    var photos: [UIImage]?
    var taskIds: [String]?
    
    init(projectID: String, title: String, category: String, designNotes: String? = nil, deadline: String, budget: Double, tasks: [Task]? = nil, photos: [UIImage]? = nil, taskIds: [String]? = nil ) {
        self.projectID = projectID
        self.title = title
        self.category = category
        self.designNotes = designNotes
        self.deadline = deadline
        self.budget = budget
        self.tasks = tasks
        self.photos = photos
        self.taskIds = taskIds
    }
    
    convenience init(projectID: String, title: String, category: String, deadline: String, budget: Double) {
        self.init(projectID: projectID, title: title, category: category, designNotes: nil, deadline: deadline, budget: budget, tasks: nil, photos: nil, taskIds: nil)
    }
    
}

class Task {
    var taskId: String
    var task: String
    var isCompleted: Bool
    var taskCost: Double?
    
    
    public init(taskId: String, task: String, isCompleted: Bool, taskCost: Double? = nil) {
        self.taskId = taskId
        self.task = task
        self.isCompleted = isCompleted
        self.taskCost = taskCost
        
    }
    
    convenience init(taskId: String, task: String, isCompleted: Bool) {
        self.init(taskId: taskId, task: task, isCompleted: isCompleted, taskCost: nil)
    }
}
