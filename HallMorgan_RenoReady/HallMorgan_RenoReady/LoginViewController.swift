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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        UINavigationBar.appearance().isTranslucent = true
        //check network
        HelperMethods.checkNetwork(on: self)
        
//
//        email_textField.resignFirstResponder()
//        password_textField.resignFirstResponder()
        //password_textField.isSecureTextEntry = true
        
        if let _ = Auth.auth().currentUser{
            //Bypass the login page
            performSegue(withIdentifier: "toHomeScreen", sender: self)
        } else {
            //Set up the login page
            let buttonArray = [newUser_signUp_button, forgotPassword_button]
            for button in buttonArray {
                guard let buttonText = button?.currentTitle else { return }
                let attributedTitle = NSAttributedString(string: buttonText, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
                button?.setAttributedTitle(attributedTitle, for: .normal)
            }
        }
        
        //set password visibily toggle based on eye being touched
        //create a button
        let passVisButton = UIButton(type: .custom)
        
        //Set the image for the button
        passVisButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        //Add a target for this button
        passVisButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        passVisButton.tintColor = UIColor.darkBrown
        //set constraints for button
        passVisButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        //Add the button to the text field's right view
        password_textField.rightView = passVisButton
        //Set the text field's right view mode to always appear
        password_textField.rightViewMode = .always
        
    }
    
    @objc func togglePasswordVisibility(){
        //Change the secure text entry property of the textField
        password_textField.isSecureTextEntry = !password_textField.isSecureTextEntry
        
        //Get a reference to the button
        let passVisButton = password_textField.rightView as! UIButton
        
        //Set the image based on whether the pasword is currently visable
        if password_textField.isSecureTextEntry{
            passVisButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            passVisButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }
    
    func clearTextFields() {
        UINavigationBar.appearance().isTranslucent = true
        email_textField.text = nil
        password_textField.text = nil
        email_textField.resignFirstResponder()
        password_textField.resignFirstResponder()
        password_textField.isSecureTextEntry = true
    }

    var signUp = true
    @IBAction func newUserSignUpTapped(_ sender: UIButton) {
        //Go to SignUp_ViewController
        print("Sign up tapped")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let signUpViewController = storyboard.instantiateViewController(withIdentifier: "signUpViewController") as? SignUp_ViewController else {
            return
        }
        
        let navigationController = UINavigationController(rootViewController: signUpViewController)
        
        if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = navigationController
        }
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
                let alert = UIAlertController(title: "Error", message: "\(authError.localizedDescription)\nPlease try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Try Again", style: .default))
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
                            let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)\nPlease try again.", preferredStyle: .alert)
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
    
    @IBAction func unwindToLogin(_ segue: UIStoryboardSegue) {
        // This method will be called when the user logs out
    }
    
    
}

