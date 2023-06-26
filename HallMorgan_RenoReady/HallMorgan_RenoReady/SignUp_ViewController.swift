//
//  SignUp_ViewController.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/23/23.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class SignUp_ViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var profilePicture: UIImageView!
    
    @IBOutlet weak var email_textField: UITextField!
    
    @IBOutlet weak var password_textField: UITextField!
    
    @IBOutlet weak var confirmPassword_textField: UITextField!
    
    @IBOutlet weak var signUpTapped: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var didSignUp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Add observers to only scroll while the keyboard is showing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //Add tap gesture for the image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profilePicture.addGestureRecognizer(tapGesture)
        
        //Set the textField's delegate
        email_textField.delegate = self
        password_textField.delegate = self
        confirmPassword_textField.delegate = self

    }
    
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        
        var errorMessages = [String]()
        
        // Check that the email is valid
        let email = email_textField.text ?? ""
        
        if !HelperMethods.isValidEmail(email) {
            errorMessages.append("The email address entered is not a valid email")
        }
        
        // Check that the password is valid
        let password = password_textField.text ?? ""
        
        let (isPasswordValid, passwordErrorMessage) = HelperMethods.isValidPassword(password)
        if !isPasswordValid {
            errorMessages.append("Password must contain " + passwordErrorMessage)
        }
        
        // Check that the password is confirmed
        if let confirmedPass = confirmPassword_textField.text, !confirmedPass.elementsEqual(password) {
            errorMessages.append("Password entries do not match")
        }
        
        // If there are any errors, show them in an alert
        if !errorMessages.isEmpty {
            showAlert(errorMessages.joined(separator: "\n"))
        } else {
            //Create the user with firebase
            createUser(_email: email, _password: password)
        }
        
    }
    
    private func createUser(_email: String, _password: String){
        Auth.auth().createUser(withEmail: _email, password: _password) { authResult, error in
            //Handle any errors
            if let error = error {
                self.showAlert(error.localizedDescription)
            }
            
            //Get the uid of the newley created user
            guard let uid = authResult?.user.uid else {return}
            
            //Create the user
            if let defaultProfileImage = UIImage(named: "defaultProfileIcon") {
                let _user = User(email: _email, profilePhoto: self.profilePicture.image ?? defaultProfileImage)
                //Add the user's profile photo to Firebase storage and add user to firestore
                self.addUserToFirestore(uid: uid, user: _user)
            }
        }
    }
    
    private func addUserToFirestore(uid: String, user: User) {
        //Create a reference to the firebase storage
        let storage = Storage.storage()
        
        //Convert the user's profile photo to data
        guard let imageData = user.profilePhoto.jpegData(compressionQuality: 0.75) else {
            print("Could not convert image to Data")
            return
        }
        
        //Create a storage reference for the profile image
        let userPhotosRef = storage.reference().child("\(uid)/profile_images/profile_photo.jpg")
        
        //Create the upload metadata
        let uploadMetadata = StorageMetadata()
        uploadMetadata.contentType = "image/jpeg"
        
        //Upload the photo to Firebase Storage
        let uploadTask = userPhotosRef.putData(imageData, metadata: uploadMetadata) { metadata, error in
            if let error = error {
                self.showAlert(error.localizedDescription)
            }
            
            //Once the upload is complete, get the download URL
            userPhotosRef.downloadURL { url, error in
                if let urlError = error {
                    self.showAlert("Error getting download URL: \(urlError.localizedDescription)")
                    return
                }
                
                guard let url = url else {
                    print("URL was nil")
                    return
                }
                 print(url)
                
                //Add user to Firestore with the profile photo URL
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "email" : user.email,
                    "profile_photo_url" : url.absoluteString,
                    "projects": [String]()
                ]
                
                db.collection("users").document(uid).setData(userData) { error in
                    if let firestoreError = error {
                        print("Error adding user to Firestore: \(firestoreError)")
                        self.didSignUp = false
                        return
                    } else {
                        print("User added to Firestore")
                        self.didSignUp = true
                        // Perform segue to home screen
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "signUpDone", sender: self)
                        }
                    }
                    
                    
                }
                
            }
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "signUpDone"{
            return didSignUp
        }
        return true
    }
    
    // MARK: PROFILE PHOTO - IMAGE PICKER METHODS
    
    @objc func imageTapped() {
        
        //Check camera and photo library access
        HelperMethods.checkCameraOrPhotoLibraryAccess(on: self)
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.openCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: { _ in
            self.openPhotoLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        self.present(imagePicker, animated: true, completion: nil)
    }

    private func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            profilePicture.contentMode = .scaleAspectFill
            profilePicture.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)

    }

    //MARK: UITextFieldDelegate and Keyboard Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case email_textField:
            password_textField.becomeFirstResponder()
        case password_textField:
            confirmPassword_textField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    //MARK: Alert Controller
    private func showAlert(_ message: String){
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Try Again", style: .default)
        alert.addAction(alertAction)
        present(alert, animated: true)
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
