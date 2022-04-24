//
//  VCStructures.swift
//  Vets-Central
//
//  Database Record Structures
//  Created by Roger Vogel on 5/30/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

// MARK: INTERNAL DATA STRUCTURES

struct VCUser {
    
    var data = VCUserRecord()
    var pets = [VCPetRecord]()
    var petImages: Dictionary = [Int:UIImage]()
    var currentAppointments = [VCAppointmentRecord]()
    var pastAppointments = [VCAppointmentRecord]()
    var passwords = VCDBPassword()
    
    mutating func reinit() {
        
        data.reinit()
        pets.removeAll()
        petImages.removeAll()
        passwords.reinit()
        currentAppointments.removeAll()
        pastAppointments.removeAll()
    }
    
    func hasAppointment(petUID: Int)-> Bool {
        
        for a in currentAppointments { if a.petUID == petUID { return true } }
        
        return false
    }
    
    func getAppointmentsFor(petUID: Int) -> [Int] {
        
        var indices = [Int]()
        
        for (index,value) in currentAppointments.enumerated() {
            
            if value.petUID == petUID { indices.append(index) }
        }
        
        return indices
    }
}

struct VCUserRecord {
    
    var userUID: Int?
    var userEmail: String
    var givenName: String
    var familyName: String
    var country: String
    var address1: String
    var address2: String
    var city: String
    var state: String
    var postalCode: String
    var phone: String
    var preferredClinicUID: Int?
    var mapClinicUID: Int?
    
    // MARK: INITIALIZER
    init () { userEmail = ""; givenName = ""; familyName = ""; country = ""; address1 = ""; address2 = ""; city = ""; state = ""; postalCode = ""; phone = ""; userUID = nil; preferredClinicUID = nil; mapClinicUID = nil }
    
    // MARK: RE-INIT
    mutating func reinit() { userEmail = ""; givenName = ""; familyName = ""; country = ""; address1 = ""; address2 = ""; city = ""; state = ""; postalCode = ""; phone = ""; userUID = nil; preferredClinicUID = nil; mapClinicUID = nil }
        
    // MARK: COMPLETENESS TEST
    func isComplete (hasState: Bool? = true ) -> Bool {
        
        if userEmail == "" || givenName == "" || familyName == "" || country == "" || address1 == "" || city == "" || phone == "" { return false }
        if hasState! && state == "" { return false }
        else { return true }
    }
    
    // MARK: OTHER METHODS
    func getAddressString () -> String { return (address1 + ", " + address2 + ", " + city + ", " + state + " " + postalCode + " " + country) }
}

struct VCPetRecord {
    
    var petUID: Int?
    var petName: String
    var petSpecies: String
    var petBreed: String
    var petAge: Int = 0
    var petGender: String
    var ownSince: String
    var hasImage: Bool
    var serverImageURL: String
    var docMetadata = [VCDocMetadata]()
    var metadataIsDownloaded: Bool
    var isValid: Bool
 
    // MARK: INITIALIZER
    init () { petUID = nil; petName = ""; petSpecies = ""; petBreed = ""; petAge = 1; petGender = ""; ownSince = ""; hasImage = false; serverImageURL = ""; metadataIsDownloaded = false; isValid = false }
        
    // MARK: RE-INIT
    mutating func reinit() { petUID = nil; petName = ""; petSpecies = ""; petBreed = ""; petAge = 1; petGender = ""; ownSince = ""; hasImage = false; serverImageURL = ""; metadataIsDownloaded = false; isValid = false; docMetadata.removeAll() }
        
    // MARK: COMPLETENESS TEST
    func isComplete () -> Bool { if petName == "" || petSpecies == "" || ownSince == "" { return false } else { return true } }
}

struct VCAppointmentRecord {
    
    var apptUID: Int?
    var petUID: Int?
    var clinicUID: Int?
    var doctorUID: Int?
    var clinicName: String
    var apptType: String
    var service = VCClinicService()
    var startDate = VCDate()
    var endDate = VCDate()
    var apptReason: String
    var apptStatus: String
    var linkedDocMetadata = [Int]()
    var clinicDistance: Float
    var appointmentStarted: Bool
    var isNew: Bool
    var isValid: Bool
    var linksAreDownloaded: Bool
    var upComingHasIssued: Bool
    var startHasBeenIssued: Bool
    var linkedDocuments = [VCDocMetadata]()
    
