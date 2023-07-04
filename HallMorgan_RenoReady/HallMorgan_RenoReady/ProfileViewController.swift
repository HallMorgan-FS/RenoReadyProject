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
        
        profilePicture_imageView.clipsToBounds = true

        // Do any additional setup after loading the view.
        //Add tap gesture for the image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profilePicture_imageView.addGestureRecognizer(tapGesture)
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

                guard let confirmText = confirmTextField?.text else { return }

                // Validate password change
                let (isValidPassword, passwordErrorMessage) = HelperMethods.isValidPassword(newText)
                if !isValidPassword {
                    self.showAlert(passwordErrorMessage) {
                        newTextField?.text = "" // Clear the new password text field
                        confirmTextField?.text = "" // Clear the confirm password text field
                    }
                    return
                }

                if newText != confirmText {
                    self.showAlert("Passwords do not match.") {
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
                                        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
                                           let window = sceneDelegate.window {
                                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                                            window.rootViewController = loginViewController
                                            window.makeKeyAndVisible()
                                        }
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
                        self.showAlert("Email changed successfully. Please sign in again with your updated credentials.") {
                            // Log out and exit the app
                            do {
                                try Auth.auth().signOut()
                                // Navigate to the login screen
                                    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
                                       let window = sceneDelegate.window {
                                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                                        window.rootViewController = loginViewController
                                        window.makeKeyAndVisible()
                                    }
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
    }



    func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logoutTapped(_ sender: UIButton) {
        //log the user out and exit to the home screen
        do {
            try Auth.auth().signOut()
            //User logged out successfully
            performSegue(withIdentifier: "unwindToLogin", sender: self)
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
            HelperMethods.showBasicErrorAlert(on: self, title: "Error Signing Out", message: error.localizedDescription)
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
            if let resizedImageData = HelperMethods.resizeAndCompressImage(image: pickedImage, targetSize: CGSize(width: 150, height: 150)) {
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
