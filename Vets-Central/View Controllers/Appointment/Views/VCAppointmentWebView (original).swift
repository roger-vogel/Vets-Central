//
//  VCConsultationWebView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 4/9/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
// 

import UIKit
import WebKit
import Foundation

class VCAppointmentWebView: VCView, WKUIDelegate, WKNavigationDelegate {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var titleBarLabel: UILabel!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var documentsButton: UIButton!
    @IBOutlet weak var maskLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var elapsedLabel: UILabel!
    
    // MARK: PROPERTIES
    
    var theTelevetController: UIViewController?
    var hangupButtonOriginFactorX: CGFloat?
    var hangupButtonOriginFactorY: CGFloat?
    var hangupButtonSizeFactor: CGFloat?
    var hangupButtonFrame: CGRect?
    var headerMaskY: CGFloat?
    var callStarting: Bool?
    var callStarted: Bool?
    var elapsedSeconds: Int64?
    var consultationTimer: Timer?
    var connectionCancelled: Bool?
    var connectionTryCounter: Int = 0
    var conferenceID: Int?
    var aURL: URL?
   
    var theWebView: WKWebView?
    var headerMaskLabel: UILabel?
    var hangupButton: UIButton?
    var logoImageView: UIImageView?
    
    // MARK: COMPUTED PROPERTIES
    
    var calculateHoursAndMinutes: String {
        
        guard elapsedSeconds != 0 else { return "00:00:00" }
        
        let hours = elapsedSeconds!/3600
        guard elapsedSeconds! % 3600 != 0 else { return String(format: "%02d:00:00",hours) }
            
        let minutes = (elapsedSeconds! - (hours * 3600)) / 60
        guard (elapsedSeconds! - (hours * 3600)) % 60 != 0 else { return  String(format: "%02d:%02d:00",hours,minutes) }
            
        let seconds = elapsedSeconds! - (hours * 3600) - (minutes * 60)
        
        return String(format: "%02d:%02d:%02d",hours,minutes,seconds)
    }
    
    // MARK: INITIALIZATION AND OVERRIDES
    