    init () {
        
        apptUID = nil; petUID = nil; clinicUID = nil; doctorUID = nil
        clinicName = ""; apptType = ""; service.reinit(); apptReason = ""
        apptStatus = ""; clinicDistance = 50.0; appointmentStarted = false
        isNew = false; isValid = false; linksAreDownloaded = false;  upComingHasIssued = false; startHasBeenIssued = false
    }

    mutating func reinit() {
        
        apptUID = 0; petUID = 0; clinicUID = 0; doctorUID = 0
        clinicName = ""; apptType = ""; service.reinit(); apptReason = ""
        apptStatus = ""; clinicDistance = 50.0; appointmentStarted = false
        isNew = false; isValid = false; linksAreDownloaded = false;  upComingHasIssued = false; startHasBeenIssued = false
    }
    
    var appointmentWindowIsOpen: Bool {
        
        let currentDate = Date()
        
        // If the appt time is in the future, check to see if it's within 15 minutes
        if startDate.theDate! > currentDate {
            
            let timeInterval = DateInterval(start: currentDate, end: startDate.theDate!)
            
            if timeInterval.duration <= 900 { return true }
            else { return false }
        }
        
        // Appointment date is now or in the past
        return true
    }
    
    func hasLinkedFileWith (fileID: Int) -> (index: Int?, result: Bool) {
        
        for (index,value) in linkedDocuments.enumerated() { if value.fileID == fileID { return (index,true) } }
        return (nil,false)
    }
}

struct VCClinicRecord {
    
    var clinicUID: Int?
    var clinicName: String
    var clinicLat: Double
    var clinicLng: Double
    var clinicAddress = VCAddress()
    var clinicDoctors = [VCDoctorRecord]()
    var clinicServices = [VCClinicService]()
    var clinicSchedule: String
    var startTimeComponents = DateComponents()
    var endTimeComponents = DateComponents()
    var isValid: Bool
    
    // MARK: INITIALIZER
    init () {  clinicUID = nil; clinicName = ""; clinicLat = 0.0; clinicLng = 0.0; clinicSchedule = ""; isValid = false }
    
    // MARK: RE-INIT
    mutating func reinit() { clinicUID = nil; clinicName = ""; clinicLat = 0.0; clinicLng = 0.0; clinicSchedule = ""; isValid = false }
    
    var defaultService: (id: Int, record: VCClinicService?) {
        
        // Find the default service
        for s in clinicServices { if s.isDefault { return (s.serviceID!, s) } }
        
        // If nothing is marked default, return the first service; if there are no services return nil (safety valve, should not happen normally)
        if clinicServices.count > 0 { return (clinicServices[0].serviceID!, clinicServices[0]) }
        else { return ( 1, nil ) }
    }
    
    var nextValidApptTime: VCDate? {
        
        let weekdays = ["Su","Mo","Tu","We","Th","Fr","Sa"]
        let nextSlot = VCDate().roundupTime()
        var isValidAppointment = false
        var safetyCounter: Int = 0
        
        let startTime = VCDate(fromDateComponents: startTimeComponents)
        let endTime = VCDate(fromDateComponents: endTimeComponents)
       
        repeat {
            
            // If we look forward a week and still no appointment, something's wrong
            guard safetyCounter <= 672 else { return nil }
            
            // The day of week must be a clinic day, and time must be between open and close
            if clinicSchedule.contains(weekdays[nextSlot.dateComponents.weekday! - 1]) &&
                (nextSlot.timeNumeric >= startTime.timeNumeric) &&
                (nextSlot.timeNumeric <= endTime.timeNumeric) { isValidAppointment = true }
                
            else {
                
                // Add 15 minutes and try again
                nextSlot.theDate = nextSlot.theDate!.addingTimeInterval(900)
                safetyCounter += 1
            }
            
        } while !isValidAppointment
        
        return nextSlot
    }
    
    var scheduleString: String {
        
        let ust = "h:mm a"
        let eut = "HH:mm"
        let dateFormatter = DateFormatter()
        
        var scheduleString = clinicSchedule
        
        if startTimeComponents.hour == endTimeComponents.hour { scheduleString += "Clinic hours not specified - please contact the clinic" }
        
        else if startTimeComponents.hour == 0 && startTimeComponents.minute == 0 && endTimeComponents.hour == 23 && startTimeComponents.minute == 59 { scheduleString += " Open 24 Hours"}
        
        else {
            
            let startDate = NSCalendar.current.date(from: startTimeComponents)
            let endDate = NSCalendar.current.date(from: endTimeComponents)
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = ust } else {dateFormatter.dateFormat = eut }
            scheduleString += ("from " + dateFormatter.string(from: startDate!) + " to " + dateFormatter.string(from: endDate!))
        }
        
