//
//  VCLoginService.swift 
//  Vets-Central
//
//  Services to login and refresh the data
//  Created by Roger Vogel on 10/19/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit
import MapKit

class VCLoginServices: NSObject, CLLocationManagerDelegate {
    
    // MARK: PROPERTIES
    
    var homeController: VCHomeViewController?
    var clinicCounter: Int = 0
    var lastTimeStamp: Double = 0
    var locationManager = CLLocationManager()
    var reLogin: Bool = false
    var userDataDone: Bool?
    var apptDataDone: Bool?
    var lookupsDone: Bool?
    var deadlockTimer = Timer()
    var alert: VCAlertServices?
    var progressAlert: VCAlertServices?
    var webServices: VCWebServices?
   
    // MARK: INITIALIZATION
    
    init (parent: VCHomeViewController) { super.init()
        
        homeController = parent
        locationManager.delegate = self
        alert = VCAlertServices(viewController: parent)
        progressAlert = VCAlertServices(viewController: parent)
        webServices = VCWebServices(parent: homeController)
        
        getLocation()
    }
    
    func reset() { clinicCounter = 0; userDataDone = false; apptDataDone = false; lookupsDone = false }
    
    // MARK: METHODS
    
    func displayProgressAlert(withMessage: String) {  progressAlert!.popupPendingMsg(aMessage: withMessage, withProgressBar: true) }
    
    func dismissProgressAlert() { progressAlert!.dismiss() }
 
    func preload(isReLogin: Bool) {
        
        reLogin = isReLogin
        getLocation()
    
        if CLLocationManager().authorizationStatus == .authorizedAlways || CLLocationManager().authorizationStatus == .authorizedWhenInUse  { completePreLoad() }
    }
    
    func completePreLoad() {
        
        if reLogin {
            
            homeController!.loginMessageLabel.text = "LOGGING IN"
            homeController!.loginActivityIndicator.isHidden = false
            homeController!.loginMessageLabel.isHidden = false
        }
     
        // Show activity indicator
        homeController!.loginActivityIndicator.isHidden = false
        webServices!.getClinicsNear(long: globalData.location.longitude, lat: globalData.location.latitude, radius: nil, callBack: clinicLoadResponse)
    }
    
    func login() {
      
        reLogin = false
        self.webServices!.authorizeUser(dbCredentials: VCDBCredentials(userEmail: globalData.user.data.userEmail, userPassword: globalData.user.passwords.currentPassword), callBack: userLoginResponse)
    }
    
