//
//  VCGlobalData.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/3/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit
import MapKit

class VCGlobalData: NSObject {

    var tokens = VCTokens()
    var flags = VCFlags()
    var lookups = VCLookups()
    var user = VCUser()
    var clinics = [VCClinicRecord]()
    var settings = VCSettings()
    var messageService = VCMessageServices()
    var location = VCLocation()
    var activeController: VCViewController?
    var activeView: VCView?
    var homeController: VCHomeViewController?
    var apptController: VCAppointmentViewController?
    var stringTable = VCStringTable()
    var webServiceQueue = [VCWebServices]()
    var taskQueue = [URLSessionDataTask]()
    var webServiceTimer = Timer()
    var refreshTimer = Timer()
    var eventTimer = Timer()
    var locationTimer = Timer()
    var savedUser: String?
    var conferenceInProgress: Bool = false
    var clinicDetailsCancelled: Bool = false
    var uploadIsCancelled: Bool = false
    var downloadIsCancelled: Bool = false
    var theElapsedSeconds: Int64?
    var theTimestamp: Int64?
    var theConferenceID: Int?
    var openedAppointment: Int = 0
    
    // MARK: INITIALIZATON
    
    override init() {
        
        super.init()
        flags.loginState = .bootUp
    }
  
    // MARK: RE-INIT
    
    func reinit(allData: Bool? = false ) {
        
        tokens.reinit()
        flags.reinit()
        user.reinit()
        lookups.reinit()
        settings.reinit()
        messageService.clearMessages()
        reinitLookups()
        
        user.pets.removeAll()
        user.currentAppointments.removeAll()
        user.pastAppointments.removeAll()
        messageService.theMessages.removeAll()
    
        if allData! { clinics.removeAll() }
    }
    
    func reinitLookups () {
        
        for var s in lookups.speciesLookups { s.reinit() }
        for var b in lookups.breedLookups { b.reinit() }
        for var g in lookups.genderLookups { g.reinit() }
    }
    
    // MARK: METHODS
    
    func executeQueuedTasks() {
        
        for task in taskQueue { task.resume() }
        taskQueue.removeAll()
    }
     
    func pauseWebservices () {
        
        stopTimers()
        
        if flags.refreshInProgress {
            
            flags.refreshInProgress = false
            flags.refreshTerminated = true
          
            if webServiceQueue.count > 0 { for w in webServiceQueue { if w.dataTask!.state == .running { w.dataTask!.cancel() } } }
        }
        
        else if flags.eventCheckInProgress {
            
            flags.eventCheckInProgress = false
            flags.eventCheckTerminated = true
          
            if webServiceQueue.count > 0 { for w in webServiceQueue { if w.dataTask!.state == .running { w.dataTask!.cancel() } } }
        }
        
        else {
            
            guard webServiceQueue.count > 0 else { return }
            for w in webServiceQueue { if w.dataTask!.state == .running { w.dataTask!.suspend() } }
        }
    }
    
    func resumeWebServices () {
        
        refreshData()
        startTimers()
   
        for w in webServiceQueue { w.dataTask!.resume() }
        webServiceQueue.removeAll()
    }
    
    func numClinicsNearUser() -> Int {
        
        var counter: Int = 0
    
        for c in clinics { if abs(c.clinicLat - location.latitude) <= 2.0 && abs(c.clinicLng - location.longitude) <= 2.0 { counter += 1 } }
            
        return counter
    }
    
    func startTimers() { startRefreshTimer(); startEventTimer(); startLocationTimer() }
    
    func stopTimers() { stopRefreshTimer(); stopEventTimer(); stopLocationTimer() }
    
    func startRefreshTimer() {
        
        // Set refresh timer to 4.5 mins (on half to minimize collision with event timer)
        refreshTimer = Timer.scheduledTimer(timeInterval: 270, target: self, selector: #selector(refreshData), userInfo: nil, repeats: true )
    }
    
    func stopRefreshTimer() {
        
        refreshTimer.invalidate()
    }
    
    func startEventTimer() {
        
        // Set event timer to one minute
       eventTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(checkForEvents), userInfo: nil, repeats: true )
    }
    
    func stopEventTimer() {
        
       eventTimer.invalidate()
    }
    
    func startLocationTimer() {
        
        // Set event timer to one minute
        locationTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(updateLocation), userInfo: nil, repeats: true )
    }
    
    func stopLocationTimer() {
        
       locationTimer.invalidate()
    }
    
    func resumeVideoConference() {
        
        guard apptController != nil else { return }
        apptController!.apptWebView.initiateConsultation()
    }
    
    func setVideoTimeParameters(elapsed: Int64, aTimestamp: Int64, anID: Int) {
        
        theElapsedSeconds = elapsed
        theTimestamp = aTimestamp
        theConferenceID = anID
    }
    
     // MARK: TIMER ACTIONS
    
    @objc func refreshData() {
        
        guard !flags.refreshInProgress && !flags.eventCheckInProgress && self.homeController != nil && flags.loginState == .loggedIn  else { return }
        guard webServiceQueue.isEmpty else { return }
       
        DispatchQueue.main.async {
            
            self.flags.refreshInProgress = true
            VCRefreshServices(parent: self.homeController!).refresh()
        }
    }
    
    @objc func abortRefresh() { flags.refreshInProgress = false }
    
    @objc func checkForEvents () {
        
        guard !flags.refreshInProgress && !globalData.flags.eventCheckInProgress && self.homeController != nil  else { return }
      
        DispatchQueue.main.async { VCEventServices(parent: self.homeController!).checkForEvents() }
    }
    
    @objc func updateLocation() {
    
        let status = CLLocationManager().authorizationStatus
    
        if status == .authorizedAlways || status == .authorizedWhenInUse  {
            
            guard CLLocationManager().location != nil else { return }
            
            location.latitude = CLLocationManager().location!.coordinate.latitude
            location.longitude = CLLocationManager().location!.coordinate.longitude
        }
    }
}
