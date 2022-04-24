//
//  VCLoginFormView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCLoginFormView : VCView {
    
    // MARK: OUTLETS
    
    // Scroll controls
    @IBOutlet weak var loginFormScrollView: UIScrollView!
    @IBOutlet weak var loginFormContentHeight: NSLayoutConstraint!
    
    // Text fields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmationTextField: UITextField!
    
    // Buttons
    @IBOutlet weak var passwordVisibilityButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var cancelLoginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: PROPERTIES
    
    var passwordIsSecure = true
 
    // MARK: INITIALIZATION
     
    override func initView() {
        
        // Attach the common controls
        scrollView = loginFormScrollView
        contentHeight = loginFormContentHeight
        
        // Set up the buttons
        loginButton.roundAllCorners(value: 10.0)
        createAccountButton.roundAllCorners(value: 10.0)
        cancelLoginButton.roundAllCorners(value: 10.0)
        cancelLoginButton.setBorder(width: 1.0, color: UIColor.lightGray.cgColor)
        
        activityIndicator.isHidden = true
        
        // Peform the remaining common initialization tasks
        super.initView()
    }
    
    override func loadData() {
        
        if globalData.settings.rememberMe {
            
            emailTextField.text = globalData.user.data.userEmail
            passwordTextField.text = globalData.user.passwords.currentPassword
        }
        
        setButtons()
    }
    
    // MARK: METHODS
    
    func showActivityIndicator(visibility: Bool) {
        
        if visibility {
            
            createAccountButton.setTitle("", for: .normal)
            activityIndicator.isHidden = false
        }
        else {

            createAccountButton.setTitle("CREATE ACCOUNT", for: .normal)
            activityIndicator.isHidden = true
        }
    }

    func clear() {
        
        emailTextField.text = ""
        passwordTextField.text = ""
        confirmationTextField.text = ""
    }
    
    func validateFields(forTab: LoginAction) -> Bool {
        
        if forTab == .create {
            
            // Get the user's input
            let email = emailTextField.text
            let password = passwordTextField.text
            let confirmation = confirmationTextField.text
            
            // Validate fields
            guard VCDataValidator().isValidEmail(emailToTest: email!) else { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Please enter a valid email"); return false }
            if !VCDataValidator().isValidPassword(passwordToTest: password!) { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Your password does not meet the security requirements"); return false }
            if password != confirmation { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Passwords don't match"); return false }
            
            // Save the input
            globalData.user.data.userEmail = email!
            globalData.user.passwords.currentPassword = password!
            
            _ = VCKeychainServices().writeData(data: globalData.user.data.userEmail, withKey: "user")
            _ = VCKeychainServices().writeData(data: globalData.user.passwords.currentPassword, withKey: "password")
        }
        
        else if forTab == .login {
            
            // Get the user's input
            let email = emailTextField.text
            let password = passwordTextField.text
            
            // Validate fields
            guard VCDataValidator().isValidEmail(emailToTest: email!) else { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Please enter a valid email"); return false }
            
            // Save the input
            globalData.user.data.userEmail = email!
            globalData.user.passwords.currentPassword = password!
            
            _ = VCKeychainServices().writeData(data: globalData.user.data.userEmail, withKey: "user")
            _ = VCKeychainServices().writeData(data: globalData.user.passwords.currentPassword, withKey: "password")
        }
        
        return true
    }
    
    func setButtons() {
        
        if emailTextField.text!.isEmpty {
            
            loginButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { self.loginButton.isEnabled = false })
            createAccountButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { self.createAccountButton.isEnabled = false })
        }
        
        else if passwordTextField.text!.isEmpty {
            
            loginButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { self.loginButton.isEnabled = false })
            createAccountButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { self.createAccountButton.isEnabled = false })
        }
        
        else if confirmationTextField.text!.isEmpty {
            
            loginButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: { self.loginButton.isEnabled = true})
            createAccountButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { self.createAccountButton.isEnabled = false })
        }
            
        else {
            
            loginButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { self.loginButton.isEnabled = false })
            createAccountButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: { self.createAccountButton.isEnabled = true})
        }
    }
    
    func setPasswordSecurity(_ state: Bool) {
        
        // Toggle the password visibility button (eye)
        if state {
            
            // Show the "show" button when the password is in secure entry mode
            passwordVisibilityButton.setImage(UIImage(named: "button.pwshow.png"), for: .normal)
            passwordTextField.isSecureTextEntry = true
            confirmationTextField.isSecureTextEntry = true
            passwordIsSecure = true
            
        }  else {
        
            // Show the "hide" button when the password is visible
            passwordVisibilityButton.setImage(UIImage(named: "button.pwhide.png"), for: .normal)
            passwordTextField.isSecureTextEntry = false
            confirmationTextField.isSecureTextEntry = false
            passwordIsSecure = false
        }
    }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func textFieldChanged(_ sender: Any) { setButtons() }
        
    @IBAction func passwordVisibiltyButtonTapped(_ sender: UIButton) { setPasswordSecurity(!passwordIsSecure) }
   
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        
        // Force end of editing and perform field validation
        endEditing()

        parentController.homeController.loginMessageLabel.text = "LOGGING IN"
        parentController.homeController.loginActivityIndicator.isHidden = false
        parentController.homeController.loginMessageLabel.isHidden = false
        
        parentController.homeController.credentialsButton.alpha = 0.0
        parentController.homeController.credentialsButton.isHidden = true

        if validateFields(forTab: .login) {
            
            self.changeDisplayState(toState: .hidden, forDuration: 0.25, atCompletion: {
                
                self.parentController.homeController.vcLogin!.reset()
                
                if globalData.flags.loginState == .loggedOut { self.parentController.homeController.vcLogin!.preload(isReLogin: true) }
                else { self.parentController.homeController.vcLogin!.login() }
            })
        }
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        
        endEditing()
        
        if validateFields(forTab: .create) {
            
            showActivityIndicator(visibility: true)
            parentController.homeController.vcLogin!.create()
        }
    }
        
    @IBAction func cancelLoginButtonTapped(_ sender: UIButton) {
        
        endEditing()
        parentController.homeController.credentialsButton.alpha = 1.0
        hideView()
    }
      
    @IBAction func endOfEditing(_ sender: UITextField) { endEditing() }
}
