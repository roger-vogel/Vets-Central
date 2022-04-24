//
//  VCSettingsView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/18/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//
 
import UIKit

class VCSettingsView: VCView {

    // MARK: OUTLET PROXIES
    
    var theVersionLevel: UILabel?
    var theTimeStepperLabel: UILabel?
    var theAlertByTextSwitch: UISwitch?
    var theAlertByEmailSwitch: UISwitch?
    var theShowOnlyVCSwitch: UISwitch?
    var theRememberMeSwitch: UISwitch?
    var theClockChoiceSwitch: UISwitch?
    var theRecordCountSwitch: UISwitch?
    var theAlertTimeStepper: UIStepper?
    var theLogoutButton: UIButton?
    
    // MARK: INTIALIZATION AND OVERRIDES
    
    override func initView() {
        
        theAlertTimeStepper!.value = 15
        theAlertTimeStepper!.minimumValue = 5
        theAlertTimeStepper!.maximumValue = 30
        theAlertTimeStepper!.stepValue = 5
        
        theLogoutButton!.roundAllCorners(value: 5)
       
        super.initView()
    }
    
    // MARK: METHODS
    
    func initControls () {
        
        theVersionLevel!.text = "Version: " + globalData.settings.appVersion
        theAlertByTextSwitch!.isOn = globalData.settings.textContact
        theAlertByEmailSwitch!.isOn = globalData.settings.emailContact
        theShowOnlyVCSwitch!.isOn = globalData.settings.onlyMapVC
        theAlertTimeStepper!.value = Double(globalData.settings.alertMinutes)
        theRememberMeSwitch!.isOn = globalData.settings.rememberMe
        theRecordCountSwitch!.isOn = globalData.settings.recordCountsAreHidden
        
        theTimeStepperLabel!.text = "Alert me " + String(Int(theAlertTimeStepper!.value)) + " min before appt"
        if globalData.settings.clock == ClockMode.c24 { theClockChoiceSwitch!.isOn = true } else { theClockChoiceSwitch!.isOn = false }
    }

    func onSwitch(selection: UISwitch) {
    
        let state : Bool = selection.isOn
        
        switch selection.tag {
        
            case 0:
                
                globalData.settings.textContact = state
                _ = VCKeychainServices().writeData(data: state, withKey: "text")
            
                webServices!.setUserContactPreferences { json, status in guard self.webServices!.isErrorFree(json: json, status: status) else { return } }
      
            case 1:
                
                globalData.settings.emailContact = state
                _ = VCKeychainServices().writeData(data: state, withKey: "email")
            
                webServices!.setUserContactPreferences { json, status in guard self.webServices!.isErrorFree(json: json, status: status) else { return } }
                
            case 2:
                
                globalData.settings.onlyMapVC = state
                _ = VCKeychainServices().writeData(data: state, withKey: "map")
                
                if parentController.clinicController.mapView != nil {
                   
                    if parentController.clinicController.mapView != nil {
                        
                        parentController.clinicController.mapView.clearAnnotations()
                        parentController.clinicController.mapView.showVCClinics()
                    }
                    
                    if !state {
                        
                        parentController.clinicController.mapView.findOtherClinics()
                        parentController.clinicController.clinicsToShow.selectedSegmentIndex = 1
                    }
                        
                    else { parentController.clinicController.clinicsToShow.selectedSegmentIndex = 0 }
                }

            case 3:
                
                globalData.settings.rememberMe = state
                _ = VCKeychainServices().writeData(data: globalData.settings.rememberMe, withKey: "auto")
                            
            case 4:
                
                if state { globalData.settings.clock = .c24 }
                else { globalData.settings.clock = .c12 }
                
                _ = VCKeychainServices().writeData(data: globalData.settings.clock.rawValue, withKey: "clock")
                
                parentController.homeController.onClockChange()
                
            case 5:
            
                globalData.settings.recordCountsAreHidden = state
                _ = VCKeychainServices().writeData(data: state, withKey: "counts")
                parentController.homeController.setBadges()
            
            default: break

        }
    }
    
    func onStepper () {
        
        theTimeStepperLabel!.text = "Alert me " + String(Int(theAlertTimeStepper!.value)) + " min before appt"
        globalData.settings.alertMinutes = Int(theAlertTimeStepper!.value)
        _ = VCKeychainServices().writeData(data: Int(theAlertTimeStepper!.value), withKey: "alert")
        
    }
    
    func onLogout() {
        
        hideView()
        parentController.gotoHome()
        parentController.homeController.loginPageButtonTapped(self)
    }
}
 

