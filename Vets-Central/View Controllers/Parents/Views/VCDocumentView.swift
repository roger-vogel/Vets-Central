//
//  VCDocumentView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/18/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit
import QuickLook

class VCDocumentView: VCView, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource {

    // MARK: OUTLETS
    
    var theTitleBarLabel: UILabel?
    var theDocumentTableView: UITableView?
    var theNoDocumentsLabel: UILabel?
    var theTableViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: PROPERTIES
    
    var anAlert: VCAlertServices?
    var subClassType: DocumentRequester?
    var quickLookController = QLPreviewController()
    var documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
    var uploadErrorMessages = [String]()
    var uploadIsCancelled: Bool?
    var documentManager: VCDocumentsManager?
    var localDocumentPath: String?
    var changedLinks = [Int:Bool]()
    var originalLinks = [VCDocMetadata]()
    var messageNeeded: Bool?

    // MARK: INITIALIZATION
    
    override func initView() {
        
        super.initView()
        
        documentManager = VCDocumentsManager(viewController: parentController)
      
        quickLookController.delegate = self
        quickLookController.dataSource = self
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        
        theDocumentTableView!.delegate = self
        theDocumentTableView!.dataSource = self
        theDocumentTableView!.allowsSelection = true
        theDocumentTableView!.separatorInset = .zero
        theDocumentTableView!.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.frame.width)
        
        theTableViewBottomConstraint.constant = parentController.tabBarController!.tabBar.frame.height
        
