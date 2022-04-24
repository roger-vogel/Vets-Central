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
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var elapsedLabel: UILabel!
    @IBOutlet weak var theWebView: WKWebView!
    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var hangupButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var hangupButtonHeight: NSLayoutConstraint!
    
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
    var conferenceAlert: VCAlertServices?
    var headerMaskLabel: UILabel?
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
        
        conferenceAlert = VCAlertServices(viewController: parentController)
        
        theWebView.uiDelegate = self
        theWebView.navigationDelegate = self
        
       
        super.initView()
    }
    
    // MARK: METHODS
    
    func postInfoToServer(_ theJSON: NSDictionary) {
        
        let theAppointment = globalData.user.currentAppointments[self.parentController.appointmentController.selectedAppointment!]
        let webServices = VCWebServices()
        let dataInAPIFormat = VCAPITranslator().formatForCreateAppt(apptRecord: theAppointment)
        
        do {
            
            var params: String = ""
            let body = try JSONEncoder().encode(dataInAPIFormat)
            
            guard !(theJSON["appointment"] is NSNull) else {
                
                self.conferenceAlert!.popupOK(aMessage: "Your veterinarian has not started the conference, please come back in a few minutes")
                return
            }
                
            guard !(((theJSON["appointment"] as! NSDictionary)["conferenceShortUrl"]) is NSNull) else {
                
                self.conferenceAlert!.popupOK(aMessage: "Your veterinarian has not started the conference, please come back in a few minutes")
                return
            }
            
            if !((theJSON["appointment"] as! NSDictionary)["conferenceShortUrl"] is NSNull) {  params += (": " + ((theJSON["appointment"] as! NSDictionary)["conferenceShortUrl"] as! String) ) }
            else { params = "FAILURE: " + (theJSON["error"] as! String) }
            
            webServices.apiDiagnostics.apiName = "TELEVET CONNECTION ATTEMPT"
            webServices.apiDiagnostics.jsonSent = body.asPrettyJSON!
            webServices.apiDiagnostics.jsonReceived = params
            webServices.postErrorToServer()
            
        } catch { }
    }
    
    func initiateConsultation() {
        
        theWebView.alpha = 0.0
        headerMaskLabel = UILabel(frame: CGRect(x: 0, y: theWebView.frame.origin.y, width: theWebView.frame.width, height: theWebView.frame.height * 0.10))
        headerMaskLabel!.backgroundColor = .black
        addSubview(headerMaskLabel!)
     
        logoImageView = UIImageView(image: UIImage(named: "logo.white.round.png"))
        logoImageView!.frame =  CGRect(x: 15.0, y: headerMaskLabel!.frame.origin.y + headerMaskLabel!.frame.height/2 - 20, width: 40, height: 40)
        addSubview(logoImageView!)
        
        hangupButtonWidth.constant = 0.25 * theWebView.frame.width
        hangupButtonHeight.constant = hangupButtonWidth.constant
        
        bringSubviewToFront(headerMaskLabel!)
        bringSubviewToFront(logoImageView!)
        bringSubviewToFront(timerLabel)
        bringSubviewToFront(elapsedLabel)
        bringSubviewToFront(hangupButton!)
    
        connectionCancelled = false
        
        theWebView.alpha = 0.0
        parentController.appointmentController.tabBarController?.tabBar.isHidden = true
      
        showView()
   
        conferenceAlert!.popupPendingCancel(aMessage: "Connecting to your Televet consultation") { () in
            
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
                    
                    self.conferenceAlert?.popupMessage(aMessage: "There was an error connecting to your conference, please try to connect again")
                    return
                    
                }  else {
                    
                    self.conferenceAlert?.popupMessage(aMessage: "There is still an error connecting to your conference, please contact your veterinarian")
                    
                    self.parentController.appointmentController.apptInformationView.televetButton.isEnabled = false
                    self.parentController.appointmentController.apptInformationView.televetButton.alpha = 0.30
                    
                    self.connectionTryCounter = 0
                    return
                }
            }
            
            guard (json["appointment"] as! NSDictionary)["conferenceShortUrl"] != nil else {
                
                self.conferenceAlert?.popupMessage(aMessage: "Your conference has not started yet, please try again in a few minutes")
                return
            }
            
            let urlString = (json["appointment"] as! NSDictionary)["conferenceShortUrl"] as! String
            let adjustedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            var theURL = URL(string: adjustedURLString!)
            
            guard theURL != nil else {
                
                if !self.connectionCancelled! { self.conferenceAlert?.popupMessage(aMessage: "There was an error connecting to your conference, please contact your veterinarian")}
                return
            }
            
            theURL!.removeAllCachedResourceValues()
            
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
        theWebView.isHidden = false
        theWebView.load(request)
    }
    
    // MARK: SELECTORS
    
    @objc func incrementTimer() {
        
        guard elapsedSeconds != nil else { return }

        elapsedSeconds! += 1
        timerLabel.text = calculateHoursAndMinutes
    }

    // MARK: WEBVIEW DELEGATE PROTOCOL
    
    func webView(_ theWebView: WKWebView,  didFinish navigation: WKNavigation!) {
        
        if callStarting! {
            
            callStarting = false
            
            self.consultationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.incrementTimer), userInfo: nil, repeats: true )
            self.conferenceAlert!.dismiss()
            
            theWebView.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 2.0, atCompletion: { return })
        }
    }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func onHangup(_ sender: Any) {
        
        VCAlertServices(viewController: parentController.appointmentController).popupYesNo(aMessage: "Are you sure you want to end the Televet consultation?", aStyle: [.destructive,.default]) { choice in
            
            if choice == 0 {
                
                self.consultationTimer!.invalidate()
                self.theWebView.changeDisplayState(toState: .hidden, withAlpha: 0.0, forDuration: 0.25, atCompletion: {
                    
                    VCAlertServices(viewController: self.parentController).popupOK(aTitle: "Consultation Complete", aMessage: "Thank you for using Vets Central!\nYour consultation time was " + self.calculateHoursAndMinutes) { () in
                        
                        self.hideView()
                        self.theWebView.load(URLRequest(url: URL(string:"about:blank")!))
                        self.parentController.appointmentController.apptInformationView.hideView(withFade: false)
                        self.parentController.appointmentController.tabBarController?.tabBar.isHidden = false
                    }
                })
            
                self.callStarted = false
                globalData.conferenceInProgress = false
                
                let keychain = VCKeychainServices()
                
                _ = keychain.writeData(data: self.elapsedSeconds!, withKey: "elapsedSeconds")
                _ = keychain.writeData(data: Int64(Date().timeIntervalSince1970), withKey: "timestamp")
                _ = keychain.writeData(data: self.conferenceID!, withKey: "conferenceID")
            }
        }
    }
    
    @IBAction func documentsButtonTapped(_ sender: Any) {
        
        parentController.appointmentController.apptDocumentView.subClassType = .linked
        parentController.appointmentController.apptDocumentView.setupView()
    }
    
    @IBAction func notesButtonTapped(_ sender: Any) {
        
        parentController.appointmentController.apptNotesView.setPetName()
        parentController.appointmentController.apptNotesView.setNoteText()
        parentController.appointmentController.apptNotesView.showView()
    }
    
    @IBAction func returnButtonTapped(_ sender: Any) { onHangup(self) }
}

                                          
