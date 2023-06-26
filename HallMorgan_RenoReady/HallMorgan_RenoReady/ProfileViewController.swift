//
//  ProfileViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var profilePicture_imageView: UIImageView!
    
    @IBOutlet weak var email_label: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func changeEmailOrPasswordTapped(_ sender: UIButton) {
    }
    
    
    
    @IBAction func logoutTapped(_ sender: UIButton) {
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
