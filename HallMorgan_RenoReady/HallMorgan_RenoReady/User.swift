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
    var photoIds: [String]?
    var taskIds: [String]?
    
    init(projectID: String, title: String, category: String, designNotes: String? = nil, deadline: String, budget: Double, tasks: [Task]? = nil, photos: [UIImage]? = nil, photoIds: [String]? = nil, taskIds: [String]? = nil ) {
        self.projectID = projectID
        self.title = title
        self.category = category
        self.designNotes = designNotes
        self.deadline = deadline
        self.budget = budget
        self.tasks = tasks
        self.photos = photos
        self.photoIds = photoIds
        self.taskIds = taskIds
    }
    
    convenience init(projectID: String, title: String, category: String, deadline: String, budget: Double) {
        self.init(projectID: projectID, title: title, category: category, designNotes: nil, deadline: deadline, budget: budget, tasks: nil, photos: nil, photoIds: nil, taskIds: nil)
    }
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "projectID": self.projectID,
            "title": self.title,
            "category": self.category,
            "deadline": self.deadline,
            "budget": self.budget,
            "totalSpent": self.totalSpent
        ]
        
        // Only add these properties to the dictionary if they're not nil
        if let designNotes = self.designNotes {
            dictionary["designNotes"] = designNotes
        }
        if let taskIds = self.taskIds {
            dictionary["tasks"] = taskIds
        }
        if let photoIds = self.photoIds {
            dictionary["photoIds"] = photoIds
        }
        
        return dictionary
    }
    
}

class Task {
    var taskId: String
    var task: String
    var isCompleted: Bool
    var taskCost = 0.00
    
    
    public init(taskId: String, task: String, isCompleted: Bool, taskCost: Double) {
        self.taskId = taskId
        self.task = task
        self.isCompleted = isCompleted
        self.taskCost = taskCost
        
    }
    
    // Add this method:
    func toDictionary() -> [String: Any] {
        return [
            "task" : self.task,
            "isCompleted" : self.isCompleted,
            "taskCost" : self.taskCost
        ]
    }
}
