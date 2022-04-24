//
//  VCConferenceDocumentView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//  

import UIKit 
import QuickLook 

class VCAppointmentDocumentView: VCDocumentView {
 
    // MARK: OUTLETS
    
    @IBOutlet weak var titleBarLabel: UILabel!
    @IBOutlet weak var documentTableView: UITableView!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var noDocumentsLabel: UILabel!
    
    // MARK: INITIALIZATION AND OVERRIDES
    
    override func initView() {

        subClassType = .appointment
        theTitleBarLabel = titleBarLabel
        theNoDocumentsLabel = noDocumentsLabel
        theDocumentTableView = documentTableView
        theTableViewBottomConstraint = tableViewBottomConstraint
        
        super.initView()
        resetButton.setBorder(width: 1, color: UIColor.lightGray.cgColor)
        resetButton.roundAllCorners(value: 3)
      
        saveButton.setBorder(width: 1, color: UIColor.lightGray.cgColor)
        saveButton.roundAllCorners(value: 3)
       
        super.initView()
    }
    
    override func handleTableSelection(indexPath: IndexPath) {
    
        if subClassType == .appointment {
            
            setButtons(returnButtonIsHidden: true)
            setLinkedState(indexPath: indexPath)
            
        }  else {
            
            setButtons(returnButtonIsHidden: false)
            let theAppointment = globalData.user.currentAppointments[parentController.selectedAppointment!]
            let theDocument = theAppointment.linkedDocuments[indexPath.row]
            let thePet = VCRecordGetter().petRecordWith(uid: theAppointment.petUID!)
           
            for (index,value) in thePet!.docMetadata.enumerated() {
                
                if value.fileID == theDocument.fileID {
                    
                    downloadDocument(index: index)
                    break
                }
            }
        }
    }
  
    override func handleTableDeselection(indexPath: IndexPath) {
        
        setButtons(returnButtonIsHidden: true)
        if subClassType == .appointment { setLinkedState(indexPath: indexPath) }
    }

    override func setCellImage(indexPath: IndexPath) -> UIImage? {
        
        var linkedImageSourceFile: String?
        var unlinkedImageSourceFile: String?
    
        let fileID = globalData.user.pets[parentController.selectedPet!].docMetadata[indexPath.row].fileID
        let fileCategory = fileCategories[VCFileServices().getFileExtension(fileName: globalData.user.pets[self.parentController.selectedPet!].docMetadata[indexPath.row].fileName)!.lowercased()]
        let isLinked = globalData.user.currentAppointments[parentController.selectedAppointment!].hasLinkedFileWith(fileID: fileID).result
        
        // Set the image files
        if fileCategory != nil {
            
            linkedImageSourceFile = "icon.table." + fileCategory! + ".linked.png"
            unlinkedImageSourceFile = "icon.table." + fileCategory! + ".png"
            
        } else {
            
            linkedImageSourceFile = "icon.table.document.linked.png"
            unlinkedImageSourceFile = "icon.table.document.png"
        }
        
        // Set image
        if isLinked { return UIImage(named: linkedImageSourceFile!) }
        else { return UIImage(named: unlinkedImageSourceFile!) }
    }
 
    // MARK: METHODS
    
    func setupView () {
   
        if subClassType == .linked { titleBarLabel.text = "Appointment Documents" }
        else { titleBarLabel.text = "Select Appt Documents" }
    
        downloadMetadata()
        setButtons(returnButtonIsHidden: false)
    }
    
    func setButtons(returnButtonIsHidden: Bool) {
        
        resetButton.isHidden = !returnButtonIsHidden
        saveButton.isHidden = !returnButtonIsHidden
        returnButton.isHidden = returnButtonIsHidden
    }
    
    func setLinkedState(indexPath: IndexPath) {
        
        let petRecord = globalData.user.pets[parentController.selectedPet!]
        let apptRecord = globalData.user.currentAppointments[parentController.selectedAppointment!]
        
        // Get the fileID of the document changing linked state
        let fileID = petRecord.docMetadata[indexPath.row].fileID
     
        // Check if this document is linked
        let linkedState = apptRecord.hasLinkedFileWith(fileID: fileID)
      
        // If so, remove it and set/update the dictionary
        if linkedState.result {
            
            globalData.user.currentAppointments[parentController.selectedAppointment!].linkedDocuments.remove(at: linkedState.index!)
          
            if changedLinks[fileID] != nil { changedLinks.updateValue(false, forKey: fileID) }
            else { changedLinks[fileID] = false }
        }
        
        // Otherwise add it to the linked list and update dictionary
        else {
            
            globalData.user.currentAppointments[parentController.selectedAppointment!].linkedDocuments.append(petRecord.docMetadata[indexPath.row])
            
            if changedLinks[fileID] != nil { changedLinks.updateValue(true, forKey: fileID) }
            else { changedLinks[fileID] = true }
        }
    
        reloadDocumentTable()
    }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func returnButtonTapped(_ sender: Any) {
     
        if !saveButton.isHidden {
            
            var linkedDocs = [Int]()
            var unlinkedDocs = [Int]()
            let apptRecord = globalData.user.currentAppointments[parentController.selectedAppointment!]
           
            for changed in changedLinks {
                
                if changed.value == true { linkedDocs.append(changed.key) }
                else { unlinkedDocs.append(changed.key) }
            }
            
            if !linkedDocs.isEmpty {
                
                parentController.appointmentController.webServices!.linkDocuments(theDocuments: VCDBLinkDocuments(documentUIDs: linkedDocs), theAppointment: apptRecord) { json, status in
                    
                    guard self.parentController.appointmentController.webServices!.isErrorFree(json: json, status: status, showAlert: false) else { return }
                    
                    if !unlinkedDocs.isEmpty {
                        
                        self.parentController.appointmentController.webServices!.unlinkDocuments(theDocuments: VCDBLinkDocuments(documentUIDs: linkedDocs), theAppointment: apptRecord) { json, status in
                            
                            guard self.parentController.appointmentController.webServices!.isErrorFree(json: json, status: status, showAlert: false) else { self.hideView(); return }
                           
                            self.parentController.controllerAlert!.popupMessage(aMessage: "Document links are saved")
                            self.hideView()
                        }
                        
                    } else {
                        
                        self.parentController.controllerAlert!.popupMessage(aMessage: "Document links are saved")
                        self.hideView()
                    }
                }
                
            } else if !unlinkedDocs.isEmpty {
            
                self.parentController.appointmentController.webServices!.unlinkDocuments(theDocuments: VCDBLinkDocuments(documentUIDs: linkedDocs), theAppointment: apptRecord) { json, status in
                    
                    guard self.parentController.appointmentController.webServices!.isErrorFree(json: json, status: status, showAlert: false) else { self.hideView(); return }
                    
                    self.parentController.controllerAlert!.popupMessage(aMessage: "Document links are saved")
                    self.hideView()
                }
                
            } else { hideView() }
            
        } else { hideView() }
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        
        globalData.user.currentAppointments[parentController.selectedAppointment!].linkedDocuments = originalLinks
        setButtons(returnButtonIsHidden: false)
        reloadDocumentTable()
    }
}
