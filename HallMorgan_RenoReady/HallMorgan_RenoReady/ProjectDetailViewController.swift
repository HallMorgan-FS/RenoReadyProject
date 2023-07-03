//
//  ProjectDetailViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProjectDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    
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
    
    var projectID: String!
    
    var project: Project!
    
    let db = Firestore.firestore()
    
    var taskArray = [Task]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        notes_textView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        //Update the navigation bar title with the project name
        navigationItem.title = project.title
        
        //Fetch tasks with project
        if let taskIds = project.taskIds {
            HelperMethods.fetchTasks(taskIDs: taskIds) { tasks in
                self.project?.tasks = tasks
                
                for task in tasks {
                    if task.isCompleted {
                        self.project.totalSpent += task.taskCost
                    }
                }
                
                //Update UI with project data
                self.updateUI()
            }
        } else {
            self.updateUI()
        }
        
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer){
        
        project.designNotes = notes_textView.text
        notes_textView.resignFirstResponder()
        HelperMethods.saveNotesToFirestore(on: self, notes: notes_textView.text, project: project)
    }
    
    
    @IBAction func addTaskTapped(_ sender: UIButton) {
        //Call the addTaskAlert
        HelperMethods.addTaskAlert(on: self) { [weak self] (task: Optional<Task>) -> Void in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let task = task else {
                //Handle the case where no task was created (the user tapped cancel or didn't enter a task in the task field)
                //Show toast type of alert that no task was created
                HelperMethods.showToast(on: strongSelf, message: "No task was entered. No task was created.")
                return
            }
            
            //Task was created and stored to FIrebase.
           
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
                    
                    //Reload the tableView
                    strongSelf.tableView.reloadData()
                }
            }
            
            strongSelf.taskArray.append(task)
            //Reload the tableView
            strongSelf.tableView.reloadData()
        }
    }
    
    @IBAction func deleteTaskTapped(_ sender: UIButton) {
        //put the table view into editing mode
        HelperMethods.editTaskTableView(tableView: tableView, addButton: addTaskButton, editButton: deleteTaskButton, deleteButton: finishWithDeleteButton, cancelButton: cancelEditingButton)
        
    }
    
    @IBAction func deleteSelectedTasksTapped(_ sender: UIButton) {
        
        //Calculate total cost of selected tasks that are completed
        var costOfSelectedCompletedTasks: Double = 0
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            for path in selectedIndexPaths {
                let task = project.tasks![path.row]
                if task.isCompleted {
                    costOfSelectedCompletedTasks += task.taskCost
                }
            }
        }
        
        //Delete the tasks and update the UI
        HelperMethods.deleteSelectedTasks(on: self, tableView: tableView, addButton: addTaskButton, editButton: deleteTaskButton, deleteButton: finishWithDeleteButton, cancelButton: cancelEditingButton, tasks: project.tasks!) { newTasks in
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
    
    
    
    func updateUI(){
        
        categoryIcon_imageView.image = UIImage(named: HelperMethods.getCategoryImageName(projectCategory: project.category))
        
        if let designNotes = project.designNotes {
            //Display the design notes
            notes_textView.text = designNotes
        } else {
            notes_textView.text = ""
        }
        
        //update deadline
        deadline_label.text = project.deadline
        
        budget_label.text = HelperMethods.formatNumberToCurrency(value: project.budget)
        
        
        
        if let tasks = project.tasks, !tasks.isEmpty {
            taskArray = tasks
            // Display the tasks
            noTasksView.isHidden = true
            tableView.isHidden = false
            addTaskButton.isHidden = false
            deleteTaskButton.isHidden = false
            cancelEditingButton.isHidden = true
            finishWithDeleteButton.isHidden = true
            
            tableView.reloadData()
            
        } else {
            // Display "No tasks" message
            noTasksView.isHidden = false
            tableView.isHidden = true
            addTaskButton.isHidden = true
            deleteTaskButton.isHidden = true
            cancelEditingButton.isHidden = true
            finishWithDeleteButton.isHidden = true
        }
        
        totalSpent_label.text = HelperMethods.formatNumberToCurrency(value: project.totalSpent)
        if project.totalSpent <= project.budget {
            //Make the text green if the totalSpent  is less than or equal to the budget
            totalSpent_label.textColor = UIColor.darkGreen
        } else {
            //Make the text red and bold if it is over the budget
            totalSpent_label.textColor = UIColor.red
            totalSpent_label.font = UIFont.boldSystemFont(ofSize: totalSpent_label.font.pointSize)
        }
        
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
            //Change background color to white for uncompleted tasks
            cell.backgroundColor = UIColor.white
            
            //Remove the strickethrough from the text
            cell.taskTitle_label.text = currentTask.task
        }
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedTask = taskArray[indexPath.row]
        //Update the task based on the tap and update in Firestore
        HelperMethods.updateTaskWhenTapped(selectedTask: selectedTask, totalSpent: &project.totalSpent)
        
        //Sort taks so that the completed tasks are at the bottom
        taskArray.sort { !$0.isCompleted && $1.isCompleted }
        
        //Assign the sorted taks back to _project.tasks
        project.tasks = taskArray
        
        tableView.reloadData()
        
        updateUI()
    }
    
    @IBAction func unwindToDetails(_ unwindSegue: UIStoryboardSegue) {
        guard let sourceViewController = unwindSegue.source as? ProjectFormViewController else {
            return
        }
        
        // Access the new project object from the source view controller
        if let newProject = sourceViewController.project {
            self.project = newProject
            updateUI()
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