    func create() {
        
        userDataDone = true
        apptDataDone = true
        lookupsDone = false
        
        // Set a timer to break a race condition if it occurs
        deadlockTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(handleRaceTimer), userInfo: nil, repeats: true )
        self.webServices!.createUser(theUserCredentials: VCDBCreateUser(userEmail: globalData.user.data.userEmail, userPassword: globalData.user.passwords.currentPassword, userType: "pet_owner"), callBack: userCreateResponse)
    }
    
    func cleanup() {
        
        deadlockTimer.invalidate()
     
        homeController!.loginActivityIndicator.isHidden = true
        homeController!.credentialsButton.setTitle("  LOGIN | REGISTER", for: .normal)
        homeController!.credentialsButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: { return } )
        homeController!.loginMessageLabel.isHidden = true
    }
    
    func getLocation() {
        
        let status = CLLocationManager().authorizationStatus
    
        if status == .authorizedAlways || status == .authorizedWhenInUse  {
            
            globalData.location.latitude = CLLocationManager().location!.coordinate.latitude
            globalData.location.longitude = CLLocationManager().location!.coordinate.longitude
            homeController!.enableTabs()
        }
        
        else { locationManager.requestWhenInUseAuthorization() }
    }
    
    func getPetPhotos(counter: Int){
        
        guard !globalData.user.pets.isEmpty else { return }
     
        if counter < globalData.user.pets.count {
            
            let thePet = globalData.user.pets[counter]
          
            if thePet.hasImage {
                
                self.webServices!.downloadPetPhoto(thePetRecord: thePet) { (data, status) in
                    
                    guard !globalData.user.pets.isEmpty else { return }
                    
                    if status && data == nil { VCAlertServices(viewController: self.homeController!).popupMessage(aTitle: "Pet Photo Error", aMessage: "A problem occurred loading your pet pictures"); return }
                    globalData.user.petImages[globalData.user.pets[counter].petUID!] = UIImage(data: data!)
                    
                    self.getPetPhotos(counter: counter + 1)
                }
                
            } else { getPetPhotos(counter: counter + 1) }
             
        } else { globalData.flags.petPhotosOnBoard = true }
    }
    
    func getClinicDetails(counter: Int) {
        
        guard !globalData.clinics.isEmpty else { return }
        
        if counter < globalData.clinics.count {
            
            webServices!.getClinicScheduleAndVets(theClinicRecord: globalData.clinics[counter]) { (json, status) in
                
                guard self.webServices!.isErrorFree(json: json, status: status) else { return }
        
                if self.progressAlert != nil { self.progressAlert!.setProgressBar(value: Float(counter) / Float(globalData.clinics.count)) }
            
                var timeWindows = [VCTimeWindow]()
                var scheduleString: String = ""
                var doctorRecord = VCDoctorRecord()
                let dayOfWeekName = ["Su ", "Mo ", "Tu ", "We ", "Th ", "Fr ", "Sa "]
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
                    globalData.clinics[counter].clinicSchedule = scheduleString
                    globalData.clinics[counter].startTimeComponents = VCScheduleManager().getTimeSpan(span: timeWindows).from
                    globalData.clinics[counter].endTimeComponents = VCScheduleManager().getTimeSpan(span: timeWindows).to
                }
                
                // Get the vets
                globalData.clinics[counter].clinicDoctors.removeAll()
                
                for v in vets {
                    
                    let details = v as! NSDictionary
                    
                    if details["status"] as! String == "approve" {
                        
                        doctorRecord.doctorUID = (details["memberId"] as! Int)
                        doctorRecord.givenName = (details["givenName"] as! String)
                        doctorRecord.familyName = (details["familyName"] as! String)
                        
                        globalData.clinics[counter].clinicDoctors.append(doctorRecord)
                    }
                }
                
                // Get the services
                guard !globalData.clinics.isEmpty else { return }
                
                self.webServices!.getClinicServiceTypes(theClinicRecord: globalData.clinics[counter]) { (json, status) in
                    
                    guard self.webServices!.isErrorFree(json: json, status: status) else { return }
                    
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
                            globalData.clinics[counter].clinicServices.append(clinicService)
                        }
                        
                        else if televetServiceDownloaded && clinicService.serviceMedicalName.lowercased().contains("televet") { continue }
                       
                        else { globalData.clinics[counter].clinicServices.append(clinicService) }
                    }
                    
                    self.getClinicDetails(counter: counter + 1)
                }
            }
            
        } else {
            
            globalData.flags.clinicDetailsOnBoard = true
            if self.progressAlert != nil { self.progressAlert!.setProgressBar(value: 1.0) }
        }
    }
    
    // MARK: LOCATION SERVICES
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        if manager.authorizationStatus == .denied {
            
            homeController!.enableTabs()
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                
                self.alert!.popupMessage(aTitle: "Location Services Disabled", aMessage:
                                        
                    "The Vets Central app needs to determine your location in order to show you clinics in your area where you can make a consultation appointment. You can still login and manage your pets and access profile.\n\nTo fully use this app, go to the phone privacy settings and set location services for this app to \"While Using the App\"."
                )
            })
            
            completePreLoad()
        }
        
        else { getLocation() }
    }
     
    // MARK: CALL BACKS
    
    func clinicLoadResponse (json: NSDictionary, status: Bool) {
        
        guard self.webServices!.isErrorFree(json: json, status: status, showAlert: false) else {
            
            alert!.popupWithCustomButtons(aTitle: "Server Connection Error", aMessage: "The app can't proceed, please retry or exit the app", buttonTitles: ["RETRY","EXIT"], theStyle: [.default,.cancel]) { choice in
            
                if choice == 0 {
                    
                    self.webServices!.getClinicsNear(long: globalData.location.longitude, lat: globalData.location.latitude, radius: nil, callBack: self.clinicLoadResponse)
                    self.cleanup()
                    return
                    
                } else { exit(1) }
            }
            
            return
        }

        // All is good so clear any remnants for the clinics array
        globalData.clinics.removeAll()
        
        var clinicRecord = VCClinicRecord()
        
        // Travers and parse the json records
        for c in (json["clinics"] as! NSArray) {
            
            let clinicParams = c as! NSDictionary
            
            if clinicParams["id"] is NSNull || clinicParams["name"] is NSNull || clinicParams["lat"] is NSNull || clinicParams["lng"] is NSNull { continue }
            
            // Create a clinic data record
            clinicRecord.clinicUID = (clinicParams["id"] as! Int)
            clinicRecord.clinicName = (clinicParams["name"] as! String)
            clinicRecord.clinicLat = Double((clinicParams["lat"] as! String))!
            clinicRecord.clinicLng = Double((clinicParams["lng"] as! String))!
            
            let address = clinicParams["address"] as! NSDictionary
            
            if !(address["addressLine1"] is NSNull) { clinicRecord.clinicAddress.street = address["addressLine1"] as! String }
            if !(address["city"] is NSNull) { clinicRecord.clinicAddress.city = address["city"] as! String }
            if !(address["state"] is NSNull) { clinicRecord.clinicAddress.state = address["state"] as! String }
            if !(address["country"] is NSNull) { clinicRecord.clinicAddress.country = address["country"] as! String }
            if !(address["postalCode"] is NSNull) { clinicRecord.clinicAddress.postalCode = address["postalCode"] as! String }
            if !(clinicParams["clinic_phone"] is NSNull) { clinicRecord.clinicAddress.phone = clinicParams["clinic_phone"] as! String }
            
            // Append to the clinic array
            if clinicRecord.clinicLat != 0 && clinicRecord.clinicLng != 0 { globalData.clinics.append(clinicRecord) }
        }
        
        // If this is a re-login, continue on else return home
        if reLogin {
            
            reLogin = false
            self.webServices!.authorizeUser(dbCredentials: VCDBCredentials(userEmail: globalData.user.data.userEmail, userPassword: globalData.user.passwords.currentPassword), callBack: userLoginResponse)
            
        } else {
  
            globalData.flags.loginState = .awaitingLogin
            homeController!.setHomePageUIElements()
        }
    }
    
    func userLoginResponse(json: NSDictionary, status: Bool) {
        
        guard webServices!.isErrorFree(json: json, status: status) else { cleanup(); return }
        
        //if globalData.user.data.userEmail != homeController!.savedUser { VCKeychainServices().resetKeyChain() }
    
        globalData.tokens.bearerToken = json["token"] as! String
        
        let user = json["user"] as! NSDictionary
        globalData.user.data.userUID = (user["id"] as! Int)
        
        // Initiate the rest of the process in parallel
        apptDataDone = false
        userDataDone = false
        lookupsDone = false
      
        self.webServices!.getUser(userUID: globalData.user.data.userUID!, callBack: userLoadResponse)
        self.webServices!.getAppointments(userUID: globalData.user.data.userUID!, startDate: "2020-01-01", endDate: "2099-12-31", callBack: appointmentLoadResponse)
        self.webServices!.getPetLookups(callBack: lookupsLoadResponse)
        
        globalData.flags.clinicDetailsOnBoard = false
        DispatchQueue.main.async { self.getClinicDetails(counter: 0) }
        
        // Set a timer to break a race condition if it occurs
        deadlockTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(handleRaceTimer), userInfo: nil, repeats: true )
    }
    
    func userLoadResponse(json: NSDictionary, status: Bool) {
        
        guard webServices!.isErrorFree(json: json, status: status) else { return }
        
        var hasImage: Bool?
        var petRecord = VCPetRecord()
        let objectTest = VCAPITranslator()
        
        guard json["petOwner"] != nil && !objectTest.isNull(object: json["petOwner"]) else { cleanup(); alert!.popupMessage(aTitle: "User Data Error", aMessage: "There seems to be a problem logging in, please try again later"); return }
        
        // Get the user record contents
        let userData = json["petOwner"] as! NSDictionary
        
        if !objectTest.isNull(object: userData["memberID"]) { globalData.user.data.userUID = (userData["memberId"] as! Int) }
        if !objectTest.isNull(object: userData["email"]) { globalData.user.data.userEmail = userData["email"] as! String }
        if !objectTest.isNull(object: userData["givenName"]) { globalData.user.data.givenName = userData["givenName"] as! String }
        if !objectTest.isNull(object: userData["familyName"]) { globalData.user.data.familyName = userData["familyName"] as! String }
        if !objectTest.isNull(object: userData["phone"]) { globalData.user.data.phone = userData["phone"] as! String }
        
        if userData["address"] != nil && !objectTest.isNull(object: userData["address"]) {
            
            let address = userData["address"] as! NSDictionary
            
            if !objectTest.isNull(object:address["addressLine1"]) { globalData.user.data.address1 = address["addressLine1"] as! String }
            if !objectTest.isNull(object:address["addressLine2"]) { globalData.user.data.address2 = address["addressLine2"] as! String }
            if !objectTest.isNull(object:address["city"]) { globalData.user.data.city = address["city"] as! String }
            if !objectTest.isNull(object:address["state"]) { globalData.user.data.state = address["state"] as! String }
            if !objectTest.isNull(object:address["country"]) { globalData.user.data.country = address["country"] as! String }
            if !objectTest.isNull(object:address["postalCode"]) { globalData.user.data.postalCode = address["postalCode"] as! String }
        }
        
        // Get user's pets
        if !objectTest.isNull(object: userData["pets"]) {
            
            let pets = userData["pets"] as! NSArray
            
            for p in pets {
                
                // Each array element holds a dictionary
                let pet = p as! NSDictionary
                
                // Check for image
                if pet["profileUrl"] is NSNull { hasImage = false } else { hasImage = true }
                
                // Create a pet data record
                petRecord.petUID = (pet["id"] as! Int)
                petRecord.petName = (pet["petName"] as! String)
                petRecord.petSpecies = (pet["petType"] as! String)
                petRecord.petBreed = (pet["breed"] as! String)
                petRecord.petAge = (pet["petAge"] as! Int)
                petRecord.petGender = (pet["petSex"] as! String)
                petRecord.ownSince = (pet["owningSince"] as! String)
                petRecord.hasImage = hasImage!
                
                if hasImage! { petRecord.serverImageURL = (pet["profileUrl"] as! String) }
                
                // Append record to the pet array
                globalData.user.pets.append(petRecord)
            }
        }
        
        globalData.flags.petPhotosOnBoard = false
        DispatchQueue.main.async { self.getPetPhotos(counter: 0) }
        
        userDataDone = true
        if apptDataDone! && lookupsDone! { loginComplete() }
    }
    
    func appointmentLoadResponse (json: NSDictionary, status: Bool) {
        
        guard webServices!.isErrorFree(json: json, status: status) else { return }
        
        var appointmentRecord = VCAppointmentRecord()
        
        // Clear any remnants in the user clinics array
        globalData.user.currentAppointments.removeAll()
        globalData.user.pastAppointments.removeAll()
        
        let events = json["events"] as! NSArray
        
        // Traverse the appointment records
        for e in events {
            
            // Each array element holds a dictionary
            let appt = e as! NSDictionary
            
            let apptInfo = appt["appointmentInfo"] as! NSDictionary
            let participantInfo = appt["participants"] as! NSArray
            let petInfo = appt["petInfo"] as! NSDictionary
            let consultType = appt["consultType"] as! NSDictionary
            let clinicDetails = appt["clinicDetails"] as! NSDictionary
            
            // Create an appointment data record
            appointmentRecord.apptUID = (apptInfo["id"] as! Int)
            appointmentRecord.petUID = (petInfo["id"] as! Int)
            appointmentRecord.clinicUID = (appt["clinicId"] as! Int)
            appointmentRecord.clinicName = clinicDetails["name"] as! String
            appointmentRecord.apptReason = appt["title"] as! String
            appointmentRecord.apptStatus = appt["status"] as! String
            
            appointmentRecord.service.serviceID = (consultType["consultTypeId"] as! Int)
            appointmentRecord.service.serviceMedicalName = consultType["consultType"] as! String
            appointmentRecord.service.servicePlainName = consultType["consultSubType"] as! String
            appointmentRecord.service.serviceDescription = consultType["description"] as! String
            appointmentRecord.service.serviceTimeRequired = consultType["consultTimeRequired"] as! Int
            appointmentRecord.service.serviceFee = consultType["fee"] as! Int
            appointmentRecord.service.isDefault = consultType["isDefault"] as! Bool
            
            appointmentRecord.startDate = VCDate(fromServerDateAndTime: (appt["start"] as! String))
            appointmentRecord.endDate = VCDate(fromServerDateAndTime: (appt["end"] as! String))
            
            if appointmentRecord.apptStatus == "AWAITING" { appointmentRecord.apptStatus = "Pending Clinic Acceptance" }
            if appointmentRecord.apptStatus == "PAYMENT_PENDING" { appointmentRecord.apptStatus = "Pending Payment" }
        
            // Get current time and date
            var timeTolerance = appointmentRecord.endDate.dateComponents
            timeTolerance.hour! += 1
            
            let appointmentDateAndTime = NSCalendar.current.date(from: timeTolerance)
            let dateAndTimeComparison = appointmentDateAndTime!.compare(Date())
            
            // Get the doctor
            for p in participantInfo {
                
                let participant = (p as! NSDictionary)
                if participant["role"] as! String == "vc_veterinarian" { appointmentRecord.doctorUID = (participant["id"] as! Int); break}
            }
            
            // Append to appointment array
            if dateAndTimeComparison == ComparisonResult.orderedDescending || dateAndTimeComparison == ComparisonResult.orderedSame { globalData.user.currentAppointments.append(appointmentRecord) }
            else { globalData.user.pastAppointments.append(appointmentRecord) }
        }
        
        apptDataDone = true
        if userDataDone! && lookupsDone! { loginComplete() }
    }
    
    func lookupsLoadResponse (json: NSDictionary, status: Bool) {
        
        guard webServices!.isErrorFree(json: json, status: status) else { return }
       
        var lookupRecord = VCLookup()
      
        // Clear the lookup data
        globalData.reinitLookups()
        
        let lookupRecords = json["lookUps"] as! NSArray
        
        // Traverse the lookup records
        for l in lookupRecords {
            
            let lookupItems = l as! NSDictionary
            
            lookupRecord.lookupType = lookupItems["lookupType"] as! String
            lookupRecord.displayName = lookupItems["displayName"] as! String
            lookupRecord.description = lookupItems["description"] as! String
            lookupRecord.lookupValue = lookupItems["lookupValue"] as! String
            lookupRecord.lookupCode = lookupItems["lookupCode"] as! String
            
            if lookupRecord.displayName[lookupRecord.displayName.count - 1].lowercased() == "s" {lookupRecord.displayName = String(lookupRecord.displayName.partial(fromIndex: 0, length: lookupRecord.displayName.count - 1)) }
            
            // Append to lookup array
            switch lookupRecord.lookupType {
            
                case "species": globalData.lookups.speciesLookups.append(lookupRecord)
                case "gender": globalData.lookups.genderLookups.append(lookupRecord)
                case "breed": globalData.lookups.breedLookups.append(lookupRecord)
                default: break
            }
        }
        
        globalData.lookups.speciesLookups.sort() { $0.displayName < $1.displayName  }
        globalData.lookups.genderLookups.sort() { $0.displayName < $1.displayName  }
        globalData.lookups.breedLookups.sort() { $0.displayName < $1.displayName }
        
        homeController!.loginFormView.activityIndicator.isHidden = true
        homeController!.loginFormView.createAccountButton.setTitle("CREATE ACCOUNT", for: .normal)
        
        if globalData.flags.isCreateAccount {
            
            VCAlertServices(viewController: self.homeController!).popupYesNo(aTitle: "Welcome To Vets Central!", aMessage: "Your account has been created, would you like the app to remember your email and password?", aStyle: [.default,.default]) { choice in
                
                if choice == 0 {
                    
                    globalData.settings.rememberMe = true
                    _ = VCKeychainServices().writeData(data: globalData.settings.rememberMe, withKey: "auto")
                }
                
                globalData.messageService.addMessage(from: "Vets Central Team", title: "Welcome to Vets Central!", messageBody: "Welcome aboard!\n\nYou can now securely store your pet's information and medical documents in the system. You can also view the Vets Central member clinics in your area and set your preferred clinic.\n\nIn order to make a televet appointment, you'll first need to fill out the information in your account profile. You can do this at anytime by tapping the 'Profile' icon in the lower right of the screen.\n\nThanks for becoming a member of Vets Central!\n\nThe Vets Central Team")
                
                self.homeController!.loginFormView.hideView()
            }
        }
        
        lookupsDone = true
        if userDataDone! && apptDataDone! { loginComplete() }
    }
    
    func userCreateResponse(json: NSDictionary, status: Bool) {
       
        guard webServices!.isErrorFree(json: json, status: status) else { return }
        
        let keychainServices = VCKeychainServices()
        _ = keychainServices.writeData(data: globalData.user.passwords.currentPassword, withKey: "user")
        
        userDataDone = true
        apptDataDone = true
        
        // Flag account creation and pop to the account view
        globalData.tokens.bearerToken = json["token"] as! String
        globalData.flags.isCreateAccount = true
        
        homeController!.messageBadgeButton.isEnabled = true
        homeController!.messageAlertButton.isEnabled = true
        homeController!.settingsButton.isEnabled = true
        homeController!.messageAlertButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: { return })
        homeController!.settingsButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: { return })
        
        // Get the user UID and clear any setting remnants
        let userData = json["user"] as! NSDictionary
        globalData.user.data.userUID = (userData["id"] as! Int)
        self.webServices!.getPetLookups(callBack: lookupsLoadResponse)
    }
    
    func loginComplete () {
        
        deadlockTimer.invalidate()
        
        // Sort the appointments
        globalData.user.currentAppointments.sort() { $0.startDate.theDate! < $1.startDate.theDate! }
    
        // Save the userid and password securely
        let vcKeyChain = VCKeychainServices()
        
        _ = vcKeyChain.writeData(data: globalData.user.data.userEmail, withKey: "user")
        _ = vcKeyChain.writeData(data: globalData.user.passwords.currentPassword, withKey: "password")
        
        // Clear plain text password for security
        globalData.user.passwords.reinit()
        
        // Update login state
        globalData.flags.loginState = .loggedIn
        
        // Check if the profile address includes a state
        if globalData.user.data.country == "Israel" || globalData.user.data.country == "Hong Kong Special Administrative Region" { globalData.flags.hasState = false }
        else { globalData.flags.hasState = true }
    
        // Return home
        homeController!.enableTabs()
        homeController!.setHomePageUIElements()
        globalData.startTimers()
    }
    
    func noClinicsRecovery(action: Bool) {
        
        if action { self.webServices!.getClinicsNear(long: globalData.location.longitude, lat: globalData.location.latitude, radius: 200, callBack: clinicLoadResponse) }
        else { exit(1) }
    }
    
    // MARK: ACTION HANDLERS
    
    @objc func handleRaceTimer () { if userDataDone! && apptDataDone! && lookupsDone! { loginComplete() } }
    
    // MARK: TIME STAMP LOGGING METHOD
    
    func logTimeStamp (forStep: String) {
        
        let currentTimeStamp : Double = NSDate().timeIntervalSince1970 * 1000
        lastTimeStamp = currentTimeStamp
    }
}
