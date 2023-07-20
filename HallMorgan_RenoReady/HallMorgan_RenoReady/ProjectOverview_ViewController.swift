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
    
    var filteredProjects = [[Project](), [Project]()]
    
    
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
    
    func filterProjectsByCompletion(){
        filteredProjects[0] = projects.filter({ $0.completed == false })
        filteredProjects[1] = projects.filter({ $0.completed == true })
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
                                            self.filterProjectsByCompletion()
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
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    //MARK: Table View Set Up
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProjects[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "reuseId", for: indexPath) as? ProjectsTableViewCell else{
            return projects_tableView.dequeueReusableCell(withIdentifier: "reuseId", for: indexPath)
        }
        
        //Get the current project
        let project = filteredProjects[indexPath.section][indexPath.row]
        
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
        if project.completed {
            cell.remainingBudget_label.text = "DONE"
        } else {
            cell.remainingBudget_label.text = "\(remainingBudgetString) Left"
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 86
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "In Progress:"
        case 1:
            return "Completed:"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
       
        
        let headerView = UIView()
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 0, width: projects_tableView.bounds.size.width, height: projects_tableView.bounds.size.height))
        headerLabel.font = UIFont.boldSystemFont(ofSize: 25)
        headerLabel.text = self.tableView(projects_tableView, titleForHeaderInSection: section)
        
        //Set the different colors for the sections
        if section == 0 {
            headerView.backgroundColor = UIColor.darkBrown
            headerLabel.textColor = UIColor.cremeWhite
        } else if section == 1 {
            headerView.backgroundColor = UIColor.darkGreen
            headerLabel.textColor = UIColor.darkBrown
        }
        
        headerLabel.sizeToFit()
        headerView.addSubview(headerLabel)
        return headerView
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = UIColor.cremeWhite

        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }

    
    var goToDetails = false
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !projects_tableView.isEditing {
            print("DidSelectRowAt was called")
            // Open detail view for that specific project
            // Get the correct project using indexPath.section and indexPath.row
            let selectedProject = filteredProjects[indexPath.section][indexPath.row]
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
            // send alert asking if the user is sure they want to delete the selected project[s]
            let alert = UIAlertController(title: "Delete Project(s)", message: "Are you sure you want to delete the selected project(s)? This action cannot be undone.", preferredStyle: .alert)

            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                // Reverse sort the indexes so we delete from the end of the list
                let sections = Array(Set(selectedRows.map { $0.section })) // Get unique sections
                for section in sections {
                    let rowsInSection = selectedRows.filter { $0.section == section }.map { $0.row }.sorted(by: >)
                    for row in rowsInSection {
                        let projectIndexPath = IndexPath(row: row, section: section)
                        self.deleteProject(projectIndexPath: projectIndexPath)
                    }
                }
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

            alert.addAction(deleteAction)
            alert.addAction(cancelAction)

            present(alert, animated: true)
        }
    }

    
    func deleteProject(projectIndexPath: IndexPath) {
        let project = filteredProjects[projectIndexPath.section][projectIndexPath.row]
        // Remove project from array
        filteredProjects[projectIndexPath.section].remove(at: projectIndexPath.row)

        // Remove project from Firebase
        let projectRef = db.collection("projects").document(project.projectID)

        projectRef.delete { err in
            if let err = err {
                print("Error removing document from Firebase: \(err.localizedDescription)")
                let alert = UIAlertController(title: "Something Went Wrong", message: "The selected project(s) were unable to be deleted. We are sorry for the inconvenience. Please try again.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)

                alert.addAction(okAction)
                self.present(alert, animated: true)
            } else {
                // Deletion successful. Now delete the project from the user's database
                guard let userID = self.currentUser?.uid else {
                    print("User is nil")
                    return
                }

                let userRef = self.db.collection("users").document(userID)

                userRef.updateData([
                    "projects": FieldValue.arrayRemove([project.projectID])
                ]) { err in
                    if let err = err {
                        print("Error updating user: \(err.localizedDescription)")
                    } else {
                        print("User updated successfully")
                    }
                }

                // Delete from the table view
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
            destinationVC.sentProject = sender as? Project
        }
    }
    

}
