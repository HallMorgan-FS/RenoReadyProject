//
//  HelperMethods.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/23/23.
//

import Foundation
import UIKit

class HelperMethods {
    
    static func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            
        let emailPred = NSPredicate(format:"SELF MATCHES %@", regex)
        return emailPred.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> (Bool, String) {
        // Check that password is at least 8 characters long
        guard password.count >= 8 else { return (false, "at least 8 characters") }
        
        // Check that password contains at least one uppercase letter
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let hasUppercaseLetter = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex).evaluate(with: password)
        guard hasUppercaseLetter else { return (false, "one uppercase letter") }
            
        // Check that password contains at least one number
        let numberRegex = ".*[0-9]+.*"
        let hasNumber = NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password)
        guard hasNumber else { return (false, "at least one number") }
            
        // If all checks passed, return true
        return (true, "Passed")
    }
    
    static func textNotEmpty(_ textField: UITextField) -> (Bool, String){
        
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
               return (false, "Empty or whitespace")
           }
           return (true, text)
    }
    
    static func resizeAndCompressImage(image: UIImage, targetSize: CGSize) -> Data? {
        // Resize image
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress image
        let imageData = newImage!.jpegData(compressionQuality: 0.5)
        
        return imageData
    }
    
    static func convertBase64ToImage(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    static func checkCameraOrPhotoLibraryAccess(on viewController: UIViewController){
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            showAlertToOpenSettings(on: viewController, withMessage: "Camera access is not available. You can enable access in Privacy Settings.")
            return
        }
        
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            showAlertToOpenSettings(on: viewController, withMessage: "Photo Library access is not available. You can enable access in Privacy Settings.")
            return
        }
    }
    
    static func showAlertToOpenSettings(on viewController: UIViewController, withMessage message: String ){
        let alert = UIAlertController(title: "Access Required", message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
}
