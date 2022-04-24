//
//  VCRecordGetter.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/26/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit

class VCRecordGetter: NSObject {
    
    // MARK: DOCUMENT
    
    // MARK: PET
    
    // Return pet record by uid
    func petRecordWith (uid: Int, fromData: VCGlobalData? = globalData) -> VCPetRecord? {
    
        for p in fromData!.user.pets { if p.petUID == uid { return p } }
        return nil
    }

    // Return pet index by uid
    func petIndexWith (uid: Int, fromData: VCGlobalData? = globalData) -> Int? {
        
        if fromData!.user.pets.count >= 0 { for p in 0...fromData!.user.pets.count - 1 { if fromData!.user.pets[p].petUID == uid { return p } } }
        return nil
    }
    
    // MARK: APPPOINTMENT
    
    // Return appointment record by uid
    func appointmentWith (uid: Int, fromData: [VCAppointmentRecord]) -> VCAppointmentRecord?  {
    
        for a in fromData { if a.apptUID == uid { return a } }
        return nil
    }
        
    // Return appointment index by UID
    func appointmentIndexWith (uid: Int, fromData: VCGlobalData? = globalData, timeFrame: ApptTimeFrame? = .current) -> Int? {
    
        if timeFrame == .current {
            
            if fromData!.user.currentAppointments.count >= 0 { for p in 0...fromData!.user.currentAppointments.count - 1  { if fromData!.user.currentAppointments[p].apptUID == uid { return p } } }
        }
        
        else {
            
            if fromData!.user.pastAppointments.count >= 0 { for p in 0...fromData!.user.pastAppointments.count - 1  { if fromData!.user.pastAppointments[p].apptUID == uid { return p } } }
        }
        
        return nil
    }
    
    // MARK: CLINIC
    
    // Check if clinic is a member of Vets Central
    func isVCMember(clinicName: String, latitude: Double, longitude: Double, fromData: VCGlobalData? = globalData) -> Int? {
    
        for c in fromData!.clinics {
            
            let latD = abs(latitude - c.clinicLat)
            let lngD = abs(longitude - c.clinicLng)
            
            if (latD <= 0.0003 && lngD <= 0.0003) { return c.clinicUID }
        }
        
        return nil
    }
    
    // Return clinic record by UID
    func clinicRecordWith (uid: Int, fromData: [VCClinicRecord]? = globalData.clinics) -> VCClinicRecord? {
    
        for c in fromData! { if c.clinicUID == uid { return c } }
        return nil
    }
                                                
    // Return clinic name by UID
    func clinicNameWith (uid: Int, fromData: [VCClinicRecord]? = globalData.clinics) -> String? {
        
        for c in fromData! { if c.clinicUID == uid { return c.clinicName } }
        return nil
    }
    
    // Return clinic record by name
    func clinicRecordWith (name: String, fromData: [VCClinicRecord]? = globalData.clinics) -> VCClinicRecord? {
   
        for c in fromData! { if c.clinicName == name { return c } }
        return nil
    }

    // Return clinic UID by name
    func clinicUIDWith(name: String, fromData: VCGlobalData? = globalData) -> Int? {
  
        for c in fromData!.clinics { if c.clinicName.uppercased() == name.uppercased() { return c.clinicUID } }
        return nil
        
    }
    
    // Return the array index of the clinics
    func clinicIndexWith (uid: Int, fromData: VCGlobalData? = globalData) -> Int? {
        
        guard !fromData!.clinics.isEmpty else { return nil }
        
        for (index,value) in fromData!.clinics.enumerated() { if value.clinicUID == uid { return index } }
        return nil
    }
    
    // Return the index of a subarray of clinics
    func clinicIndexInSubArray(clinicUID: Int, subArray: [VCClinicRecord]) -> Int? {
        
        guard !subArray.isEmpty else { return nil }
            
        for (index,value) in subArray.enumerated() { if value.clinicUID == clinicUID  { return index } }
        return nil
    }
    
    // Return the index of a subarray of clinics
    func clinicIndexInSubArray(clinicName: String, subArray: [VCClinicRecord]) -> Int? {
        
        guard subArray.count > 0 else { return nil }
            
        for s in 0...(subArray.count - 1) { if subArray[s].clinicName == clinicName  { return s } }
        
        return nil
    }
    
    func doctorRecordWith(clinic: VCClinicRecord, theDoctorUID: Int) -> VCDoctorRecord? {
        
        for d in clinic.clinicDoctors { if d.doctorUID == theDoctorUID { return d } }
        return nil
    }
        
    // Return the array index of the doctor within the clinic
    func doctorIndexWith (clinicDoctors: [VCDoctorRecord], doctorUID: Int) -> Int? {
        
        if clinicDoctors.count > 0 { for d in 0...clinicDoctors.count-1 { if clinicDoctors[d].doctorUID == doctorUID { return d } } }
        return nil
    }
    
    // Return count of new appointments
    func newAppointments (fromData: VCGlobalData? = globalData) -> Int {
        
        var qty: Int = 0
        
        for a in fromData!.user.currentAppointments { if a.isNew { qty += 1 } }

        return qty
    }
}
