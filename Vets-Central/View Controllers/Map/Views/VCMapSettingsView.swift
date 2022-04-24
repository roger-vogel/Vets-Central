//
//  VCMapSettingsView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/18/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCMapSettingsView: VCSettingsView {

    @IBOutlet weak var versionLevel: UILabel!
    @IBOutlet weak var stepperLabel: UILabel!
    @IBOutlet weak var alertByTextSwitch: UISwitch!
    @IBOutlet weak var alertByEmailSwitch: UISwitch!
    @IBOutlet weak var showOnlyVCSwitch: UISwitch!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    @IBOutlet weak var clockChoiceSwitch: UISwitch!
    @IBOutlet weak var recordCountSwitch: UISwitch!
    @IBOutlet weak var alertTimeStepper: UIStepper!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func initView() {
        
        theVersionLevel = versionLevel
        theTimeStepperLabel = stepperLabel
        theAlertByTextSwitch = alertByTextSwitch
        theAlertByEmailSwitch = alertByEmailSwitch
        theShowOnlyVCSwitch = showOnlyVCSwitch
        theRememberMeSwitch = rememberMeSwitch
        theClockChoiceSwitch = clockChoiceSwitch
        theRecordCountSwitch = recordCountSwitch
        theAlertTimeStepper = alertTimeStepper
        theLogoutButton = logoutButton
        
        super.initView()
    }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func returnButtonTapped(_ sender: Any) { hideView() }
    
    @IBAction func settingsSwitchTapped(_ sender: UISwitch) { onSwitch(selection: sender) }
    
    @IBAction func stepperValueChanged(_ sender: Any) { onStepper() }
    
    @IBAction func logoutButtonTapped(_ sender: Any) { onLogout() }

}


