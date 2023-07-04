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
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.locale = Locale(identifier: "en_US")
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        date_textField.delegate = self
        date_textField.textAlignment = .center
        //Set the picker as the input view of the text field
        date_textField.inputView = datePicker
        
        // Add a done button to the date picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPressed))
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonClicked))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([cancelBarButton, flexSpace, doneButton], animated: true)
        date_textField.inputAccessoryView = toolbar
        
    }
    
    @objc func cancelPressed() {
         self.resignFirstResponder()
       }
    
    @objc func dateChanged(_ sender: UIDatePicker){
        // Format the date from the date picker into a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeStyle = .none
        dateFormatter.timeZone = TimeZone.current
        let selectedDate = sender.date
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss z"

        guard let date = inputDateFormatter.date(from: inputDateFormatter.string(from: selectedDate)) else {
                // Handle invalid date string
                print("Invalid date")
                return
            }

        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = "MM/dd/yyyy"

        let formattedDate = outputDateFormatter.string(from: date)
        
        
        // Set the text field's text to the formatted date string
        date_textField.text = formattedDate
        print("Date changed and should be: \(formattedDate)")
    }
    
    @objc func doneButtonClicked(){
        date_textField.resignFirstResponder()
        // Format the date from the date picker into a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeStyle = .none
        let formattedDate = dateFormatter.string(from: datePicker.date)
        print("Done clicked. Date is: \(formattedDate)")
        
        // Update the date picker's value to match the selected date
        datePicker.setDate(dateFormatter.date(from: date_textField.text ?? "") ?? Date(), animated: true)
        
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
        print("saved tapped")
        //Verify the entries
        verifyEntries()
        
        if projectFinished {
            performSegue(withIdentifier: "unwindToDetails", sender: self)
        } else {
            let message = "Project Title, Project Category, Deadline, and Budget fields must be entered in order to create a new project"
            HelperMethods.showBasicErrorAlert(on: self, title: "Cannot Create Project", message: message)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return projectFinished
    }
    
    @IBAction func addTaskTapped(_ sender: UIButton) {
        //Call the showTaskAlert
        showTaskAlert()
        //Since the task has been added to the array, update the table view
        updateTableView()
    }
    
    @IBAction func deleteTaskTapped(_ sender: UIButton) {
        //put the table view into editing mode
        HelperMethods.editTaskTableView(tableView: tableView, addButton: addTask_button, editButton: deleteTask_Button, deleteButton: finishDeleteTasksButton, cancelButton: cancelEditingButton)
    }
    
    @IBAction func deleteSelectedTasksTapped(_ sender: UIButton) {
        //Check if any rows are selected
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
            print("No rows selected")
            return
        }
        
        //Show an alert to confirm deletion
        let alert = UIAlertController(title: "Delete Tasks", message: "Are you sure you want to delete the selected task(s)? This action cannot be undone.", preferredStyle: .alert)
        
        //Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        //Delete Action
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            
            //Delete the tasks from the tasks array
            self.tasksArray = self.tasksArray.enumerated().filter { indexPath in
                !selectedIndexPaths.contains { $0.row == indexPath.offset }
            }.map { $0.element }
            
            //Quit editing
            HelperMethods.quitEditing(tableView: self.tableView, addButton: self.addTask_button, editButton: self.deleteTask_Button, deleteButton: self.finishDeleteTasksButton, cancelButton: self.cancelEditingButton)
            
            //Reload the tableView
            self.updateTableView()
        }))
    }
    
    @IBAction func cancelEditingTapped(_ sender: UIButton) {
        HelperMethods.quitEditing(tableView: tableView, addButton: addTask_button, editButton: deleteTask_Button, deleteButton: finishDeleteTasksButton, cancelButton: cancelEditingButton)
    }
    
    func showTaskAlert(){
        let alert = UIAlertController(title: "Create Task", message: "What is the task that needs to be completed and it's total cost?", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "What is the task?"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "How much will task cost?"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Add Task", style: .default, handler: { [weak alert] _ in
            guard let alert = alert else { return }
            let taskField = alert.textFields![0]
            let costField = alert.textFields![1]
            costField.keyboardType = .decimalPad

            guard let taskText = taskField.text, !taskText.isEmpty else {
                // If the task field is empty, call the completion handler with nil
                HelperMethods.showToast(on: self, message: "No Task Was Created")
                return
            }

            // Get and convert the cost. If it is empty, default the cost to 0.00
            let costText = costField.text ?? "0.00"
            let cost = Double(costText) ?? 0.00
            
            // Generate a temporary task ID using UUID
            let temporaryTaskId = UUID().uuidString

            // Create the task with an empty ID
            let task = Task(taskId: temporaryTaskId, task: taskText, isCompleted: false, taskCost: cost)
            
            //add that task to the tasks array
            self.tasksArray.append(task)
            self.noTasksView.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }))
        
        present(alert, animated: true)
    }
    
    func updateTableView(){
        
        if tasksArray.isEmpty {
            // Display "No tasks" message
            noTasksView.isHidden = false
            tableView.isHidden = true
            addTask_button.isHidden = false
            deleteTask_Button.isHidden = false
            cancelEditingButton.isHidden = true
            finishDeleteTasksButton.isHidden = true
            
        } else {
            //Hide the tableView and tableView buttons
            noTasksView.isHidden = true
            tableView.isHidden = false
            addTask_button.isHidden = false
            deleteTask_Button.isHidden = false
            cancelEditingButton.isHidden = true
            finishDeleteTasksButton.isHidden = true
        }
        
        //Reload the tableView
        tableView.reloadData()
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
        }
        
        //Update the tableView
        updateTableView()
        
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
                    handleDesignNotes(updatedProject)
                    //If the tasks aren't empty, save the tasks to firestore and get the updated taskID
                    if (!tasksArray.isEmpty){
                        for task in tasksArray {
                            //save to firestore and update the project's taskIDs
                            self.saveTasksToFirestore(task: task, _project: updatedProject)
                        }
                    }
                    
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
                    handleDesignNotes(newProject)
                    //If the tasks aren't empty, save the tasks to firestore and get the updated taskID
                    if (!tasksArray.isEmpty){
                        for task in tasksArray {
                            //save to firestore and update the project's taskIDs
                            self.saveTasksToFirestore(task: task, _project: newProject)
                        }
                    }
                    
                    // Save new project to Firestore
                    saveProjectToFirestore(newProject) { success in
                        if success {
                            self.projectFinished = true
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
            
            return
        }
    }
    
    func saveTasksToFirestore(task: Task, _project: Project){
        var reference: DocumentReference? = nil
        reference = Firestore.firestore().collection("tasks").addDocument(data: task.toDictionary(), completion: { (error) in
            if let error = error{
                print("Error adding task to Firestore: \(error.localizedDescription)")
                HelperMethods.showBasicErrorAlert(on: self, title: "Error Storing Task", message: error.localizedDescription)
                
            } else {
                //Replace the taskID with the Firestore document ID
                if let documentId = reference?.documentID {
                    task.taskId = documentId
                    //Task should be saved to firestore with a new ID
                    print("Task: \(task.task) was saved to Firestore with the taskID: \(task.taskId) matching the document ID: \(documentId)")
                    //Save the taskID to the project
                    if _project.taskIds == nil {
                        _project.taskIds = [documentId]
                    } else if let taskIDs = _project.taskIds, !taskIDs.contains(documentId) {
                        _project.taskIds?.append(documentId)
                    }
                } else {
                    print("Error: Firestore document reference is nil")
                }
            }
        }) //End of document reference
        
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

    
    func handleDesignNotes(_ _project: Project){
        //Check if design notes were entered
        if note_textView.hasText {
            _project.designNotes = note_textView.text
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
        //HelperMethods.updateTaskWhenTapped(selectedTask: selectedTask, totalSpent: &totalSpent)
        
        selectedTask.isCompleted.toggle()
        
        //Sort taks so that the completed tasks are at the bottom
        tasksArray.sort { $0.isCompleted && !$1.isCompleted }
        
        
        tableView.reloadRows(at: [indexPath], with: .none)
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
