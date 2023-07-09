//
//  ProjectDetailViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProjectDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var categoryIcon_imageView: UIImageView!
    
    @IBOutlet weak var deadline_label: UILabel!
    
    @IBOutlet weak var notes_textView: UITextView!
    
    @IBOutlet weak var budget_label: UILabel!
    
    @IBOutlet weak var totalSpent_label: UILabel!
    
    @IBOutlet weak var addTaskButton: UIButton!
    
    @IBOutlet weak var deleteTaskButton: UIButton!
    
    @IBOutlet weak var finishWithDeleteButton: UIButton!
    
    @IBOutlet weak var cancelEditingButton: UIButton!
    
    @IBOutlet weak var noTasksView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var loadingView: UIView?
    
    var project: Project!
    var _project: Project?
    
    let db = Firestore.firestore()
    
    var taskArray = [Task]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Detail View Controller: viewDidLoad called")
        // Do any additional setup after loading the view.
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        notes_textView.delegate = self
        
        // Create a custom back button
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBackToOverview))
        // Set the custom back button as the left bar button item
        navigationItem.leftBarButtonItem = backButton
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.view.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false
        
        guard let sentProject = _project else {
            print("Project is nil")
            return
        }
        
        project = sentProject
        
        //Update the navigation bar title with the project name
        navigationItem.title = project.title
        
        //Fetch tasks with project
        if let taskIds = project.taskIds {
            HelperMethods.fetchTasks(taskIDs: taskIds) { tasks in
                self.project?.tasks = tasks
                
                /*for task in tasks {
                    if task.isCompleted {
                        self.project.totalSpent += task.taskCost
                    }
                }
                 */
                
                //Update UI with project data
                self.updateUI()
            }
        } else {
            self.updateUI()
        }
        
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: tableView)
            if let _ = tableView.indexPathForRow(at: tapLocation) {
                // Tapped inside a table view cell, skip keyboard dismissal
                return
            }
        
        project.designNotes = notes_textView.text
        notes_textView.resignFirstResponder()
        HelperMethods.saveNotesToFirestore(on: self, notes: notes_textView.text, project: project)
    }

    
    
    @IBAction func addTaskTapped(_ sender: UIButton) {
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
                
                // Start a new Firestore transaction
                let db = Firestore.firestore()
                db.runTransaction({ (transaction, errorPointer) -> Any? in
                    //show the loading view while running the transaction
                    DispatchQueue.main.async {
                        strongSelf.showLoadingView()
                    }
                    // Store the task in Firestore
                    let newDocumentRef = db.collection("tasks").document()
                    transaction.setData(task.toDictionary(), forDocument: newDocumentRef)
                    
                    // Replace the taskID with the Firestore document ID
                    task.taskId = newDocumentRef.documentID
                    
                    // Add that task to the projects document task array under the projectID
                    let projectRef = db.collection("projects").document(strongSelf.project.projectID)
                    transaction.updateData([
                        "tasks": FieldValue.arrayUnion([task.taskId])
                    ], forDocument: projectRef)
                    
                    return nil
                    
                }) { (object, error) in
                    //Hide loading view if there is an error or if it completed succesfully
                    DispatchQueue.main.async {
                        strongSelf.hideLoadingView()
                    }
                    if let error = error {
                        print("Error adding task to Firestore: \(error.localizedDescription)")
                        
                        HelperMethods.showBasicErrorAlert(on: strongSelf, title: "Error Storing Task to \(strongSelf.project.title)", message: error.localizedDescription)
                    } else {
                        print("Task ID: \(task.taskId) should equal document ID: \(task.taskId)")
                        print("Task \(task.task) was successfully added to Firestore")
                        
                        // Only update the project's task array if task was successfully added to firestore
                        if strongSelf.project.tasks == nil {
                            strongSelf.project.tasks = [task]
                        } else {
                            strongSelf.project.tasks?.append(task)
                        }
                        print("\(task.task) was added to the projects task array")
                        
                        // Add the task to the taskArray
                        strongSelf.taskArray.append(task)
                        strongSelf.updateUI()
                        // Reload the tableView
                        strongSelf.tableView.reloadData()
                    }
                }
            } // End of add task completion handler
        
    }
    
    func showLoadingView() {
        // Create the loading view
        loadingView = UIView(frame: view.bounds)
        loadingView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Add the label to the loading view
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        label.text = "Adding task to project..."
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.center = loadingView?.center ?? CGPoint.zero
        loadingView?.addSubview(label)

        // Add a loading indicator to the view
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = loadingView?.center ?? CGPoint.zero
        activityIndicator.startAnimating()
        loadingView?.addSubview(activityIndicator)

        // Add the loading view as a subview and bring it to the front
        view.addSubview(loadingView!)
        view.bringSubviewToFront(loadingView!)
    }
    
    func hideLoadingView() {
        // Remove the loading view from the view hierarchy
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
    
    @IBAction func deleteTaskTapped(_ sender: UIButton) {
        //put the table view into editing mode
        HelperMethods.editTaskTableView(tableView: tableView, addButton: addTaskButton, editButton: deleteTaskButton, deleteButton: finishWithDeleteButton, cancelButton: cancelEditingButton)
        
    }
    
    @IBAction func deleteSelectedTasksTapped(_ sender: UIButton) {
        
        //Calculate total cost of selected tasks that are completed
        var costOfSelectedCompletedTasks: Double = 0
        let selectedTasksIds = tableView.indexPathsForSelectedRows?.map { taskArray[$0.row].taskId } ?? []

            for task in project.tasks! {
                if selectedTasksIds.contains(task.taskId), task.isCompleted {
                    costOfSelectedCompletedTasks += task.taskCost
                }
            }
        
        //Delete the tasks and update the UI
        HelperMethods.deleteSelectedTasks(on: self, tableView: tableView, selectedTaskIds: selectedTasksIds, addButton: addTaskButton, editButton: deleteTaskButton, deleteButton: finishWithDeleteButton, cancelButton: cancelEditingButton, tasks: project.tasks!) { newTasks in
            //update the tasks array
            self.project.tasks = newTasks
            
            //Subtract the cost of the deleted completed tasks from total spent
            self.project.totalSpent -= costOfSelectedCompletedTasks
            
            //Update the UI
            self.updateUI()
        }
        
    }
    
    @IBAction func cancelEditingTapped(_ sender: UIButton) {
        HelperMethods.quitEditing(tableView: tableView, addButton: addTaskButton, editButton: deleteTaskButton, deleteButton: finishWithDeleteButton, cancelButton: cancelEditingButton)
    }
    
    @objc func goBackToOverview(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        //Instantiate the home view controller
        guard let homeScreen = storyboard.instantiateViewController(withIdentifier: "homeViewController") as? ProjectOverview_ViewController else {
            print("Could not instantiate HomeViewController")
                    return
        }
        
        //set the home screen as the root of your navigation stack
        self.navigationController?.setViewControllers([homeScreen], animated: true)
    }
    
    func updateTotalSpentInFirestore(){
        let docRef = Firestore.firestore().collection("projects").document(project.projectID)
        docRef.updateData(["totalSpent": project.totalSpent]) { error in
            if let error = error {
                print("Error updating totalSpent: \(error.localizedDescription)")
                HelperMethods.showBasicErrorAlert(on: self, title: "Error Updating Total Spent", message: error.localizedDescription)
            } else {
                print("Total spent successfully updated. \(self.project.title)'s total spent: \(self.project.totalSpent)")
            }
        }
    }
    
    
    
    func updateUI(){
        
        var remainingBudget = project.budget
        updateTotalSpentInFirestore()
        totalSpent_label.text = HelperMethods.formatNumberToCurrency(value: project.totalSpent)
        if project.totalSpent <= project.budget {
            //Make the text green if the totalSpent  is less than or equal to the budget
            totalSpent_label.textColor = UIColor.darkGreen
            //subtract the total spent from the remaining budget
            budget_label.textColor = UIColor.darkBrown
            remainingBudget = project.budget - project.totalSpent
            print("Remaining Budget is: \(remainingBudget)")
        } else if project.totalSpent > project.budget {
            //Make the text red and bold if it is over the budget
            totalSpent_label.textColor = UIColor.red
            totalSpent_label.font = UIFont.boldSystemFont(ofSize: totalSpent_label.font.pointSize)
            //Make the remaining budget $0
            remainingBudget = 0.00
            budget_label.textColor = UIColor.red
            budget_label.font = UIFont.boldSystemFont(ofSize: totalSpent_label.font.pointSize)
            print("Remaining budget should be set to 0.00. Remaining budget is \(remainingBudget)")
        }
        
        categoryIcon_imageView.image = UIImage(named: HelperMethods.getCategoryImageName(projectCategory: project.category))
        
        if let designNotes = project.designNotes {
            //Display the design notes
            notes_textView.text = designNotes
        } else {
            notes_textView.text = ""
        }
        
        //update deadline
        deadline_label.text = "Deadline: \(project.deadline)"
        
        budget_label.text = HelperMethods.formatNumberToCurrency(value: remainingBudget)
        
        if let tasks = project.tasks, !tasks.isEmpty {
            taskArray = tasks
            
        }
        
        if taskArray.isEmpty {
            // Display "No tasks" message
            noTasksView.isHidden = false
            tableView.isHidden = true
            addTaskButton.isHidden = false
            deleteTaskButton.isHidden = true
            cancelEditingButton.isHidden = true
            finishWithDeleteButton.isHidden = true
        } else {
            // Display the tasks
            noTasksView.isHidden = true
            tableView.isHidden = false
            addTaskButton.isHidden = false
            deleteTaskButton.isHidden = false
            cancelEditingButton.isHidden = true
            finishWithDeleteButton.isHidden = true
        }
        tableView.reloadData()
        
        
    }
    
    func updateBudget(){
        var remainingBudget = project.budget
        totalSpent_label.text = HelperMethods.formatNumberToCurrency(value: project.totalSpent)
        if project.totalSpent <= project.budget {
            //Make the text green if the totalSpent  is less than or equal to the budget
            totalSpent_label.textColor = UIColor.darkGreen
            //subtract the total spent from the remaining budget
            remainingBudget = project.budget - project.totalSpent
            print("Remaining Budget is: \(remainingBudget)")
        } else if project.totalSpent > project.budget {
            //Make the text red and bold if it is over the budget
            totalSpent_label.textColor = UIColor.red
            totalSpent_label.font = UIFont.boldSystemFont(ofSize: totalSpent_label.font.pointSize)
            //Make the remaining budget $0
            remainingBudget = 0.00
            print("Remaining budget should be set to 0.00. Remaining budget is \(remainingBudget)")
        }
        
        budget_label.text = HelperMethods.formatNumberToCurrency(value: remainingBudget)
    }
    
    
    @IBAction func editProjectTapped(_ sender: UIBarButtonItem) {
        // Go to create project screen
        self.performSegue(withIdentifier: "toEditProject", sender: self)
    }
    
    
    //MARK: Table View Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "task_reuseID", for: indexPath) as? TaskTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: "task_reuseID", for: indexPath)
        }
        
        let currentTask = taskArray[indexPath.row]
        cell.taskTitle_label.text = currentTask.task
        
        if (currentTask.isCompleted){
            cell.taskCircle_imageView.image = UIImage(systemName: "circle.inset.filled")
            cell.backgroundColor = UIColor.darkGreen
            //Add a strikethrough to the text
            let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: currentTask.task)
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributedString.length))
            cell.taskTitle_label.attributedText = attributedString
        } else {
            cell.taskCircle_imageView.image = UIImage(systemName: "circle")
            cell.backgroundColor = UIColor.white
            // Remove the strikethrough from the text
            let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: currentTask.task)
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: NSMakeRange(0, attributedString.length))
            cell.taskTitle_label.attributedText = attributedString
        }
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !tableView.isEditing{
            let selectedTask = taskArray[indexPath.row]
            //Update the task based on the tap and update in Firestore
            HelperMethods.updateTaskWhenTapped(selectedTask: selectedTask, totalSpent: &project.totalSpent)
            //Update the task in firestore
            HelperMethods.updateTaskInFirestore(on: self, selectedTask: selectedTask)
            
            print("DidSelectRowAt(): New total spent is: \(project.totalSpent)")
            
            //Sort taks so that the completed tasks are at the bottom
            taskArray.sort { !$0.isCompleted && $1.isCompleted }
            
            //Assign the sorted taks back to _project.tasks
            project.tasks = taskArray
            
            updateUI()
            
            tableView.reloadData()
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Check segue identifier
        if segue.identifier == "toEditProject" {
            // Get the new view controller using segue.destination.
            let destinationVC = segue.destination as! ProjectFormViewController
            // Pass the selected object to the new view controller.
            destinationVC.project = self.project
            destinationVC.isEditMode = true
        }
    }
    

}