    override func initView() {
        
        setupOverlays()
        
        hangupButton = UIButton(frame: hangupButtonFrame!)
        hangupButton!.addTarget(self, action: #selector(onHangup), for: .touchUpInside)
        hangupButton!.backgroundColor = .clear
        addSubview(hangupButton!)
        
        headerMaskLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: headerMaskY!), size: CGSize(width: self.frame.width, height: (self.frame.height - 94) * 0.10)))
        headerMaskLabel!.backgroundColor = .black
        addSubview(headerMaskLabel!)
     
        logoImageView = UIImageView(image: UIImage(named: "logo.white.round.png"))
        logoImageView!.frame =  CGRect(x: 15.0, y: headerMaskLabel!.frame.origin.y + maskLabel.frame.height/2 - 20, width: 40, height: 40)
        addSubview(logoImageView!)
        
      
        parentController.appointmentController.controllerAlert = VCAlertServices(viewController: parentController)
        
        super.initView()
    }
    
    // MARK: METHODS
    
    func setupOverlays() {
        
        var bx: CGFloat?
        var by: CGFloat?
        var bh: CGFloat?
        var bw: CGFloat?
        
        switch UIDevice().type {
        
            case .iPhone7: bx = 10; by = 512; bw = 85; bh = 110; headerMaskY = 70
            case .iPhone7Plus: bx = 10; by = 512; bw = 85; bh = 110; headerMaskY = 70
            case .iPhoneSE2: bx = 10; by = 512; bw = 85; bh = 110; headerMaskY = 70
            case .iPhone8: bx = 10; by = 512; bw = 85; bh = 110; headerMaskY = 70
            case .iPhone8Plus: bx = 26; by = 582; bw = 85; bh = 110; headerMaskY = 70
            case .iPhoneX: bx = 10; by = 657; bw = 85; bh = 110; headerMaskY = 94
            case .iPhoneXS: bx = 10; by = 657; bw = 85; bh = 110; headerMaskY = 94
            case .iPhoneXSMax: bx = 10; by = 657; bw = 85; bh = 110; headerMaskY = 94
            case .iPhoneXR: bx = 10; by = 657; bw = 85; bh = 110; headerMaskY = 94
            case .iPhone11: bx = 10; by = 749; bw = 85; bh = 110; headerMaskY = 94
            case .iPhone11Pro: bx = 10; by = 657; bw = 85; bh = 110; headerMaskY = 94
            case .iPhone11ProMax: bx = 25; by = 707; bw = 85; bh = 110; headerMaskY = 94
            case .iPhone12Mini: bx = 10; by = 657; bw = 85; bh = 110; headerMaskY = 94
            case .iPhone12: bx = 0; by = 667; bw = 90; bh = 130; headerMaskY = 94
            case .iPhone12Pro: bx = 10; by = 690; bw = 85; bh = 110; headerMaskY = 94
            case .iPhone12ProMax: bx = 25; by = 772; bw = 85; bh = 110; headerMaskY = 94
            case .iPhone13: bx = 0; by = 670; bw = 90; bh = 130; headerMaskY = 94
            case .iPhone13Pro: bx = 0; by = 680; bw = 90; bh = 130; headerMaskY = 94
            case .iPhone13ProMax: bx = 15; by = 772; bw = 85; bh = 110; headerMaskY = 94
            default: bx = 0; by = 680; bw = 90; bh = 130; headerMaskY = 94
        }
        
        hangupButtonFrame = CGRect(x: bx!, y: by!, width: bw!, height: bh!)
        
    }
    
    func postInfoToServer(_ theJSON: NSDictionary) {
        
        let theAppointment = globalData.user.currentAppointments[self.parentController.appointmentController.selectedAppointment!]
        let webServices = VCWebServices()
        let dataInAPIFormat = VCAPITranslator().formatForCreateAppt(apptRecord: theAppointment)
        
        do {
            
            var params: String = ""
            let body = try JSONEncoder().encode(dataInAPIFormat)
            
            if !((theJSON["appointment"] as! NSDictionary)["conferenceShortUrl"] is NSNull) {  params += (": " + ((theJSON["appointment"] as! NSDictionary)["conferenceShortUrl"] as! String) ) }
            else { params = "FAILURE: " + (theJSON["error"] as! String) }
            
            webServices.apiDiagnostics.apiName = "TELEVET CONNECTION ATTEMPT"
            webServices.apiDiagnostics.jsonSent = body.asPrettyJSON!
            webServices.apiDiagnostics.jsonReceived = params
            webServices.postErrorToServer()
            
        } catch { }
    }
    
    func initiateConsultation() {
        
        theWebView = nil
        theWebView = WKWebView(frame: CGRect(x: 0, y: 94, width: self.frame.width, height: self.frame.height - 114))
     
        addSubview(theWebView!)
        bringSubviewToFront(timerLabel)
        bringSubviewToFront(elapsedLabel)
        bringSubviewToFront(headerMaskLabel!)
        bringSubviewToFront(logoImageView!)
        bringSubviewToFront(hangupButton!)
        
        theWebView!.uiDelegate = self
        theWebView!.navigationDelegate = self
        
        connectionCancelled = false
        maskLabel.alpha = 0.0
        maskLabel.isHidden = true
    
        parentController.appointmentController.controllerAlert!.popupPendingCancel(aMessage: "Connecting to your Televet consultation") { () in
            
            if globalData.webServiceQueue.last != nil {
                
                globalData.webServiceQueue.last!.dataTask!.cancel()
                globalData.webServiceQueue.removeLast()
            }
         
            self.connectionCancelled = true
            self.hideView()
        }
        
        getConferenceNotes()
        getVideoCredentials()
    }
    
    func getConferenceNotes() {
        
        // Get the appointment notes
        webServices!.getAppointmentNotes(theAppointment: self.parentController.appointmentController.apptInformationView.localAppointmentRecord) { ( json, status ) in
            
            guard self.webServices!.isErrorFree(json: json, status: status) else { return }
            
            let apptNotes = json["notes"] as! NSDictionary
            let notes = apptNotes["notes"] as! NSArray
            
            for n in notes {
                
                let noteFields = n as! NSDictionary
                if (noteFields["subject"] as! String) == "Help Needed" {
                    
                    self.parentController.appointmentController.apptNotesView.noteUID = (noteFields["id"] as! Int)
                    self.parentController.appointmentController.apptNotesView.notesTextView.text = (noteFields["note"] as! String)
                    self.parentController.appointmentController.apptNotesView.noteText = self.parentController.appointmentController.apptNotesView.notesTextView.text
                    break
                }
                
            }
        }
    }
    
    func getVideoCredentials() {
        
        guard !connectionCancelled! else { return }
    
        webServices!.getVideoCredentials(theAppointment: self.parentController.appointmentController.apptInformationView.localAppointmentRecord) { (json, status) in
            
            guard self.webServices!.isErrorFree(json: json, status: status) else { return }
            self.postInfoToServer(json)
            
            guard !((json["appointment"] as! NSDictionary)["conferenceShortUrl"] is NSNull) else {
                
                if self.connectionTryCounter == 0 {
                    
                    self.parentController.appointmentController.controllerAlert?.popupMessage(aMessage: "There was an error connecting to your conference, please try to connect again")
                    return
                    
                }  else {
                    
                    self.parentController.appointmentController.controllerAlert?.popupMessage(aMessage: "There is still an error connecting to your conference, please contact your veterinarian")
                    
                    self.parentController.appointmentController.apptInformationView.televetButton.isEnabled = false
                    self.parentController.appointmentController.apptInformationView.televetButton.alpha = 0.30
                    
                    self.connectionTryCounter = 0
                    return
                }
            }
            
            guard (json["appointment"] as! NSDictionary)["conferenceShortUrl"] != nil else {
                
                self.parentController.appointmentController.controllerAlert?.popupMessage(aMessage: "Your conference has not started yet, please try again in a few minutes")
                return
            }
            
            let urlString = (json["appointment"] as! NSDictionary)["conferenceShortUrl"] as! String
            let adjustedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let theURL = URL(string: adjustedURLString!)
            
            guard theURL != nil else {
                
                if !self.connectionCancelled! { self.parentController.appointmentController.controllerAlert?.popupMessage(aMessage: "There was an error connecting to your conference, please contact your veterinarian")}
                return
            }
            
            let id = (json["appointment"] as! NSDictionary)["id"] as! Int
          
            self.conferenceID = id
            self.callStarting = true
            self.callStarted = true
          
            self.loadURL(url: theURL!)
            globalData.conferenceInProgress = true
            
            self.aURL = theURL!
            
            let keychain = VCKeychainServices()
            let lastID = keychain.readInt(withKey: "conferenceID")
         
            if lastID != nil {
                
                if lastID == self.conferenceID {
                    
                    self.elapsedSeconds = keychain.readInt64(withKey: "elapsedSeconds")
                    if self.elapsedSeconds == nil  { self.elapsedSeconds = 0 }
                    
                    let timestamp = keychain.readInt64(withKey: "timestamp")
                    if timestamp != nil { if timestamp != 0 { self.elapsedSeconds! += (Int64(Date().timeIntervalSince1970) - timestamp!) } }
              
                } else {
                    
                    _ = keychain.writeData(data: Int64(Date().timeIntervalSince1970), withKey: "timestamp")
                    _ = keychain.writeData(data: self.conferenceID!, withKey: "conferenceID")
                    _ = keychain.writeData(data: Int64(0), withKey: "elapsedSeconds")
                    
                    self.elapsedSeconds = 0
                }
                
            } else {
                
                _ = keychain.writeData(data: Int64(Date().timeIntervalSince1970), withKey: "timestamp")
                _ = keychain.writeData(data: self.conferenceID!, withKey: "conferenceID")
                _ = keychain.writeData(data: Int64(0), withKey: "elapsedSeconds")
                
                self.elapsedSeconds = 0
                
            }
            
            self.timerLabel.text = self.calculateHoursAndMinutes
        }
    }
    
    func loadURL(url: URL) {
        
        let request = URLRequest(url: url)
        theWebView!.isHidden = false
        theWebView!.load(request)
    }
    
    // MARK: SELECTORS
    
    @objc func incrementTimer() {
        
        guard elapsedSeconds != nil else { return }

        elapsedSeconds! += 1
        timerLabel.text = calculateHoursAndMinutes
    }

    @objc func onHangup() {
        
        VCAlertServices(viewController: parentController.appointmentController).popupYesNo(aMessage: "Are you sure you want to end the Televet consultation?", aStyle: [.destructive,.default]) { choice in
            
            if choice == 0 {
                
                self.consultationTimer!.invalidate()
                
                self.bringSubviewToFront(self.maskLabel)
                self.maskLabel.isHidden = false
                self.maskLabel.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: {
                    
                    self.theWebView = nil
                   
                    VCAlertServices(viewController: self.parentController).popupMessage(aTitle: "Consultation Complete", aMessage: "Thank you for using Vets Central!\nYour consultation time was " + self.calculateHoursAndMinutes, aViewDelay: 3.0) { () in
                        
                        self.parentController.appointmentController.apptInformationView.hideView(withFade: false)
                        self.hideView()
                        self.parentController.appointmentController.tabBarController?.tabBar.isHidden = false
                    }
                    
                    self.callStarted = false
                    
                    globalData.conferenceInProgress = false
                    
                    let keychain = VCKeychainServices()
                    
                    _ = keychain.writeData(data: self.elapsedSeconds!, withKey: "elapsedSeconds")
                    _ = keychain.writeData(data: Int64(Date().timeIntervalSince1970), withKey: "timestamp")
                    _ = keychain.writeData(data: self.conferenceID!, withKey: "conferenceID")
                })
            }
        }
    }
    
    // MARK: WEBVIEW DELEGATE PROTOCOL
    
    func webView(_ theWebView: WKWebView,  didFinish navigation: WKNavigation!) {
        
        if callStarting! {
            
            self.consultationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.incrementTimer), userInfo: nil, repeats: true )
           
            callStarting = false
            parentController.appointmentController.controllerAlert!.dismiss()
            
            parentController.appointmentController.tabBarController?.tabBar.isHidden = true
            showView()
        }
    }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func documentsButtonTapped(_ sender: Any) {
        
        parentController.appointmentController.apptDocumentView.setupView()
    }
    
    @IBAction func notesButtonTapped(_ sender: Any) {
        
        parentController.appointmentController.apptNotesView.setPetName()
        parentController.appointmentController.apptNotesView.setNoteText()
        parentController.appointmentController.apptNotesView.showView()
    }
    
    @IBAction func returnButtonTapped(_ sender: Any) { onHangup() }
}

                                          
