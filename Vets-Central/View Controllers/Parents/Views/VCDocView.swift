//
//  VCDocView.swift
//  Vets-Central
//
//  Descendent of VCView class adding document upload, download and viewing methods
//  Created by Roger Vogel on 1/26/21.
//  Copyright © 2021 Roger Vogel. All rights reserved. 
//  

import UIKit
import QuickLook

class VCDocView: VCView, QLPreviewControllerDelegate, QLPreviewControllerDataSource {

    // MARK: PROPERTIES
    
    var theTable: UITableView?
 
    var linkedDocsMetaData = [VCDocMetadata]()
    var quickLookController = QLPreviewController()
    var selectedDocument: Int = -1
    var documentCounter: Int = 0
    var downloadCounter: Int?
    var docTarget: DocumentTarget?
    var appointmentController: VCApptViewController?
    var thePetRecord: VCPetRecord?
    var theAppointmentRecord: VCAppointmentRecord?
    var documentToDelete: IndexPath?
    
    // MARK: INITIALIZATION
    
    override func initView() {
        
        // Assign quicklook controller elements
        quickLookController.delegate = self
        quickLookController.dataSource = self
        
        super.initView()
    }
    
    // MARK: TABLE MANAGEMENT METHODS
    
    func clearLinkFlags () {
        
        guard docMetaData.count != 0 else { return }
        for d in 0...docMetaData.count - 1 { docMetaData[d].isLinked = false }
    }
        
    func setLinkFlag (withFileID: Int, toState: Bool ) {
        
        for d in 0...docMetaData.count - 1 { if docMetaData[d].fileID == withFileID { docMetaData[d].isLinked = toState } }
    }
    
    func setCellImage (indexPath: IndexPath) -> UIImage {
        
        var cellImage: UIImage?
        let isLinked = docMetaData[indexPath.row].isLinked
        var imageLinkedFile: String?
        var imageUnlinkedFile: String?
        let defaultImageLinkedFile = "icon.table.document.linked.png"
        let defaultImageUnlikedFile = "icon.table.document.png"
        
        // Get the file type
        let fileCategory = fileCategories[VCFileServices().getFileExtension(fileName: docMetaData[indexPath.row].fileName)!.lowercased()]
        
        if fileCategory != nil {
            
            imageLinkedFile = "icon.table." + fileCategory! + ".linked.png"
            imageUnlinkedFile = "icon.table." + fileCategory! + ".png"
        }
        
        if imageLinkedFile == nil || imageUnlinkedFile == nil {
            
            imageLinkedFile = defaultImageLinkedFile
            imageUnlinkedFile = defaultImageUnlikedFile
        }
        
        // Only show link icons if this is the appointment doc view
        if isLinked && docTarget == .appointment { cellImage = UIImage(named: imageLinkedFile!) }
        else { cellImage = UIImage(named: imageUnlinkedFile!) }
            
        return cellImage!
    }
    
    // MARK: UPLOAD METHODS
    
    func confirmUpLoad (theURLS: [URL]) {
        
        var fileNamesString: String = ""
        
        currentURLS = theURLS
        for f in theURLS { fileNamesString += ("\n" + f.lastPathComponent) }
        
        alert!.popupQuestion(aTitle: "Document Upload", aMessage: "\nPlease confirm upload for:\n" + fileNamesString, firstMsg: "CANCEL", secondMsg: "OK", trueSelection: .second, callBack: uploadConfirmationResponse)
    }
    
    func doUpload (url: URL) {
        
        var fileData: Data?
        let fileType = fileTypes[url.pathExtension.lowercased()]
        var target: String?
        var uid: String?
        var error: NSError? = nil
        
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { (url) in
                
            let accessGranted = url.startAccessingSecurityScopedResource()
            guard accessGranted else { NSLog("*** ACCESS NOT GRANTED ***"); return }
            
          //  fileData = FileManager().contents(atPath: url.path)
            
            do { try fileData = Data(contentsOf: url) }
            catch { NSLog("*** File Read Error"); print("*** File Read Error") }
                
            url.stopAccessingSecurityScopedResource()
            
            switch docTarget {
            
                case .pet: target = "pet"; uid = globalData.user.pets[parentController()!.petController().selectedPet].petUID
                case .appointment: target = "appointment"; uid = self.appointmentController!.appointmentFormView.localAppointmentRecord.apptUID
                default: break
            }
            
            VCWebServices().uploadDocument(theTarget: target!, theUID: uid!, theFileType: fileType!, theFileData: fileData!, theFileName: url.lastPathComponent, callBack: self.uploadResponse)
        }
    }
    
    func documentUploadHasCompleted (docMetaData: VCDocMetadata) { /* Placeholder for subclasses */ }
    
    
    func getLinkedAppointmentDocs () {
        
        if docTarget == .linked || docTarget == .appointment{ VCWebServices().getLinkedDocumentsForAppointment(theAppointment: theAppointmentRecord!, callBack: getLinkedDocumentResponse) }
        else { downloadComplete() }
    }
    
    func downloadComplete() {
        
        switch  docTarget {
        
            case .pet: parentController()!.petController().petInformationView.localPetRecord!.docsAreDownloaded = true    //thePetRecord!.docsAreDownloaded = true
            case .appointment: globalData.user.pets[appointmentController!.selectedPet].docsAreDownloaded = true
            case .linked: globalData.user.pets[appointmentController!.selectedPet].docsAreDownloaded = true
            default: break
        }
        
        reloadDocumentTable()
        alert?.dismiss()
    }
    
