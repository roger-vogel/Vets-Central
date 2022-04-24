//
//  VCAPITranslator.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/26/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit

class VCAPITranslator: NSObject {
    
    // MARK: METHODS
    
    func formatForUserUpdate(userData: VCUserRecord) -> VCDBUpdateUser {
        
        var userAddressData: VCDBAddress?
        var userLanguageData: VCDBLanguage?
        
        let timeZone = (TimeZone.current).identifier
        
        userAddressData = VCDBAddress(a1: userData.address1, a2: userData.address2, ci: userData.city, st: userData.state, co: userData.country, pc: userData.postalCode)
        userLanguageData = VCDBLanguage()
       
        return VCDBUpdateUser(title: "", givenName: userData.givenName, familyName: userData.familyName, language: userLanguageData!, address: userAddressData!, phone1: userData.phone, phone2: "", bio: "", degree1: "", degree2: "", weChat: "", contactEmail: userData.userEmail, timeZone: timeZone)
    }
    
    func formatForCreatePet(petRecord: VCPetRecord) -> VCDBCreatePet {
        
        return VCDBCreatePet(petName: petRecord.petName, petSpecies: petRecord.petSpecies, petBreed: petRecord.petBreed, petAge: petRecord.petAge, petGender: petRecord.petGender, ownSince: petRecord.ownSince)
    }
    
    func formatForPetUpdate(petRecord: VCPetRecord) -> VCDBUpdatePet {
        
        let ownerName = globalData.user.data.givenName + " " + globalData.user.data.familyName
   
        return VCDBUpdatePet(
            
            petUID: petRecord.petUID!,
            petName: petRecord.petName,
            petOwnerName: ownerName,
            petSpecies: petRecord.petSpecies,
            petBreed: petRecord.petBreed,
            petOwnerUID: 0, idType: 0,
            petVet: 0,
            petAge: petRecord.petAge,
            petGender: petRecord.petGender,
            ownSince: petRecord.ownSince,
            petUserUID: globalData.user.data.userUID!,
            petReferenceID: 0,
            petPhotoURL: petRecord.serverImageURL
        )
    }
    
    func formatForCreateAppt(apptRecord: VCAppointmentRecord) -> VCDBCreateAppointment {
       
        var userParticipant = VCDBAppointmentParticipants()
        var doctorParticipant = VCDBAppointmentParticipants()
        let delta: TimeInterval?
            
        if apptRecord.service.serviceTimeRequired != 0 { delta = Double(apptRecord.service.serviceTimeRequired) * 60 }
        else { delta = 180 }
      
        let endDate = VCDate(date: apptRecord.startDate.theDate!.addingTimeInterval(delta!))
        
        let apiFromString = apptRecord.startDate.APITimeAndDateString
        let apiToString = endDate.APITimeAndDateString
      
        userParticipant.partProfile = VCDBAppointmentProfile(givenName: globalData.user.data.givenName, familyName: globalData.user.data.familyName, title: "")
        userParticipant.partUID = globalData.user.data.userUID!
        userParticipant.partLocation = globalData.user.data.city + " " + globalData.user.data.state + " " + globalData.user.data.country
        userParticipant.partTimeZone = (TimeZone.current).identifier
        userParticipant.acceptanceStatus = "Pending"
        userParticipant.isApptInitiator = true
        
        let clinicRecord = VCRecordGetter().clinicRecordWith(uid: apptRecord.clinicUID!)
        var doctorRecord: VCDoctorRecord?
        
        if apptRecord.doctorUID != nil {
            
            doctorRecord = VCRecordGetter().doctorRecordWith(clinic: clinicRecord!, theDoctorUID: apptRecord.doctorUID!)
            doctorParticipant.partProfile = VCDBAppointmentProfile(givenName: doctorRecord!.givenName ,familyName: doctorRecord!.familyName, title: "")
            doctorParticipant.partUID = apptRecord.doctorUID!
            
        } else {
            
            doctorParticipant.partProfile = VCDBAppointmentProfile(givenName: "" ,familyName: "", title: "")
            doctorParticipant.partUID = 0
        }
    
        doctorParticipant.partRole = "vc_veterinarian"
        doctorParticipant.partTimeZone = (TimeZone.current).identifier
        doctorParticipant.acceptanceStatus = "Pending"
        doctorParticipant.isApptInitiator = false
      
        var createAppt = VCDBCreateAppointment(ft: apiFromString, tt: apiToString, an: "", pu: apptRecord.petUID!, ct: apptRecord.service.serviceID, po: globalData.user.data.userUID!, ar: apptRecord.apptReason)
       
        createAppt.participants.append(userParticipant)
        createAppt.participants.append(doctorParticipant)
        
        return createAppt
    }
    
    func formatForRescheduleAppt (apptRecord: VCAppointmentRecord) -> VCDBRescheduleAppointment {
        
        var delta: Double?
        
        if apptRecord.service.serviceTimeRequired != 0 { delta = Double(apptRecord.service.serviceTimeRequired) * 60 }
        else { delta = 180 }
        
        let endDate = VCDate(date: apptRecord.startDate.theDate!.addingTimeInterval(delta!))
        let apiFromString = apptRecord.startDate.APITimeAndDateString
        let apiToString = endDate.APITimeAndDateString
        
        return VCDBRescheduleAppointment(from: apiFromString, to: apiToString)
    }
    
    func isNull (object : Any?) -> Bool {  if object is NSNull { return true } else { return false } }
}
