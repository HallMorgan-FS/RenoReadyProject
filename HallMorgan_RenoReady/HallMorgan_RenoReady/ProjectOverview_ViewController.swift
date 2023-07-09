//
//  ProjectOverview_ViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/23/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProjectOverview_ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var ProjectsNum_label: UILabel!
    
    @IBOutlet weak var projects_tableView: UITableView!
    
    @IBOutlet weak var noProjectsView: UIView!
    
    @IBOutlet weak var editButton: UIButton!
    
    
    var currentUser: FirebaseAuth.User?
    var projects: [Project] = []
    
    let db = Firestore.firestore()
    
    var selectedProject: Project?
    
    var remaining = 0.00
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ProjectsOverview: viewDidLoad was called ")
        HelperMethods.checkNetwork(on: self)
        
        projects_tableView.rowHeight = UITableView.automaticDimension
        projects_tableView.estimatedRowHeight = 86

        // Do any additional setup after loading the view.
        
        projects_tableView.delegate = self
        projects_tableView.dataSource = self
        
        projects_tableView.allowsMultipleSelectionDuringEditing = true
        
        //Check if the current user has any projects saved
        getCurrentUserAndProjects()
        
    }
    
    
    private func getCurrentUserAndProjects(){
        
        currentUser = Auth.auth().currentUser
        
        guard let userID = Auth.auth().currentUser?.uid else {return}
        
        let userRef = db.collection("users").document(userID)
        userRef.getDocument { (_document, error) in
            if let document = _document, document.exists {
                
                if let projectIds = document.data()?["projects"] as? [String]{
                    
                    if projectIds.isEmpty{
                        
                        //Show the noProjectsView
                        self.noProjectsView.isHidden = false
                        self.projects_tableView.isHidden = true
                        
                    } else {
                        print("project Ids count is: \(projectIds.count)")
                        //loop through the project IDs
                        for projectId in projectIds {
                            
                            let projectRef = self.db.collection("projects").document(projectId)
                            
                            projectRef.getDocument { (projectDocument, error) in
                                if let projectDocument = projectDocument, projectDocument.exists{
                                    if let project = HelperMethods.project(from: projectDocument){
                                        
                                        //add to projects array
                                        self.projects.append(project)
                                        
                                        DispatchQueue.main.async {
                                            self.updateProjectUI()
                                            self.projects_tableView.reloadData()
                                        }
                                    }
                                } else {
                                    print("Project does not exist")
                                }
                            }
                        }
                    }
                } else {
                    //If the "projects" field/key doesn't exist or isn't an array
                    self.noProjectsView.isHidden = false
                    self.projects_tableView.isHidden = true
                }
            } else {
                print("User does not exist")
            }
        }
        
    }
    
    
    @IBAction func editTapped(_ sender: UIButton) {
        //Toggle the editing mode
        projects_tableView.isEditing.toggle()
        //editButton.titleLabel?.text = projects_tableView.isEditing ? "Done" : "Edit"
        
        if projects_tableView.isEditing {
            // If tableView is in editing mode, add the delete button
            editButton.setTitle("Done", for: .normal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteSelectedProjects))
            goToDetails = false
        } else {
            // If tableView is not in editing mode, remove the delete button
            editButton.setTitle("Edit", for: .normal)
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    //MARK: Table View Set Up
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "reuseId", for: indexPath) as? ProjectsTableViewCell else{
            return projects_tableView.dequeueReusableCell(withIdentifier: "reuseId", for: indexPath)
        }
        
        //Get the current project
        let project = projects[indexPath.row]
        
        //Set the properites
        cell.projectName_label.text = project.title
        let imageName = HelperMethods.getCategoryImageName(projectCategory: project.category)
        cell.categoryIcon.image = UIImage(named: imageName)
        cell.deadline_label.text = "Deadline: \(project.deadline)"
        var remainingBudget = project.budget
        if project.totalSpent <= project.budget{
            remainingBudget = project.budget - project.totalSpent
        } else {
            remainingBudget = 0.00
        }
        print("Remaining budget is \(remainingBudget)")
        let remainingBudgetString = HelperMethods.formatNumberToCurrency(value: remainingBudget)
        cell.remainingBudget_label.text = "\(remainingBudgetString) Left"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 86
    }
    
    var goToDetails = false
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !projects_tableView.isEditing {
            print("DidSelectRowAt was called")
            //Open detail view for that specific project
            let selectedProject = projects[indexPath.row]
            print("Selected Project: \(selectedProject.title)")
            self.selectedProject = selectedProject
            print("Self.selectedProject? equals: \(self.selectedProject?.title ?? "nil")")
            goToDetails = true
            // Perform the segue
            self.performSegue(withIdentifier: "toDetails", sender: selectedProject)
        } else {
            goToDetails = false
        }
    }
    var goToNewProject = false
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "toDetails"{
            return goToDetails
        }
        if identifier == "toNewProject"{
            return goToNewProject
        }
        if identifier == "toProfile"{
            return true
        }
        return false
    }
    
    //MARK: Delete Project
    
    @objc func deleteSelectedProjects() {
        if let selectedRows = projects_tableView.indexPathsForSelectedRows {
            //send alert asking if the user is sure they want to delete the selected project[s]
            let alert = UIAlertController(title: "Delete Project(s)", message: "Are you sure you want to delete the selected project(s)? This action cannot be undone.", preferredStyle: .alert)

            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                // Reverse sort the indexes so we delete from the end of the list
                let indexes = selectedRows.map { $0.row }.sorted(by: >)
                for index in indexes {
                    self.deleteProject(projectIndexPath: IndexPath(row: index, section: 0))
                }
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

            alert.addAction(deleteAction)
            alert.addAction(cancelAction)

            present(alert, animated: true)
        }
    }
    
    func deleteProject(projectIndexPath: IndexPath){
        
        let project = projects[projectIndexPath.row]
        
        //remove project from array
        projects.remove(at: projectIndexPath.row)
        
        //Remove project from firebase
        let projectRef = db.collection("projects").document(project.projectID)
        
        projectRef.delete { err in
            if let err = err {
                print("Error removing document from firebase: \(err.localizedDescription)")
                let alert = UIAlertController(title: "Something Went Wrong", message: "The selected project(s) were unable to be deleted. We are sorry for inconvience. Please try again.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                
                alert.addAction(okAction)
                self.present(alert, animated: true)
                
            } else {
                //Deletion successfull
                
                //delete from the table view
                self.projects_tableView.deleteRows(at: [projectIndexPath], with: .automatic)
                
                self.updateProjectUI()
            }
            
        }
        
    }
    
    //MARK: UI Update
    
    func updateProjectUI(){
        if projects.isEmpty {
            //Show the noProjectsView and hide the table view
            self.editButton.isHidden = true
            self.noProjectsView.isHidden = false
            self.projects_tableView.isHidden = true
        } else {
            //Hide the noProjectsView and show the tableView
            self.editButton.isHidden = false
            self.noProjectsView.isHidden = true
            self.projects_tableView.isHidden = false
            
        }
        
        //Update the projectsNum_label
        self.ProjectsNum_label.text = "Projects(\(projects.count))"
        
    }
    
    //MARK: Navigation
    
    @IBAction func createProjectTapped(_ sender: UIButton) {
        goToNewProject = true
        performSegue(withIdentifier: "toNewProject", sender: self)
        goToNewProject = false
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare for segue called")
        // Check segue identifier
        if segue.identifier == "toDetails" {
            print("toDetails was called")
            // Get the new view controller using segue.destination.
            let destinationVC = segue.destination as! ProjectDetailViewController
            // Pass the selected object to the new view controller.
            destinationVC._project = sender as? Project
        }
    }
    

}