        return scheduleString
    }
    
    func isValidAppointmentTime(_ apptTime: VCDate) -> (date: VCDate?, isValid: Bool) {
        
        let weekdays = ["Su","Mo","Tu","We","Th","Fr","Sa"]
        guard clinicSchedule.contains(weekdays[apptTime.dateComponents.weekday!-1]) else { return (nil, false) }
        
        let startDateAndTime = VCDate(fromDateComponents: startTimeComponents)
        let endDateAndTime = VCDate(fromDateComponents: endTimeComponents)
        
        guard (apptTime.timeNumeric >= startDateAndTime.timeNumeric) && (apptTime.timeNumeric <= endDateAndTime.timeNumeric) else {
            
            let revertDate = VCDate(date: apptTime)
            
            revertDate.dateComponents.hour = startTimeComponents.hour!
            revertDate.dateComponents.minute = startTimeComponents.minute!
            
            return (revertDate, false)
        }
        
        return (nil, true)
    }
}

struct VCDoctorRecord {
    
    var doctorUID: Int?
    var givenName: String
    var familyName: String
    var suffix: String
    var specialty: String
    var isValid: Bool
    
    // Initializer
    init (){ doctorUID = nil; givenName = ""; familyName = ""; suffix = ""; specialty = ""; isValid = false }
 
    // Clearer
    mutating func reinit() { doctorUID = nil; givenName = ""; familyName = ""; suffix = ""; specialty = ""; isValid = false }
}

struct VCClinicService {
    
    var serviceID: Int?
    var serviceMedicalName: String
    var servicePlainName: String
    var serviceDescription: String
    var serviceTimeRequired: Int
    var serviceFee: Int
    var isDefault: Bool
    
    init (sid: Int? = nil, smn: String? = "", spn: String? = "", sdn: String? = "", str: Int? = 30, fee: Int? = 100, def: Bool? = false ) {
        
        serviceID = sid; serviceMedicalName = smn!; servicePlainName = spn!; serviceDescription = sdn!; serviceTimeRequired = str!; serviceFee = fee!; isDefault = def!
    }
    
    mutating func reinit() {
        
        serviceID = nil; serviceMedicalName = ""; servicePlainName = ""; serviceDescription = ""; serviceTimeRequired = 30; serviceFee = 100; isDefault = false
    }
}

struct VCSettings {
    
    var appVersion: String
    var phoneContact: Bool
    var textContact: Bool
    var emailContact: Bool
    var onlyMapVC: Bool
    var rememberMe: Bool
    var clock: ClockMode
    var recordCountsAreHidden: Bool
    var alertMinutes: Int
    
    init () {
        
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        
        appVersion = version + "." + build
        phoneContact = false; textContact = false; emailContact = false; onlyMapVC = false; rememberMe = false; clock = .c24; alertMinutes = 15; recordCountsAreHidden = false
    }
    
    mutating func reinit() { phoneContact = false; textContact = false; emailContact = false; onlyMapVC = false; rememberMe = false; clock = .c24; alertMinutes = 15 ; recordCountsAreHidden = false }
}

struct VCDocMetadata {
    
    var fileID: Int
    var localURL: String
    var fileName: String
    var fileType: String
    var previewURL: String
    var downloadURL: String
    var notes: String
    var petUID: String
    var docFolderID: String
    var docFileID: String
    var isDownloaded: Bool
    
    // MARK: INITIALIZER
    init () { fileID = 0; localURL = ""; fileName = ""; fileType = ""; previewURL = ""; downloadURL = ""; notes = ""; petUID = ""; docFolderID = ""; docFileID = ""; isDownloaded = false }
    
    // MARK: RE-INIT
    mutating func reinit() { fileID = 0; localURL = ""; fileName = ""; fileType = ""; previewURL = ""; downloadURL = ""; notes = ""; petUID = ""; docFolderID = ""; docFileID = ""; isDownloaded = false }
}

struct VCMessage {
    
    var from: String
    var title: String
    var message: String
    var timeStamp: String
    var unread: Bool
    
    // MARK: INITIALIZER
    init( isFrom: String? = "Vets Central Admin", aTitle: String? = "", aMessage: String? = "", aTimeStamp: String? = "", unreadState: Bool? = true) { from = isFrom!; title = aTitle!; message = aMessage!; timeStamp = aTimeStamp!; unread = unreadState! }
    
    // MARK: RE-INIT
    mutating func reinit() { from = ""; title = ""; message = ""; timeStamp = ""; unread = true }
}

