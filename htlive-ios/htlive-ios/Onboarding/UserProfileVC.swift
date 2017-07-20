//
//  UserProfileVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack
import PhoneNumberKit
import MBProgressHUD

class UserProfileVC: UIViewController, UITextFieldDelegate {
    
    var onboardingViewDelegate:OnboardingViewDelegate? = nil
    let phoneNumberKit = PhoneNumberKit()
    
    @IBOutlet weak var nameTextField: CustomTextField!
    @IBOutlet weak var phoneNumberTextField: CustomPhoneTextField!
    @IBOutlet weak var photoImage: UIImageView!
    
    let picker = UIImagePickerController()
    var imagePicked:Bool = false
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!

    @IBAction func saveProfile(_ sender: Any) {
        getOrCreateHyperTrackUser()
    }

    @IBAction func skipProfile(_ sender: Any) {
        // TODO: On skip profile, a user is created with empty
        // name and phone number. Should we use the device id
        // in this case?
        getOrCreateHyperTrackUser()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNumberTextField.delegate = self
        nameTextField.delegate = self
        nameTextField.autocapitalizationType = .words
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Text editing dismiss gesture
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(UserProfileVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Image tap gesture
        setImageDelegate()
    }
    
    func dismissKeyboard() {
        // Dismiss the key when the tap gesture is used on the view
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            bottomConstraint.constant = keyboardSize.height + 10
            topConstraint.constant = topConstraint.constant - keyboardSize.height - 10
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 20
        topConstraint.constant = 60
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Phone number field did begin editing.
        // Set the text to be the default country code
        
        if (textField.tag == 1) {
            // The phone number text field has a tag of 1 in the storyboard
            if let country = (Locale.current as NSLocale).object(forKey: .countryCode) as? String {
                let countryCode = phoneNumberKit.countryCode(for: country)!
                phoneNumberTextField.text = "+\(countryCode) "
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func alertError(msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func getOrCreateHyperTrackUser() {
        let name = nameTextField.text ?? ""
        var phone = phoneNumberTextField.text ?? ""
        var photo: UIImage? = nil
        
        if (imagePicked) {
            if let image = photoImage.image {
                photo = resizeImage(image: image, targetSize: CGSize(width: 200, height: 200))
            }
        }
        
        if (phone != "") {
            do {
                let parsedPhone = try phoneNumberKit.parse(phone)
                phone = phoneNumberKit.format(parsedPhone, toType: .e164) // Sends phone as +15103094946
            }
            catch {
                alertError(msg: "Please enter a valid phone number")
                return
            }
        }

        // Phone number is used as the user lookup id
        self.showActivityIndicator()

        HyperTrack.getOrCreateUser(name, phone, phone, photo) { (user, error) in
            self.hideActivityIndicator()
            
            if (error != nil) {
                // Handle error on get or create user
                self.alertError(msg: (error?.type.rawValue)!)
                return
            }
            
            if (user != nil) {
                // User successfully created
                print("User created:", user!.id)
                HyperTrack.startTracking()
                self.onboardingViewDelegate?.didCreatedUser(user: user!,currentController:self)
                if (phone != "") {
                    // If phone was given, send verification code
                    self.sendVerificationCode()
                } else {
                    // So user was created but since there was no phone
                    // number, just go to the placeline screen
                    self.onboardingViewDelegate?.didSkipProfile(currentController: self)
                }
            }
        }
    }
    
    func sendVerificationCode() {
        let requestService = RequestService.shared
        requestService.sendHyperTrackCode(completionHandler: { (error) in
            if (error != nil) {
                // Handle error
                // TODO: better handling required
                self.alertError(msg: "Verification code could not be sent")
            } else {
                // This means the verification text was sent successfully
                // Move to the verification code view.
//                self.dismiss(animated: false, completion: {
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let verifyController = storyboard.instantiateViewController(withIdentifier: "ValidateCodeVC") as! ValidateCodeVC
                    verifyController.onboardingViewDelegate = self.onboardingViewDelegate
                    self.present(verifyController, animated: true, completion: nil)

//                })
                
                //self.onboardingViewDelegate?.willGoToValidateCode(currentController: self,presentController: verifyController)
                
            }
        })
    }
    
    func showActivityIndicator(animated: Bool = true) {
        MBProgressHUD.showAdded(to: self.view, animated: animated)
    }
    
    func hideActivityIndicator(animate animated: Bool = true) {
        MBProgressHUD.hide(for: self.view, animated: animated)
    }
}

extension UserProfileVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func setImageDelegate() {
        let imageTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                      action: #selector(UserProfileVC.pickImage))
        photoImage.addGestureRecognizer(imageTap)
        picker.delegate = self
        
        photoImage.image = UIImage(named: "profile-1")?.withRenderingMode(.alwaysTemplate)
        photoImage.tintColor = .white
    }
    
    func pickImage() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Add a photo", message: "Where do you want your photo from?", preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            //
        }
        actionSheetController.addAction(cancelActionButton)
        
        let cameraActionButton = UIAlertAction(title: "From camera", style: .default)
        { _ in
            self.pickFromCamera()
        }
        actionSheetController.addAction(cameraActionButton)
        
        let libraryActionButton = UIAlertAction(title: "From library", style: .default)
        { _ in
            self.pickFromLibrary()
        }
        actionSheetController.addAction(libraryActionButton)
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func pickFromCamera() {
        picker.allowsEditing = true
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .fullScreen
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.cameraDevice = UIImagePickerController.isCameraDeviceAvailable(.front) ? .front : .rear

        present(picker, animated: true, completion: nil)
    }
    
    func pickFromLibrary() {
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(picker, animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    //MARK: - Delegates
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
        photoImage.contentMode = .scaleAspectFit
        photoImage.image = chosenImage
        imagePicked = true
        dismiss(animated:true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
