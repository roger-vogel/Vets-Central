//
//  VCVideoConferenceView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit
import OpenTok

class VCVideoConferenceView: VCView, OTSessionDelegate, OTPublisherDelegate, OTSubscriberKitDelegate {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var videoControlToolBar: UIToolbar!
    
    // MARK: PROPERTIES
    
    var otSession: OTSession?
    var otPublisher: OTPublisher?
    var otSubscriber: OTSubscriber?
    var popupAlert: VCAlertServices?
    var publisherView: UIView?
    var subscriberView: UIView?
    var parentController: VCAppointmentViewController?
    var functionCalled: Int?
    var timeoutTimer = Timer()
  
    // MARK: INITIALIZATION
    
    override func initView ( parent: VCViewController ) {
        
        theParent = parent
        popupAlert = VCAlertServices(viewController: theParent!)
        
        // Initially hide form and set to view frame
        self.alpha = 0.0
        self.frame = theParent!.view.frame
        self.backgroundColor = .black
        
        super.initView(parent: parent)
    }
    
    override func loadData() { (parentController = theParent! as? VCAppointmentViewController) }
    
    // MARK: METHODS
    
    func initiateConsulation () {
        
        videoControlToolBar.alpha = 0.0
        videoControlToolBar.isTranslucent = true
        theParent!.tabBarController?.tabBar.isHidden = true
        
        timeoutTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(timeoutHandler), userInfo: nil, repeats: true )
        
        self.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: {
            
            self.popupAlert?.popupPendingMsg(aTitle: "", aMessage: "Connecting to your Vets-Central Televet consultation")
   
            VCWebServices().getAppointmentNotes(theAppointment: self.parentController!.appointmentFormView.localAppointmentRecord) { ( json, webServiceSuccess ) in
                
                let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
                if success.webServiceSuccess {
                    
                    let apptNotes = json["notes"] as! NSDictionary
                    let notes = apptNotes["notes"] as! NSArray
                    
                    for n in notes {
                        
                        let noteFields = n as! NSDictionary
                        if (noteFields["subject"] as! String) == "Help Needed" {
                            
                            self.parentController!.conferenceNotesFormView.noteUID = (noteFields["id"] as! Int)
                            self.parentController!.conferenceNotesFormView.notesTextView.text = (noteFields["note"] as! String)
                            self.parentController!.conferenceNotesFormView.noteText = self.parentController!.conferenceNotesFormView.notesTextView.text
                            break
                        }
                    }
                    
                }
                
                VCWebServices().getVideoCredentials(theAppointment: self.parentController!.appointmentFormView.localAppointmentRecord, callBack: self.connectToSession)
            }
        })
    }
            
    func connectToSession (json: NSDictionary, webServiceSuccess: Bool) {
        
        timeoutTimer.invalidate()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
        guard success.webServiceSuccess else { popupAlert!.dismiss(); popupAlert!.popupOK(aTitle: "Session Connect Error", aMessage: success.errorString); return}
   
        var tokBoxToken: String?
        let sessionRecord = (json["appointment"] as! NSDictionary)

        let tokBoxSessionID = (sessionRecord["sessionId"] as! String)
 
        let participants = (sessionRecord["participants"] as! NSArray)
    
        for p in participants {
            
            let participant = (p as! NSDictionary)
            if (participant["role"] as! String) == "vc_veterinarian" { tokBoxToken = (participant["tokBoxToken"] as! String); break }
        }
 
        otSession = OTSession(apiKey: "46318472", sessionId: tokBoxSessionID, delegate: self)
        guard otSession != nil else { return }

        var error: OTError?
        otSession?.connect(withToken:tokBoxToken!, error: &error)

        if error != nil { print(error!.localizedDescription); return }
    }
    
    func endSession () {
        
        var error: OTError?
        
        otSession!.disconnect(&error)
        // TODO: ERROR HANDLER
        
        parentController!.appointmentFormView.showView();
        parentController!.tabBarController?.tabBar.isHidden = false
        parentController!.conferenceDocumentsFormView.docMetaData.removeAll()
      
        self.changeDisplayState(toState: .hidden, forDuration: 0.25, atCompletion: { self.publisherView?.removeFromSuperview(); self.subscriberView?.removeFromSuperview() })
    }
    
    // MARK: SESSION DELEGATE PROTOCOL
    
    func sessionDidConnect(_ session: OTSession) {
        
        let settings = OTPublisherSettings()
        var error: OTError?
        
        popupAlert?.dismiss()
        self.showView()
        
        videoControlToolBar.changeDisplayState(toState: .dimmed, withAlpha: 0.70, forDuration: 0.25, atCompletion: {return})
        
        settings.name = UIDevice.current.name
        
        guard let publisher = OTPublisher(delegate: self, settings: settings) else { return }
        
        session.publish(publisher, error: &error)
        
        guard error == nil else {  print(error!.localizedDescription); return }
        
        publisherView = publisher.view
  
        guard publisherView != nil else { return }
        
        let screenBounds = UIScreen.main.bounds
        publisherView!.frame = CGRect(x: screenBounds.width - 150 - 20, y: screenBounds.height - 150 - 64, width: 150, height: 150)
           
        self.addSubview(publisherView!)
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) { NSLog(error.localizedDescription); print (error.localizedDescription) }
  
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        
        var error: OTError?
        
        otSubscriber = OTSubscriber(stream: stream, delegate: self)
        guard let subscriber = otSubscriber else { return }
       
        session.subscribe(subscriber, error: &error)
        guard error == nil else { print(error!.localizedDescription); return }
        
        subscriberView = subscriber.view
        guard subscriberView != nil else { return }
        subscriberView?.frame = UIScreen.main.bounds
        
        self.insertSubview(subscriberView!, at: 0)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        
    }
    
    // MARK: PUBLISHER DELEGATE PROTOCOL
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) { NSLog(error.localizedDescription); print (error.localizedDescription) }
    
    // MARK: SUBSCRIBER DELEGATE PROTOCOL
    
    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) { }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) { }
    
    // MARK: TIMEOUT HANDLER
    
    @objc func timeoutHandler () {
        
        parentController!.alert!.popupQuestion(aTitle: "", aMessage: "There seems to be a very slow connection to the conference", firstMsg: "EXIT CONFERENCE", secondMsg: "WAIT", callBack: slowConnectionResponse)
    }
    
    // MARK: CALL BACKS
    
    func slowConnectionResponse (answer: Bool) {
        
        if answer { timeoutTimer.invalidate(); endSession() }
        else { parentController!.alert!.dismiss(); return }
    }
   
    // MARK: ACTION HANDLERS
    
    @IBAction func toolBarButtonTapped(_ sender: UIBarButtonItem) {
        
        functionCalled = sender.tag
        
        switch sender.tag {
        
            case 0: alert!.popupQuestion(aTitle: "", aMessage: "Are you sure you want to end your Televet consultation?", firstMsg: "CANCEL", secondMsg: "OK") { (cancel) in if !cancel { self.endSession() } }
                
            case 1: parentController!.conferenceDocumentsFormView.frame = UIScreen.main.bounds
                    parentController!.conferenceDocumentsFormView.resetButtons(returnButtonIsHidden: false)
                    parentController!.conferenceDocumentsFormView.setTitleBarLabel(forType: .linked)
                    parentController!.conferenceDocumentsFormView.showView()
          
            case 2: parentController!.conferenceNotesFormView.frame = UIScreen.main.bounds
                    parentController!.conferenceNotesFormView.setPetName()
                    parentController!.conferenceNotesFormView.setNoteText()
                    parentController!.conferenceNotesFormView.showView()
                
            default: break
        }
    }
}
