//
//  VCCodableDBStructures.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/3/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import Foundation
import UIKit

// MARK: DATA STRUCTURES FOR API ENCODING

struct VCDBCredentials: Codable {
    
    var userEmail: String
    var userPassword: String
    
    enum CodingKeys :String, CodingKey {
    
        case userEmail = "email"
        case userPassword = "password"
    }
}

struct VCDBCreateUser : Codable {
    
    var userEmail: String
    var userPassword: String
    var userType: String
    
    enum CodingKeys: String, CodingKey {
        
        case userEmail = "email"
        case userPassword = "password"
        case userType = "userType"
    }
}

struct VCDBUpdateUser: Codable {
    
    var title: String
    var givenName: String
    var familyName: String
    var language: VCDBLanguage
    var address: VCDBAddress
    var phone1: String
    var phone2: String
    var bio: String
    var degree1: String
    var degree2: String
    var weChat: String
    var contactEmail: String
    var timeZone: String
    
    enum CodingKeys: String, CodingKey {
        
        case title = "title"
        case givenName = "givenName"
        case familyName = "familyName"
        case language = "language"
        case address = "address"
        case phone1 = "phone"
        case phone2 = "secondaryPhone"
        case bio = "bio"
        case degree1 = "degree"
        case degree2 = "otherdegree"
        case weChat = "wechatID"
        case contactEmail = "contactEmail"
        case timeZone = "defaultTimeZone"
    }
}

struct VCDBCreatePet: Codable {
    
    var petName: String
    var petSpecies: String
    var petBreed: String
    var petAge: Int
    var petGender: String
    var ownSince: String
 
    enum CodingKeys :String, CodingKey {
        
        case petName = "petName"
        case petSpecies = "petType"
        case petBreed = "breed"
        case petAge = "petAge"
        case petGender = "petSex"
        case ownSince = "owningSince"
    }
}

struct VCDBUpdatePet: Codable {
    
    var petUID: Int
    var petName: String
    var petOwnerName: String
    var petSpecies: String
    var petBreed: String
    var petOwnerUID: Int
    var idType: Int
    var petVet: Int
    var petAge: Int
    var petGender: String
    var ownSince: String
    var petUserUID: Int
    var petReferenceID: Int
    var petPhotoURL: String
 
    enum CodingKeys : String, CodingKey {
        
        case petUID = "id"
        case petName = "petName"
        case petOwnerName = "petOwnerName"
        case petSpecies = "petType"
        case petBreed = "breed"
        case petOwnerUID = "petOwnerId"
        case idType = "idType"
        case petVet = "veterinarian"
        case petAge = "petAge"
        case petGender = "petSex"
        case ownSince = "owningSince"
        case petUserUID = "petUserId"
        case petReferenceID = "petReferenceId"
        case petPhotoURL = "profileURL"
    }
    

}

struct VCDBCreateAppointment: Codable {
    
    var fromTime: String
    var toTime: String
    var apptNotes: String
    var petUID: Int
    var consultType: Int
    var petOwnerUID: Int
    var participants = [VCDBAppointmentParticipants]()
    var apptReason: String

    enum CodingKeys : String, CodingKey {
        
        case fromTime = "from"
        case toTime = "to"
        case apptNotes = "notes"
        case petUID = "petId"
        case consultType = "consultTypeId"
        case petOwnerUID = "petOwnerId"
        case participants = "participants"
        case apptReason = "subject"
    }
    
    init (ft: String? = "", tt: String? = "", an: String? = "", pu: Int? = 0, ct: Int? = 0, po: Int? = 0, ar: String? = "") {
        
        fromTime = ft!; toTime = tt!; apptNotes = an!; petUID = pu!; consultType = ct!; petOwnerUID = po!; apptReason = ar!
    }
}

struct VCDBPassword: Codable {
    
    var currentPassword: String
    var newPassword: String
    
    enum CodingKeys : String, CodingKey {
        
        case currentPassword = "oldPassword"
        case newPassword = "newPassword"
    }
    
    // MARK: INITIALIZER
    init (op: String? = "", np: String? = "") { currentPassword = op!; newPassword = np! }
    
    // MARK: COMPLETE TEST
    func isComplete() -> (status: Bool, message: String) {
        
        if newPassword == "" { return (status: true, message: "" ) }
       
        else {
            
            if currentPassword == "" { return (status: false, message: "To change your password, please enter your old password") }
            else if currentPassword == newPassword { return (status: false, message:"Your new password must be different than your old password")}
            else { return (status: true, message: "") }
        }
    }
    
    // MARK: RE-INIT
    mutating func reinit() { currentPassword = ""; newPassword = "" }
}

struct VCDBLinkDocuments: Codable {
    
    var documentUIDs: [Int]
    
