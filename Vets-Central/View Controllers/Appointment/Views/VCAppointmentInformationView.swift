//
//  VCAppointmentFormView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.

import UIKit 

class VCAppointmentInformationView : VCView, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var apptScrollView: UIScrollView!
    @IBOutlet weak var apptContentView: UIView!
    @IBOutlet weak var locationSegmentControl: UISegmentedControl!
    @IBOutlet weak var patientTextField: UITextField!
    @IBOutlet weak var clinicTextField: UITextField!
    @IBOutlet weak var doctorTextField: UITextField!
    @IBOutlet weak var typeTextField: UITextField!
    @IBOutlet weak var reasonTextView: UITextView!
    @IBOutlet weak var reasonTitleBar: UIButton!
    @IBOutlet weak var apptContentHeight: NSLayoutConstraint!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var scheduleLabel: UILabel!
    @IBOutlet weak var availableTimeLabel: UILabel!
    @IBOutlet weak var documentLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var documentButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var televetButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var currentApptMessageLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateAndTimeLabel: UILabel!
    
    // MARK: PROPERTIES
    
    var localAppointmentRecord = VCAppointmentRecord()
    var placeholderTextColor = VCColorServices().grayColorByValue(value: 205)
    var initialConstraint : CGFloat?
    var petPickerView = UIPickerView()
    var clinicPickerView = UIPickerView()
    var doctorPickerView = UIPickerView()
    var apptTypePickerView = UIPickerView()
    var toolBar: UIToolbar = UIToolbar()
    var doneButton: UIBarButtonItem?
    var selectedClinicWithinDistance: Int?
    var selectedField: ApptFields = .nofield
    var clinicDoctors = [VCDoctorRecord]()
    var doctorDataMapper: VCDataSourceMapper?
    var serviceDataMapper: VCDataSourceMapper?
    var doctorOffsetTitle = "None"
    var serviceOffsetTitle = "I'm not sure"
    var appointmentDuration: Double?
   
    // MARK: INITIALIZATION
    
    override func initView() {
        
        doctorDataMapper = VCDataSourceMapper(theOffsetTitles: [doctorOffsetTitle])
        serviceDataMapper = VCDataSourceMapper(theOffsetTitles: [serviceOffsetTitle])
        
        activityIndicator.isHidden = true
       
        // Attach the outlets
        scrollView = apptScrollView
        contentHeight = apptContentHeight
    
        // Setup the slider
        distanceSlider.isContinuous = true
        distanceSlider.maximumValue = 200
        distanceSlider.minimumValue = 10
        distanceSlider.value = 50
        
        // Attach the delegates
        patientTextField.delegate = self
        clinicTextField.delegate = self
        doctorTextField.delegate = self
        typeTextField.delegate = self
        reasonTextView.delegate = self
        
        // Init the textview
        reasonTextView.roundCorners(corners: .bottom, radius: 10)
        reasonTextView.setBorder(width: 1.0, color: UIColor.lightGray.cgColor)
        reasonTextView.isSelectable = true
        reasonTitleBar.roundCorners(corners: .top, radius: 10)
       
        
        // Setup the buttons
        documentButton.roundAllCorners(value: 4.0)
        documentButton.setBorder(width: 1.0, color: UIColor.lightGray.cgColor)
        submitButton.roundAllCorners(value: 10.0)
        televetButton.roundAllCorners(value: 10.0)
    
        distanceSlider.addTarget(self, action: #selector(onSliderChange(slider:event:)), for: .valueChanged)
        
        setupPickers()
        reasonTextView.inputAccessoryView = toolBar
      
        super.initView()
    }

    override func keyboardWillShow(notification: NSNotification) {
        
        guard globalData.activeView != nil else { return }
        guard self == globalData.activeView! else { return }
       
        super.keyboardWillShow(notification: notification)
        
        guard parentController.appointmentController.selectedPet != nil else { return }
    
        switch selectedField {
     
            case .patient:
                
                patientTextField.text = globalData.user.pets[parentController.appointmentController.selectedPet!].petName
            
            case .clinic:
                
                guard selectedClinicWithinDistance != nil else { return }
               
                let theClinic = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!]
                //if theClinic.nextValidApptTime != nil { dateTextField.text = theClinic.nextValidApptTime!.dateAndTimeString }
               
                clinicTextField.text = theClinic.clinicName
                setClinicDoctors()
    
            case .doctor:
                
                if clinicDoctors.count > 0 && parentController.appointmentController.selectedDoctor != nil { doctorTextField.text = "Dr. " + clinicDoctors[parentController.appointmentController.selectedDoctor!].givenName + " " + clinicDoctors[parentController.appointmentController.selectedDoctor!].familyName }
                
            case .type:
    
                guard selectedClinicWithinDistance != nil else { return }
                
                if parentController.appointmentController.selectedType != nil { typeTextField.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicServices[parentController.appointmentController.selectedType!].serviceMedicalName }
                   
            default: break
        }
    }
    
    // MARK: METHODS

    func getNextAppointment() -> VCDate? {
        
        let theClinic = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!]
        
        guard theClinic.clinicSchedule != "" else {
            
            parentController.controllerAlert!.popupOK(aMessage: "This clinic has not posted a schedule - please choose a different clinic or contact the clinic directly")
            return nil
        }
        
        let nextAvailableAppt = theClinic.nextValidApptTime
        
        guard nextAvailableAppt != nil else {
            
            VCAlertServices(viewController: parentController).popupOK(aMessage: "There are no appointments available right now, please contact your clinic")
            return nil
        }
        
        return nextAvailableAppt!
    }
    
    func setupPickers () {
        
        // Pet picker view
        petPickerView.delegate = self
        petPickerView.dataSource = self
        petPickerView.backgroundColor = UIColor.black
        petPickerView.setValue(UIColor.white, forKeyPath: "textColor")
        petPickerView.frame.size.height = 0.25 * self.frame.size.height
       
        // Clinic picker view
        clinicPickerView.delegate = self
        clinicPickerView.dataSource = self
        clinicPickerView.backgroundColor = UIColor.black
        clinicPickerView.setValue(UIColor.white, forKeyPath: "textColor")
        clinicPickerView.frame.size.height = 0.25 * self.frame.size.height
    
        // Doctor picker view
        doctorPickerView.delegate = self
        doctorPickerView.dataSource = self
        doctorPickerView.backgroundColor = UIColor.black
        doctorPickerView.setValue(UIColor.white, forKeyPath: "textColor")
        doctorPickerView.frame.size.height = 0.25 * self.frame.size.height
        
        // Appt type picker view
        apptTypePickerView.delegate = self
        apptTypePickerView.dataSource = self
        apptTypePickerView.backgroundColor = UIColor.black
        apptTypePickerView.setValue(UIColor.white, forKeyPath: "textColor")
        apptTypePickerView.frame.size.height = 0.25 * self.frame.size.height
        
        // Date picker view
        datePicker.minuteInterval = 15
        datePicker.datePickerMode = .dateAndTime
       
        if globalData.settings.clock == .c12 { datePicker.locale = Locale(identifier: "en_US") }
        else { datePicker.locale = Locale(identifier: "en_GB") }
      
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)

        // Done button toolbar
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(onDoneButton))
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = false
        toolBar.tintColor = .white
        toolBar.barTintColor = UIColor(displayP3Red: 67/255, green: 146/255, blue: 203/255, alpha: 1.0)
        toolBar.sizeToFit()
        toolBar.setItems([doneButton!], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        // Connect pickers and toolbar
        patientTextField.inputView = petPickerView
        patientTextField.inputAccessoryView = toolBar
        clinicTextField.inputView = clinicPickerView
        clinicTextField.inputAccessoryView = toolBar
        doctorTextField.inputView = doctorPickerView
        doctorTextField.inputAccessoryView = toolBar
        typeTextField.inputView = apptTypePickerView
        typeTextField.inputAccessoryView = toolBar
        reasonTextView.inputAccessoryView = toolBar
    }
    
    func setCalendar() {
        
        let nextDate = getNextAppointment()
        guard nextDate != nil else { return }
        
        datePicker.date = nextDate!.localDate
        datePicker.minimumDate = datePicker.date
      
        calendarIsDimmed(false)
        availableTimeLabel.text = "Earliest appt request: " + nextDate!.dateAndTimeString
    }
        
    func setClinicDoctors () {
    
        guard selectedClinicWithinDistance != nil else { return }
        guard parentController.appointmentController.clinicsWithinDistance.count > 0 else { return }
        guard parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicDoctors.count > 0 else { return }
     
        // Set the doctors for the clinic
        doctorTextField.text = ""
        typeTextField.text = ""
    
        clinicDoctors.removeAll()
        clinicDoctors = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicDoctors
        
        for (index, value) in clinicDoctors.enumerated() {
            
            doctorDataMapper!.cacheTitles(forIndex: index, title: "Dr. " + value.givenName + " " + value.familyName)
            
        }
        
        for (index, value) in parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicServices.enumerated() {
            
            serviceDataMapper!.cacheTitles(forIndex: index, title: value.serviceMedicalName )
        }
    }
    
    func refreshClockMode() {
        
        if globalData.settings.clock == .c12 { datePicker.locale = Locale(identifier: "en_US") }
        else { datePicker.locale = Locale(identifier: "en_GB")}
        
        if !clinicTextField.text!.isEmpty { scheduleLabel.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].scheduleString }
    }
    
    func clearView() {
        
        var clinicUID: Int?
        let mapClinicRecord = VCClinicRecord()
        
        patientTextField.text = ""
        doctorTextField.text = ""
        reasonTextView.text = ""
        datePicker.date = Date()
    
        parentController.appointmentController.selectedAppointment = nil
        parentController.appointmentController.selectedPet = nil
        parentController.appointmentController.selectedDoctor = nil
        selectedClinicWithinDistance = nil
        clinicTextField.text = ""
        
        guard globalData.user.data.mapClinicUID != 0 || globalData.user.data.preferredClinicUID != nil else { return }
      
        // First map request, then preferred clinic
        if globalData.user.data.mapClinicUID != nil {
            
            clinicUID = globalData.user.data.mapClinicUID!
            globalData.user.data.mapClinicUID = nil
            
            if VCRecordGetter().clinicRecordWith(uid: clinicUID!) != nil {
           
                var distanceRadius = VCDistanceCalculator().distanceRadius(clinicLat: mapClinicRecord.clinicLat, clinicLng: mapClinicRecord.clinicLng, compareLat: globalData.location.latitude, compareLng: globalData.location.longitude)
                
                if distanceRadius >= Double(distanceSlider.maximumValue) {
                    
                    parentController.appointmentController.getAllClinics()
                    distanceSlider.value = distanceSlider.maximumValue
                    distanceLabel.text = "All VC Clinics"
                }
                
                else {
                    
                    if distanceRadius < 50 { distanceRadius = 50 }
                    parentController.appointmentController.getClinicsWithinDistance(atDistance: distanceRadius)
                    distanceSlider.value = Float(distanceRadius)
                    distanceLabel.text = "Show me clinics within " + String(Int(distanceSlider.value)) + " km of my location:"
                }
            }
        }
        
        else if globalData.user.data.preferredClinicUID != nil { clinicUID = globalData.user.data.preferredClinicUID }
            
        for (index, value) in parentController.appointmentController.clinicsWithinDistance.enumerated() {
            
            if value.clinicUID == clinicUID {
                
                selectedClinicWithinDistance = index
                clinicTextField.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicName
                scheduleLabel.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].scheduleString
                clinicPickerView.selectRow(selectedClinicWithinDistance!, inComponent: 0, animated: false )
                setClinicDoctors()
            }
        }
    }
    
    func setForNewAppointment() {
        
        setAppointmentButtons()
        calendarIsDimmed(true)
    }
    
    func setAppointmentInfo() {
        
        var timeframe: ApptTimeFrame?
        
        setAppointmentButtons()
        calendarIsDimmed(false)
        
        // Get the appointment data
        if parentController.appointmentController.appointmentSelector.selectedSegmentIndex == 0 { localAppointmentRecord = globalData.user.currentAppointments[parentController.appointmentController.selectedAppointment!]; timeframe = .current }
        else { localAppointmentRecord = globalData.user.pastAppointments[parentController.appointmentController.selectedAppointment!]; timeframe = .past }
       
        // Get the clinic record
        let clinicRecord = VCRecordGetter().clinicRecordWith(uid: localAppointmentRecord.clinicUID!, fromData: globalData.clinics)
        
        // Calculate its distance away
        if localAppointmentRecord.clinicUID != nil {
       
            localAppointmentRecord.clinicDistance = Float(VCDistanceCalculator().distanceRadius(clinicLat: clinicRecord!.clinicLat, clinicLng: clinicRecord!.clinicLng, compareLat: parentController.appointmentController.currentLat!, compareLng: parentController.appointmentController.currentLng!))
           
            if localAppointmentRecord.clinicDistance < 50 { localAppointmentRecord.clinicDistance = 50 }
            else { localAppointmentRecord.clinicDistance += 50 }
            
        } else { localAppointmentRecord.clinicDistance = 50 }
        
        // Set the distance slider and get the clinics within that radius
        distanceSlider.value = localAppointmentRecord.clinicDistance
        parentController.appointmentController.getClinicsWithinDistance(atDistance: Double(localAppointmentRecord.clinicDistance))
        selectedClinicWithinDistance = VCRecordGetter().clinicIndexInSubArray(clinicUID: clinicRecord!.clinicUID!, subArray: parentController.appointmentController.clinicsWithinDistance)
        
        // Capture the selected indices of the appointment, pet, clinic
        parentController.appointmentController.selectedAppointment = VCRecordGetter().appointmentIndexWith(uid: localAppointmentRecord.apptUID!, timeFrame: timeframe)
        parentController.appointmentController.selectedPet = VCRecordGetter().petIndexWith(uid: localAppointmentRecord.petUID!)
       
        // Set the clinic doctors for the selected clinic and then get the index of the doctor for the appointment
        setClinicDoctors()
        
        if localAppointmentRecord.doctorUID != nil {
            
            parentController.appointmentController.selectedDoctor = VCRecordGetter().doctorIndexWith(clinicDoctors: clinicDoctors, doctorUID: localAppointmentRecord.doctorUID!)
        }
       
        // Set the type segement
        if localAppointmentRecord.apptType == "Televet" { locationSegmentControl!.selectedSegmentIndex = 0 }
        else { locationSegmentControl!.selectedSegmentIndex = 0 }
        
        // Fill in patient and clinic fields
        patientTextField.text = globalData.user.pets[parentController.appointmentController.selectedPet!].petName
        clinicTextField.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicName
    
        // Construct and fill in the doctor name
        if parentController.appointmentController.selectedDoctor != nil && parentController.appointmentController.selectedDoctor != 0 {
            
            let theDoctor = clinicDoctors[parentController.appointmentController.selectedDoctor!]
            doctorTextField.text = "Dr. " + theDoctor.givenName + " " + theDoctor.familyName
            
        } else { doctorTextField.text = "No Doctor Selected" }

        // Set consult type
        if localAppointmentRecord.service.serviceID != 0 { typeTextField.text = localAppointmentRecord.service.serviceMedicalName}
        else { typeTextField.text = serviceOffsetTitle }
        
        // Fill in the date field
        datePicker.date = localAppointmentRecord.startDate.localDate
       
        // Fill in the reason text
        if localAppointmentRecord.apptReason != "" { reasonTextView.text = localAppointmentRecord.apptReason }
      
        // Set the focus to the patient field and load the pickers
        selectedField = .patient
        petPickerView.reloadAllComponents()
        clinicPickerView.reloadAllComponents()
        doctorPickerView.reloadAllComponents()
        apptTypePickerView.reloadAllComponents()
        
        // Build the schedule string
        scheduleLabel.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].scheduleString
        
        // Set date pickers
        if parentController.appointmentController.selectedAppointment != nil {
            
            datePicker.date = localAppointmentRecord.startDate.theDate!
            appointmentDuration = TimeInterval(localAppointmentRecord.endDate |-| localAppointmentRecord.startDate)
        }
        
        setAppointmentButtons()
    }
    
    func getAppointment () -> Bool {
        
        guard patientTextField.text != "" && clinicTextField.text != "" else {
          
            VCAlertServices(viewController: parentController.appointmentController).popupMessage(aMessage: "Please complete all the required fields before submitting the appointment request")
            return false
        }
        
        // Note we already have the start date components
        localAppointmentRecord.petUID = globalData.user.pets[parentController.appointmentController.selectedPet!].petUID
        localAppointmentRecord.clinicUID = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicUID
        localAppointmentRecord.clinicName = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicName
        localAppointmentRecord.startDate = VCDate(date: datePicker.date)
        
        if parentController.appointmentController.selectedDoctor != nil && doctorTextField.text != doctorOffsetTitle && doctorTextField.text != "" {
            
            localAppointmentRecord.doctorUID = clinicDoctors[parentController.appointmentController.selectedDoctor!].doctorUID!
            
        } else { localAppointmentRecord.doctorUID = nil }
        
        if locationSegmentControl?.selectedSegmentIndex == 0 {  localAppointmentRecord.apptType = "Televet" }
        else { localAppointmentRecord.apptType = "In Clinic" }
       
        if parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicServices.count > 0 {
            
            if parentController.appointmentController.selectedType == nil { localAppointmentRecord.service = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].defaultService.record! }
            else { localAppointmentRecord.service = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicServices[parentController.appointmentController.selectedType!] }
        }
       
        localAppointmentRecord.apptReason = reasonTextView.text!
        localAppointmentRecord.apptStatus = "Pending Clinic Acceptance"
        
        return true
    }
    
    func setAppointmentButtons () {
        
        if parentController.appointmentController.isCreate {
            
            titleLabel.text = "MAKE AN APPOINTMENT"
            submitButton.setTitle("SUBMIT", for: .normal)
            documentLabel.text = "Choose documents for appointment"
            
            submitButton.isEnabled = true
            submitButton.isHidden = false
            televetButton.isHidden = true
           
            distanceSlider.isEnabled = true
            patientTextField.isEnabled = true
            clinicTextField.isEnabled = true
            doctorTextField.isEnabled = true
            typeTextField.isEnabled = true
            reasonTextView.isEditable = true
   
        } else {
        
            titleLabel.text = "YOUR APPOINTMENT"
            
            if parentController.appointmentController.appointmentSelector.selectedSegmentIndex == 0 {
            
                submitButton.setTitle("RESCHEDULE", for: .normal)
               
                submitButton.isEnabled = true
                televetButton.isHidden = false
                
            } else {
                
                submitButton.isHidden = true
                televetButton.isHidden = true
            }
            
            distanceSlider.isEnabled = false
            patientTextField.isEnabled = false
            clinicTextField.isEnabled = false
            doctorTextField.isEnabled = false
            typeTextField.isEnabled = false
            reasonTextView.isEditable = false
        }
    }
    
    func setAppointmentNotes() {
        
        webServices!.getAppointmentNotes(theAppointment: localAppointmentRecord) { json, status in
           
            guard self.webServices!.isErrorFree(json: json, status: status) else { return }
        
            var noteUID: Int?
            let apptNotes = json["notes"] as! NSDictionary
            let notes = apptNotes["notes"] as! NSArray
            
            for n in notes {
                
                let noteFields = n as! NSDictionary
                if (noteFields["subject"] as! String) == "Help Needed" { noteUID = (noteFields["id"] as! Int); break }
            }
            
            self.webServices!.setAppointmentNotes(theAppointment: self.localAppointmentRecord, theNote: VCDBAppointmentNote(nu: noteUID, mi: Int(globalData.user.data.userUID!), su: "Help Needed", nt: self.localAppointmentRecord.apptReason) ) {
                
                (json, status) in return
            }
        }
    }
    
    func calendarIsDimmed(_ state: Bool) {
        
        var alpha: CGFloat?
        
        if state { alpha = 0.30 } else { alpha = 1.0 }
        
        dateAndTimeLabel.changeDisplayState(toState: .dimmed, withAlpha: alpha!, forDuration: 0.25, atCompletion: { return })
        datePicker.changeDisplayState(toState: .dimmed, withAlpha: alpha!, forDuration: 0.25, atCompletion: { return })
       
        datePicker.isEnabled = !state
    }
    
    func interfaceIsEnabled(_ state: Bool) {
    
        patientTextField.isEnabled = state
        clinicTextField.isEnabled = state
        doctorTextField.isEnabled = state
       // datePicker.isEnabled = state
        reasonTextView.isEditable = state
        submitButton.isEnabled = state
    }
    
    // MARK: PICKER DELEGATE PROTOCOL
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        switch pickerView {
        
            case petPickerView: return globalData.user.pets.count
                
            case clinicPickerView: return parentController.appointmentController.clinicsWithinDistance.count
                
            case doctorPickerView: return doctorDataMapper!.count(forRootSource: clinicDoctors)
                
            case apptTypePickerView: return serviceDataMapper!.count(forRootSource: parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicServices)
                
            default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch pickerView {
        
            case petPickerView: return globalData.user.pets[row].petName
                
            case clinicPickerView: return (parentController as! VCAppointmentViewController).clinicsWithinDistance[row].clinicName
                
            case doctorPickerView: return doctorDataMapper!.title(forIndex: row)
                
            case apptTypePickerView: return serviceDataMapper!.title(forIndex: row)
                
            default: return ""
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerView {
        
            case petPickerView:
                
                parentController.appointmentController.selectedPet = row
                patientTextField.text = globalData.user.pets[parentController.appointmentController.selectedPet!].petName
                
            case clinicPickerView:
            
                selectedClinicWithinDistance = row
            
                let theClinic = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!]
            
                clinicTextField.text = theClinic.clinicName
                scheduleLabel.text = theClinic.scheduleString
               
                setCalendar()
                setClinicDoctors()
                
            case doctorPickerView:
                
                parentController.appointmentController.selectedDoctor = doctorDataMapper!.getRootIndex(forDataSourceIndex: row)
                doctorTextField.text = doctorDataMapper!.title(forIndex: row)
                
            case apptTypePickerView:
            
                parentController.appointmentController.selectedType = doctorDataMapper!.getRootIndex(forDataSourceIndex: row)
                typeTextField.text = serviceDataMapper!.title(forIndex: row)

            default: return
        }
    }
    
    // MARK: TEXTVIEW DELEGATE PROTOCOL
    
    func textViewDidBeginEditing(_ textView: UITextView) { selectedField = .reason }
   
    func textViewDidEndEditing(_ textView: UITextView) {  textView.resignFirstResponder() }
        
    // MARK: TEXTFIELD DELEGATE PROTOCOL

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        if (textField == doctorTextField || textField == typeTextField) && clinicTextField.text!.isEmpty {
            
            VCAlertServices(viewController: parentController).popupMessage(aMessage:  "Please select a clinic")
            return false
        }
        
        else if textField == clinicTextField && parentController.appointmentController.clinicsWithinDistance.isEmpty {
            
            dismissKeyboard()
            VCAlertServices(viewController: parentController).popupMessage(aMessage: "There are no VC clinics in your local area, please increase the search distance by using the slider")
                
            return false
        }
        
        else if textField == typeTextField && selectedClinicWithinDistance != nil && parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicServices.count == 0 {
            
            VCAlertServices(viewController: parentController).popupMessage(aMessage: "This clinic doesn't require an appointment type")
            return false
        }
        
        else if textField == doctorTextField && parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicDoctors.count == 0 {
            
            VCAlertServices(viewController: parentController).popupMessage(aMessage:  "This clinic has not provided a list of it's doctors, the field can be left blank")
            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {

        switch textField {
        
            case patientTextField:
                
                if parentController.appointmentController.selectedPet == nil { parentController.appointmentController.selectedPet = 0 }
                selectedField = .patient
                petPickerView.selectRow(parentController.appointmentController.selectedPet!, inComponent: 0, animated: false)
                
            case clinicTextField:
                
                if selectedClinicWithinDistance == nil { selectedClinicWithinDistance = 0 }
                
                selectedField = .clinic
                scheduleLabel.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].scheduleString
                clinicPickerView.selectRow(selectedClinicWithinDistance!, inComponent: 0, animated: false)
                clinicTextField.text = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!].clinicName
                setCalendar()
                calendarIsDimmed(false)
              
            case doctorTextField:
                
                selectedField = .doctor
                
                if parentController.appointmentController.selectedDoctor == nil { doctorPickerView.selectRow(0, inComponent: 0, animated: false) }
                else { doctorPickerView.selectRow(doctorDataMapper!.getDataSourceIndex(forRootIndex: parentController.appointmentController.selectedDoctor!), inComponent: 0, animated: false) }
                
            case typeTextField:
            
                selectedField = .type
                
                if parentController.appointmentController.selectedType != nil { apptTypePickerView.selectRow(parentController.appointmentController.selectedType!, inComponent: 0, animated: false) }
                else { typeTextField.text = serviceOffsetTitle }
                
            default: selectedField = .nofield
        }
    }
    
    // MARK: CALL BACKS
    
    func appointmentRequestResponse (json: NSDictionary, status: Bool) {
        
        activityIndicator.isHidden = true
        interfaceIsEnabled(true)
        submitButton.setTitle("SUBMIT", for: .normal)
        
        guard webServices!.isErrorFree(json: json, status: status) else { return }
        
        webServices!.postErrorToServer()
        
        if parentController.appointmentController.selectedAppointment == nil {
            
            let appt = (json["appointment"] as! NSDictionary)
            let apptInfo = (appt["appointmentInfo"] as! NSDictionary)
            
            localAppointmentRecord.apptUID = (apptInfo["id"] as! Int)
            localAppointmentRecord.endDate = VCDate(fromServerDateAndTime: (appt["to"] as! String))
            globalData.user.currentAppointments.append(localAppointmentRecord)
        }
        else { globalData.user.currentAppointments[parentController.appointmentController.selectedAppointment!] = localAppointmentRecord }
        
        // Asynchronously set the appointment help needed note to the reason text
        setAppointmentNotes()
        parentController.appointmentController.reloadAppointmentTable()
       
        if parentController.appointmentController.selectedAppointment == nil { submitButton.setTitle("SUBMIT", for: .normal)}
        else { submitButton.setTitle("RESCHEDULE", for: .normal) }
        
        activityIndicator.isHidden = true
        
        globalData.messageService.addMessage(from: "Vets Central Admin", title: "Appointment Request Sent", messageBody: "Your appointment request to " + clinicTextField.text! + " has been submitted.  We'll alert you when it has been accepted by the clinic.")
        globalData.user.currentAppointments.sort() { $0.startDate.theDate! < $1.startDate.theDate! }
        
        parentController.homeController.setBadges()
        parentController.homeController.setHomePageUIElements()
     
        hideView()
        clearView()
    }
    
    func appointmentCancelledResponse() { }
    
    func appointmentRescheduleResponse (json: NSDictionary, status: Bool) {
    
        activityIndicator.isHidden = true
        
        guard self.webServices!.isErrorFree(json: json, status: status) else { return }
       
        localAppointmentRecord.endDate = VCDate(date: localAppointmentRecord.startDate.theDate!.addingTimeInterval(appointmentDuration!))
        
        globalData.user.currentAppointments[parentController.appointmentController.selectedAppointment!] = localAppointmentRecord
        globalData.messageService.addMessage(from: "Vets Central Admin", title: "Appointment Reschedule Request Sent", messageBody: "Your request to reschedule " + clinicTextField.text! + " has been submitted.  We'll alert you when it has been accepted by the clinic.")
        globalData.user.currentAppointments.sort() { $0.startDate.theDate! < $1.startDate.theDate! }
        
        parentController.appointmentController.appointmentTable.reloadData()
        parentController.homeController.setHomePageUIElements()
      
        hideView()
        clearView()
    }
    
    // MARK: ACTION HANDLERS
    
    @objc func onDoneButton() { dismissKeyboard() }
        
    @objc func onSliderChange (slider: UISlider, event: UIEvent) {
        
        if let touchEvent = event.allTouches?.first {
            
            switch touchEvent.phase {
            
                case .began: break
                    
                case .moved:
                   
                    if slider.value == slider.maximumValue { distanceLabel.text = "All VC Clinics" }
                    else { distanceLabel.text = "Show me clinics within " + String(Int(distanceSlider.value)) + " km of my location:" }
                    
                case .ended:
                    
                    clinicTextField.text!.removeAll()
                    doctorTextField.text!.removeAll()
                    
                    if slider.value == slider.maximumValue {parentController.appointmentController.getAllClinics() }
                    else {
                        
                        parentController.appointmentController.getClinicsWithinDistance(atDistance: Double(distanceSlider.value))
                        selectedClinicWithinDistance = nil
                    }
                    
                    clinicPickerView.reloadAllComponents()
                 
                default: break
            }
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: Any) {
         
        let pickerDate = VCDate(date: datePicker.date)
        let theClinic = parentController.appointmentController.clinicsWithinDistance[selectedClinicWithinDistance!]
        let apptStatus = theClinic.isValidAppointmentTime(pickerDate)
      
        guard apptStatus.isValid else {
                    
            if apptStatus.date == nil { datePicker.date = datePicker.minimumDate! }
            else { datePicker.date = apptStatus.date!.theDate! }
            
            return
        }
    }
    
    @IBAction func documentButtonTapped(_ sender: Any) {
        
        endEditing()
        
        guard patientTextField.text != "" else {
            
            VCAlertServices(viewController: parentController.appointmentController).popupMessage(aMessage: "Please select a pet to upload or download documents")
            return
        }
        
        guard parentController.appointmentController.apptInformationView.localAppointmentRecord.apptUID != nil else {
            
            VCAlertServices(viewController: parentController.appointmentController).popupMessage(aMessage: "Please submit this appointment request before selecting documents")
            return
        }
        
        parentController.appointmentController.apptDocumentView.subClassType = .appointment
        parentController.appointmentController.apptDocumentView.setupView()
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        
        guard !scheduleLabel.text!.contains("Clinic") else {
            
            parentController.appointmentController.controllerAlert!.popupMessage(aMessage: "Unfortunately this clinic has not posted it's schedule. Please select a different clinic or contact the clinic directly")
            return
        }
        
        if submitButton.currentTitle == "RESCHEDULE"  {
            
            let currentDate = globalData.user.currentAppointments[parentController.appointmentController.selectedAppointment!].startDate
            guard currentDate |!=| VCDate(date: datePicker.date) else { VCAlertServices(viewController: parentController).popupMessage(aMessage: "You haven't changed the date or time yet"); return }
        }
        
        guard getAppointment() else {  VCAlertServices(viewController: parentController).popupMessage(aMessage: "Please enter all the information for the appointment"); return }
        
        if globalData.flags.refreshInProgress { globalData.abortRefresh() }
      
        dismissKeyboard()
        submitButton.setTitle("", for: .normal)
        activityIndicator.isHidden = false
        localAppointmentRecord.clinicDistance = distanceSlider.value
        
        interfaceIsEnabled(false)
       
        if parentController.appointmentController.selectedAppointment == nil { webServices!.createAppointment(theApptData: localAppointmentRecord, callBack: appointmentRequestResponse) }
        else { webServices!.rescheduleAppointment(theApptData: localAppointmentRecord, callBack: appointmentRescheduleResponse) }
    }
    
    @IBAction func televetButtonTapped(_ sender: Any) {
        
        if globalData.user.currentAppointments[parentController.appointmentController.selectedAppointment!].appointmentWindowIsOpen {
         
            parentController.appointmentController.apptWebView.initiateConsultation()
            globalData.user.currentAppointments[parentController.appointmentController.selectedAppointment!].startHasBeenIssued = true
        }
        
        else { parentController.appointmentController.controllerAlert!.popupMessage(aMessage: "It's early - you can start the Televet conference up to 15 minutes before the scheduled time") { () in self.returnButtonTapped(self) } }
    }
   
    @IBAction func returnButtonTapped(_ sender: Any) {
        
        globalData.openedAppointment = 0
        parentController.appointmentController.appointmentTable.reloadData()
      
        dismissKeyboard()
        hideView()
        clearView()
    }
}
