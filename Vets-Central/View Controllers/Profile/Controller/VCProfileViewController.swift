//
//  VCAccountViewController.swift
//  Vets-Central
//
//  Account Scene Controller
//  Created by Roger Vogel on 5/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCProfileViewController: VCViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // MARK: OUTLETS
    
    @IBOutlet var profileSettingsView: VCProfileSettingsView!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var givenNameTextField: UITextField!
    @IBOutlet weak var familyNameTextField: UITextField!
    @IBOutlet weak var address1TextField: UITextField!
    @IBOutlet weak var address2TextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var postalTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
 
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var contentHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var settingsButton: UIButton!
  
    // MARK: PROPERTIES
    
    var countryPickerView = UIPickerView()
    var statePickerView = UIPickerView()
    var toolBar: UIToolbar = UIToolbar()
    var doneButton: UIBarButtonItem?
    var countryPickerArray = [String]()
    var statePickerArray = [String]()
    var pickerArray = [String]()
    var countrySelected: Int = 0
    var stateSelected: Int = 0
    var scrollHeight : CGFloat?
    var hasState: Bool?
    var localUserData = VCUserRecord()
    var localSwitchData =  VCSettings()
    var userUpdateData: VCDBUpdateUser?
    var userAddressData: VCDBAddress?
    var userLanguageData: VCDBLanguage?
    var changePassword = VCDBPassword()
        
    // MARK: INITIALIZATION AND OVERRIDES
    
    override func viewDidLoad() { super.viewDidLoad()
        
        // Round the save and cancel buttons
        saveButton.roundAllCorners(value: 10.0)
        cancelButton.roundAllCorners(value: 10.0)
        
        countryTextField.delegate = self
        stateTextField.delegate = self
        
        view.addSubview(profileSettingsView)
        profileSettingsView.initView()
    
        // Setup the picker view and menu
        setupPicker()
    }
    
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated)
        
        emailTextField.placeholder = globalData.user.data.userEmail
        showActivityIndicator(false)
        
        globalData.activeController = self
    }
 
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated)
        
        // Add self as observer of keyboard show and hide notications
        NotificationCenter.default.addObserver(self, selector: #selector( VCProfileViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector( VCProfileViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Set the scroll height and copy the user data for recovery purposes
        scrollHeight = contentHeight.constant
        localUserData = globalData.user.data
        localSwitchData = globalData.settings
        
        // Load the text fields with current data
        setTextFields()
    
        // Load the countries and states into arrays
        setCountries()
        setStates()
        
        // Set the default selections for the pickers
        setSelections()
    }
    
    override func viewWillDisappear(_ animated: Bool) { doLogoutTasks(); super.viewWillDisappear(false) }
    
    override func doLogoutTasks() {
        
        profileSettingsView.hideView()
        clearData()
    }
    
    // MARK: METHODS
    
    func setTextFields () {
        
        emailTextField.text = localUserData.userEmail
        emailTextField.textColor = UIColor(displayP3Red: 0.50, green: 0.50, blue: 0.50, alpha: 1.0)
        
        countryTextField.text = localUserData.country
        givenNameTextField.text = localUserData.givenName
        familyNameTextField.text = localUserData.familyName
        address1TextField.text = localUserData.address1
        address2TextField.text = localUserData.address2
        cityTextField.text = localUserData.city
        stateTextField.text = localUserData.state
        postalTextField.text = localUserData.postalCode
        phoneTextField.text = localUserData.phone
    }
    
    func getTextFields() {
        
        localUserData.userEmail = emailTextField.text!
        localUserData.country = countryTextField.text!
        localUserData.givenName = givenNameTextField.text!
        localUserData.familyName = familyNameTextField.text!
        localUserData.address1 = address1TextField.text!
        localUserData.address2 = address2TextField.text!
        localUserData.city = cityTextField.text!
        localUserData.state = stateTextField.text!
        localUserData.postalCode = postalTextField.text!
        localUserData.phone = phoneTextField.text!
        
        changePassword.currentPassword = currentPasswordTextField.text!
        changePassword.newPassword = newPasswordTextField.text!
        
    }
    
    func setupPicker() {
        
        // Set up the country picker
        countryPickerView.delegate = self
        countryPickerView.dataSource = self
        countryPickerView.backgroundColor = UIColor.black
        countryPickerView.setValue(UIColor.white, forKeyPath: "textColor")
        countryPickerView.frame.size.height = 0.25 * view.frame.size.height
        
        // Set up the state picker
        statePickerView.delegate = self
        statePickerView.dataSource = self
        statePickerView.backgroundColor = UIColor.black
        statePickerView.setValue(UIColor.white, forKeyPath: "textColor")
        statePickerView.frame.size.height = 0.25 * view.frame.size.height
        
        // Create Done button UIPicker
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(dismissPicker))
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = false
        toolBar.tintColor = .white
        toolBar.barTintColor = UIColor(displayP3Red: 67/255, green: 146/255, blue: 203/255, alpha: 1.0)
        toolBar.sizeToFit()
        toolBar.setItems([doneButton!], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        // Connect picker and toolbar
        countryTextField.inputView = countryPickerView
        countryTextField.inputAccessoryView = toolBar
        stateTextField.inputView = statePickerView
        stateTextField.inputAccessoryView = toolBar
        
        phoneTextField.inputAccessoryView = toolBar
    }
    
    func setCountries() {
        
        countryNames = countryNames.sorted()
        
        countryPickerArray.removeAll()
        for c in countryNames { countryPickerArray.append(c) }
    }
    
    func setStates() {
        
        statePickerArray.removeAll()
        
        switch countryTextField.text {
                
            case "China":
            
                stateTextField.isEnabled = true; stateTextField.placeholder = "Region / Province"
                statePickerArray.removeAll(); for s in chStateNames { statePickerArray.append(s) }
                chStateNames = chStateNames.sorted()
                hasState = true

            case "United States":
            
                stateTextField.isEnabled = true; stateTextField.placeholder = "State"
                statePickerArray.removeAll(); for s in usStateNames { statePickerArray.append(s) }
                usStateNames = usStateNames.sorted()
                hasState = true
  
            default:
            
                stateTextField.isEnabled = false
                stateTextField.placeholder = "Not Applicable"
                hasState = false
        }
    }
    
    func setSelections() {
        
        if countryTextField.text != "" {  for (index,value) in countryPickerArray.enumerated() { if countryTextField.text == value { countrySelected = index; break } } }
    
        if stateTextField.text != "" { for (index,value) in statePickerArray.enumerated() { if stateTextField.text == value { stateSelected = index; break } } }
    }
    
    func clearData() {
        
        guard emailTextField != nil else { return }
            
        emailTextField.text = ""
        newPasswordTextField.text = ""
        currentPasswordTextField.text = ""
        givenNameTextField.text = ""
        familyNameTextField.text = ""
        address1TextField.text = ""
        address2TextField.text = ""
        cityTextField.text = ""
        stateTextField.text = ""
        countryTextField.text = ""
        postalTextField.text = ""
        phoneTextField.text = ""
    }
    
    func cleanup() {
        
        saveButton.setTitle("SAVE", for: .normal)
        activityIndicator.isHidden = true
    }
    
    func showActivityIndicator(_ state: Bool) {
        
        if state { saveButton.setTitle("", for: .normal);  activityIndicator.isHidden = false }
        else { saveButton.setTitle("SAVE", for: .normal);  activityIndicator.isHidden = true }
    }
    
    // MARK: TEXTFIELD DELEGATE PROTOCOL
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == countryTextField || textField == stateTextField { return false }
        else { return true }
    }
    
    // MARK: PICKER DELEGATE PROTOCOL
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView == countryPickerView { return countryPickerArray.count}
        else { return statePickerArray.count }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView == countryPickerView { return countryPickerArray[row] }
        else { return statePickerArray[row] }
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == countryPickerView { countrySelected = row; countryTextField.text = countryPickerArray[row] }
        else { stateSelected = row; stateTextField.text = statePickerArray[row]}
    }
    
    func changePasswordResponse( json: NSDictionary, status: Bool) {
        
        guard webServices!.isErrorFree(json: json, status: status ) else {
            
            showActivityIndicator(false)
            return
        }
        
        _ = VCKeychainServices().writeData(data: changePassword.newPassword, withKey: "password")
     
        changePassword.reinit()
        VCWebServices(parent: self).updateUser(theUserData: localUserData, callBack: updateUserResponse)
    }
    
    func updateUserResponse (json: NSDictionary, status: Bool) {
    
        cleanup()
        
        guard webServices!.isErrorFree(json: json, status: status ) else {
            
            showActivityIndicator(false)
            return
        }
        
        globalData.user.data = localUserData
        globalData.settings = localSwitchData
        globalData.flags.hasState = hasState!
        showActivityIndicator(false)
        
        VCAlertServices(viewController: self).popupMessage(aMessage: "Your profile has been updated")
    }
    
    // MARK: ACTION HANDLERS
    
    @objc func dismissPicker () { view.endEditing(true) }
    
    @objc func keyboardWillShow (notification: NSNotification) {
        
        // Make sure we have a valid notification and if so, get the keyboard size
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        
        // Get the keyboard height
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.size.height
        
        // Reset the content view to area minus keyboard
        contentHeight.constant = scrollHeight! + keyboardHeight - tabBarController!.tabBar.frame.height
    }
    
    @objc func keyboardWillHide (notification: NSNotification) {  contentHeight.constant = scrollHeight! }
    
    @IBAction func endEditing(_ sender: Any) { view.endEditing(true) }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
    
        view.endEditing(true)
        
        getTextFields()
    
        guard localUserData.isComplete(hasState: hasState!) else { VCAlertServices(viewController: self).popupMessage(aMessage: "Please complete all the required fields"); return }
        
        let retval = changePassword.isComplete()
        guard retval.status else { VCAlertServices(viewController: self).popupMessage(aMessage: retval.message); return }
            
        showActivityIndicator(true)
            
        if changePassword.newPassword != "" { VCWebServices(parent: self).changePassword(thePassword: changePassword, callBack: changePasswordResponse) }
        else { VCWebServices(parent: self).updateUser(theUserData: localUserData, callBack: updateUserResponse) }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) { view.endEditing(true); self.tabBarController?.selectedIndex = 0 }
    
    @IBAction func countryEditingBegins(_ sender: Any) {
        
        countryPickerView.reloadAllComponents()
        countryPickerView.selectRow(countrySelected, inComponent: 0, animated: false)
        countryTextField.text = countryPickerArray[countrySelected]
    }
    
    @IBAction func countryEditingEnded(_ sender: Any) {
        
        stateTextField.text = ""
        stateSelected = 0
        setStates()
    }
    
    @IBAction func stateEditingBegins(_ sender: Any) {
        
        guard countryTextField.text != "" else { VCAlertServices(viewController: self).popupMessage(aMessage: "Please enter a country first"); return }
        
        statePickerView.reloadAllComponents()
        statePickerView.selectRow(stateSelected, inComponent: 0, animated: false)
        stateTextField.text = statePickerArray[stateSelected]
    }

    @IBAction func settingsButtonTapped(_ sender: Any) { profileSettingsView.initControls(); profileSettingsView.showView() }
}
