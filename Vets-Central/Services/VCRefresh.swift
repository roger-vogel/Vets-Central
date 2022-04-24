//
//  VCRefresh.swift
//  Vets-Central
//
//  Created by Roger Vogel on 10/22/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCRefresh: NSObject {
    
    /// PROPERTIES
    
    var parentController: VCHomeViewController?
    var localData = VCGlobalData()
    var petCounter: Int = 0
    var clinicCounter: Int = 0
    
    /// INITIALIZATION
    
    init (parent: VCHomeViewController? = nil) { super.init()
        
        parentController = parent
    }
    
    /// PIUBLIC METHODS
    
    func refresh() {
        
        petCounter = 0
        clinicCounter = 0
        vcGlobalData.lastRefresh = false
        
        localData = vcGlobalData
        localData.vcClinics.getClinics(theCallBack: clinicLoadResponse)
    }
    
    /// PRIVATE METHODS
    
    // Preload clinics for map view when not logged in
    private func clinicLoadResponse (json: NSDictionary, status: Bool) {
        
        var clinicRecord = VCClinicRecord()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { vcGlobalData.lastRefresh = false; return }
        
        // All is good so clear any remnants for the clinics array
        localData.vcClinics.clinics.removeAll()
      
        // Travers and parse the json records
        for c in (json["clinics"] as! NSArray) {
            
            let clinicParams = c as! NSDictionary
            
            // Check for valid data
            if clinicParams["id"] == nil || clinicParams["name"] == nil || clinicParams["lat"] == nil || clinicParams["lng"] == nil { continue }
            if clinicParams["id"] is NSNull || clinicParams["name"] is NSNull || clinicParams["lat"] is NSNull || clinicParams["lng"] is NSNull { continue }
            
            // Create a clinic data record
            // Create a clinic data record
            clinicRecord.clinicUID = String(clinicParams["id"] as! Int)
            clinicRecord.clinicName = (clinicParams["name"] as! String)
            clinicRecord.clinicLat = Double((clinicParams["lat"] as! String))!
            clinicRecord.clinicLng = Double((clinicParams["lng"] as! String))!
            
            // Append to the clinic array
            localData.vcClinics.clinics.append(clinicRecord)
        }
   
        localData.vcUser.data.password = VCKeychainServices().readString(withKey: "vcpassword")!
        localData.vcUser.authorizeUser(theCallBack: userLoginResponse)
    }
        
    // Login
    private func userLoginResponse(json: NSDictionary, status: Bool) {
    
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { vcGlobalData.lastRefresh = false; return }
            
        localData.bearerToken = json["token"] as! String
        
        let user = json["user"] as! NSDictionary
        localData.vcUser.data.userUID = String(user["id"] as! Int)
            
        // Initiate user record retrieval
        localData.vcUser.getUser(theUserID: vcGlobalData.vcUser.data.userUID, theCallBack: userLoadResponse)
    }
    
    private func userLoadResponse(json: NSDictionary, status: Bool) {
    
        let objectTest = VCAPITranslator()
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { vcGlobalData.lastRefresh = false; return }
        
        let userData = json["member"] as! NSDictionary
        
        if !objectTest.isNull(object: userData["memberID"]) { localData.vcUser.data.userUID = String(userData["memberId"] as! Int) }
        if !objectTest.isNull(object: userData["email"]) { localData.vcUser.data.userEmail = userData["email"] as! String }
        if !objectTest.isNull(object: userData["givenName"]) { localData.vcUser.data.givenName = userData["givenName"] as! String }
        if !objectTest.isNull(object: userData["familyName"]) { localData.vcUser.data.familyName = userData["familyName"] as! String }
        if !objectTest.isNull(object: userData["phone"]) { localData.vcUser.data.phone = userData["phone"] as! String }
        
        if userData["address"] != nil && !objectTest.isNull(object: userData["address"]) {
            
            let address = userData["address"] as! NSDictionary
            
            if !objectTest.isNull(object:address["addressLine1"]) { localData.vcUser.data.address1 = address["addressLine1"] as! String }
            if !objectTest.isNull(object:address["addressLine2"]) { localData.vcUser.data.address2 = address["addressLine2"] as! String }
            if !objectTest.isNull(object:address["city"]) { localData.vcUser.data.city = address["city"] as! String }
            if !objectTest.isNull(object:address["state"]) { localData.vcUser.data.state = address["state"] as! String }
            if !objectTest.isNull(object:address["country"]) { localData.vcUser.data.country = address["country"] as! String }
            if !objectTest.isNull(object:address["postalCode"]) { localData.vcUser.data.postalCode = address["postalCode"] as! String }
        }
        
        // Clear any password data that was used
        localData.vcUser.data.password = ""
        
        // Initiate pet record retrieval
        localData.vcUser.getAllPets(theCallBack: petLoadResponse)
    }
    
    // Pet chain
    private func petLoadResponse (json: NSDictionary, status: Bool) {
        
        var hasImage: Bool?
        var petRecord = VCPetRecord()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { vcGlobalData.lastRefresh = false; return }
        
        // Clear any remnants in the pets array
        localData.vcUser.pets.removeAll()
        
        let pets = json["petDetails"] as! NSArray
        
        // Traverse the pet records
        for p in pets {
            
            // Each array element holds a dictionary
            let pet = p as! NSDictionary
            
            // Check for image
            if pet["profileUrl"] is NSNull { hasImage = false } else { hasImage = true }
            
            // Create a pet data record
            petRecord.petUID = String(pet["id"] as! Int)
            petRecord.petName = String(pet["petName"] as! String)
            petRecord.petSpecies = (pet["petType"] as! String)
            petRecord.petBreed = (pet["breed"] as! String)
            petRecord.petAge = (pet["petAge"] as! Int)
            petRecord.petGender = (pet["petSex"] as! String)
            petRecord.ownSince = (pet["owningSince"] as! String)
            petRecord.hasImage = hasImage!
            
            if hasImage! { petRecord.serverImageURL = (pet["profileUrl"] as! String) }
    
            // Append record to the pet array
            localData.vcUser.pets.append(petRecord)
        }
        
        getPetPhotos()
    }
    
    private func getPetPhotos() {
        
        if petCounter < localData.vcUser.pets.count {
            
            let thePet = localData.vcUser.pets[petCounter]
            if thePet.hasImage { localData.vcUser.downloadPetPhoto(aPetRecord: thePet, theCallBack: petPhotoLoadResponse) }
            else { petPhotoLoadResponse(data: nil, status: true) }
        }
        else { getDoctors() }
    }
    
    private func petPhotoLoadResponse (data: Data?, status: Bool) {
        
        // Guard against communication errors
        guard status && data != nil else { vcGlobalData.lastRefresh = false; return }
        
        vcGlobalData.petImages[vcGlobalData.vcUser.pets[petCounter].petUID] = UIImage(data: data!)
        petCounter += 1
       
        getPetPhotos()
    }
    
    // Clinic chain
    private func getDoctors() {
        
        // Loop to get doctors for each clinic then exit
        if clinicCounter < vcGlobalData.vcClinics.clinics.count {
            
            let uid = vcGlobalData.vcClinics.clinics[clinicCounter].clinicUID
            vcGlobalData.vcClinics.getDoctors(aClinicUID: uid, theCallBack: doctorLoadResponse)
        }
        
        else { loginComplete() }
    
        // Initiate appointment record retrieval
        // globalData.userEntity.getAppointments(theCallBack: appointmentLoadResponse)
    }
  
    private func doctorLoadResponse (json: NSDictionary, status: Bool) {
        
        var doctorRecord = VCDoctorRecord()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { vcGlobalData.lastRefresh = false; return }
        
        let doctors = json.value(forKey: "members") as! NSArray
        
        for d in doctors {
            
            let details = d as! NSDictionary
            
            if details["status"] as! String == "approve" {
                
                doctorRecord.doctorUID = String(details["memberId"] as! Int)
                doctorRecord.givenName = (details["givenName"] as! String)
                doctorRecord.familyName = (details["familyName"] as! String)
                
                localData.vcClinics.clinics[clinicCounter].clinicDoctors.append(doctorRecord)
            }
            
        }
        
        // Continue loop until all clinics are accessed
        clinicCounter += 1
        getDoctors()
    }
    
    private func getClinicSchedules() {
        
        // Loop to get schedule for each clinic then exit
        if clinicCounter < vcGlobalData.vcClinics.clinics.count {
            
            localData.vcClinics.getClinicSchedule(aClinicRecord: vcGlobalData.vcClinics.clinics[clinicCounter], theCallBack: clinicScheduleLoadResponse)
        }
        
        else { getDoctors() }
    }
    
    private func clinicScheduleLoadResponse (json: NSDictionary, status: Bool) {
        
        var scheduleString: String = "Schedule: "
        let dayOfWeekName = ["Mo-", "Tu-", "We-", "Th-", "Fr", "Sa", "Su"]
        
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { vcGlobalData.lastRefresh = false; return }
        
        let schedule = json.value(forKey: "schedule") as! NSArray
        
        if schedule.count != 0 {
            
            let schedParams = schedule[0] as! NSDictionary
            
//          let startDate = schedParams.value(forKey: "startDate") as! String
//          let endDate = schedParams.value(forKey: "endDate") as! String
            
            let availableTimes = (schedParams.value(forKey: "availableTimes") as! NSArray)[0] as! NSDictionary
            let fromTime = availableTimes["from"] as! String
            let toTime = availableTimes["to"] as! String
            let dayOfWeek = schedParams.value(forKey: "dayOfWeek") as! NSArray
            
            for d in 0...(dayOfWeek.count-1) { if (dayOfWeek[d] as! Int) > 0 { scheduleString += dayOfWeekName[d] } }
            scheduleString += " from " + fromTime + " to " + toTime
            
            vcGlobalData.vcClinics.clinics[clinicCounter].clinicSchedule = scheduleString
        }
        
        // Continue loop until all clinics are accessed
        clinicCounter += 1
        getClinicSchedules()
        
    }

    // Appointment chain
    private func appointmentLoadResponse (json: NSDictionary, status: Bool) {
        
        var appointmentRecord = VCAppointmentRecord()
    
         let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
         guard success.status else { vcGlobalData.lastRefresh = false; return }

        // Clear any remnants in the user clinics array
        vcGlobalData.vcUser.appointments.removeAll()
        
        let events = json["events"] as! NSArray
        
        // Traverse the appointment records
        for e in events {
            
            // Each array element holds a dictionary
            let appt = e as! NSDictionary
            
            let apptInfo = appt["appointmentInfo"] as! NSDictionary
            let petInfo = appt["petInfo"] as! NSDictionary
      
            // Create an appointment data record
            appointmentRecord.apptUID = apptInfo["id"] as! String
            appointmentRecord.petUID = petInfo["id"] as! String
            appointmentRecord.clinicUID =  appt["clinicId"] as! String
            appointmentRecord.apptDateAndTime = appt["start"] as! String
            appointmentRecord.apptReason = appt["title"] as! String
            appointmentRecord.apptStatus = appt["status"] as! String
            
            if appointmentRecord.apptStatus == "AWAITING" { appointmentRecord.apptStatus = "PENDING" }
                   
            // Append to appointment array
            vcGlobalData.vcUser.appointments.append(appointmentRecord)
        }
        
        // Chain is complete; exit the chain
        loginComplete()
    }
    
    // Chain complete
    private func loginComplete () {
        
        print ("   *** refresh complete ***    ")
        
        vcGlobalData.isLoggedIn = true
        vcGlobalData.isLocked = true
        vcGlobalData = localData
        vcGlobalData.isLocked = false
        vcGlobalData.lastRefresh = true
        
        parentController!.setWelcomeMessage()
        parentController!.setAppointmentBadge(apptQty: vcGlobalData.vcUser.appointments.count)
    }
    
    /// CLINIC LOAD FAILURE CALLBACK
    
    private func noClinicsRecovery(action: Bool) {
        
        if action { vcGlobalData.vcClinics.getClinics(theCallBack: clinicLoadResponse) }
        else { exit(1) }
    }

}
