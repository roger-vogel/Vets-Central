//
//  VCAppointmentViewController.swift
//  Vets-Central
//
//  Appointment scene controller and views
//  Created by Roger Vogel on 5/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//
 
import UIKit
import MapKit

class VCAppointmentViewController: VCViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    // MARK: OUTLETS
    
    @IBOutlet var apptInformationView: VCAppointmentInformationView!
    @IBOutlet var apptWebView: VCAppointmentWebView!
    @IBOutlet var apptNotesView: VCAppointmentNotesView!
    @IBOutlet var apptDocumentView: VCAppointmentDocumentView!
    @IBOutlet var apptSettingsView: VCAppointmentSettingsView!
    @IBOutlet weak var appointmentTable: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var appointmentSelector: UISegmentedControl!
    @IBOutlet weak var settingsButton: UIButton!
    
    // MARK: PROPERTIES
     
    var clinicCounter: Int = 0
    var currentLat: Double?
    var currentLng: Double?
    var clinicsWithinDistance = [VCClinicRecord]()
    var locationManager = CLLocationManager()
    var doctorSpecified = true
    var isCreate: Bool = false
    var isStart: Bool = false
    var viewsAreInitialized = false
    var selectedDoctor: Int?
    var selectedType: Int?
    var locationServicesEnabled: Bool = true
    var clinicLoadWatchTimer = Timer()
    var cumulativeTime: Int?
  
    // MARK: INITIALIZATION AND OVERRIDES
    
    override func viewDidLoad() { super.viewDidLoad()
        
        globalData.apptController = self
        
        setSubViews(subviews: [apptInformationView,apptNotesView,apptDocumentView,apptWebView])
        
        appointmentTable.dataSource = self
        appointmentTable.delegate = self
        appointmentTable.separatorColor = .darkGray
        appointmentTable.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: view.frame.width)
        
        messageLabel.isHidden = true
        locationManager.delegate = self
 
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let selectedColor = UIColor(displayP3Red: 0.0, green: 97/255, blue: 185/255, alpha: 1.0)
        let normalColor = UIColor.white
        
        appointmentSelector.layer.cornerRadius = 3
        appointmentSelector.layer.borderWidth = 1
        appointmentSelector.layer.borderColor = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        
        appointmentSelector.setTitleTextAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : normalColor], for: .highlighted)
        appointmentSelector.setTitleTextAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : normalColor], for: .normal)
        appointmentSelector.setTitleTextAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : selectedColor], for: .selected)
        
        plusButton.alpha = 0.0
    
        initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated)
        
        cumulativeTime = 0
        
        globalData.activeController = self
        globalData.clinicDetailsCancelled = false
      
        // If the profile is not yet completed, redirect there
        guard globalData.user.data.isComplete(hasState: globalData.flags.hasState) else { controllerAlert!.popupMessage(aMessage: "To make an appointment please first complete your profile", callBack: noProfileResponse); return }
    
        // Get authorization to use location services
        if locationServicesEnabled {
            
            currentLat = CLLocationManager().location?.coordinate.latitude
            currentLng = CLLocationManager().location?.coordinate.longitude
        }
        else { locationManager.requestWhenInUseAuthorization() }
        
        if !globalData.flags.clinicDetailsOnBoard {
            
            homeController.vcLogin!.displayProgressAlert(withMessage: "Gathering some clinic information")
            clinicLoadWatchTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(watchForClinicLoad), userInfo: nil, repeats: true )
        }
        
        // Complete the setup (executed from getClinicDetails if that route is taken)
        else { setupAppointmentData() }
    }
    
    override func doLogoutTasks() {
        
        if appointmentTable != nil { appointmentTable.reloadData() }
  
        apptInformationView.hideView()
        apptWebView.hideView()
        apptNotesView.hideView()
        apptDocumentView.hideView()
        apptSettingsView.hideView()
        
        if apptDocumentView.documentManager != nil { apptDocumentView.documentManager!.theMetadata.removeAll() }
    }
    
    override func onClockChange() {
        
        reloadAppointmentTable()
        
        if globalData.settings.clock == .c12 { apptInformationView.datePicker.locale = Locale(identifier: "en_US") }
        else { apptInformationView.datePicker.locale = Locale(identifier: "en_GB") }
    }
    
    // MARK: METHODS
    
    func initViews() {
        
        view.addSubview(apptInformationView)
        apptInformationView.initView()
        
        view.addSubview(apptNotesView)
        apptNotesView.initView()
        
        view.addSubview(apptDocumentView)
        apptDocumentView.initView()
        
        view.addSubview(apptSettingsView)
        apptSettingsView.initView()
    
        view.addSubview(apptWebView)
        apptWebView.initView()
     
        viewsAreInitialized = true
    }
    
    func setupAppointmentData() {
        
        if currentLat != nil && currentLng != nil { getClinicsWithinDistance(atDistance: 50.0) }
        else { getClinicsWithinDistance(atDistance: 20000) }
        
        apptInformationView.refreshClockMode()
        apptInformationView.setClinicDoctors()
        
        reloadAppointmentTable()
        apptDocumentView.documentTableView.reloadData()
        
        if globalData.user.data.mapClinicUID != nil { isCreate = true; plusButtonTapped(self) }
    }
    
    func preloadAppointmentForm (apptUID: Int, start: Bool) {
        
        isCreate = false 
        isStart = start
        selectedAppointment = VCRecordGetter().appointmentIndexWith(uid: apptUID)
        
        if !viewsAreInitialized { initViews() }
        
        let theAppointment = globalData.user.currentAppointments[selectedAppointment!]
        selectedPet = VCRecordGetter().petIndexWith(uid: theAppointment.petUID!)
        
        apptInformationView.setAppointmentButtons()
        apptInformationView.setAppointmentInfo()
        apptInformationView.showView()
    }
    
    func getAllClinics() {
        
        clinicsWithinDistance.removeAll()
        clinicsWithinDistance = globalData.clinics
    }
    
    func getClinicsWithinDistance(atDistance: Double) {
        
        clinicsWithinDistance.removeAll()
        
        if currentLat == nil { currentLat = 0 }
        if currentLng == nil { currentLng = 0 }
        
        for c in globalData.clinics {
            
            let distance = VCDistanceCalculator().distanceRadius(clinicLat: c.clinicLat, clinicLng: c.clinicLng, compareLat: currentLat!, compareLng: currentLng!)
            if distance <= atDistance { clinicsWithinDistance.append(c) }
        }
    }
    
    func reloadAppointmentTable() {
        
        guard appointmentTable != nil else { return }
        
        if appointmentSelector.selectedSegmentIndex == 0 && self.plusButton.alpha == 0.0 { plusButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { self.plusButton.isHidden = false } ) }
        else if appointmentSelector.selectedSegmentIndex == 1 && self.plusButton.alpha == 1.0 { plusButton.changeDisplayState(toState: .hidden, withAlpha: 0.0, forDuration: 0.25, atCompletion: { self.plusButton.isHidden = true } ) }
        
        if globalData.flags.loginState == .loggedIn {
            
            // Set message
            if globalData.user.pets.count == 0 {
                
                plusButton.isHidden = true
                appointmentTable.isHidden = true
                messageLabel.text = "You have no pets on file yet"
                messageLabel.isHidden = false
            }
            
            else if globalData.user.currentAppointments.count == 0 && appointmentSelector.selectedSegmentIndex == 0 {
                
                plusButton.isHidden = false
                appointmentTable.isHidden = true
                messageLabel.isHidden = false
                messageLabel.text = "You have no appointments on file"
            }
            
            else if ( globalData.user.pastAppointments.count == 0 && appointmentSelector.selectedSegmentIndex == 1) {
                
                plusButton.isHidden = false
                appointmentTable.isHidden = true
                messageLabel.isHidden = false
                messageLabel.text = "You have no past appointments on file"
            }
            
            else {
                
                appointmentTable.isHidden = false
                plusButton.isHidden = false
                messageLabel.isHidden = true
                appointmentTable.reloadData()
            }
        }
        
        else {
            
            plusButton.isHidden = true
            appointmentTable.isHidden = true
            messageLabel.text = "Please login to make an appointment"
            messageLabel.isHidden = false
        }
    }
    
    func confirmCancellation() {
        
        if appointmentSelector.selectedSegmentIndex == 0 {
            
            controllerAlert!.popupYesNo(aMessage: "Are you sure you want to cancel this appointment?", aStyle: [.destructive,.default]) { choice in
                
                if choice == 0 {
                    
                    self.controllerAlert!.popupPendingMsg(aMessage: "Cancelling appointment")
                    VCWebServices(parent: self).cancelAppointment(apptUID: globalData.user.currentAppointments[self.selectedAppointment!].apptUID!, callBack: self.cancelAppointmentResponse)
                    
                }
            }
        }
        
        else {
            
            controllerAlert!.popupPendingMsg(aMessage: "Deleting appointment")
            VCWebServices(parent: self).cancelAppointment(apptUID: globalData.user.pastAppointments[self.selectedAppointment!].apptUID!, callBack: self.cancelAppointmentResponse) }
    }
    
    // MARK: TABLEVIEW DELEGATE PROTOCOL
    
    // Report number of sections
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    // Report the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if globalData.flags.clinicDetailsOnBoard {
            
            if appointmentSelector.selectedSegmentIndex == 0 { return globalData.user.currentAppointments.count }
            else{ return globalData.user.pastAppointments.count }
            
        }
        
        else { return 0 }
    }
        
    // If asked for row height...
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 128 }
            
    // Capture highlight
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { return true }
    
    // Dequeue the cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var petImage: UIImage?
        let apptData: VCAppointmentRecord?
        
        if appointmentSelector.selectedSegmentIndex == 0 { apptData = globalData.user.currentAppointments[indexPath.row] }
        else { apptData = globalData.user.pastAppointments[indexPath.row] }
        
        let petData = VCRecordGetter().petRecordWith(uid: apptData!.petUID!)
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Appointments", for: indexPath) as! VCAppointmentTableViewCell
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Get the pet image
        if petData!.hasImage { petImage = globalData.user.petImages[petData!.petUID!] }
        else { petImage = UIImage(named: "image.nopic.png") }
        
        // Fill in the pet pic, name, and appt status
        cell.petImageView.image = petImage
        cell.petNameButton.setTitle(petData!.petName, for: .normal)
        cell.appointmentTypeLabel.text = apptData!.apptStatus
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Set the background color
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white
        cell.selectedBackgroundView = backgroundView
        
        // Get the clinic name and doctor
        var theDoctorName: String?
        var theClinicName = apptData!.clinicName
        let theClinicRecord = VCRecordGetter().clinicRecordWith(uid: apptData!.clinicUID!)
      
        if theClinicRecord != nil && apptData!.doctorUID != nil {
            
            let doctor = VCRecordGetter().doctorRecordWith(clinic: theClinicRecord!, theDoctorUID: apptData!.doctorUID!)
            if doctor != nil { theDoctorName = "Dr. " + doctor!.givenName + " " + doctor!.familyName }
            else { theDoctorName = "No Doctor Selected" }
            
        } else { theDoctorName = "No Doctor Selected"; doctorSpecified = false }
        
        cell.clinicNameLabel.text = theClinicName
        cell.doctorNameLabel.text = theDoctorName!
        
        // Fill cell with content information
        let contentFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let clinicNameSize = theClinicName.width(withFont: UIFont.systemFont(ofSize: 14, weight: .semibold))
        let doctorNameSize = theDoctorName!.width(withFont: UIFont.systemFont(ofSize: 14, weight: .semibold))
        let ellipsisSize = " ...".width(withFont: contentFont)
        
        if clinicNameSize > 200 {
            
            while theClinicName.width(withFont: contentFont) > 200 - ellipsisSize { theClinicName.removeLast() }
            cell.clinicNameLabel.text = theClinicName + " ..."
        }
    
        if doctorNameSize > 200 {
            
            while theDoctorName!.width(withFont: contentFont) > 200 - ellipsisSize {theDoctorName!.removeLast() }
            cell.doctorNameLabel.text = theDoctorName! + " ..."
        }
        
        // Fill in date and time
        cell.appointmentDateLabel.text = apptData!.startDate.dateString
        cell.appointmentTimeLabel.text = apptData!.startDate.timeString + " to " + apptData!.endDate.timeString
        
        // Return the cell
        return cell
    }
    
    // Capture selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        isCreate = false
        selectedAppointment = indexPath.row
    
        var theAppointment: VCAppointmentRecord?
        
        if appointmentSelector.selectedSegmentIndex == 0 {
            
            theAppointment = globalData.user.currentAppointments[selectedAppointment!]
            globalData.openedAppointment = theAppointment!.apptUID!
            
        } else { theAppointment = globalData.user.pastAppointments[selectedAppointment!] }
        
        selectedPet = VCRecordGetter().petIndexWith(uid: theAppointment!.petUID!)
        
        apptInformationView.setAppointmentInfo()
        apptInformationView.documentLabel.alpha = 1.0
        apptInformationView.documentButton.alpha = 1.0
        apptInformationView.showView()
    }
    
    // Delete button title
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? { return "CANCEL" }
    
    // Editing style
    func tableView(_ tableView: UITableView,editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        if appointmentSelector.selectedSegmentIndex == 0 { return .delete }
        else { return .none }
    }
       
    // Delete appointment
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        guard tableView == appointmentTable else { return }
        
        selectedAppointment = indexPath.row
        if editingStyle == .delete { confirmCancellation() }
    }
    
    // MARK: LOCATION SERVICES
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse { locationServicesEnabled = true }
        else { locationServicesEnabled = false }
    }
    
    // MARK: CALL BACKS
    
    func cancelAppointmentResponse(json: NSDictionary, status: Bool) {
        
        controllerAlert!.dismiss()
        guard self.webServices!.isErrorFree(json: json, status: status) else { return }
        
        if appointmentSelector.selectedSegmentIndex == 0 { globalData.user.currentAppointments.remove(at: selectedAppointment!) }
        else { globalData.user.pastAppointments.remove(at: selectedAppointment!) }
        
        selectedAppointment = nil
        homeController.setBadges()
        
        if globalData.user.currentAppointments.count == 0 { messageLabel.isHidden = false }
        reloadAppointmentTable()
        
        homeController.setHomePageUIElements()
    }
    
    func exitAppointment() { return }
    
    func bookAppointment() {
        
        isCreate = true
      
        apptInformationView.clearView()
        apptInformationView.setForNewAppointment()
       
        apptInformationView.showView()
        appointmentSelector.selectedSegmentIndex = 0
    }
    
    func noProfileResponse () { gotoProfile() }
    
    // MARK: CLINIC DETAIL LOAD WATCHER
    
    @objc func watchForClinicLoad() {
        
        cumulativeTime! += 1
        
        if globalData.flags.clinicDetailsOnBoard {
            
            self.homeController.vcLogin!.dismissProgressAlert()
            self.clinicLoadWatchTimer.invalidate()
            self.setupAppointmentData()
            
        } else {
            
            if cumulativeTime! > 30 {
                
                self.homeController.vcLogin!.dismissProgressAlert()
                self.clinicLoadWatchTimer.invalidate()
                
                DispatchQueue.main.async {
                    
                    self.controllerAlert!.popupMessage(aTitle: "Download Error", aMessage: "There seems to be a problem downloading the clinic details. The app will retry the next time you navigate to this tab.") { () in self.gotoHome()}
                }
            }
        }
    }

    // MARK: ACTION HANDLERS
    
    @IBAction func selectorTapped(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 { apptInformationView.currentApptMessageLabel.isHidden = false }
        else { apptInformationView.currentApptMessageLabel.isHidden = true }
      
        reloadAppointmentTable()
        
    }
    
    @IBAction func settingsButtonTapped(_ sender: Any) { apptSettingsView.initControls(); apptSettingsView.showView() }
        
    @IBAction func plusButtonTapped(_ sender: Any) {
     
        apptInformationView.localAppointmentRecord.reinit()
        apptInformationView.documentLabel.alpha = 0.20
        apptInformationView.documentButton.alpha = 0.20
     
        if globalData.flags.isFirstAppointmentRequest {
            
            controllerAlert!.popupWithCustomButtons(
                
                aTitle: "IMPORTANT", aMessage: "Televet consultations can only be accepted if the veterinarian has already seen your pet for this condition", buttonTitles: ["OK","CANCEL"], theStyle: [.default,.destructive]) { choice in
                
                if choice == 0 { self.bookAppointment() }
                else { self.exitAppointment() }
            }
           
            globalData.flags.isFirstAppointmentRequest = false
        }
        
        else if globalData.user.pets.count == 0 { controllerAlert!.popupOK(aMessage: "You don't have any pets on file yet") }
        
        else { bookAppointment() }
    }
}
