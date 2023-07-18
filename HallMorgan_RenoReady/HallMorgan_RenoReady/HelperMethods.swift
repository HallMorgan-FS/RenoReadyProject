//
//  HelperMethods.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/23/23.
//

import Foundation
import UIKit
import FirebaseFirestore

class HelperMethods {
    
    static func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            
        let emailPred = NSPredicate(format:"SELF MATCHES %@", regex)
        return emailPred.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> (Bool, String) {
        // Check that password is at least 8 characters long
        guard password.count >= 8 else { return (false, "at least 8 characters") }
        
        // Check that password contains at least one uppercase letter
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let hasUppercaseLetter = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex).evaluate(with: password)
        guard hasUppercaseLetter else { return (false, "one uppercase letter") }
            
        // Check that password contains at least one number
        let numberRegex = ".*[0-9]+.*"
        let hasNumber = NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password)
        guard hasNumber else { return (false, "at least one number") }
            
        // If all checks passed, return true
        return (true, "Passed")
    }
    
    static func textNotEmpty(_ textField: UITextField) -> (Bool, String){
        
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
               return (false, "Empty or whitespace")
           }
           return (true, text)
    }
    //MARK: IMAGE RESIZING
    
    static func resizeAndCompressImage(image: UIImage, targetSize: CGSize) -> Data? {
        // Ensure the image is a perfect square by cropping to the center square
        let originalSize = min(image.size.width, image.size.height)
        let cropRect = CGRect(x: (image.size.width - originalSize) / 2,
                              y: (image.size.height - originalSize) / 2,
                              width: originalSize, height: originalSize)
        let imageRef = image.cgImage?.cropping(to: cropRect)
        let squareImage = UIImage(cgImage: imageRef!, scale: 1.0, orientation: image.imageOrientation)
        
        // Resize the square image to target size
        let rect = CGRect(origin: .zero, size: targetSize)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        squareImage.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress the image
        let imageData = resizedImage!.jpegData(compressionQuality: 0.5)
        
        return imageData
    }

    
    //MARK: CAMERA AND PHOTO LIBRARY ACCESS
    
    static func checkCameraOrPhotoLibraryAccess(on viewController: UIViewController){
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            showAlertToOpenSettings(on: viewController, withMessage: "Camera access is not available. You can enable access in Privacy Settings.")
            return
        }
        
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            showAlertToOpenSettings(on: viewController, withMessage: "Photo Library access is not available. You can enable access in Privacy Settings.")
            return
        }
    }
    
    static func showAlertToOpenSettings(on viewController: UIViewController, withMessage message: String ){
        let alert = UIAlertController(title: "Access Required", message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        viewController.present(alert, animated: true, completion: nil)
    } //End of settings alert method
    
    //MARK: ADD TASK ALERT
    static func addTaskAlert(on viewController: UIViewController, completion: @escaping (Task?) -> Void) {
        let alert = UIAlertController(title: "Create Task", message: "What is the task that needs to be completed and it's total cost?", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "What is the task?"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Task cost (ex: $50 or 50)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            // When the Cancel button is clicked, call the completion handler with nil
            completion(nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Add Task", style: .default, handler: { [weak alert] _ in
            guard let alert = alert else { return }
            let taskField = alert.textFields![0]
            let costField = alert.textFields![1]

            guard let taskText = taskField.text, !taskText.isEmpty else {
                // If the task field is empty, call the completion handler with nil
                completion(nil)
                return
            }

            // Get and convert the cost. If it is empty, default the cost to 0.00
            let costText = costField.text ?? "0.00"
            let cleanCostText = costText.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            let cost = Double(cleanCostText) ?? 0.00

            // Create the task with an empty ID
            let task = Task(taskId: "", task: taskText, isCompleted: false, taskCost: cost)
            
            completion(task)
            
        })) //End of addAction

        // Present the alert
        viewController.present(alert, animated: true, completion: nil)
    } // End of taskAlert Method
    
    
    //MARK: ADD TASK TO PROJECT
    static func addTaskToProject(projectID: String, taskId: String, completion: @escaping (Error?) -> Void){
        let projectsCollection = Firestore.firestore().collection("projects")
        
        // Use FieldValue.arrayUnion to add the taskId to the tasks array field
        // arrayUnion will only add the taskId if it's not already present in the array
        projectsCollection.document(projectID).updateData([
            "tasks": FieldValue.arrayUnion([taskId])
        ]) { error in
            completion(error)
        }
    }
    
    //MARK: GET PROJECTS AND TASKS
    
    static func project(from document: DocumentSnapshot) -> Project? {
        var project: Project
        if let projectData = document.data() {
            let projectId = document.documentID
            let title = projectData["title"] as? String ?? ""
            let category = projectData["category"] as? String ?? ""
            let deadline = projectData["deadline"] as? String ?? ""
            let budget = projectData["budget"] as? Double ?? 0.00
            let designNotes = projectData["designNotes"] as? String ?? ""
            let taskIds = projectData["tasks"] as? [String]
            let photoIds = projectData["photoIds"] as? [String]
            let totalSpent = projectData["totalSpent"] as? Double ?? 0.00
            let completed = projectData["completed"] as? Bool ?? false
            
            project = Project(projectID: projectId, title: title, category: category, designNotes: designNotes, deadline: deadline, budget: budget, tasks: nil, photoIds: photoIds, taskIds: taskIds, completed: completed)
            project.totalSpent = totalSpent
            
            return project
        }
        return nil
    }
    
    static func fetchTasks(taskIDs: [String], completion: @escaping ([Task]) -> Void) {
        let tasksCollection = Firestore.firestore().collection("tasks")
        let tasksDispatchGroup = DispatchGroup()
        
        var tasks: [Task] = []
        
        for taskID in taskIDs {
            tasksDispatchGroup.enter()
            
            tasksCollection.document(taskID).getDocument { documentSnapshot, error in
                if let error = error {
                    print("Error fetching task: \(error)")
                } else if let document = documentSnapshot {
                    if let task = self.task(from: document){
                        tasks.append(task)
                    }
                    
                }
                
                tasksDispatchGroup.leave()
            }
        }
        
        tasksDispatchGroup.notify(queue: .main) {
            completion(tasks)
        }
    }
    
    static func task(from document: DocumentSnapshot) -> Task? {
        if let taskData = document.data(){
            let taskId = document.documentID
            if let task = taskData["task"] as? String,
               let isCompleted = taskData["isCompleted"] as? Bool{
                let taskCost = taskData["taskCost"] as? Double ?? 0.00
                return Task(taskId: taskId, task: task, isCompleted: isCompleted, taskCost: taskCost)
            }
               
        }
        return nil
    }
    
    //MARK: Error Alert
    static func showBasicErrorAlert(on vc: UIViewController, title: String, message: String){
        let alert = UIAlertController(title: title, message: "\(message)\nWe are sorry for the inconvience. Please try again.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        //Present the alert
        vc.present(alert, animated: true)
        
    }
    
    static func showToast(on vc: UIViewController, message: String) {
        let toastViewController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        vc.present(toastViewController, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            toastViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: DELETE TASKS
    static func editTaskTableView(tableView: UITableView, addButton: UIButton, editButton: UIButton, deleteButton: UIButton, cancelButton: UIButton){
        //Change the isEditing to true
        tableView.isEditing = true
        
        //Hide the add and edit buttons
        addButton.isHidden = true
        editButton.isHidden = true
        
        //Show the delete button
        deleteButton.isHidden = false
        cancelButton.isHidden = false
        
    }
    
    static func deleteSelectedTasks(on vc: UIViewController, tableView: UITableView ,selectedTaskIds: [String], addButton: UIButton, editButton: UIButton, deleteButton: UIButton, cancelButton: UIButton ,tasks: [Task], updateTasks: @escaping ([Task]) -> Void){

        //Check if any rows are selected
        guard !selectedTaskIds.isEmpty else {
            print("No tasks selected")
            return
        }

        //Show an alert to confirm deletion
        let alert = UIAlertController(title: "Delete Tasks", message: "Are you sure you want to delete the selected task(s)? This action cannot be undone.", preferredStyle: .alert)

        //Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        //Delete action
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            //Delete the selected tasks from Firestore and from the tasks array
            for taskId in selectedTaskIds {
                // Find the task from the tasks array
                if let task = tasks.first(where: { $0.taskId == taskId }) {
                    //Delete task from Firestore
                    Firestore.firestore().collection("tasks").document(task.taskId).delete() { error in
                        if let error = error {
                            print("Error removing task from Firestore: \(error.localizedDescription)")
                        } else {
                            print("\(task.task) successfully removed!")
                        }
                    }
                }
            }

            //Delete the tasks from the tasks array
            updateTasks(tasks.filter { task in
                !selectedTaskIds.contains(task.taskId)
            })

            //Quit editing
            quitEditing(tableView: tableView, addButton: addButton, editButton: editButton, deleteButton: deleteButton, cancelButton: cancelButton)

            //Reload the tableView
            tableView.reloadData()
        }))

        //Present the alert
        vc.present(alert, animated: true)
    }

    
    
    static func quitEditing(tableView: UITableView ,addButton: UIButton, editButton: UIButton, deleteButton: UIButton, cancelButton: UIButton){
        //hide the delete button
        deleteButton.isHidden = true
        cancelButton.isHidden = true
        
        //Show the add and edit button
        addButton.isHidden = false
        editButton.isHidden = false
        tableView.isEditing = false
    }
    
    //MARK: Update task if completed
    static func updateTaskWhenTapped(selectedTask: Task, totalSpent: inout Double){
        //Toggle the completion status
        selectedTask.isCompleted = !selectedTask.isCompleted
        
            //Adjust the totalSpent based on the task's status
        if selectedTask.isCompleted{
            totalSpent += selectedTask.taskCost
            print("Total spent is now: \(totalSpent)")
        } else {
            totalSpent -= selectedTask.taskCost
            print("Total spent is now: \(totalSpent)")
        }
    }
    
    //MARK: UPDATE TASK IN FIRESTORE
    static func updateTaskInFirestore(on vc: UIViewController ,selectedTask: Task){
        //get reference to task database
        let docRef = Firestore.firestore().collection("tasks").document(selectedTask.taskId)
        docRef.updateData(["isCompleted": selectedTask.isCompleted]) { error in
            if let error = error {
                print("Error updating task: \(error.localizedDescription)")
                showBasicErrorAlert(on: vc, title: "Error Updating Task", message: error.localizedDescription)
            } else {
                print("Task successfully updated. \(selectedTask.task) is completed: \(selectedTask.isCompleted)")
            }
        }
    }
    
    //MARK: SAVE NOTES TO FIRESTORE
    static func saveNotesToFirestore(on vc: UIViewController, notes: String, project: Project){
        let docRef = Firestore.firestore().collection("projects").document(project.projectID)
        docRef.updateData([
            "designNotes": notes
        ]) { err in
            if let err = err {
                print("Error updating notes: \(err.localizedDescription)")
                DispatchQueue.main.async {
                    showBasicErrorAlert(on: vc, title: "Error Saving Notes", message: err.localizedDescription)
                }
            } else {
                print("Design notes successfully updated")
            }
        }
    }
    
    //MARK: GET CATEGORY ICON
    static func getCategoryImageName(projectCategory: String) -> String {
        return projectCategory.lowercased().replacingOccurrences(of: " ", with: "")
    }
    
    //MARK: FORMAT MONEY
    static func formatNumberToCurrency(value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale.current
        let currencyString = numberFormatter.string(from: NSNumber(value: value))
        
        return currencyString ?? value.description
    }
    
    //MARK: CHECK NETWORK CONNECTIVITY
    static func checkNetwork(on vc: UIViewController){
        if NetworkManager.isConnectedToNetwork() {
            // User is connected to the internet, proceed with app functionality
        } else {
            let alertController = UIAlertController(title: "No Internet Connection", message: "Please connect to a network to use the app.", preferredStyle: .alert)
            
            // Add a custom action to the alert
            let closeAction = UIAlertAction(title: "Close App", style: .destructive) { _ in
                UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            }
            alertController.addAction(closeAction)
            
            // Present the alert
            vc.present(alertController, animated: true, completion: nil)
        }
    }
    
    /*static func olderCodeForAddTask(){
        //Call the addTaskAlert
        HelperMethods.addTaskAlert(on: self) { [weak self] (task: Optional<Task>) -> Void in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let task = task else {
                //Handle the case where no task was created (the user tapped cancel or didn't enter a task in the task field)
                //Show toast type of alert that no task was created
                HelperMethods.showToast(on: strongSelf, message: "No task was created.")
                return
            }
            
            //Task was created.
            //Store the task in Firestore
            //get the reference for the tasks database
            var reference: DocumentReference? = nil
            reference = Firestore.firestore().collection("tasks").addDocument(data: task.toDictionary(), completion: { (error) in
                if let error = error{
                    print("Error adding task to Firestore: \(error.localizedDescription)")
                    
                } else {
                    //Replace the taskID with the Firestore document ID
                    if let documentId = reference?.documentID {
                        task.taskId = documentId
                        print("Task ID: \(task.taskId) should equal document ID: \(documentId)")
                        print("Task \(task.task) was successfully added to Firestore")
                        
                        //Add that task to the projects document taskId array under the updated projectID
                        HelperMethods.addTaskToProject(projectID: strongSelf.project.projectID, taskId: task.taskId) { (error) in
                            if let error = error {
                                print("Error adding task to Firestore: \(error.localizedDescription)")
                                HelperMethods.showBasicErrorAlert(on: strongSelf, title: "Error Storing Task to \(strongSelf.project.title)", message: error.localizedDescription)
                            } else {
                                //Only update the project's task array if task was successfully added to firestore
                                
                                //Update the project's task array
                                if strongSelf.project.tasks == nil {
                                    strongSelf.project.tasks = [task]
                                } else {
                                    strongSelf.project.tasks?.append(task)
                                }
                                print("\(task.task) was added to the projects task array")
                                
                                //Add the task to the taskArray
                                strongSelf.taskArray.append(task)
                                //Reload the tableView
                                strongSelf.tableView.reloadData()
                            }
                        }
                        
                    } else {
                        print("Error: Firestore document reference is nil")
                    }
                }
            }) //End of document reference
           
        }
    }
     */
    
}
