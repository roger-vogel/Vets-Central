//
//  VCRefreshServices.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/20/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit
import MapKit

class VCRefreshServices: NSObject {

    var parentController: VCHomeViewController?
    var petCounter: Int = 0
    var clinicCounter: Int = 0
    var lastTimeStamp: Double = 0
    var locationManager = CLLocationManager()
    var password: String?
    var canceledApptUIDs = [Int]()
    var newApptUIDs = [Int]()
    var newTimeUIDs = [Int]()
    var newStatusUIDs = [Int]()
    var refreshWebServices: VCWebServices?
   
    // MARK: INITIALIZATION
    
    init (parent: VCHomeViewController? = nil) { super.init()
        
        parentController = parent
        refreshWebServices = VCWebServices(callFromRefresh: true)
    }
    
    func refresh () {
    
        //print ("*** REFRESHING ***")
        
        // Get the password
        password = VCKeychainServices().readString(withKey: "password")
        guard password != nil else { refreshComplete(isTerminated: true); return }
        
        // Begin the refresh process
        refreshWebServices!.getClinicsNear(long: globalData.location.longitude, lat: globalData.location.latitude, radius: 100, callBack: clinicLoadResponse)
    }
    
    // MARK: METHODS
    
    func checkForChanges() {
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
        
        canceledApptUIDs.removeAll()
        newApptUIDs.removeAll()
        newTimeUIDs.removeAll()
        newStatusUIDs.removeAll()
        
        // Check if an appointment is in global data but is not in refresh data; that is a cancelled appointment
        for a in globalData.user.currentAppointments {
            
            let currentRefreshAppointment = VCRecordGetter().appointmentWith(uid: a.apptUID!, fromData: refreshData.user.currentAppointments)
            let pastRefreshAppointment = VCRecordGetter().appointmentWith(uid: a.apptUID!, fromData: refreshData.user.pastAppointments)
         
            if currentRefreshAppointment != nil || pastRefreshAppointment != nil { continue }
            else { canceledApptUIDs.append(a.apptUID!) }
        }
        
        // Check if an appointment in refresh data is not in global data; that is a new appointment
        for a in refreshData.user.currentAppointments {
            
            let currentAppointment = VCRecordGetter().appointmentWith(uid: a.apptUID!, fromData: globalData.user.currentAppointments)
        
            if currentAppointment != nil { continue }
            else { newApptUIDs.append(a.apptUID!) }
        }
        
        // Check each refresh data appointment against global data appointment and compare the start date components
        for a in globalData.user.currentAppointments {
            
            let refreshAppointment = VCRecordGetter().appointmentWith(uid: a.apptUID!, fromData: refreshData.user.currentAppointments)
            
            if refreshAppointment == nil { continue }
            else { if a.startDate |!=| refreshAppointment!.startDate { newTimeUIDs.append(a.apptUID!) } }
        }
        
        // Check each refresh data appointment against global data appointment and compare status
        for a in globalData.user.currentAppointments {
            
            let currentAppointment = VCRecordGetter().appointmentWith(uid: a.apptUID!, fromData: globalData.user.currentAppointments)
            let refreshAppointment = VCRecordGetter().appointmentWith(uid: a.apptUID!, fromData: refreshData.user.currentAppointments)
        
            if currentAppointment != nil && refreshAppointment != nil { if currentAppointment!.apptStatus != refreshAppointment!.apptStatus { newStatusUIDs.append(a.apptUID!)} }
            
        }
        
        // Create messages - cancelled appointments
        for a in canceledApptUIDs {
            
            let appointment = VCRecordGetter().appointmentWith(uid: a, fromData: globalData.user.currentAppointments)
           
            if appointment != nil {
                
                let timeAndDateString = appointment!.startDate.dateAndTimeString
                globalData.messageService.addMessage(from: "Vets Central Admin", title: "Cancellation", messageBody: "Your appointment on " + timeAndDateString + " has been canceled")
            }
        }
        
        // Create messages - new appointments
        for a in newApptUIDs {
            
            let appointment = VCRecordGetter().appointmentWith(uid: a, fromData: refreshData.user.currentAppointments)
      
            if appointment != nil {
                
                let timeAndDateString = appointment!.startDate.dateAndTimeString
                globalData.messageService.addMessage(from: "Vets Central Admin", title: "New appointment", messageBody: "Your have a new appointment on " + timeAndDateString)
            }
        }
        
        // Create messages - time change
        for a in newTimeUIDs {
            
            let currentAppointment = VCRecordGetter().appointmentWith(uid: a, fromData: globalData.user.currentAppointments)
            let refreshAppointment = VCRecordGetter().appointmentWith(uid: a, fromData: refreshData.user.currentAppointments)
  
            if currentAppointment != nil && refreshAppointment != nil {
                
                let currentTimeAndDateString = currentAppointment!.startDate.dateAndTimeString
                let refreshTimeAndDateString = refreshAppointment!.startDate.dateAndTimeString
                
                globalData.messageService.addMessage(from: "Vets Central Admin", title: "Appointment Time Change", messageBody: "Your appointment on " + currentTimeAndDateString + " has been changed to " + refreshTimeAndDateString)
            }
        }
        
        // Create messages - status change
        for a in newStatusUIDs {
            
            let refreshAppointment = VCRecordGetter().appointmentWith(uid: a, fromData: refreshData.user.currentAppointments)
        
            if refreshAppointment != nil {
                
                let refreshTimeAndDateString = refreshAppointment!.startDate.dateAndTimeString
                globalData.messageService.addMessage(from: "Vets Central Admin", title: "Appointment Status Change", messageBody: "The status for your appointment on " + refreshTimeAndDateString + " has been changed")
            }
        }
        
        if parentController!.appointmentController.appointmentTable != nil { parentController!.appointmentController.appointmentTable.reloadData() }
        if parentController!.petController.petCollectionView != nil { parentController!.petController.petCollectionView.reloadData() }
       
    }
    
