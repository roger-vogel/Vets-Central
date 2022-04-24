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
import OpenTok

class VCApptViewController: VCViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    // MARK: OUTLETS
    
    @IBOutlet var apptInformationView: VCApptInformationView!
    @IBOutlet var apptWebView: VCApptWebView!
    @IBOutlet var apptNotesView: VCApptNotesView!
    @IBOutlet var apptDocumentView: VCApptDocumentView!
    @IBOutlet var apptSettingsView: VCApptSettingsView!
    
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
    var isCreate: Bool?
    var isStart: Bool = false
    var viewsAreInitialized = false
    var selectedAppointment: Int = -1
    var selectedDoctor: Int = -1
    var selectedType: Int = -1
    var selectedPet: Int = 0
    var profileTab = Int(VCTab.profile.rawValue)
    var homeTab = Int(VCTab.login.rawValue)
    var petTab = Int(VCTab.pets.rawValue)
    var alert: VCAlertServices?
    var locationServicesEnabled: Bool = true
    
    // MARK: INITIALIZATION AND OVERRIDES
    
    override func viewDidLoad() { super.viewDidLoad()
        
        setSubViews(subviews: [apptInformationView,apptNotesView,apptDocumentView,apptWebView])
        
        appointmentTable.dataSource = self
        appointmentTable.delegate = self
        appointmentTable.separatorColor = .darkGray
        appointmentTable.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: view.frame.width)
        
        messageLabel.isHidden = true
        locationManager.delegate = self
        alert = VCAlertServices(viewController: self)
        
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let selectedColor = UIColor(displayP3Red: 0.0, green: 97/255, blue: 185/255, alpha: 1.0)
        let normalColor = UIColor.white
        
        appointmentSelector.layer.cornerRadius = 3
        appointmentSelector.layer.borderWidth = 1
        appointmentSelector.layer.borderColor = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        
        appointmentSelector.setTitleTextAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : normalColor], for: .highlighted)
        appointmentSelector.setTitleTextAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : normalColor], for: .normal)
        appointmentSelector.setTitleTextAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : selectedColor], for: .selected)
        
        initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated)
        
        globalData.activeController = self
      
        // If the profile is not yet completed, redirect there
        guard globalData.user.data.isComplete() else { VCAlertServices(viewController: self).popupOK(aTitle: "", aMessage: "To make an appointment please first complete your profile", callBack: noProfileResponse); return }
    
        // Get authorization to use location services
        if locationServicesEnabled {
            
            currentLat = CLLocationManager().location?.coordinate.latitude
            currentLng = CLLocationManager().location?.coordinate.longitude
        }
        else { locationManager.requestWhenInUseAuthorization() }
        
        // If clinic details have not been loaded, do so now
        if !globalData.flags.clinicDetailsOnBoard {
            
            homeController().stopTimers()
            alert!.popupPendingMsg(aTitle: "", aMessage: "Just a moment, we need to gather some clinic information the first time you access your appointments")
            
            // If pet photos have not been loaded, load pet photos first (calls clinic details upon completion)
            if !globalData.flags.petPhotosOnBoard {
                
                petController().isCallFromAppointments = true
                petController().getPetPhotos()
            }
            else { getClinicDetails() }
        }
        
        // Complete the setup (executed from getClinicDetails if that route is taken)
        else { setupAppointmentData() }
    }
    
    override func doLogoutTasks() {
        
        apptInformationView.hideView()
        apptWebView.hideView()
        apptNotesView.hideView()
        apptDocumentView.hideView()
        apptSettingsView.hideView()
    
        doctorSpecified = true
        isCreate = false
        isStart = false
        selectedAppointment = -1
        selectedDoctor = -1
        selectedPet = -1
        apptDocumentView.docMetadata.removeAll()
    }
    
    override func updateClockPreference() { reloadAppointmentTable() }
    
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
    
    func getDetailedData () {
        
        // If pet photos have not been loaded, load pet photos first (calls clinic details upon completion)
        if !globalData.flags.petPhotosOnBoard {
            
            petController().isCallFromAppointments = true
            petController().getPetPhotos()
        }
        else { getClinicDetails() }
    }
    
    func setupAppointmentData() {
        
        if currentLat != nil && currentLng != nil { getClinicList(atDistance: 50.0) }
        else { getClinicList(atDistance: 20000) }
        
        apptInformationView.refreshClockMode()
        apptInformationView.setClinicDoctors()
        
        reloadAppointmentTable()
        apptDocumentView.documentTableView.reloadData()
      
//        if globalData.user.currentAppointments.count == 0 { messageLabel.isHidden = false } else { messageLabel.isHidden = true }
        
        if globalData.user.data.mapClinicUID != "" { isCreate = true; plusButtonTapped(self) }
    }
    
    func getClinicDetails() {
        
        // Loop to get schedule and vets for each clinic then exit
        if clinicCounter < globalData.clinics.count { VCWebServices(parent: self).getClinicScheduleAndVets(theClinicRecord: globalData.clinics[clinicCounter], callBack: clinicDetailsLoadResponse) }
        
        else { clinicCounter = 0; getClinicServices() }
    }
    
    func getClinicServices() {
        
        // Loop to get services type and then exit
        if clinicCounter < globalData.clinics.count { VCWebServices(parent: self).getClinicServiceTypes(theClinicRecord: globalData.clinics[clinicCounter], callBack: clinicServicesLoadResponse) }
      
        else {
            
            alert!.dismiss()
            globalData.flags.clinicDetailsOnBoard = true
            homeController().startTimers()
            setupAppointmentData()
        }
    }
  
    func preloadAppointmentForm (apptUID: String, start: Bool) {
        
        isCreate = false 
        isStart = start
        selectedAppointment = VCRecordGetter().appointmentIndexWith(uid: apptUID)
        
        if !viewsAreInitialized { initViews() }
        
        let theAppointment = globalData.user.currentAppointments[selectedAppointment]
        selectedPet = VCRecordGetter().petIndexWith(uid: theAppointment.petUID)
        
        apptInformationView.setAppointmentButtons()
        apptInformationView.setAppointmentInfo()
        apptInformationView.showView()
    }
    
    func getClinicList(atDistance: Double) {
        
        clinicsWithinDistance.removeAll()
        
        if currentLat == nil { currentLat = 0 }
        if currentLng == nil { currentLng = 0 }
        
        for c in globalData.clinics {
            
            let deltaLat = (currentLat! - c.clinicLat) * 111
            let deltaLng = (currentLng! - c.clinicLng) * 111
            let distance = pow((pow(deltaLat,2.0)+pow(deltaLng,2.0)),0.5)
            
            if distance <= atDistance { clinicsWithinDistance.append(c) }
        }
    }
    
    func reloadAppointmentTable() {
    
        guard appointmentTable != nil else { return }
        
        if globalData.flags.loginState == .loggedIn {
        
            // Set message
            if globalData.user.pets.count == 0 {
                
                plusButton.isHidden = true
                appointmentTable.isHidden = true
                messageLabel.text = "You have no pets on file yet"
                messageLabel.isHidden = false
            }
            
            else if ( globalData.user.currentAppointments.count == 0 && appointmentSelector.selectedSegmentIndex == 0) || (globalData.user.pastAppointments.count == 0 && appointmentSelector.selectedSegmentIndex == 1) {
                
                plusButton.isHidden = false
                appointmentTable.isHidden = true
                
                messageLabel.isHidden = false
                
                if appointmentSelector.selectedSegmentIndex == 0 { messageLabel.text = "You have no appointments on file" }
                else { messageLabel.text = "You have no past appointments on file" }
            }
            
            else {
                
                plusButton.isHidden = false
                appointmentTable.isHidden = false
                messageLabel.isHidden = true
            }
            
            // Enable plus button
            if plusButton.isHidden == false { plusButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { return }) }
        }
            
        else {
            
            plusButton.isHidden = true
            appointmentTable.isHidden = true
            messageLabel.text = "Please login to make an appointment"
            messageLabel.isHidden = false
        }
        
        appointmentTable.reloadData()
    }
    
    func confirmCancellation() {
        
        if appointmentSelector.selectedSegmentIndex == 0 {
            
            VCAlertServices(viewController: self).popupYesNo(aTitle: "", aMessage: "Are you sure you want to cancel this appointment?") { (response) in
                
                if response {
                    
                    self.alert?.popupPendingMsg(aTitle: "", aMessage: "Cancelling appointment")
                    VCWebServices(parent: self).cancelAppointment(apptUID: globalData.user.currentAppointments[self.selectedAppointment].apptUID, callBack: self.cancelAppointmentResponse)
                    
                }
            }
        }
        
        else {
            
            alert?.popupPendingMsg(aTitle: "", aMessage: "Deleting appointment")
            VCWebServices(parent: self).cancelAppointment(apptUID: globalData.user.pastAppointments[self.selectedAppointment].apptUID, callBack: self.cancelAppointmentResponse) }
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
        
        var petData = VCPetRecord()
        VCRecordGetter().petRecordWith(uid: apptData!.petUID, putInPetRecord: &petData)
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Appointments", for: indexPath) as! VCApptTableViewCell
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Get the pet image
        if petData.hasImage { petImage = globalData.user.petImages[petData.petUID] }
        else { petImage = UIImage(named: "image.nopic.png") }
        
        // Fill in the pet pic, name, and appt status
        cell.petImageView.image = petImage
        cell.petNameButton.setTitle(petData.petName, for: .normal)
        cell.appointmentTypeLabel.text = apptData!.apptStatus
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white
        cell.selectedBackgroundView = backgroundView
        
        // Fill in the clinic
        var clinic = VCClinicRecord()
        _ = VCRecordGetter().clinicRecordWith(uid: apptData!.clinicUID, putInClinicRecord: &clinic)
        cell.clinicNameLabel.text = clinic.clinicName
        
        // Fill in the doctor
        if clinic.clinicDoctors.count > 0 {
            
            var doctor = VCDoctorRecord()
            VCRecordGetter().doctorRecordWith(clinic: clinic, theDoctorUID: apptData!.doctorUID, putInDoctorRecord: &doctor)
            if doctor.isValid { cell.doctorNameLabel.text = "Dr. " + doctor.givenName + " " + doctor.familyName }
        }
        
        else { cell.doctorNameLabel.text = "No Doctor Selected"; doctorSpecified = false }
        
        // Fill in date and time
        cell.appointmentDateLabel.text = VCDateServices(clock: globalData.settings.clock).getDateString(dateComponents: apptData!.startDateComponents)
        cell.appointmentTimeLabel.text = VCDateServices(clock: globalData.settings.clock).getTimeString(dateComponents: apptData!.startDateComponents)
        
        // Truncate potential long strings cleanly
        if cell.clinicNameLabel.text!.count > 20 {  let newString = cell.clinicNameLabel.text?.partial(fromIndex: 0, length: 20); cell.clinicNameLabel.text = newString! + " ..." }
        if doctorSpecified && cell.doctorNameLabel.text!.count > 20 {  let newString = cell.doctorNameLabel.text?.partial(fromIndex: 0, length: 20); cell.doctorNameLabel.text = newString! + " ..." }
        
        // Return the cell
        return cell
    }
    
    // Capture selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        isCreate = false
        selectedAppointment = indexPath.row
    
        var theAppointment: VCAppointmentRecord?
        
        if appointmentSelector.selectedSegmentIndex == 0 { theAppointment = globalData.user.currentAppointments[selectedAppointment] }
        else { theAppointment = globalData.user.pastAppointments[selectedAppointment] }
        
        selectedPet = VCRecordGetter().petIndexWith(uid: theAppointment!.petUID)
      
        apptDocumentView.setAppointmentInfo(appointmentRecord: theAppointment!)
        
        apptInformationView.setAppointmentInfo()
        apptInformationView.documentLabel.alpha = 1.0
        apptInformationView.documentButton.alpha = 1.0
        apptInformationView.setAppointmentButtons()
        
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
    
    func clinicDetailsLoadResponse (json: NSDictionary, webServiceSuccess: Bool) {
        
        var timeWindows = [VCTimeWindow]()
        var scheduleString: String = ""
        let dayOfWeekName = ["Su ", "Mo ", "Tu ", "We ", "Th ", "Fr ", "Sa "]
        var doctorRecord = VCDoctorRecord()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
        guard success.webServiceSuccess else {
            
            if success.errorString != "userTimeout" { VCAlertServices(viewController: self).popupOK(aTitle: "Clinic Schedule Error", aMessage: success.errorString) }
            NSLog(success.errorString)
            return
        }
        
        let schedule = json.value(forKey: "schedule") as! NSArray
        let vets = json.value(forKey: "vets") as! NSArray
        
        // Get the schedule
        if schedule.count != 0 {
            
            // Parse the json
            let schedParams = schedule[0] as! NSDictionary
            
            let availableTimes = (schedParams.value(forKey: "availableTimes") as! NSArray)
        
            for a in availableTimes {
                
                let clinicTimes = a as! NSDictionary
                
                let from = clinicTimes["from"] as! String
                let to = clinicTimes["to"] as! String
                
                let timeWindow = VCTimeWindow(f: from, t: to)
                timeWindows.append(timeWindow)
            }
     
            var dayOfWeek = schedParams.value(forKey: "dayOfWeek") as! [Int]
            dayOfWeek.sort()
            for d in dayOfWeek { scheduleString += dayOfWeekName[d] }
            
            // Save the schedule string
            globalData.clinics[clinicCounter].clinicSchedule = scheduleString
            globalData.clinics[clinicCounter].startTimeComponents = VCDateServices().getTimeSpan(span: timeWindows).from
            globalData.clinics[clinicCounter].endTimeComponents = VCDateServices().getTimeSpan(span: timeWindows).to
            
        }
        
        // Get the vets
        
        globalData.clinics[clinicCounter].clinicDoctors.removeAll()
        
        for v in vets {
            
            let details = v as! NSDictionary
            
            if details["status"] as! String == "approve" {
                
                doctorRecord.doctorUID = String(details["memberId"] as! Int)
                doctorRecord.givenName = (details["givenName"] as! String)
                doctorRecord.familyName = (details["familyName"] as! String)
                
                globalData.clinics[clinicCounter].clinicDoctors.append(doctorRecord)
            }
        }
        
        // Continue loop until all clinics are accessed
        clinicCounter += 1
        getClinicDetails()
    }
    
    func clinicServicesLoadResponse (json: NSDictionary, webServiceSuccess: Bool) {
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
        
        guard success.webServiceSuccess else {
            
            if success.errorString != "userTimeout" { VCAlertServices(viewController: self).popupOK(aTitle: "Consultation Type Error", aMessage: success.errorString) }
            NSLog(success.errorString)
            return
        }
        
        var televetServiceDownloaded: Bool = false
        var clinicService = VCClinicService()
        
        let consultTypes = (json["consultTypes"] as! NSArray)
        
        for t in consultTypes {
            
            let params = t as! NSDictionary
            
            clinicService.isDefault = (params["isDefault"] as! Bool)
            clinicService.serviceID = (params["consultTypeId"] as! Int)
            clinicService.serviceMedicalName = (params["consultType"] as! String)
            clinicService.servicePlainName = (params["consultSubType"] as! String)
            clinicService.serviceDescription = (params["description"] as! String)
            clinicService.serviceFee = (params["fee"] as! Int)
            clinicService.serviceTimeRequired = (params["consultTimeRequired"] as! Int)
            
            if !televetServiceDownloaded && clinicService.serviceMedicalName.lowercased().contains("televet") {
                
                televetServiceDownloaded = true
                clinicService.serviceMedicalName = "General Televet Consultation"
                globalData.clinics[clinicCounter].clinicServices.append(clinicService)
            }
            
            else if televetServiceDownloaded && clinicService.serviceMedicalName.lowercased().contains("televet") { continue }
           
            else { globalData.clinics[clinicCounter].clinicServices.append(clinicService) }
            
        }
        
        // Continue loop until all clinics are accessed
        clinicCounter += 1
        getClinicServices()
    }

    func cancelAppointmentResponse(json: NSDictionary, webServiceSuccess: Bool) {
        
        alert!.dismiss()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
      
        guard success.webServiceSuccess else {
            
            if success.errorString != "userTimeout" { VCAlertServices(viewController: self).popupOK(aTitle: "", aMessage: success.errorString) }
            NSLog(success.errorString)
            return
        }
    
        if appointmentSelector.selectedSegmentIndex == 0 { globalData.user.currentAppointments.remove(at: selectedAppointment) }
        else { globalData.user.pastAppointments.remove(at: selectedAppointment) }
        
        selectedAppointment = -1
        homeController().setBadges()
        
        if globalData.user.currentAppointments.count == 0 { messageLabel.isHidden = false }
        reloadAppointmentTable()
        
        homeController().setHomePageUIElements()
    }
    
    func exitAppointment() { return }
    
    func bookAppointment() {
        
        apptInformationView.clearView()
        apptInformationView.showView()
        appointmentSelector.selectedSegmentIndex = 0
    }
    
    func noProfileResponse () {self.tabBarController?.selectedIndex = profileTab }

    // MARK: ACTION HANDLERS
    
    @IBAction func selectorTapped(_ sender: UISegmentedControl) { reloadAppointmentTable() }
    
    @IBAction func settingsButtonTapped(_ sender: Any) { apptSettingsView.initControls(); apptSettingsView.showView() }
        
    @IBAction func plusButtonTapped(_ sender: Any) {
     
        apptInformationView.localAppointmentRecord.reinit()
        apptInformationView.documentLabel.alpha = 0.20
        apptInformationView.documentButton.alpha = 0.20
        
        isCreate = true
        apptInformationView.setAppointmentButtons()
        
        if globalData.flags.isFirstAppointmentRequest {
            
            VCAlertServices(viewController: self).popupQuestion(aTitle: "IMPORTANT", aMessage: "Televet consultations can only be accepted if the veterinarian has already seen your pet for this condition", firstMsg: "CANCEL", secondMsg: "OK", firstCallBack: exitAppointment, secondCallBack: bookAppointment)
            globalData.flags.isFirstAppointmentRequest = false
        }
        
        else { bookAppointment() }
    }
}
 
