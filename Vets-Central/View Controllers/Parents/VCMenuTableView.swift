//
//  VCMenuTableView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/14/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCMenuTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    var theParent: VCViewController?
    var theOpenButton: UIButton?
    var theCloseButton: UIButton?
    var theTrailingConstraint: NSLayoutConstraint?
    
    func setupMenu (parent: VCViewController, openButton: UIButton, closeButton: UIButton, trailingConstraint: NSLayoutConstraint) {
        
        theParent = parent
        theOpenButton = openButton
        theCloseButton = closeButton
        theTrailingConstraint = trailingConstraint
    }
    
    func initMenuState() {
        
        isHidden = true
        delegate = self
        dataSource = self
        separatorColor = .lightGray
        contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: theParent!.view.frame.width)
    
        theTrailingConstraint!.constant = frame.width
        theCloseButton!.isHidden = true
      
        frame.size.width = 1
        reloadData()
    }

    func setMenuState () {
        
        if isHidden {
        
            isHidden = false
            UIView.animate(withDuration: 0.25, animations: { self.theTrailingConstraint!.constant = 0;  self.frame.size.width = self.theParent!.view.frame.width  }, completion: {finished in self.theCloseButton!.isEnabled = true; self.theCloseButton!.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: {self.theOpenButton!.isHidden = true })})
        }
        
        else {
            
            theCloseButton!.isEnabled = false
            theCloseButton!.isHidden = true
       
            UIView.animate(withDuration: 0.25 , animations: { self.theTrailingConstraint!.constant = self.theParent!.view.frame.size.width; self.frame.size.width = 0 }, completion: { finished in self.isHidden = true; self.theOpenButton!.isHidden = false })
        }
    }
    
    // MARK: TABLEVIEW PROTOCOL
    
    // Report number of sections
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    // Report the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 7 }
        
    // If asked for row height...
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 60 }
    
    // Capture highlight
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { return true }
    
    // Dequeue the cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Create the cell
        let cell = (tableView.dequeueReusableCell(withIdentifier: "Settings", for: indexPath)) as! VCMenuTableCell
        cell.cellNumber = indexPath.row
        cell.homeViewController = theParent!.homeController()
       
        if indexPath.row == MenuItem.alert.rawValue {cell.showStepper() } else { cell.showSwitch() }
       
        if isHidden { cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
        else { cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: frame.size.width)}
        
        cell.setMenuItems()
     
        // Return the cell
        return cell
    }
}

class VCMenuTableCell: UITableViewCell {
    
    // MARK: OUTLETS
    
    var theSettingsLabel: UILabel?
    var theSettingsSwitch: UISwitch?
    var theSettingsStepper: UIStepper?
    var theLogoutButton: UIButton?
    
    // MARK: PROPERTIES
    
    var cellNumber: Int?
    var homeViewController: VCHomeViewController?
    
    // MARK: INITIALIZATION
  
    func initTableCell() {
        
        guard theSettingsStepper != nil && theSettingsSwitch != nil && theLogoutButton != nil else { return }
        
        theSettingsStepper!.value = 15
        theSettingsStepper!.minimumValue = 5
        theSettingsStepper!.maximumValue = 30
        theSettingsStepper!.stepValue = 5
        
        theSettingsSwitch!.layer.cornerRadius = 15
        theLogoutButton!.setCornerRadius(value: 5)
        theLogoutButton!.setBorder(width: 1.0, color: UIColor.lightGray.cgColor)
    }
    
    // MARK: METHODS
    
