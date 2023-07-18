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
    
    var loadingView: UIView?
    
    
    var project: Project?
    
    var isEditMode: Bool = false
    
    var tasksArray = [Task]()
    
    let datePicker = UIDatePicker()
    
    let defaultCategoryText = "Choose One:"
    
    var category = ""
    
    var totalSpent = 0.00
    
    var projectFinished: Bool = false
    
    var savedProject: Project?
    
    var projectIsCompleted: Bool = false
    
    var completedTasks = [Task]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HelperMethods.checkNetwork(on: self)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.dataSource = self
        note_textView.delegate = self
        tableView.allowsSelection = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.view.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false
        
        //Decide if this is edit mode
        if isEditMode {
            print("in edit mode")
            //Get the project being edited
            guard let _project = project else {print("Project is null"); return}
            //Change navigation title
            navigationItem.title = "Edit Project"
            totalSpent = _project.totalSpent
            print("view did load: in Edit mode: Sent projects total spent: \(_project.totalSpent)\nCaptured total spent: \(totalSpent)")
            //Fill out the UI
            updateUI(_project: _project)
        } else {
            navigationItem.title = "Create Project"
            category_button.setTitle("Kitchen", for: .normal)
            print("Captured total spent: \(totalSpent)")
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
        
        if #available(iOS 16.0, *) {
            let saveButton = UIBarButtonItem(title: "Save", image: nil, primaryAction: UIAction(handler: { [weak self] _ in
                self?.perform(#selector(self?.saveTapped))
            }))
            navigationItem.rightBarButtonItem = saveButton
        } else {
            // Fallback for earlier iOS versions
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
        }
        
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
        
        let tapLocation = sender.location(in: tableView)
            if let _ = tableView.indexPathForRow(at: tapLocation) {
                // Tapped inside a table view cell, skip keyboard dismissal
                return
            }
        projectName_textField.resignFirstResponder()
        note_textView.resignFirstResponder()
        budget_textField.resignFirstResponder()
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
                self.category = chosenCategory
                print("Chose category: \(self.category)")
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
   
    
    @objc func saveTapped() {
        print("saved tapped")
        
        //Show the loading view
        showLoadingView()
        
        //Verify the entries
        verifyEntries()
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
        print("deleteSelectedTasksTapped")
        // Check if any rows are selected
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
            print("No rows selected")
            return
        }
        
        // Show an alert to confirm deletion
        let alert = UIAlertController(title: "Delete Tasks", message: "Are you sure you want to delete the selected task(s)? This action cannot be undone.", preferredStyle: .alert)
        
        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Delete Action
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            // Track selected tasks and their costs
            var selectedTasks: [Task] = []
            var costOfSelectedCompletedTasks: Double = 0
            
            for path in selectedIndexPaths {
                let task = self.tasksArray[path.row]
                selectedTasks.append(task)
                if task.isCompleted {
                    costOfSelectedCompletedTasks += task.taskCost
                }
            }
            
            // Filter the tasks array to remove selected tasks
            self.tasksArray = self.tasksArray.filter { task in
                selectedTasks.first(where: { $0.taskId == task.taskId }) == nil
            }
            
            // Subtract the cost of the deleted completed tasks from total spent
            self.totalSpent -= costOfSelectedCompletedTasks
            
            // Quit editing
            HelperMethods.quitEditing(tableView: self.tableView, addButton: self.addTask_button, editButton: self.deleteTask_Button, deleteButton: self.finishDeleteTasksButton, cancelButton: self.cancelEditingButton)
            
            // Reload the tableView
            self.updateTableView()
        }))
        
        present(alert, animated: true)
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
            textField.placeholder = "Task cost (ex: $50 or 50)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Add Task", style: .default, handler: { [weak alert] _ in
            guard let alert = alert else { return }
            let taskField = alert.textFields![0]
            let costField = alert.textFields![1]

            guard let taskText = taskField.text, !taskText.isEmpty else {
                // If the task field is empty, call the completion handler with nil
                HelperMethods.showToast(on: self, message: "No Task Was Created")
                return
            }

            // Get and convert the cost. If it is empty, default the cost to 0.00
            let costText = costField.text ?? "0.00"
            let cleanCostText = costText.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            let cost = Double(cleanCostText) ?? 0.00
            //generate unique task ID
            let tempId = UUID().uuidString
            // Create the task with an empty ID
            let task = Task(taskId: tempId, task: taskText, isCompleted: false, taskCost: cost)
            
            //add that task to the tasks array
            self.tasksArray.append(task)
            self.updateTableView()
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
            deleteTask_Button.isHidden = true
            cancelEditingButton.isHidden = true
            finishDeleteTasksButton.isHidden = true
            
        } else {
            //show the tableView and tableView buttons
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
    
    func checkCompletedProject(){
        if completedTasks == tasksArray {
            //show alert asking if the project should be marked as completed
            let alert = UIAlertController(title: "All Tasks Complete", message: "All tasks have been marked as complete! Would you like to mark this project as completed?", preferredStyle: .alert)
            
            let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                self.projectIsCompleted = true
            }
            
            let cancelAction = UIAlertAction(title: "No", style: .cancel)
            
            alert.addAction(yesAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        }
    }
    
    func updateUI(_project: Project){
        projectName_textField.text = _project.title
        category_button.setTitle(_project.category, for: .normal)
        category = _project.category
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
            
            for task in tasksArray {
                if task.isCompleted {
                    completedTasks.append(task)
                }
            }
            
        }
        
        //Update the tableView
        updateTableView()
        
    }
    
    func verifyEntries() {
        print("verify entries called")
        let (titleIsFilled, projectTitle) = HelperMethods.textNotEmpty(projectName_textField)
        let (budgetIsFilled, budget) = HelperMethods.textNotEmpty(budget_textField)
        let (dateIsFilled, deadlineText) = HelperMethods.textNotEmpty(date_textField)
        print("Category equals \(category) and button text equals \(category_button.titleLabel?.text ?? "nil")")
        if category_button.titleLabel?.text == "Kitchen" {
            category = "Kitchen"
        }
        
        if titleIsFilled && budgetIsFilled && dateIsFilled && category != "" {
            // If the project title, category, deadline, and budget are filled in, check that the budget can be a valid Double variable
            let cleanBudgetText = budget.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if let budgetDouble = Double(cleanBudgetText) {
                if isEditMode {
                    // Update the existing project
                    guard let existingProject = project else {
                        hideLoadingView()
                        print("Project is nil")
                        return
                    }
                    
                    let updatedProject = Project(projectID: existingProject.projectID, title: projectTitle, category: category, deadline: deadlineText, budget: budgetDouble, tasks: tasksArray, completed: false)
                    print("Edited project's total spent is currently \(updatedProject.totalSpent) before updating")
                    updatedProject.totalSpent = totalSpent
                    print("Edited project's total spent is now \(updatedProject.totalSpent) after updating")
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
                        self.hideLoadingView()
                        if success {
                            self.projectFinished = true
                            self.performSegue(withIdentifier: "savedProjectDetails", sender: updatedProject)
                            print("Project was saved. Go to Details Page")
                        } else {
                            self.projectFinished = false
                        }
                    }
                } else {
                    // Create a new project
                    let newProject = Project(projectID: "", title: projectTitle, category: category, deadline: deadlineText, budget: budgetDouble, tasks: tasksArray, completed: false)
                    newProject.totalSpent = totalSpent
                    print("New project's total spent is \(newProject.totalSpent)")
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
                        self.hideLoadingView()
                        if success {
                            self.projectFinished = true
                            self.performSegue(withIdentifier: "savedProjectDetails", sender: newProject)
                            print("Project was saved. Go to Details Page")
                        } else {
                            self.projectFinished = false
                            print("Project was not saved successfully")
                        }
                    }
                }
            } else {
                hideLoadingView()
                HelperMethods.showToast(on: self, message: "Budget input must be set to a valid number")
                projectFinished = false
            }
        } else {
            hideLoadingView()
            // Something isn't input correctly
            print("Entries were not verified")
            let message = "Project Title, Project Category, Deadline, and Budget fields must be entered in order to create a new project"
            HelperMethods.showBasicErrorAlert(on: self, title: "Cannot Create Project", message: message)
            return
        }
    }
    
    func saveTasksToFirestore(task: Task, _project: Project){
        print("save tasks to firestore called")
        var reference: DocumentReference? = nil
        reference = Firestore.firestore().collection("tasks").addDocument(data: task.toDictionary(), completion: { (error) in
            if let error = error{
                self.hideLoadingView()
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
        print("Add Project to firestore called")
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
                    self.hideLoadingView()
                    completion(false)
                }
            }
        }
    }

    func addProjectToUserProjects(_ project: Project, completion: @escaping (Bool) -> Void) {
        print("Add Project to user's projects called")
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
        print("Update project called")
        projectRef.setData(project.toDictionary(), merge: true) { error in
            if let error = error {
                print("Error updating project: \(error.localizedDescription)")
                completion(false)
            } else {
                if let taskIDs = project.taskIds {
                    projectRef.updateData(["tasks": taskIDs]) {error in
                        if let error = error {
                            print("Error updating taskIds in Firestore: \(error.localizedDescription)")
                        } else {
                            print("taskIds updated successfully in Firestore")
                        }
                    }
                }
                if let notes = project.designNotes {
                    projectRef.updateData(["designNotes" : notes]) {error in
                        if let error = error {
                            print("Error updating design notes in Firestore: \(error.localizedDescription)")
                        } else {
                            print("design notes updated successfully in Firestore")
                        }
                    }
                }
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
    
    func showLoadingView() {
        // Create the loading view
        loadingView = UIView(frame: view.bounds)
        loadingView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Add the label to the loading view
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        label.text = "Saving your project..."
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


    
    //MARK: Table View Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Cell for Row")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "task_reuse_ID", for: indexPath) as? TaskTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: "task_reuse_ID", for: indexPath)
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
            print("didSelectRowAt was tapped")
            
            let selectedTask = tasksArray[indexPath.row]
            print("The selected task was: \(selectedTask.task) and is this task completed?: \(selectedTask.isCompleted)")
            
            //Update the task based on the tap
            HelperMethods.updateTaskWhenTapped(selectedTask: selectedTask, totalSpent: &totalSpent)
            
            print("the selected task is now completed? : \(selectedTask.isCompleted)")
            
            //Sort tasks so that the completed tasks are at the bottom
            tasksArray.sort { !$0.isCompleted && $1.isCompleted }
            
            if selectedTask.isCompleted{
                completedTasks.append(selectedTask)
                checkCompletedProject()
            } else if !selectedTask.isCompleted {
                completedTasks.removeAll { $0 == selectedTask }
            }
            
            //If the project was completed and the task completed was marked as incomplete, change the projectIsCompleted variable to false
            if projectIsCompleted && !selectedTask.isCompleted{
                projectIsCompleted = false
            }
            
            print("Calling ReloadTableView")
            tableView.reloadData()
            print("ReloadTableView has been called")
        }
    }

    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "savedProjectDetails",
               let project = sender as? Project,
               let detailVC = segue.destination as? ProjectDetailViewController{
                
            detailVC.sentProject = project
            
            }
    }
    

}
