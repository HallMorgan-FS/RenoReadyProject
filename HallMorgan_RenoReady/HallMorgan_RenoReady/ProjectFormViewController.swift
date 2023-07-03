//
//  ProjectFormViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class ProjectFormViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var projectName_textField: UITextField!
    
    @IBOutlet weak var category_button: UIButton!
    
    @IBOutlet weak var categoryIcon_imageView: UIImageView!
    
    @IBOutlet weak var note_textView: UITextView!
    
    @IBOutlet weak var budget_textField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var noTasksView: UIView!
    
    @IBOutlet weak var addTask_button: UIButton!
    
    @IBOutlet weak var deleteTask_Button: UIButton!
    
    @IBOutlet weak var finishDeleteTasksButton: UIButton!
    
    @IBOutlet weak var cancelEditingButton: UIButton!
    
    @IBOutlet weak var date_textField: UITextField!
    
    
    var project: Project?
    
    var isEditMode: Bool = false
    
    var tasksArray = [Task]()
    
    let datePicker = UIDatePicker()
    
    let defaultCategoryText = "Choose One:"
    
    var category = ""
    
    var totalSpent = 0.00
    
    var projectFinished: Bool = false
    
    var savedProject: Project?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HelperMethods.checkNetwork(on: self)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.dataSource = self
        note_textView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        //Decide if this is edit mode
        if isEditMode {
            //Get the project being edited
            guard let _project = project else {print("Project is null"); return}
            //Change navigation title
            navigationItem.title = "Edit Project"
            totalSpent = _project.totalSpent
            //Fill out the UI
            updateUI(_project: _project)
        } else {
            navigationItem.title = "Create Project"
        }
        
        //Set up the datePicker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        date_textField.delegate = self
        //Set the picker as the input view of the text field
        date_textField.inputView = datePicker
        
        //Add a done button to the date picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonClicked))
        toolbar.setItems([doneButton], animated: true)
        date_textField.inputAccessoryView = toolbar
        
    }
    
    @objc func dateChanged(_ sender: UIDatePicker){
        // Format the date from the date picker into a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeStyle = .none
        
        // Set the text field's text to the formatted date string
        date_textField.text = dateFormatter.string(from: sender.date)
    }
    
    @objc func doneButtonClicked(){
        date_textField.resignFirstResponder()
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer){
        note_textView.resignFirstResponder()
    }
    
    
    @IBAction func chooseCategoryTapped(_ sender: UIButton) {
        //create action sheet
        let categoryActionSheet = UIAlertController(title: "Choose Room to Renovate", message: nil, preferredStyle: .actionSheet)
        let categories = ["Bathroom", "Bedroom", "Kitchen" ,"Living Room"]
        for (_, chosenCategory) in categories.enumerated(){
            //Change the button title that opened the action sheet
            let action = UIAlertAction(title: chosenCategory, style: .default) { (action) in
                sender.setTitle(chosenCategory, for: .normal)
                //Set the category variable
                self.category = sender.titleLabel?.text ?? self.defaultCategoryText
                //set the category icon image
                self.categoryIcon_imageView.image = UIImage(named: HelperMethods.getCategoryImageName(projectCategory: chosenCategory))
            }
            
            categoryActionSheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        categoryActionSheet.addAction(cancelAction)
        
        //Support for iPad
        if let popoverController = categoryActionSheet.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        self.present(categoryActionSheet, animated: true)
        
    }
   
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        //Verify the entries
        verifyEntries()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return projectFinished
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
                HelperMethods.showToast(on: strongSelf, message: "No task was created.")
                return
            }
            
            
            //Add the task to the task array
            strongSelf.tasksArray.append(task)
            strongSelf.tableView.reloadData()
        }
    }
    
    @IBAction func deleteTaskTapped(_ sender: UIButton) {
        //put the table view into editing mode
        HelperMethods.editTaskTableView(tableView: tableView, addButton: addTask_button, editButton: deleteTask_Button, deleteButton: finishDeleteTasksButton, cancelButton: cancelEditingButton)
    }
    
    @IBAction func deleteSelectedTasksTapped(_ sender: UIButton) {
        
        //Delete the tasks and update the UI
        HelperMethods.deleteSelectedTasks(on: self, tableView: tableView, addButton: addTask_button, editButton: deleteTask_Button, deleteButton: finishDeleteTasksButton, cancelButton: cancelEditingButton, tasks: tasksArray) { newTasks in
            //update the tasks array
            self.tasksArray = newTasks
        }
    }
    
    @IBAction func cancelEditingTapped(_ sender: UIButton) {
        HelperMethods.quitEditing(tableView: tableView, addButton: addTask_button, editButton: deleteTask_Button, deleteButton: finishDeleteTasksButton, cancelButton: cancelEditingButton)
    }
    
    func updateUI(_project: Project){
        projectName_textField.text = _project.title
        category_button.titleLabel?.text = _project.category
        categoryIcon_imageView.image = UIImage(named: HelperMethods.getCategoryImageName(projectCategory: _project.category))
        
        //Set deadline date button text
        date_textField.text = _project.deadline
        
        //set design notes
        if let designNotes = _project.designNotes {
            note_textView.text = designNotes
        } else {
            note_textView.text = ""
        }
        
        //Set budget
        budget_textField.text = _project.budget.description
        
        if let tasks = _project.tasks, !tasks.isEmpty {
            // Display the tasks
            tasksArray = tasks
            noTasksView.isHidden = true
            tableView.isHidden = false
            addTask_button.isHidden = false
            deleteTask_Button.isHidden = false
            cancelEditingButton.isHidden = true
            finishDeleteTasksButton.isHidden = true
            
        } else {
            // Display "No tasks" message
            noTasksView.isHidden = false
            tableView.isHidden = true
            addTask_button.isHidden = true
            deleteTask_Button.isHidden = true
            cancelEditingButton.isHidden = true
            finishDeleteTasksButton.isHidden = true
        }
        
    }
    
    func verifyEntries() {
        let (titleIsFilled, projectTitle) = HelperMethods.textNotEmpty(projectName_textField)
        let (budgetIsFilled, budget) = HelperMethods.textNotEmpty(budget_textField)
        let (dateIsFilled, deadlineText) = HelperMethods.textNotEmpty(date_textField)
        
        if titleIsFilled && budgetIsFilled && dateIsFilled && category_button.titleLabel?.text != defaultCategoryText && category != defaultCategoryText {
            // If the project title, category, deadline, and budget are filled in, check that the budget can be a valid Double variable
            if let budgetDouble = Double(budget) {
                if isEditMode {
                    // Update the existing project
                    guard let existingProject = project else {
                        print("Project is nil")
                        return
                    }
                    
                    let updatedProject = Project(projectID: existingProject.projectID, title: projectTitle, category: category, deadline: deadlineText, budget: budgetDouble, tasks: tasksArray)
                    handleDesignNotesAndTaskIDs(updatedProject)
                    
                    // Save project to Firestore
                    saveProjectToFirestore(updatedProject) { success in
                        if success {
                            self.projectFinished = true
                            self.performSegue(withIdentifier: "unwindToDetails", sender: self)
                        } else {
                            self.projectFinished = false
                        }
                    }
                } else {
                    // Create a new project
                    let newProject = Project(projectID: "", title: projectTitle, category: category, deadline: deadlineText, budget: budgetDouble, tasks: tasksArray)
                    handleDesignNotesAndTaskIDs(newProject)
                    
                    // Save new project to Firestore
                    saveProjectToFirestore(newProject) { success in
                        if success {
                            self.projectFinished = true
                            self.performSegue(withIdentifier: "unwindToDetails", sender: self)
                        } else {
                            self.projectFinished = false
                        }
                    }
                }
            } else {
                HelperMethods.showToast(on: self, message: "Budget input must be set to a valid number")
                projectFinished = false
            }
        } else {
            // Something isn't input correctly
            let message = "Project Title, Project Category, Deadline, and Budget fields must be entered in order to create a new project"
            HelperMethods.showBasicErrorAlert(on: self, title: "Cannot Create Project", message: message)
            projectFinished = false
        }
    }

    func saveProjectToFirestore(_ project: Project, completion: @escaping (Bool) -> Void) {
        let projectsRef = Firestore.firestore().collection("projects")
        
        if isEditMode {
            // Update the existing project
            let existingProjectRef = projectsRef.document(project.projectID)
            updateProject(existingProjectRef, project) { success in
                self.savedProject = project
                completion(success)
            }
        } else {
            // Create a new project and capture the documentID
            let newProjectRef = projectsRef.document()
            project.projectID = newProjectRef.documentID
            updateProject(newProjectRef, project) { success in
                if success {
                    self.addProjectToUserProjects(project) { userProjectsSuccess in
                        self.savedProject = project
                        completion(userProjectsSuccess)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    func addProjectToUserProjects(_ project: Project, completion: @escaping (Bool) -> Void) {
        let userRef = Firestore.firestore().collection("users").document(Auth.auth().currentUser!.uid)
        userRef.updateData([
            "projects": FieldValue.arrayUnion([project.projectID])
        ]) { error in
            if let error = error {
                print("Error adding project to user projects array: \(error.localizedDescription)")
                HelperMethods.showBasicErrorAlert(on: self, title: "Error Saving Project To Database", message: error.localizedDescription)
                completion(false)
            } else {
                print("Successfully added project ID: \(project.projectID) to the user's projects array")
                completion(true)
            }
        }
    }


    func updateProject(_ projectRef: DocumentReference, _ project: Project, completion: @escaping (Bool) -> Void) {
        projectRef.setData(project.toDictionary(), merge: true) { error in
            if let error = error {
                print("Error updating project: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    HelperMethods.showBasicErrorAlert(on: self, title: "Error Saving Project", message: error.localizedDescription)
                }
                completion(false)
            } else {
                print("Project successfully updated")
                completion(true)
            }
        }
    }

    
    func handleDesignNotesAndTaskIDs(_ _project: Project){
        //Check if design notes were entered
        if note_textView.hasText {
            _project.designNotes = note_textView.text
        }
        if tasksArray.count != 0 {
            for task in tasksArray{
                if _project.taskIds == nil {
                    _project.taskIds = [task.taskId]
                } else {
                    _project.taskIds?.append(task.taskId)
                }
            }
        }
    }
    
    //MARK: Table View Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "task_reuseID", for: indexPath) as? TaskTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: "task_reuseID", for: indexPath)
        }
        
        let currentTask = tasksArray[indexPath.row]
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
        
        let selectedTask = tasksArray[indexPath.row]
        
        //Update the task based on the tap and update in Firestore
        HelperMethods.updateTaskWhenTapped(selectedTask: selectedTask, totalSpent: &totalSpent)
        
        //Sort taks so that the completed tasks are at the bottom
        tasksArray.sort { !$0.isCompleted && $1.isCompleted }
        
        if isEditMode {
            guard let _project = project else {print("Project is Nil"); return}
            //Assign the sorted tasks back to _project.tasks
            _project.tasks = tasksArray
        }
        
        
        tableView.reloadData()

    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "unwindToDetails" {
                if let destinationVC = segue.destination as? ProjectDetailViewController {
                    destinationVC.project = savedProject
                }
            }
    }
    

}
