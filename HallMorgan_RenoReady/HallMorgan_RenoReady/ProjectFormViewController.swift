//
//  ProjectFormViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit

class ProjectFormViewController: UIViewController {
    
    
    @IBOutlet weak var projectName_textField: UITextField!
    
    
    @IBOutlet weak var category_button: UIButton!
    
    @IBOutlet weak var categoryIcon_imageView: UIImageView!
    
    @IBOutlet weak var date_button: UIButton!
    
    @IBOutlet weak var note_textView: UITextView!
    
    @IBOutlet weak var budget_textField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var noTasksView: UIView!
    
    @IBOutlet weak var addTask_button: UIButton!
    
    @IBOutlet weak var deleteTask_Button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func chooseCategoryTapped(_ sender: UIButton) {
    }
    
    @IBAction func chooseDeadlineTapped(_ sender: UIButton) {
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func addTaskTapped(_ sender: UIButton) {
    }
    
    @IBAction func deleteTaskTapped(_ sender: UIButton) {
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