    enum CodingKeys : String, CodingKey { case documentUIDs = "documentIds" }
}

struct VCDBRescheduleAppointment: Codable {
 
    var from: String
    var to: String
    
    enum CodingKeys: String, CodingKey { case from = "from"; case to = "to" }
}

struct VCDBContactPreferences: Codable {
    
    var smsEnabled: String
    var emailEnabled: String

    enum CodingKeys: String, CodingKey { case smsEnabled = "smsEnabled"; case emailEnabled = "emailEnabled" }
}

struct VCDBAppointmentNotes: Codable {
    
    var notes = [VCDBAppointmentNote]()
    
    enum CodingKeys: String, CodingKey { case notes = "notes" }
}

// MARK: EMBEDDED API STRUCTURES

struct VCDBAddress: Codable {
    
    var address1: String
    var address2: String
    var city: String
    var state: String
    var country: String
    var postalCode: String
    
    enum CodingKeys :String, CodingKey {
    
        case address1 = "addressLine1"
        case address2 = "addressLine2"
        case city = "city"
        case state = "state"
        case country = "country"
        case postalCode = "postalCode"
    }
    
    // MARK: INITIALIZER
    init (a1: String? = "", a2: String? = "", ci: String? = "", st: String? = "", co: String? = "", pc: String? = "" ) { address1 = a1!; address2 = a2!; city = ci!; state = st!; country = co!; postalCode = pc! }
    
    // MARK: RE-INIT
    mutating func reinit() {address1 = ""; address2 = ""; city = ""; state = ""; country = ""; postalCode = "" }
}
    
struct VCDBLanguage: Codable {
    
    var primary: String = "English"
    var secondary: String = ""
    var other: String = ""
 
    enum CodingKeys :String, CodingKey {
        
        case primary = "primaryLanguage"
        case secondary = "secondary"
        case other = "other"
    }
}

struct VCDBAppointmentParticipants: Codable {
    
    var partRole: String = "pet_owner"
    var partUID: Int? = nil
    var partProfile = VCDBAppointmentProfile()
    var partLocation: String = ""
    var partTimeZone: String = ""
    var partPayment: Int = 0
    var partIsPrimary: Bool = false
    var acceptanceStatus: String = ""
    var conferenceMode: String = "online"
    var paymentStatus: String = ""
    var isApptInitiator: Bool = false
    
    enum CodingKeys : String, CodingKey {
        
        case partRole = "role"
        case partUID = "id"
        case partProfile = "profile"
        case partLocation = "location"
        case partTimeZone = "defaultTimeZone"
        case partPayment = "paymentPreference"
        case partIsPrimary = "isPrimary"
        case acceptanceStatus = "acceptanceStatus"
        case conferenceMode = "mode"
        case paymentStatus = "paymentStatus"
        case isApptInitiator = "isAppointmentInitiator"
    
    }
}

struct VCDBAppointmentProfile: Codable {
    
    var givenName: String = ""
    var familyName: String = ""
    var title: String = ""
  
    enum CodingKeys :String, CodingKey {
        
        case givenName = "giveName"
        case familyName = "familyName"
        case title = "title"
    }
}

struct VCDBAppointmentNote: Codable {
    
    var noteUID: Int
    var memberId: Int
    var subject: String
    var note: String
    
    enum CodingKeys: String, CodingKey {
        
        case noteUID = "id"
        case memberId = "memberId"
        case subject = "subject"
        case note = "note"
    }
    
    init (nu: Int? = 0, mi: Int? = 0, su: String? = "", nt: String? = ""  ) { noteUID = nu!; memberId = mi!; subject = su!; note = nt! }
    mutating func reinit () { noteUID = 0; memberId = 0; subject = ""; note = "" }
}

// MARK: DIAGNOSTIC

struct VCAPIDiagnostics: Codable {
    
    var apiName: String
    var apiEndpoint: String
    var jsonSent: String
    var jsonReceived: String
    var apiMethod: String
    var errorDescription: String
    var userName: String
    var postDate: String
    
    enum CodingKeys: String, CodingKey {
        
        case apiName = "api_name"
        case apiEndpoint = "api_endpoint"
        case jsonSent = "json_sent"
        case jsonReceived = "json_received"
        case apiMethod = "api_method"
        case errorDescription = "error_description"
        case userName = "user_name"
        case postDate = "post_date"
    }
    
    init() {
        
        apiName = ""
        apiEndpoint = ""
        jsonSent = ""
        jsonReceived = ""
        apiMethod = ""
        errorDescription = "NONE"
        userName = ""
        postDate = ""
    }
    
    mutating func reinit() {
        
        apiName = ""
        apiEndpoint = ""
        jsonSent = ""
        jsonReceived = ""
        apiMethod = ""
        errorDescription = "NONE"
        userName = ""
        postDate = ""
    }
}