    func setMenuItems() {
        
        switch MenuItem(rawValue: cellNumber!) {

            case .text:
                
                theSettingsLabel!.alpha = 1.0
                theSettingsSwitch!.alpha = 1.0
                theSettingsStepper!.alpha = 1.0
                theLogoutButton!.isHidden = true
                
                theSettingsSwitch!.isOn = globalData.settings.textContact
                theSettingsLabel!.text = "Contact me by text"
                
            case .email:
                
                theSettingsLabel!.alpha = 1.0
                theSettingsSwitch!.alpha = 1.0
                theSettingsStepper!.alpha = 1.0
                theLogoutButton!.isHidden = true
                
                theSettingsSwitch!.isOn = globalData.settings.emailContact
                theSettingsLabel!.text = "Contact me by email"
                
            case .map:
                
                theSettingsLabel!.alpha = 1.0
                theSettingsSwitch!.alpha = 1.0
                theSettingsStepper!.alpha = 1.0
                theLogoutButton!.isHidden = true
                
                theSettingsSwitch!.isOn = globalData.settings.onlyMapVC
                theSettingsLabel!.text = "Show only VC clinics on map"
                
            case .auto:
                
                theSettingsLabel!.alpha = 1.0
                theSettingsSwitch!.alpha = 1.0
                theSettingsStepper!.alpha = 1.0
                theLogoutButton!.isHidden = true
                
                if globalData.settings.rememberMeID != "" { theSettingsSwitch!.isOn = true } else { theSettingsSwitch!.isOn = false }
                theSettingsLabel!.text = "Remember me"
                
            case .clock:
                
                theSettingsLabel!.alpha = 1.0
                theSettingsSwitch!.alpha = 1.0
                theSettingsStepper!.alpha = 1.0
                theLogoutButton!.isHidden = true
                
                if globalData.settings.clock == ClockMode.c24 { theSettingsSwitch!.isOn = true } else { theSettingsSwitch!.isOn = false }
                theSettingsLabel!.text = "Use 24 hour clock"
                
            case .alert:
                
                theSettingsLabel!.alpha = 1.0
                theSettingsSwitch!.alpha = 1.0
                theSettingsStepper!.alpha = 1.0
                theLogoutButton!.isHidden = true
                
                theSettingsStepper!.value = Double(globalData.settings.alertMinutes)
                theSettingsLabel!.text = "Alert me " + String(globalData.settings.alertMinutes) + " min before appt"
                
            case .logout:
            
                theSettingsLabel!.alpha = 0.0
                theSettingsSwitch!.alpha = 0.0
                theSettingsStepper!.alpha = 0.0
                theLogoutButton!.isHidden = false
        
            default: break
        }
    }
    
    func showSwitch() { theSettingsStepper!.isHidden = true; theSettingsSwitch!.isHidden = false }
    
    func showStepper() { theSettingsStepper!.isHidden = false; theSettingsSwitch!.isHidden = true }
    
    // MARK: CALL BACKS
    
    func userPreferencesResponse (json: NSDictionary, webServiceSuccess: Bool) {
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
        guard success.webServiceSuccess else { VCAlertServices(viewController: globalData.activeController!).popupOK(aTitle: "", aMessage: success.errorString); return }
       
    }
    
    // MARK: ACTION HANDLERS
  
    func onLogoutButton() {
        
        homeViewController!.menuTableView.setMenuState()
        homeViewController!.loginPageButtonTapped(self)
    }
    
    func onSwitch(sender: UISwitch) {
        
        let state : Bool = sender.isOn
        
        switch MenuItem(rawValue: cellNumber!) {
        
            case .text:
                
                globalData.settings.textContact = state
                _ = VCKeychainServices(aServiceName: "vetscentral").writeData(data: state, withKey: globalData.user.data.userEmail + ".text")
                VCWebServices().setUserContactPreferences(callBack: userPreferencesResponse)
          
            case .email:
                
                globalData.settings.emailContact = state
                _ = VCKeychainServices(aServiceName: "vetscentral").writeData(data: state, withKey: globalData.user.data.userEmail + ".email")
                VCWebServices().setUserContactPreferences(callBack: userPreferencesResponse)
                
            case .map:
                
                globalData.settings.onlyMapVC = state
                _ = VCKeychainServices(aServiceName: "vetscentral").writeData(data: state, withKey: globalData.user.data.userEmail + ".map")
                
            case .auto:
                
                if state { globalData.settings.rememberMeID = globalData.user.data.userEmail }
                else { globalData.settings.rememberMeID = "" }
                
                _ = VCKeychainServices(aServiceName: "vetscentral").writeData(data: globalData.settings.rememberMeID, withKey: globalData.user.data.userEmail + ".auto")
                _ = VCKeychainServices(aServiceName: "vetscentral").writeData(data: globalData.settings.rememberMeID, withKey: "auto")
               
            case .clock:
                
                if state { globalData.settings.clock = .c24 }
                else { globalData.settings.clock = .c12 }
                
                _ = VCKeychainServices(aServiceName: "vetscentral").writeData(data: globalData.settings.clock.rawValue, withKey: globalData.user.data.userEmail + ".clock")
                
            default: break
        }
    }
    
    func onStepper() {
        
        theSettingsLabel!.text = "Alert me " + String(Int(theSettingsStepper!.value)) + " min before appt"
        globalData.settings.alertMinutes = Int(theSettingsStepper!.value)
        _ = VCKeychainServices(aServiceName: "vetscentral").writeData(data: Int(theSettingsStepper!.value), withKey: globalData.user.data.userEmail + ".alert")
    }
}
