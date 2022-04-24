//
//  VCClinicInformationViewa.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit
import MapKit

class VCClinicInformationView: VCView {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var clinicTitleLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var postalLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var preferredClinicLabel: UILabel!
    @IBOutlet weak var preferredClinicSwitch: UISwitch!
    @IBOutlet weak var vcMembershipLabel: UILabel!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var televetButton: UIButton!
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    // MARK: PROPERTIES
    
    var selectedMapItem: MKMapItem?
    var theClinicRecord: VCClinicRecord?
    weak var delegate: VCClinicMapDelegate?
    var initialPreferenceStatus: Bool?
  
    // MARK: INITIALIZATION
    
    override func initView() {
        
        callButton.roundAllCorners(value: 10.0)
        televetButton.roundAllCorners(value: 10.0)
        directionsButton.roundAllCorners(value: 10.0)
    
        super.initView()
    }
    
    // MARK: METHODS
    
    func setClinicInfo(vcPlacemark: VCPlacemark) {
        
        selectedMapItem = vcPlacemark.mapItem
        
        clinicTitleLabel.text = vcPlacemark.mapItem.name
        streetLabel.text = vcPlacemark.mapItem.placemark.subThoroughfare!
        streetLabel.text! += (" " + vcPlacemark.mapItem.placemark.thoroughfare!)
        
        cityLabel.text = vcPlacemark.mapItem.placemark.locality
        stateLabel.text = vcPlacemark.mapItem.placemark.administrativeArea
        postalLabel.text = vcPlacemark.mapItem.placemark.postalCode
        
        phoneLabel.textColor = .label
        phoneLabel.text = vcPlacemark.mapItem.phoneNumber
        
        preferredClinicSwitch.isHidden = true
        preferredClinicLabel.isHidden = true
      
        vcMembershipLabel.text = "NO"
        vcMembershipLabel.textColor = .systemRed
      
        televetButton.alpha = 0.30
        televetButton.isEnabled = false
    }
    
    func setClinicInfo(clinicRecord: VCClinicRecord ) {
        
        theClinicRecord = clinicRecord
        
        clinicTitleLabel.text = clinicRecord.clinicName
        
        if clinicRecord.clinicAddress.street != "" { streetLabel.textColor = .darkText; streetLabel.text = clinicRecord.clinicAddress.street } else { streetLabel.textColor = .lightGray; streetLabel.text = "No street listed" }
        if clinicRecord.clinicAddress.city != "" { cityLabel.textColor = .darkText; cityLabel.text = clinicRecord.clinicAddress.city } else { cityLabel.textColor = .lightGray; cityLabel.text = "No city listed" }
        if clinicRecord.clinicAddress.state != "" { stateLabel.textColor = .darkText; stateLabel.text = clinicRecord.clinicAddress.state } else {stateLabel.textColor = .lightGray; stateLabel.text = "No state listed"}
        if clinicRecord.clinicAddress.postalCode != "" { postalLabel.textColor = .darkText; postalLabel.text = clinicRecord.clinicAddress.postalCode } else {postalLabel.textColor = .lightGray; postalLabel.text = "No postal code listed"}
       
        if clinicRecord.clinicAddress.phone != "" {
            
            let countryCode = Locale.current.regionCode!.split(separator: "_").last
            let rawPhone = clinicRecord.clinicAddress.phone.removeCharacters(charsToRemove: [" ","(",")","-"])
    
            phoneLabel.textColor = .darkText
            phoneLabel.text = rawPhone.mapToFormat(format: phoneFormats[String(countryCode!)]!)
        }
        
        else {
            
            phoneLabel.textColor = .lightGray;
            phoneLabel.text = "No phone number listed"
        }
        
        vcMembershipLabel.text = "YES"
        vcMembershipLabel.textColor = .systemGreen
        
        if globalData.flags.loginState == .loggedIn {
            
            preferredClinicLabel.isHidden = false
            preferredClinicSwitch.isHidden = false
            
            if clinicRecord.clinicUID == globalData.user.data.preferredClinicUID { preferredClinicSwitch.isOn = true } else {  preferredClinicSwitch.isOn = false  }
            
            televetButton.alpha = 1.0
            televetButton.isEnabled = true
        }
        
        else {
            
            preferredClinicLabel.isHidden = true
            preferredClinicSwitch.isHidden = true
            
            televetButton.alpha = 0.30
            televetButton.isEnabled = false
        }
    }
        
    // MARK: ACTION HANDLERS
    
    @IBAction func preferredClinicSwitchTapped(_ sender: Any) {
        
        let clinicName = clinicTitleLabel.text!
       
        if preferredClinicSwitch.isOn { globalData.user.data.preferredClinicUID = VCRecordGetter().clinicUIDWith(name: clinicName)! }
        else { globalData.user.data.preferredClinicUID = nil }
            
        _ = VCKeychainServices().writeData(data: globalData.user.data.preferredClinicUID!, withKey: "preference")
    }
    
    @IBAction func callButtonTapped(_ sender: Any) {
        
        var phoneNumber: String?
        var callString: String?
        let countryCode = String(Locale.current.regionCode!.split(separator: "_").last!)
        
        if parentController.clinicController.isVCClinic! { phoneNumber = theClinicRecord!.clinicAddress.phone}
        else { phoneNumber = selectedMapItem!.phoneNumber! }
        
        // Trim out symbols
        phoneNumber = phoneNumber!.removeCharacters(charsToRemove: ["-","(",")"," ","+"])
        
        // Further trimming by country style
        switch countryCode {
            
            case "US":
                
                if phoneNumber!.first == "1" {  phoneNumber = String(phoneNumber!.partial(fromIndex: 1, length: phoneNumber!.count-1)) }
        
            case "HK":
            
                if String(phoneNumber!.partial(fromIndex: 0, length: 3)) == "852" { phoneNumber = String(phoneNumber!.partial(fromIndex: 3, length: phoneNumber!.count-3)) }
            
            default:
            
                break
        }
        
        callString = "tel://" + phoneNumber!

        if let url = URL(string: callString!) { if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url, options: [:], completionHandler: nil) } }
        else { NSLog("INVALID CALL URL") }
    }
  
    @IBAction func televetButtonTapped(_ sender: Any) {
        
        // Can only be reached if VC Clinic
        guard globalData.flags.loginState == .loggedIn else { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Please login to create a televet appointment"); return }
       
        parentController.gotoAppointments()
       // parentController.tabBarController!.selectedIndex = parentController.appointmentIndex
        
        globalData.user.data.mapClinicUID = VCRecordGetter().clinicUIDWith(name: theClinicRecord!.clinicName)!
        parentController.appointmentController.plusButtonTapped(self)
    }
    
    @IBAction func directionsButtonTapped(_ sender: Any) { delegate!.getDirections() }
        
    @IBAction func doneButtonTapped(_ sender: Any) {
        
        delegate!.refreshLocations()
        delegate!.clinicsToShowTapped(delegate!.getSegmentControl())
        hideView() }
}

