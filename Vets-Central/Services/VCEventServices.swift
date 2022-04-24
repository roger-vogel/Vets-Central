//
//  VCEventManager.swift
//  Vets-Central
//
//  Created by Roger Vogel on 11/1/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit
import Foundation

class VCEventServices: NSObject {
    
    // MARK: PROPERTIES
    
    var parentController: VCHomeViewController?
    var isApptStart: Bool = false
    var reminderHasIssued: Bool = false
    var timeInterval: TimeInterval?
  
    // MARK: INITIALIZATION
    
    init (parent: VCHomeViewController? = nil) { super.init(); parentController = parent }
        
    // MARK: METHODS
    
    func checkForEvents() {
       
        globalData.flags.eventCheckInProgress = true
        issueReminders()
    }
    
    func issueReminders () {
        
        guard globalData.flags.loginState == .loggedIn else { return }
        
        for (index, _) in globalData.user.currentAppointments.enumerated() {
            
            let timeInterval = globalData.user.currentAppointments[index].startDate.theDate!.timeIntervalSinceNow
          
            if timeInterval >= 120 && timeInterval <= Double(globalData.settings.alertMinutes * 60) {
                
                if !globalData.user.currentAppointments[index].upComingHasIssued && !globalData.conferenceInProgress {
                    
                    let petInfo = VCRecordGetter().petRecordWith(uid: globalData.user.currentAppointments[index].petUID!)
                    let alertMessage = ("\n" + petInfo!.petName + "'s appointment is in " + String( Int((timeInterval/60) + 0.50)) + " minutes")
                    
                    globalData.user.currentAppointments[index].upComingHasIssued = true
                    VCAlertServices(viewController: parentController!).popupMessage(aTitle: "Appointment Alert", aMessage: alertMessage, aViewDelay: 5.0)
                }
            }
            
            else if timeInterval <= 0 && timeInterval >= -60 { alertIfAppointmentTime(apptIndex: index) }
        }
        
        checkComplete()
    }
    
    func alertIfAppointmentTime (apptIndex: Int) {
        
        guard globalData.flags.loginState == .loggedIn else { return }
        guard !globalData.user.currentAppointments[apptIndex].startHasBeenIssued else { return }
        
        if parentController!.appointmentController.apptWebView.callStarted != nil {
            
            guard !parentController!.appointmentController.apptWebView.callStarted! else { globalData.user.currentAppointments[apptIndex].startHasBeenIssued = true; return }
        }
    
        globalData.user.currentAppointments[apptIndex].startHasBeenIssued = true
        
        if globalData.user.currentAppointments[apptIndex].appointmentWindowIsOpen {
            
            let petInfo = VCRecordGetter().petRecordWith(uid: globalData.user.currentAppointments[apptIndex].petUID!)
            
            isApptStart = true
            parentController!.appointmentController.apptInformationView.setAppointmentButtons()
            
            VCAlertServices(viewController: parentController!).popupMessage(aTitle: "Appointment Alert", aMessage: "It's time for " + petInfo!.petName + "'s appointment")
        }
    }
    
    func checkComplete () {
        
        guard !globalData.flags.eventCheckTerminated else { globalData.flags.eventCheckTerminated = false; return }
        globalData.flags.eventCheckInProgress = false
    }
}