struct VCTimeWindow {
    
    var from: String
    var to: String
    
    // MARK: INITIALIZER
    init (f: String? = "", t: String? = "") { from = f!; to = t! }
    
    // MARK: RE-INIT
    mutating func reinit() { from = ""; to = "" }
}

struct VCClockValues {

    var hour: Int
    var minutes: Int
    
    // MARK: INITIALIZER
    init (h: Int? = 0, m: Int? = 0) { hour = h!; minutes = m! }
    
    // MARK: RE-INIT
    mutating func reinit() { hour = 0; minutes = 0 }
}

struct VCLanguage {
    
    var english: String
    var chinese: String
    var hebrew: String
    
    init (en: String? = "", ch: String? = "", he: String? = "") { english = en!; chinese = ch!; hebrew = he! }
}

struct VCFlags {
    
    var loginState: LoginState
    var isCreateAccount: Bool
    var isFirstAppointmentRequest: Bool
    var lastRefreshSuceeded: Bool
    var refreshInProgress: Bool
    var refreshTerminated: Bool
    var eventCheckInProgress: Bool
    var eventCheckTerminated: Bool
    var petPhotosOnBoard: Bool
    var clinicDetailsOnBoard: Bool
    var hasState: Bool
    var isTestMode: Bool
    
    init() {
        
        loginState = .bootUp
        isCreateAccount = false
        isFirstAppointmentRequest = true
        refreshInProgress = false
        lastRefreshSuceeded = false
        refreshTerminated = false
        eventCheckInProgress = false
        eventCheckTerminated = false
        petPhotosOnBoard = false
        clinicDetailsOnBoard = false
        hasState = true
        isTestMode = true
    }
    
    mutating func reinit() {
        
        loginState = .loggedOut
        isCreateAccount = false
        isFirstAppointmentRequest = true
        refreshInProgress = false
        lastRefreshSuceeded = false
        refreshTerminated = false
        eventCheckInProgress = false
        eventCheckTerminated = false
        petPhotosOnBoard = false
        clinicDetailsOnBoard = false
        hasState = true
        isTestMode = true
    }
}

struct VCLookup{
    
    var lookupCode: String
    var lookupValue: String
    var lookupType: String
    var displayName: String
    var description: String
    
    // MARK: INITIALIZER
    init (lc: String? = "", lv: String? = "", lt: String? = "", dn: String? = "", de: String? = "") { lookupCode = lc!; lookupValue = lv!; lookupType = lt!; displayName = dn!; description = de! }
    
    // MARK: RE-INIT
    mutating func reinit() { lookupCode = ""; lookupValue = ""; lookupType = ""; displayName = ""; description = "" }
}

struct VCLookups {
    
    var speciesLookups = [VCLookup]()
    var genderLookups = [VCLookup]()
    var breedLookups = [VCLookup]()
    
    mutating func reinit() { speciesLookups.removeAll(); genderLookups.removeAll(); breedLookups.removeAll() }
}

struct VCLocation {
    
    var longitude: Double
    var latitude: Double
    
    init () { longitude = 0.0; latitude = 0.0 }
    
    mutating func reinit() { longitude = 0.0; latitude = 0.0 }
}

struct VCTokens {
    
    var bearerToken: String {
        
        get { return VCKeychainServices().readString(withKey: "bearertoken")! }
        set { _ = VCKeychainServices().writeData(data: newValue, withKey: "bearertoken") }
    }

    init () { bearerToken = "" }
    mutating func reinit() { bearerToken = "" }
}

struct VCTime {
    
    var year: Int?
    var month: Int?
    var day: Int?
    var hour: Int?
    var minute: Int?
}

struct VCAddress {
    
    var street: String
    var city: String
    var state: String
    var postalCode: String
    var country: String
    var phone: String
    
    init() { street = ""; city = ""; state = ""; postalCode = ""; country = ""; phone = "" }
    
    mutating func reinit() { street = ""; city = ""; state = ""; postalCode = ""; country = ""; phone = "" }
    
}

struct VCMapItem {
    
    var isValid: Bool
    var isVCClinic: Bool
    var clinicRecord = VCClinicRecord()
    var mapItem: MKMapItem?
    
    init() { isValid = false; isVCClinic = false; mapItem = MKMapItem() }
    
    mutating func reinit() { isValid = false; isVCClinic = false }
}

struct VCPlacemark {
    
    var vcClinic = VCClinicRecord()
    var mapItem = MKMapItem()
}

struct VCAlertTextFieldInit {
    
    var placeHolder: String
    var defaultText: String
}




