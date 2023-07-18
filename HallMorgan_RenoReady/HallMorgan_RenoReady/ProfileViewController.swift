//
//  ProfileViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Photos
import AVFoundation

class ProfileViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profilePicture_imageView: UIImageView!
    
    @IBOutlet weak var email_label: UILabel!
    
    let currentUser = Auth.auth().currentUser
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        //Add tap gesture for the image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profilePicture_imageView.addGestureRecognizer(tapGesture)
        
        //Update UI
        updateUI()
        
    }
    
    func updateUI() {
        // Get the current user's UID
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert("User is not logged in.")
            return
        }

        // Create a reference to the Firestore database
        let db = Firestore.firestore()

        // Retrieve the user document from Firestore
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.showAlert("Failed to fetch user data: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.data() else {
                self.showAlert("User document does not exist.")
                return
            }
            
            // Access the profile photo URL and email from the document
            if let profilePhotoURL = document["profile_photo_url"] as? String,
               let email = document["email"] as? String {
                // Use the profile photo URL and email to update the UI
                
                self.email_label.text = email
                
                if let imageURL = URL(string: profilePhotoURL){
                    URLSession.shared.dataTask(with: imageURL) { data, response, error in
                        guard let imageData = data else {
                            print("Failed to download image data: \(error?.localizedDescription ?? "")")
                            return
                        }
                        
                        // Create the image from the downloaded data
                        if let image = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                // Update the image view with the downloaded image
                                self.profilePicture_imageView.image = image
                                print("Successfully captured image data and set ptofile photo")
                            }
                        }
                    }.resume()
                }
                
            }
        }

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func changeEmailOrPasswordTapped(_ sender: UIButton) {
        let passwordRequirements = """
Password Must:
- Be at least 8 characters or longer
- Contain at least one uppercase letter
- Contain at least one number
"""
        switch sender.tag {
        case 0:
            //Change email tapped
            showChangeVariableAlert(title: "Change Email", message: "Please confirm your current email and then enter the new email you would like to use.", placeholder: "email")
            return
        case 1:
            showChangeVariableAlert(title: "Change Password", message: "Please confirm your current password and then enter your new password\n\n\(passwordRequirements)", placeholder: "password")
            return
        default:
            print("This shouldn't happen")
        }
    }
    
    func showChangeVariableAlert(title: String, message: String, placeholder: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        var currentTextField: UITextField?
        var newTextField: UITextField?
        var confirmTextField: UITextField?

        // Create the first text field for current value
        alert.addTextField { textField in
            textField.placeholder = "Current \(placeholder)"
            currentTextField = textField
        }

        // Create the second text field for new value
        alert.addTextField { textField in
            textField.placeholder = "New \(placeholder)"
            textField.delegate = self
            newTextField = textField
        }

        // Add action buttons to the alert
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            // Handle the save button action here
            // Access the entered values using `alert.textFields?[index].text`
            guard let currentText = currentTextField?.text else { return }
            guard let newText = newTextField?.text else { return }

            if title == "Change Password" {
                // Create the third text field for confirm value
                alert.addTextField { textField in
                    textField.placeholder = "Confirm \(placeholder)"
                    textField.delegate = self
                    confirmTextField = textField
                }

                
                // Validate password change
                let (isValidPassword, passwordErrorMessage) = HelperMethods.isValidPassword(newText)
                if !isValidPassword {
                    self.showAlert("Password must include at least \(passwordErrorMessage)") {
                        newTextField?.text = "" // Clear the new password text field
                        confirmTextField?.text = "" // Clear the confirm password text field
                    }
                    return
                }
                

                // Validate current password
                let credential = EmailAuthProvider.credential(withEmail: Auth.auth().currentUser?.email ?? "", password: currentText)
                Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                    if error != nil {
                        self.showAlert("Current password is incorrect.") {
                            currentTextField?.text = "" // Clear the current password text field
                            newTextField?.text = "" // Clear the new password text field
                            confirmTextField?.text = "" // Clear the confirm password text field
                        }
                        return
                    }

                    // Change the user's password using the Firebase Auth API
                    Auth.auth().currentUser?.updatePassword(to: newText) { error in
                        if let error = error {
                            self.showAlert("Failed to change password: \(error.localizedDescription)")
                        } else {
                            self.showAlert("Password changed successfully. Please sign in again with your updated credentials.") {
                                // Log out and exit the app
                                do {
                                    try Auth.auth().signOut()
                                    // Navigate to the login screen
                                    //self.performSegue(withIdentifier: "unwindToLogin", sender: self)
                                    self.goToLoginScreen()
                                } catch let signOutError as NSError {
                                    print("Error signing out: \(signOutError.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            } else if title == "Change Email" {
                // Validate email change
                if currentText != Auth.auth().currentUser?.email {
                    self.showAlert("Current email does not match the user's current email.") {
                        currentTextField?.text = "" // Clear the current email text field
                        newTextField?.text = "" // Clear the new email text field
                    }
                    return
                }

                if !HelperMethods.isValidEmail(newText) {
                    self.showAlert("Invalid email format.") {
                        newTextField?.text = "" // Clear the new email text field
                    }
                    return
                }

                // Change the user's email using the Firebase Auth API
                Auth.auth().currentUser?.updateEmail(to: newText) { error in
                    if let error = error {
                        self.showAlert("Failed to change email: \(error.localizedDescription)")
                    } else {
                        if let currentUser = self.currentUser {
                            let uid = currentUser.uid
                            
                            let userDoc = Firestore.firestore().collection("users").document(uid)
                            
                            userDoc.updateData(["email" : newText]) { err in
                                if let err = err {
                                    print("Error updating user email: \(err.localizedDescription)")
                                } else {
                                    print("Email in document was successfully updated")
                                }
                            }
                        }
                        self.showAlert("Email changed successfully. Please sign in again with your updated credentials.") {
                            // Log out and exit the app
                            do {
                                try Auth.auth().signOut()
                                // Navigate to the login screen
                                //self.performSegue(withIdentifier: "unwindToLogin", sender: self)
                                self.goToLoginScreen()
                            } catch let signOutError as NSError {
                                print("Error signing out: \(signOutError.localizedDescription)")
                            }
                        }
                    }
                }
            }
        })

        // Present the alert
        present(alert, animated: true, completion: nil)
        updateUI()
    }



    func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logoutTapped(_ sender: UIButton) {
        print("Logout tapped")
        //log the user out and exit to the home screen
        do {
            try Auth.auth().signOut()
            //User logged out successfully
            print("User logged out.")
            //NotificationCenter.default.post(name: .didLogout, object: nil)
            //performSegue(withIdentifier: "unwindToLogin", sender: self)
            goToLoginScreen()
            print("Went back to login")
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
            HelperMethods.showBasicErrorAlert(on: self, title: "Error Signing Out", message: error.localizedDescription)
        }
    }
    
    @IBAction func deleteAccount(_ sender: UIButton) {
        let alert = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account? This cannot be undone. All Project data will be lost", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let user = Auth.auth().currentUser else {return}
            
            //delete all of the users data
            self.deleteUserData(user: user)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func deleteUserData( user : FirebaseAuth.User){
        // Create a DispatchGroup
        let group = DispatchGroup()
        
        //fetch all of the projects of the user
        let userRef = Firestore.firestore().collection("users").document(user.uid)
        userRef.getDocument { (snapshot, error) in
            if let error = error {
                print("Error getting user document: \(error.localizedDescription)")
            } else {
                if let userData = snapshot?.data() {
                    let projectIDs = userData["projects"] as? [String] ?? []
                    let profilePhotoURL = userData["profile_photo_url"] as? String
                    
                    //Fetch and delete each project
                    
                    for projectID in projectIDs {
                        let projectRef = Firestore.firestore().collection("projects").document(projectID)
                        projectRef.getDocument { (snapshot, error ) in
                            if let error = error {
                                print("Error getting project document: \(error.localizedDescription)")
                            } else {
                                
                                //If there is a list of task IDs withing the project document, delete each task
                                if let projectData = snapshot?.data() {
                                    let taskIDs = projectData["tasks"] as? [String] ?? []
                                    for taskID in taskIDs {
                                        // Enter the group before each request
                                        group.enter()
                                        
                                        let taskRef = projectRef.collection("tasks").document(taskID)
                                        taskRef.delete { error in
                                            if let error = error {
                                                print("Error deleting tasks: \(error.localizedDescription) ")
                                            } else {
                                                print("tasks have been deleted")
                                            }
                                            // Leave the group as soon as the request is finished
                                            group.leave()
                                        }
                                    }
                                }
                                
                                // Enter the group for the project deletion
                                group.enter()
                                //Delete the project document
                                projectRef.delete { err in
                                    if let err = err {
                                        print("Error deleting project document: \(err.localizedDescription)")
                                    } else {
                                        print("Project document successfully removed!")
                                    }
                                    // Leave the group when the project deletion is done
                                    group.leave()
                                }
                            }
                        }
                    }
                    
                    //Delete the profile photo
                    if let profilePhotoURL = profilePhotoURL {
                        // Enter the group for the image deletion
                        group.enter()
                        
                        let storageRef = Storage.storage().reference(forURL: profilePhotoURL)
                        storageRef.delete { error in
                            if let error = error {
                                print("Error deleting image: \(error.localizedDescription)")
                            } else {
                                print("Image deleted successfully")
                            }
                            // Leave the group when the image deletion is done
                            group.leave()
                        }
                    }
                    
                    // When all the previous operations (tasks, projects, image deletions) are done, then proceed to delete user document and user from Firebase Auth
                    group.notify(queue: .main) {
                        // Delete the user document
                        userRef.delete { err in
                            if let err = err {
                                print("Error removing user document: \(err)")
                                HelperMethods.showBasicErrorAlert(on: self, title: "Error Deleting Account", message: "Error: \(err.localizedDescription)")
                            } else {
                                print("User document successfully removed!")
                                
                                // Then delete the user from Firebase Auth
                                user.delete { error in
                                    if let error = error {
                                        print("An error occurred when deleting the user")
                                        HelperMethods.showBasicErrorAlert(on: self, title: "Error Deleting Account", message: "Error: \(error.localizedDescription)")
                                    } else {
                                        print("User was deleted from Firebase Auth")
                                        // Navigate back to login screen or perform further clean up
                                        self.goToLoginScreen()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    func goToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {
            return
        }
        
        let navigationController = UINavigationController(rootViewController: loginViewController)
        
        if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = navigationController
        }
    }

    
    
    // MARK: PROFILE PHOTO - IMAGE PICKER METHODS
    
    @objc func imageTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
                self.openCamera()
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionSheet.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: { _ in
                self.openPhotoLibrary()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .camera
                    self.present(imagePicker, animated: true, completion: nil)
                } else {
                    self.showCameraAccessDeniedAlert()
                }
            }
        }
    }

    private func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .photoLibrary
                    self.present(imagePicker, animated: true, completion: nil)
                case .denied, .restricted:
                    self.showPhotoLibraryAccessDeniedAlert()
                case .notDetermined:
                    break
                case .limited:
                    self.showLimitedAccessAlert()
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func showLimitedAccessAlert() {
        let alert = UIAlertController(
            title: "Limited Access",
            message: "Your access to the photo library is limited. To grant full access, please follow these steps:\n\n1. Open the Settings app.\n2. Navigate to Privacy > Photos.\n3. Enable access to Photos for this app.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if let resizedImageData = HelperMethods.resizeAndCompressImage(image: pickedImage, targetSize: CGSize(width: 115, height: 115)) {
                profilePicture_imageView.contentMode = .scaleAspectFill
                profilePicture_imageView.image = UIImage(data: resizedImageData)
                
                // Get the current user's UID
                guard let uid = Auth.auth().currentUser?.uid else {
                    showAlert("User is not logged in.")
                    return
                }
                
                // Create a reference to the Firebase Storage
                let storage = Storage.storage()
                
                // Create a storage reference for the profile image
                let userPhotosRef = storage.reference().child("\(uid)/profile_images/profile_photo.jpg")
                
                // Create the upload metadata
                let uploadMetadata = StorageMetadata()
                uploadMetadata.contentType = "image/jpeg"
                
                // Upload the photo to Firebase Storage
                _ = userPhotosRef.putData(resizedImageData, metadata: uploadMetadata) { metadata, error in
                    if let error = error {
                        self.showAlert("Failed to upload profile photo: \(error.localizedDescription)")
                        return
                    }
                    
                    // Once the upload is complete, get the download URL
                    userPhotosRef.downloadURL { url, error in
                        if let urlError = error {
                            self.showAlert("Error getting download URL: \(urlError.localizedDescription)")
                            return
                        }
                        
                        guard let url = url else {
                            print("URL was nil")
                            return
                        }
                        
                        // Update the profile photo URL in Firestore
                        let db = Firestore.firestore()
                        db.collection("users").document(uid).updateData(["profile_photo_url": url.absoluteString]) { error in
                            if let firestoreError = error {
                                self.showAlert("Failed to update profile photo URL in Firestore: \(firestoreError.localizedDescription)")
                            } else {
                                print("Profile photo updated successfully.")
                            }
                        }
                    }
                }
            } else {
                showAlert("Failed to resize and compress image.")
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }


    private func showPhotoLibraryAccessDeniedAlert() {
        let alert = UIAlertController(title: "Photo Library Access Denied", message: "Please grant permission to access the photo library in Settings to select an image.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func showCameraAccessDeniedAlert() {
        let alert = UIAlertController(title: "Camera Access Denied", message: "Please grant permission to access the camera in Settings to take a photo.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
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

extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
}
