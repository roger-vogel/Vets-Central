//
//  VCConferenceNotesView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCAppointmentNotesView: VCView, UITextViewDelegate {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var petNameLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: PROPERTIES
    
    var toolBar: UIToolbar = UIToolbar()
    var doneButton: UIBarButtonItem?
    var noteUID: Int?
    var noteText: String = ""
   
    // MARK: INITIALIZATION
    
    override func initView() {
        
        backButton.roundAllCorners(value: 10.0)
        backButton.setBorder(width: 1.0, color: UIColor.lightGray.cgColor)
        notesTextView.roundAllCorners(value: 10.0)
        notesTextView.setBorder(width: 1.0, color: UIColor.lightGray.cgColor)
        
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(dismissKeyboard))
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = false
        toolBar.tintColor = .white
        toolBar.barTintColor = UIColor(displayP3Red: 67/255, green: 146/255, blue: 203/255, alpha: 1.0)
        toolBar.sizeToFit()
        toolBar.setItems([doneButton!], animated: false)
        toolBar.isUserInteractionEnabled = true
        notesTextView.inputAccessoryView = toolBar
    
        super.initView()
    }
    
    override func loadData() {  }
    
    // MARK: METHODS
        
    func setPetName () { petNameLabel.text = globalData.user.pets[parentController.appointmentController.selectedPet!].petName }
    
    func setNoteText () {
        
        webServices!.getAppointmentNotes(theAppointment: parentController.appointmentController.apptInformationView.localAppointmentRecord) { (json, status) in
            
            guard self.webServices!.isErrorFree(json: json, status: status) else {
                
                self.notesTextView.text = self.parentController.appointmentController.apptInformationView.localAppointmentRecord.apptReason;
                return
            }
    
            let apptNotes = json["notes"] as! NSDictionary
            let notes = apptNotes["notes"] as! NSArray
            
            for n in notes {
                
                let noteFields = n as! NSDictionary
                if (noteFields["subject"] as! String) == "Help Needed" { self.notesTextView.text = (noteFields["note"] as! String); break }
            }
        }
    }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func returnButtonTapped(_ sender: Any) {
        
        dismissKeyboard()
        
        if notesTextView.text != noteText {
            
            VCAlertServices(viewController: parentController).popupYesNo(aMessage: "Do you want to save your changes?", aStyle: [.destructive,.default]) { choice in
                
                if choice == 0 {
                    
                    // TODO: ERROR HANDLER
                    self.webServices!.setAppointmentNotes(
                        
                        theAppointment: self.parentController.appointmentController.apptInformationView.localAppointmentRecord,
                        theNote: VCDBAppointmentNote(nu: self.noteUID!, mi: Int(globalData.user.data.userUID!), su: "Help Needed", nt: self.notesTextView.text!)) { (json, status) in }
                }
                
                self.hideView()
            }
        }
        
        self.hideView()
    }
        
    @IBAction func backButtonTapped(_ sender: Any) {
        
        
        returnButtonTapped(self)
        
    }
}

 
