//
//  ProjectDetailViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProjectDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var categoryIcon_imageView: UIImageView!
    
    @IBOutlet weak var deadline_label: UILabel!
    
    @IBOutlet weak var notes_textView: UITextView!
    
    @IBOutlet weak var budget_label: UILabel!
    
    @IBOutlet weak var totalSpent_label: UILabel!
    
    @IBOutlet weak var addTaskButton: UIButton!
    
    @IBOutlet weak var deleteTaskButton: UIButton!
    
    @IBOutlet weak var noTasksView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var projectID: String!
    
    var project: Project?
    
    let db = Firestore.firestore()
    
    var taskArray = [Task]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //Fetch project with project ID
        let projectRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("projects").document(projectID)
        
        projectRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let project = self.project(from: document) {
                    self.project = project
                    //fetch the projects tasks
                    if let taskIds = project.taskIds {
                        self.fetchTasks(taskIDs: taskIds) { tasks in
                            self.project?.tasks = tasks
                            //Update UI with project data
                            self.updateUI(with: project)
                        }
                    } else {
                        self.updateUI(with: project)
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
        
    }
    
    func project(from document: DocumentSnapshot) -> Project? {
        var project: Project
        if let projectData = document.data() {
            let projectId = document.documentID
            let title = projectData["title"] as? String ?? ""
            let category = projectData["category"] as? String ?? ""
            let deadline = projectData["deadline"] as? String ?? ""
            let budget = projectData["budget"] as? Double ?? 0
            let designNotes = projectData["notes"] as? String ?? ""
            let taskIds = projectData["tasks"] as? [String]
            
            project = Project(projectID: projectId, title: title, category: category, deadline: deadline, budget: budget, tasks: nil, taskIds: taskIds)
            
            
            return project
        }
        return nil
    }
    
    func fetchTasks(taskIDs: [String], completion: @escaping ([Task]) -> Void) {
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
    
    func task(from document: DocumentSnapshot) -> Task? {
        if let taskData = document.data(){
            let taskId = document.documentID
            if let task = taskData["task"] as? String,
               let isCompleted = taskData["isCompleted"] as? Bool{
                let taskCost = taskData["taskCost"] as? Double
                return Task(taskId: taskId, task: task, isCompleted: isCompleted, taskCost: taskCost)
            }
               
        }
        return nil
    }
    
    func updateUI(with project: Project){
        if let designNotes = project.designNotes {
            //Display the design notes
            notes_textView.text = designNotes
        } else {
            notes_textView.text = ""
        }
        
        //update deadline
        deadline_label.text = project.deadline
        
        budget_label.text = project.budget.description
        
        var totalCost = 0.00
        
        if let tasks = project.tasks, !tasks.isEmpty {
            // Display the tasks
            noTasksView.isHidden = true
            tableView.isHidden = false
            for task in tasks {
                if task.isCompleted {
                    if let taskCost = task.taskCost{
                        totalCost += taskCost
                    }
                }
            }
            
            totalSpent_label.text = totalCost.description
            
        } else {
            // Display "No tasks" message
            noTasksView.isHidden = false
            tableView.isHidden = true
        }
        
        
    }
    
    
    
    @IBAction func addTaskTapped(_ sender: UIButton) {
    }
    
    @IBAction func deleteTaskTapped(_ sender: UIButton) {
    }
    
    
    @IBAction func editProjectTapped(_ sender: UIBarButtonItem) {
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
            cell.backgroundColor = UIColor(red: 150.0/255.0, green: 165.0/255.0, blue: 117.0/255.0, alpha: 1.0)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var currentTask = taskArray[indexPath.row]
        
        let alert = UIAlertController(title: "\(currentTask.task)", message: "How much did this item cost you?", preferredStyle: .alert)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "$100"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            let costTextField = alert.textFields![0] as UITextField
            //convert the cost to a double
        }
        
        
        
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