        anAlert = VCAlertServices(viewController: parentController)
    }
        
    // MARK: METHODS
    
    func reloadDocumentTable() {
        
        guard theDocumentTableView != nil else { return }
        globalData.user.pets[self.parentController.selectedPet!].docMetadata.sort() { $0.fileName < $1.fileName }
        theDocumentTableView!.reloadData()
        theDocumentTableView!.isHidden = false
    }
    
    func downloadMetadata() {
        
        showView()
        
        if !globalData.user.pets[parentController.selectedPet!].metadataIsDownloaded {
            
            messageNeeded = false
            theNoDocumentsLabel!.text!.removeAll()
            anAlert!.popupPendingMsg(aMessage: "Retrieving your document information")
            
            documentManager!.getMetadataFor(petUID: globalData.user.pets[parentController.selectedPet!].petUID!) { docMetadata in
                
                globalData.user.pets[self.parentController.selectedPet!].docMetadata.removeAll()
                
                if self.subClassType == .pet { self.anAlert!.dismiss() }
                
                guard docMetadata != nil else {
                    
                    self.anAlert!.popupOK(aMessage: "There seems to be a problem accessing the documents, please try again or contact the clinic")
                    return
                }
                
                globalData.user.pets[self.parentController.selectedPet!].docMetadata = docMetadata!
                globalData.user.pets[self.parentController.selectedPet!].metadataIsDownloaded = true
              
                if globalData.user.pets[self.parentController.selectedPet!].docMetadata.count == 0 { self.theNoDocumentsLabel!.text = "There are no documents on file for " + globalData.user.pets[self.parentController.selectedPet!].petName }
                else { self.theNoDocumentsLabel!.text!.removeAll() }

                if self.subClassType == .appointment || self.subClassType == .linked { self.downloadLinkedDocuments(apptUID: globalData.user.currentAppointments[self.parentController.selectedAppointment!].apptUID!) }
                else { self.reloadDocumentTable() }
            }
            
        } else if (self.subClassType == .appointment || self.subClassType == .linked) && !globalData.user.currentAppointments[self.parentController.selectedAppointment!].linksAreDownloaded {
            
            self.messageNeeded = true
            self.downloadLinkedDocuments(apptUID: globalData.user.currentAppointments[parentController.selectedAppointment!].apptUID!)
            
        } else {
            
            self.reloadDocumentTable()
            self.theDocumentTableView?.isHidden = false
        }
    }
    
    func downloadDocument(index: Int) {
        
        guard !globalData.user.pets[parentController.selectedPet!].docMetadata[index].isDownloaded else {
            
            self.localDocumentPath = globalData.user.pets[parentController.selectedPet!].docMetadata[index].localURL
            self.quickLookController.currentPreviewItemIndex = 0
            self.quickLookController.reloadData()
            self.parentController.present(self.quickLookController, animated: true, completion: nil)
            
            return
        }
    
        anAlert!.popupPendingMsg(aMessage: "Loading the document")
   
        documentManager!.getPetDocument(someMetadata: globalData.user.pets[parentController.selectedPet!].docMetadata[index]) { path in
            
            self.anAlert!.dismiss()
            
            guard path != nil else {
                
                self.anAlert!.popupOK(aMessage: "There seems to be a problem retrieving the document, please try again or contact the clinic")
                return
            }
            
            self.localDocumentPath = path!
         
            globalData.user.pets[self.parentController.selectedPet!].docMetadata[index].isDownloaded = true
            globalData.user.pets[self.parentController.selectedPet!].docMetadata[index].localURL = path!
            
            self.quickLookController.currentPreviewItemIndex = 0
            self.quickLookController.reloadData()
            self.parentController.present(self.quickLookController, animated: true, completion: nil)
        }
    }
    
    func downloadLinkedDocuments(apptUID: Int) {
        
        guard subClassType == .appointment || subClassType == .linked else { anAlert!.dismiss(); return }
        
        if messageNeeded! {
            
            anAlert!.popupPendingMsg(aMessage: "Retrieving your document information")
        }
        
        globalData.user.currentAppointments[parentController.selectedAppointment!].linkedDocuments.removeAll()
        changedLinks.removeAll()
        
        documentManager!.getLinkedDocumentsFor(apptUID: globalData.user.currentAppointments[parentController.selectedAppointment!].apptUID!) { docs in
            
            self.anAlert!.dismiss()
            
            for d in docs {
                
                for petMetadata in globalData.user.pets[self.parentController.selectedPet!].docMetadata {
                    
                    if petMetadata.fileID == d {
                        
                        globalData.user.currentAppointments[self.parentController.selectedAppointment!].linkedDocuments.append(petMetadata)
                    }
                }
            }
            
            self.originalLinks = globalData.user.currentAppointments[self.parentController.selectedAppointment!].linkedDocuments
            self.reloadDocumentTable()
            self.theDocumentTableView?.isHidden = false
          
            globalData.user.currentAppointments[self.parentController.selectedAppointment!].linksAreDownloaded = true
        }
    }
    
    func uploadDocuments(urls: [URL]) {
        
        globalData.uploadIsCancelled = false
        
        if theNoDocumentsLabel != nil { theNoDocumentsLabel!.text!.removeAll() }
        uploadErrorMessages.removeAll()
        
        anAlert!.popupPendingCancel(aMessage: "Uploading Documents", withProgressBar: true) { () in self.cancelOperation(); return }
        
        documentManager!.uploadPetDocumentFor(petUID: globalData.user.pets[parentController.selectedPet!].petUID!, urls: urls) { message, progress, index, uid in
            
            var metadata = VCDocMetadata()
            
            switch progress {
                
                
                case .inprogress:
                    
                    self.anAlert!.setProgressBar(value: Float(index+1)/Float(urls.count))
                  
                    metadata.fileID = uid!
                    metadata.localURL = urls[index].absoluteString
                    metadata.fileName = urls[index].lastPathComponent
                    
                    globalData.user.pets[self.parentController.selectedPet!].docMetadata.append(metadata)
                    
                case .complete:
                    
                    self.anAlert!.setProgressBar(value: 1.0)
                    self.anAlert!.dismiss()
                    self.theDocumentTableView!.reloadData()
                    
                case .failed, .cancelled:
                
                   self.uploadErrorMessages.append(message)
            }
        }
    }
    
    func setCellImage (indexPath: IndexPath) -> UIImage? { return nil }
        
    func cancelOperation () {
        
         self.anAlert!.dismiss()
         self.documentManager!.cancel()
         self.reloadDocumentTable()
         
         globalData.downloadIsCancelled = true
    }
    
    func onPlus() { parentController.present(documentPicker, animated: true, completion: nil) }
    
    // MARK: PLACEHOLDERS FOR SUBCLASSES
    
    func handleTableSelection(indexPath: IndexPath) { }
    
    func handleTableDeselection(indexPath: IndexPath) { }
    
    // MARK: QUICKLOOK DELEGATE PROTOCOL
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1  /*docMetadata.count*/ }
   
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
       
        return URL(fileURLWithPath: self.localDocumentPath!) as QLPreviewItem
    }
    
    // MARK: DOCUMENT PICKER DELEGATE PROTOCOL
    
    func documentPicker(_ picker: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard urls.count > 0 else { return }
        
        var fileNamesString: String = ""
        for f in urls { fileNamesString += ("\n" + f.lastPathComponent) }
        
        VCAlertServices(viewController: parentController).popupOKCancel(aTitle: "Document Upload", aMessage: "\nPlease confirm upload for:\n" + fileNamesString) { choice in
            
             if choice == 0 { self.uploadDocuments(urls: urls) }
        }
    }
    
    func documentPickerWasCancelled(_ picker: UIDocumentPickerViewController) { }
        
    // MARK: TABLE DELEGATE PROTOCOL
    
    // Report number of sections
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    // Report the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch subClassType! {
                
            case .pet:
                
                if parentController.selectedPet == nil { return 0 }
                else { return globalData.user.pets[parentController.selectedPet!].docMetadata.count }
            
            case .appointment:
            
                if parentController.selectedAppointment == nil { return 0 }
                else { return globalData.user.pets[parentController.selectedPet!].docMetadata.count }
                
            case .linked:
                
                return globalData.user.currentAppointments[parentController.selectedAppointment!].linkedDocuments.count
        }
    }
    
    // If asked for row height...
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 44 }
    
    // Capture highlight
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { return true }
    
    // Dequeue the cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        
        // Put the filename from the url into the cell label
        switch subClassType! {
            
            case .pet:
                
                cell.textLabel!.text = globalData.user.pets[self.parentController.selectedPet!].docMetadata[indexPath.row].fileName
                cell.accessoryType = .disclosureIndicator
                
            case .appointment:
                
                cell.textLabel!.text = globalData.user.pets[self.parentController.selectedPet!].docMetadata[indexPath.row].fileName
                cell.accessoryType = .detailDisclosureButton
                
            case .linked:
                
                cell.textLabel!.text = globalData.user.currentAppointments[parentController.selectedAppointment!].linkedDocuments[indexPath.row].fileName
                cell.accessoryType = .disclosureIndicator
    
        }
       
        cell.backgroundColor = .white
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        cell.imageView!.image = setCellImage(indexPath: indexPath)
        cell.textLabel!.textColor = .label
        
        if subClassType == .appointment { cell.accessoryType = .detailDisclosureButton }
        else { cell.accessoryType = .disclosureIndicator}

        // Return the cell
        return cell
    }
    
    // Capture selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { handleTableSelection(indexPath: indexPath) }
    
    // Capture Deselection
    func tableView( _ tableView: UITableView, didDeselectRowAt: IndexPath) { handleTableDeselection(indexPath: didDeselectRowAt) }
 
    // Detail button
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) { downloadDocument(index: indexPath.row) }
}