    // MARK: DISPLAY DOCUMENT METHODS
        
    func displayDocument () {
        
        var saveSelection: Int?
        
        switch docTarget {
        
            case .pet:  saveSelection = parentController()!.petController().selectedPet
            case .appointment:  saveSelection = appointmentController!.selectedPet
            default: break
        }
   
        if parentController()!.presentedViewController == nil {
            
            quickLookController.currentPreviewItemIndex = selectedDocument
            quickLookController.reloadData()
            parentController()!.present(quickLookController, animated: true, completion: {
                                
                switch self.docTarget {
                
                    case .pet: self.parentController()!.petController().selectedPet = saveSelection!
                    case .appointment: self.appointmentController?.selectedAppointment = saveSelection!
                    default: break
                }
            })
        }
        else {
            
            parentController()!.dismiss(animated: true, completion: {
                
                self.quickLookController.currentPreviewItemIndex = self.selectedDocument
                self.quickLookController.reloadData()
                self.parentController()!.present(self.quickLookController, animated: true, completion: {
                                            
                    switch self.docTarget {
                    
                        case .pet: self.parentController()!.petController().selectedPet = saveSelection!
                        case .appointment: self.appointmentController?.selectedAppointment = saveSelection!
                        default: break
                    }
                })
            })
        }
    }
    
    // MARK: QUICKLOOK DELEGATE PROTOCOL
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1  /*docMetaData.count*/ }
   
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return (URL(fileURLWithPath: docMetaData[selectedDocument].localURL)) as QLPreviewItem }
        
    // MARK: CALL BACKS
    
    func uploadConfirmationResponse (success: Bool) {
        
        guard success else { return }
        
        if documentCounter < currentURLS.count {
            
            alert!.popupPendingMsg(aTitle: "", aMessage: "Uploading " + currentURLS[documentCounter].lastPathComponent)
            doUpload(url: currentURLS[documentCounter])
            documentCounter += 1
        }
        else {
            
            alert?.popupOK(aTitle: "Upload Complete", aMessage: String(format: "\nUploaded %d document(s) successfully", currentURLS.count) )
            docMetaData.sort() { $0.fileName < $1.fileName }
            theTable?.reloadData()
        }
    }
    
    func uploadResponse (json: NSDictionary, webServiceSuccess: Bool ) {
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
        guard success.webServiceSuccess else { VCAlertServices(viewController: parentController()!).popupOK(aTitle: "", aMessage: success.errorString); NSLog(success.errorString); return}
        
        // Save the path the the URL array
        if webServiceSuccess {
            
            var theDocMetaData = VCDocMetadata()
            
            let url = currentURLS[documentCounter-1]
            
            let docData = VCFileServices().readFile(fullPath: url.path)
            let path = VCFileServices().createFile(theContents: docData!, name: url.lastPathComponent  )
 
            theDocMetaData.localURL = path!
            theDocMetaData.fileName = url.lastPathComponent
            theDocMetaData.fileType = fileTypes[url.pathExtension.lowercased()]!
           
            let documentInfo = (json["documentInstance"] as! NSDictionary)
            theDocMetaData.docFileID = String(documentInfo["id"] as! Int)
            theDocMetaData.petUID = String(documentInfo["pet"] as! Int)
            
            // Append the new document transfer data
            docMetaData.append(theDocMetaData)
            
            // Placeholder for children to do something
            documentUploadHasCompleted(docMetaData: theDocMetaData)
            
            // Get the next document
            uploadConfirmationResponse(success: true)
        }
    }
    
    func deleteDocumentResponse(json: NSDictionary, webServiceSuccess: Bool) {
        
        var indexPaths = [IndexPath]()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
        guard success.webServiceSuccess else { VCAlertServices(viewController: parentController()!).popupOK(aTitle: "", aMessage: success.errorString); NSLog(success.errorString); return}
        
        docMetaData.remove(at: documentToDelete!.row)
        indexPaths.append(documentToDelete!)
        theTable!.deleteRows(at: indexPaths, with: .fade)
    }
    
    func getLinkedDocumentResponse (json: NSDictionary, webServiceSuccess: Bool) {
        
        let success = VCErrorServices().checkForWebServiceError(json: json, webServiceSuccess: webServiceSuccess)
        guard success.webServiceSuccess else { VCAlertServices(viewController: parentController()!).popupOK(aTitle: "", aMessage: success.errorString); NSLog(success.errorString); return}
        
        // Save the already linked documents into docsLinkedUID array
        let linkedDocs = (json["documents"] as! NSArray)
        
        clearLinkFlags()
     
        for linkInfo in linkedDocs {
            
            let docInfo = (linkInfo as! NSDictionary)
            let fileUID = (docInfo["fileId"] as! Int)
        
            setLinkFlag(withFileID: fileUID, toState: true)
        }
      
        linkedDocsMetaData.removeAll()
        for i in docMetaData { if i.isLinked { linkedDocsMetaData.append(i) } }
      
        downloadComplete()
    }
}
 
   

 
  
 
 
 
