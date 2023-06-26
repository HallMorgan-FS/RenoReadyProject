//
//  ViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/22/23.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var email_textField: UITextField!
    
    @IBOutlet weak var password_textField: UITextField!
    
    @IBOutlet weak var forgotPassword_button: UIButton!
    
    @IBOutlet weak var newUser_signUp_button: UIButton!
    
    var userEmail = ""
    var userPassword = ""
    
    var didSignIn = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        UINavigationBar.appearance().isTranslucent = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let buttonArray = [newUser_signUp_button, forgotPassword_button]
        for button in buttonArray {
            guard let buttonText = button?.currentTitle else { return }
            let attributedTitle = NSAttributedString(string: buttonText, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
            button?.setAttributedTitle(attributedTitle, for: .normal)
        }
        
    }

    @IBAction func newUserSignUpTapped(_ sender: UIButton) {
        //Go to SignUp_ViewController
    }
    
    @IBAction func signInTapped(_ sender: UIButton) {
        //Verify the user input
        let (emailFilled, email) = HelperMethods.textNotEmpty(email_textField)
        let (passFilled, password) = HelperMethods.textNotEmpty(password_textField)
        
        if (emailFilled && passFilled){
            userEmail = email
            userPassword = password
            
            //Sign in via firebase Auth
            signInWithFirebase()
            
        } else {
            //send alert
            let alert = UIAlertController(title: "Error", message: "Email and password fields cannot be left blank. Please try again.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            //Add the action and present the alert
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            
            didSignIn = false
        }
    }
    
    private func signInWithFirebase(){
        Auth.auth().signIn(withEmail: userEmail, password: userPassword) {[weak self] authResult, error in
            guard let strongSelf = self else {return}
            
            //Handle the error
            if let error = error {
                let authError = error as NSError
                // Show an alert with the error
                let alert = UIAlertController(title: "Error", message: authError.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                strongSelf.present(alert, animated: true)
                strongSelf.didSignIn = false
                return
            }
            
            //If successful, navigate to the view controller
            if let _ = authResult {
                strongSelf.didSignIn = true
                strongSelf.performSegue(withIdentifier: "toHomeScreen", sender: nil)
            }
        }
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        //Create alert to get the users email
        let alertController = UIAlertController(title: "Reset Password", message: "Please enter your email address:", preferredStyle: .alert)
            
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Enter Your Email"
            }
            
            let sendAction = UIAlertAction(title: "Send", style: .default, handler: { alert -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                if let emailToBeReset = firstTextField.text {
                    Auth.auth().sendPasswordReset(withEmail: emailToBeReset) { error in
                        // Handle errors here
                        if let error = error {
                            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true)
                            return
                        } else {
                            let alert = UIAlertController(title: "Success", message: "A reset password link has been sent to your email if the email address is registered to a user.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true)
                        }
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            alertController.addAction(sendAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "toHomeScreen" {
            return didSignIn
        }
        return true
    }
    
    
}