    func getPetPhotos(counter: Int){
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
       
        guard !globalData.user.pets.isEmpty else {
            
            getClinicDetails(counter: 0)
            refreshComplete(isTerminated: true)
          
            return
        }
     
        if counter < refreshData.user.pets.count {
            
            let thePet = refreshData.user.pets[counter]
          
            if thePet.hasImage {
                
                self.refreshWebServices!.downloadPetPhoto(thePetRecord: thePet) { (data, status) in
                    
                    guard !refreshData.user.pets.isEmpty else { self.refreshComplete(isTerminated: true); return }
                    
                    if status || data == nil {
                        
                        self.refreshComplete(isTerminated: true);
                        return
                    }
                    
                    refreshData.user.petImages[refreshData.user.pets[counter].petUID!] = UIImage(data: data!)
                    
                    self.getPetPhotos(counter: counter + 1)
                }
                
            } else { getPetPhotos(counter: counter + 1) }
             
        } else {
            
            globalData.flags.petPhotosOnBoard = true
            getClinicDetails(counter: 0)
        }
    }
    
    func getClinicDetails(counter: Int) {
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
        guard !refreshData.clinics.isEmpty else { refreshComplete(); return }
       
        if counter < refreshData.clinics.count {
            
            self.refreshWebServices!.getClinicScheduleAndVets(theClinicRecord: refreshData.clinics[counter]) { (json, status) in
                
                guard self.refreshWebServices!.isErrorFree(json: json, status: status, showAlert: false) else { self.refreshComplete(isTerminated: true); return }
                
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
                    refreshData.clinics[counter].clinicSchedule = scheduleString
                    refreshData.clinics[counter].startTimeComponents = VCScheduleManager().getTimeSpan(span: timeWindows).from
                    refreshData.clinics[counter].endTimeComponents = VCScheduleManager().getTimeSpan(span: timeWindows).to
                }
                
                // Get the vets
                refreshData.clinics[counter].clinicDoctors.removeAll()
                
                for v in vets {
                    
                    let details = v as! NSDictionary
                    
                    if details["status"] as! String == "approve" {
                        
                        doctorRecord.doctorUID = (details["memberId"] as! Int)
                        doctorRecord.givenName = (details["givenName"] as! String)
                        doctorRecord.familyName = (details["familyName"] as! String)
                        
                        refreshData.clinics[counter].clinicDoctors.append(doctorRecord)
                    }
                }
                
                // Get the services
                guard !refreshData.clinics.isEmpty else { self.refreshComplete(isTerminated: true); return }
                
                self.refreshWebServices!.getClinicServiceTypes(theClinicRecord: refreshData.clinics[counter]) { (json, status) in
                    
                    guard !refreshData.clinics.isEmpty else { self.refreshComplete(isTerminated: true); return }
                    guard self.refreshWebServices!.isErrorFree(json: json, status: status) else { self.refreshComplete(isTerminated: true); return }
                    
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
                            refreshData.clinics[counter].clinicServices.append(clinicService)
                        }
                        
                        else if televetServiceDownloaded && clinicService.serviceMedicalName.lowercased().contains("televet") { continue }
                       
                        else { refreshData.clinics[counter].clinicServices.append(clinicService) }
                    }
                    
                    self.getClinicDetails(counter: counter + 1)
                }
            }
            
        } else {
            
            globalData.flags.clinicDetailsOnBoard = true
            refreshComplete()
        }
    }
    
    // MARK: CALL BACKS
    
    func clinicLoadResponse (json: NSDictionary, status: Bool) {
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
        guard self.refreshWebServices!.isErrorFree(json: json, status: status, showAlert: false) else { refreshComplete(isTerminated: true); return }
        
        var clinicRecord = VCClinicRecord()
      
        // All is good so clear any remnants for the clinics array
        refreshData.clinics.removeAll()
        
        // Travers and parse the json records
        for c in (json["clinics"] as! NSArray) {
            
            let clinicParams = c as! NSDictionary
            
            // Check for valid data
            if clinicParams["id"] == nil || clinicParams["name"] == nil || clinicParams["lat"] == nil || clinicParams["lng"] == nil { continue }
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
            if clinicRecord.clinicLat != 0 && clinicRecord.clinicLng != 0  { refreshData.clinics.append(clinicRecord) }
        }
        
        refreshWebServices!.authorizeUser(dbCredentials: VCDBCredentials(userEmail: globalData.user.data.userEmail, userPassword: password!), callBack: userLoginResponse)
    }
    
    func userLoginResponse(json: NSDictionary, status: Bool) {
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
        guard self.refreshWebServices!.isErrorFree(json: json, status: status, showAlert: false) else { refreshComplete(isTerminated: true); return }
 
        refreshData.tokens.bearerToken = json["token"] as! String
        
        let user = json["user"] as! NSDictionary
        refreshData.user.data.userUID = (user["id"] as! Int)
        
        refreshWebServices!.getUser(userUID: refreshData.user.data.userUID!, callBack: userLoadResponse)
    }
    
    func userLoadResponse(json: NSDictionary, status: Bool) {
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
        guard self.refreshWebServices!.isErrorFree(json: json, status: status, showAlert: false) else { refreshComplete(isTerminated: true); return }
        
        var hasImage: Bool?
        var petRecord = VCPetRecord()
        let objectTest = VCAPITranslator()
        
        guard json["petOwner"] != nil && !objectTest.isNull(object: json["petOwner"]) else { refreshComplete(isTerminated: true); return }
        
        // Get the user record contents
        let userData = json["petOwner"] as! NSDictionary
        
        if !objectTest.isNull(object: userData["memberID"]) { refreshData.user.data.userUID = (userData["memberId"] as! Int) }
        if !objectTest.isNull(object: userData["email"]) { refreshData.user.data.userEmail = userData["email"] as! String }
        if !objectTest.isNull(object: userData["givenName"]) {refreshData.user.data.givenName = userData["givenName"] as! String }
        if !objectTest.isNull(object: userData["familyName"]) { refreshData.user.data.familyName = userData["familyName"] as! String }
        if !objectTest.isNull(object: userData["phone"]) { refreshData.user.data.phone = userData["phone"] as! String }
        
        if userData["address"] != nil && !objectTest.isNull(object: userData["address"]) {
            
            let address = userData["address"] as! NSDictionary
            
            if !objectTest.isNull(object:address["addressLine1"]) { refreshData.user.data.address1 = address["addressLine1"] as! String }
            if !objectTest.isNull(object:address["addressLine2"]) { refreshData.user.data.address2 = address["addressLine2"] as! String }
            if !objectTest.isNull(object:address["city"]) { refreshData.user.data.city = address["city"] as! String }
            if !objectTest.isNull(object:address["state"]) { refreshData.user.data.state = address["state"] as! String }
            if !objectTest.isNull(object:address["country"]) { refreshData.user.data.country = address["country"] as! String }
            if !objectTest.isNull(object:address["postalCode"]) { refreshData.user.data.postalCode = address["postalCode"] as! String }
        }
        
        // Get user's pets
        refreshData.user.pets.removeAll()
        
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
                refreshData.user.pets.append(petRecord)
            }
        }
        
        refreshWebServices!.getAppointments(userUID: refreshData.user.data.userUID!, startDate: "2021-01-01", endDate: "2099-12-31", callBack: appointmentLoadResponse)
    }
    
    func appointmentLoadResponse (json: NSDictionary, status: Bool) {
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
        guard self.refreshWebServices!.isErrorFree(json: json, status: status, showAlert: false) else { refreshComplete(isTerminated: true); return }
        
        var appointmentRecord = VCAppointmentRecord()
    
        // Clear any remnants in the user clinics array
        refreshData.user.currentAppointments.removeAll()
        refreshData.user.pastAppointments.removeAll()
        
        let events = json["events"] as! NSArray
        
        // Traverse the appointment records
        for e in events {
            
            // Each array element holds a dictionary
            let appt = e as! NSDictionary
            
            let apptInfo = appt["appointmentInfo"] as! NSDictionary
            let petInfo = appt["petInfo"] as! NSDictionary
            let clinicDetails = appt["clinicDetails"] as! NSDictionary
            
            // Create an appointment data record
            appointmentRecord.apptUID = (apptInfo["id"] as! Int)
            appointmentRecord.petUID = (petInfo["id"] as! Int)
            appointmentRecord.clinicUID = (appt["clinicId"] as! Int)
            appointmentRecord.apptReason = appt["title"] as! String
            appointmentRecord.apptStatus = appt["status"] as! String
            appointmentRecord.clinicName = clinicDetails["name"] as! String
            
            appointmentRecord.startDate = VCDate(fromServerDateAndTime: (appt["start"] as! String))
            appointmentRecord.endDate =  VCDate(fromServerDateAndTime: (appt["end"] as! String))
            
            if appointmentRecord.apptStatus == "AWAITING" { appointmentRecord.apptStatus = "Pending Clinic Acceptance" }
            if appointmentRecord.apptStatus == "PAYMENT_PENDING" { appointmentRecord.apptStatus = "Pending Payment" }
        
            // Get current time and date
            var timeTolerance = appointmentRecord.endDate.dateComponents
            timeTolerance.hour! += 1
            
            let appointmentDateAndTime = NSCalendar.current.date(from: timeTolerance)
            let dateAndTimeComparison = appointmentDateAndTime!.compare(Date())
    
            // Append to appointment array
            if dateAndTimeComparison == ComparisonResult.orderedDescending || dateAndTimeComparison == ComparisonResult.orderedSame || globalData.openedAppointment == appointmentRecord.apptUID! {
                
                let anApptRecord = VCRecordGetter().appointmentWith(uid: appointmentRecord.apptUID!, fromData: refreshData.user.currentAppointments)
                
                if anApptRecord != nil {
                    
                    appointmentRecord.upComingHasIssued = anApptRecord!.upComingHasIssued
                    appointmentRecord.startHasBeenIssued = anApptRecord!.startHasBeenIssued
                }
 
                refreshData.user.currentAppointments.append(appointmentRecord)
            }
            
            else { refreshData.user.pastAppointments.append(appointmentRecord) }
        }
        
        refreshWebServices!.getPetLookups(callBack: lookupsLoadResponse)
    }
    
    func lookupsLoadResponse (json: NSDictionary, status: Bool) {
        
        guard globalData.flags.refreshInProgress && globalData.flags.loginState == .loggedIn else { refreshComplete(isTerminated: true); return }
        guard self.refreshWebServices!.isErrorFree(json: json, status: status, showAlert: false) else { refreshComplete(isTerminated: true); return }
        
        var lookupRecord = VCLookup()
        
        // Clear any remnants in the user clinics array
        refreshData.lookups.genderLookups.removeAll()
        refreshData.lookups.speciesLookups.removeAll()
        refreshData.lookups.breedLookups.removeAll()
        
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
            
            case "species": refreshData.lookups.speciesLookups.append(lookupRecord)
            case "gender": refreshData.lookups.genderLookups.append(lookupRecord)
            case "breed": refreshData.lookups.breedLookups.append(lookupRecord)
            default: break
            }
        }
        
        refreshData.lookups.speciesLookups.sort() { $0.displayName < $1.displayName  }
        refreshData.lookups.genderLookups.sort() { $0.displayName < $1.displayName  }
        refreshData.lookups.breedLookups.sort() { $0.displayName < $1.displayName }
        
        getPetPhotos(counter: 0)
    }
    
    func refreshComplete (isTerminated: Bool? = false ) {
        
        //print("*** REFRESH COMPLETE ***")
        
        guard !isTerminated! else {
            
            globalData.flags.lastRefreshSuceeded = false
            globalData.flags.refreshInProgress = false
            globalData.flags.refreshTerminated = false
            globalData.executeQueuedTasks()
            
            return
        }
        
        let preferredClinic = globalData.user.data.preferredClinicUID
        
        checkForChanges()
        
        globalData.tokens = refreshData.tokens
        globalData.user.data = refreshData.user.data
        globalData.user.currentAppointments = refreshData.user.currentAppointments
        globalData.clinics = refreshData.clinics
        globalData.lookups = refreshData.lookups
        globalData.user.data.preferredClinicUID = preferredClinic
        
        // Remove cancelled appointments
        var indices = [Int]()
        
        for (index, value) in globalData.user.currentAppointments.enumerated() {
            
            if canceledApptUIDs.contains(value.apptUID!) { indices.append(index) }
        }
        
        // Remove cancelled appointments
        for i in indices { globalData.user.currentAppointments.remove(at: i) }
    
        if parentController!.appointmentController.appointmentTable != nil { parentController!.appointmentController.appointmentTable.reloadData() }
    
        if canceledApptUIDs.count > 0 && parentController!.tabBarController?.selectedViewController == parentController!.appointmentController {
            
            VCAlertServices(viewController: parentController!).popupMessage(aMessage: "A clinic has canceled your appointment, see your messages for more info")
            canceledApptUIDs.removeAll()
        }
        
        parentController!.setBadges()
        globalData.flags.refreshInProgress = false
        
        // Execute any tasks that were delayed due to refresh
        globalData.executeQueuedTasks()
    }
}

 
 
