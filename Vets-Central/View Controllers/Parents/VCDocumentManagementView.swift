//
//  VCDocumentManagementView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 9/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit
import QuickLook

class VCDocumentManagementView: UIView, QLPreviewControllerDelegate, QLPreviewControllerDataSource {

    /// PROPERTIES
    
    var theParent: UIViewController?
    var theTable: UITableView?
    var docMetaData = [VCDocMetaData]()
    var linkedDocsMetaData = [VCDocMetaData]()
    var currentURLS = [URL]()
    var swipeInForm: UIView?
    var slideType: SlideIn = .disabled
    var alert: VCPopupAlert?
    var documentCounter: Int = 0
    var slideInDidOccur: Bool?
    var quickLookController = QLPreviewController()
    var selectedDocument: Int = -1
    var downloadCounter: Int?
    var docTarget: DocumentTarget?
    var petController: VCPetsViewController?
    var appointmentController: VCAppointmentViewController?
    var thePetRecord: VCPetRecord?
    var theAppointmentRecord: VCAppointmentRecord?
    var documentToDelete: IndexPath?
   

    /// INITIALIZATION
    
    func initView(parent: UIViewController ) {
        
        // Assign quicklook controller elements
        quickLookController.delegate = self
        quickLookController.dataSource = self
        
        // Connect the view controller for this form
        theParent = parent
        
        // Setup swipe gesture capture
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
             
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        self.addGestureRecognizer(leftSwipe)
        self.addGestureRecognizer(rightSwipe)
        
        // Initially hide form
        self.alpha = 0.0
        self.frame = theParent!.view.frame
        
        // Create alert
        alert = VCPopupAlert(viewController: theParent!)
        
        // If this is a slide in, adust initialize frame accordingly
        switch slideType {
        
            case .childr: self.frame.origin.x = self.frame.size.width
            case .childl: self.frame.origin.x = -self.frame.size.width

            default: break
        }
        
        if theTable != nil { theTable?.allowsSelection = true }
        
        loadData()
    }
    
    func loadData() {}
    
    /// METHODS
    
    func confirmUpLoad (theURLS: [URL]) {
        
        var fileNamesString: String = ""
        
        currentURLS = theURLS
        for f in theURLS { fileNamesString += ("\n" + f.lastPathComponent) }
        
        alert!.popupQuestion(aTitle: "Document Upload", aMessage: "\nPlease confirm upload for:\n" + fileNamesString, firstMsg: "CANCEL", secondMsg: "OK", trueSelection: .second, callBack: uploadConfirmationResponse)
    }
    
    func doUpload (url: URL) {
        
        let fileData = VCFileServices().readFile(fullPath: url.path)
        let fileType = fileTypes[url.pathExtension.lowercased()]
        var target: String?
        var uid: String?
        
        switch docTarget {
        
            case .pet: target = "pet"; uid = globalData.user.pets[petController!.selectedPet].petUID
            case .appointment: target = "appointment"; uid = appointmentController!.appointmentFormView.localAppointmentRecord.apptUID
            default: break
        }
        
        VCWebServices().uploadDocument(theTarget: target!, theUID: uid!, theFileType: fileType!, theFileData: fileData!, theFileName: url.lastPathComponent, callBack: uploadResponse)
    }
    
    func onSwipe (direction: UISwipeGestureRecognizer.Direction) {
        
        // If we are parent, only react if the swipe matches our child
        if slideType == .parentr { if direction == .left { slideInDidOccur = true; swipeInForm?.slideIn(forDuration: 0.25, atCompletion: {  self.swipeInFormDidShow() }) } }
        if slideType == .parentl { if direction == .right { slideInDidOccur = true; swipeInForm?.slideIn(forDuration: 0.25, atCompletion: { self.swipeInFormDidShow() }) } }
        
        if slideType == .childr { swipeInFormDidHide(); if direction == .right { slideInDidOccur = false; swipeInForm?.slideOut(forDuration: 0.25, atCompletion: { self.alpha = 0.0 }) } }
        if slideType == .childr { if direction == .left { slideInDidOccur = true; swipeInForm?.slideIn(forDuration: 0.25, atCompletion: { self.swipeInFormDidShow() }) } }
        
        if slideType == .childl { swipeInFormDidHide(); if direction == .left { slideInDidOccur = false; swipeInForm?.slideOut(forDuration: 0.25, atCompletion: { self.alpha = 0.0 }) } }
        if slideType == .childl { if direction == .right { slideInDidOccur = true; swipeInForm?.slideIn(forDuration: 0.25, atCompletion: { self.swipeInFormDidShow() }) } }
        
        swipeInFormDidOccur()
    }
    
    func swipeInFormDidOccur() {}
    
    func swipeInFormDidShow() {}
    
    func swipeInFormDidHide() {}
    
    func showForm() { self.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: { return }) }
    
    func hideForm() { self.changeDisplayState(toState: .hidden, forDuration: 0.25, atCompletion: { return }) }

    func messageAlert (aTitle: String? = "", aMessage: String) { alert!.popupOK(aTitle: aTitle!, aMessage: aMessage) }
    
    func messageAlert (aTitle: String? = "", aMessage: String, atCompletion: @escaping ()-> Void ) { alert!.popupOK(aTitle: aTitle!, aMessage: aMessage, callBack: atCompletion) }
    
    func questionAlert (aTitle: String? = "", aMessage: String, atCompletion: @escaping (Bool)-> Void ) { alert!.popupYesNo(aTitle: aTitle!, aMessage: aMessage, callBack: atCompletion) }
    
    func activityAlert (aTitle: String? = "", aMessage: String) { alert!.popupPendingMsg(aTitle: aTitle!, aMessage: aMessage) }
    
    func dismissActivityAlert() { alert?.dismiss() }
    
    func documentUploadHasCompleted (docMetaData: VCDocMetaData) {}
    
    func getDocumentsMetaData() {
        
        docMetaData.removeAll()
        theTable?.reloadData()
        
        switch docTarget {
        
            case .pet:
                
                if !thePetRecord!.docsAreDownloaded {
                    
                    alert?.popupPendingMsg(aTitle: "", aMessage: "Checking for documents")
                    VCWebServices().requestDocumentsMetaData(theTarget: "pet", theUID: petController!.petInformationView.localPetRecord!.petUID, callBack: documentsRequestResponse)
                }
                
                else {
                    
                    docMetaData = petController!.petInformationView.localPetRecord!.docMetaData
                    reloadDocumentTable()
                }
                
            case .appointment:
                
                alert?.popupPendingMsg(aTitle: "", aMessage: "Checking for documents")
                VCWebServices().requestDocumentsMetaData(theTarget: "pet", theUID: globalData.user.pets[appointmentController!.selectedPet].petUID, callBack: documentsRequestResponse)
                
            case .linked:
            
            alert?.popupPendingMsg(aTitle: "", aMessage: "Checking for documents")
                VCWebServices().requestDocumentsMetaData(theTarget: "pet", theUID: globalData.user.pets[appointmentController!.selectedPet].petUID, callBack: documentsRequestResponse)
         
            default: break
        }
    }
    
    func getServerDocuments() {
        
        if downloadCounter! < docMetaData.count {
            
            if docMetaData[downloadCounter!].localURL == "" {
                
                let theCallURL = docMetaData[downloadCounter!].downloadURL
                let theFileName = docMetaData[downloadCounter!].fileName
                
                VCWebServices().downloadDocument(callURL: theCallURL) { (docData: Data?, status: Bool) in
                    
                    /// TODO: ADD ERROR CHECKING HERE
                    
                    let path = VCFileServices().createFile(theContents: docData!, name: theFileName)
                    
                    if path != nil {
                        
                        self.docMetaData[self.downloadCounter!].localURL = path!
                        self.downloadCounter! += 1
                        
                        if self.downloadCounter == self.docMetaData.count {
                            
                            self.getLinkedAppointmentDocs()
                            
                            if self.docTarget == DocumentTarget.pet {
                                
                                globalData.user.pets[self.petController!.selectedPet].docMetaData = self.docMetaData
                                globalData.user.pets[self.petController!.selectedPet].docsAreDownloaded = true
                            }
                            
                            else {
                                
                                globalData.user.pets[self.appointmentController!.selectedPet].docMetaData = self.docMetaData
                                globalData.user.pets[self.appointmentController!.selectedPet].docsAreDownloaded = true
                            }
                        }
                        else { self.getServerDocuments() }
                    }
                }
            }
            
            else {
                
                downloadCounter! += 1
                if downloadCounter == docMetaData.count { getLinkedAppointmentDocs() }
                else { getServerDocuments() }
            }
        }
    }
    
    func getLinkedAppointmentDocs () {
        
        if docTarget == DocumentTarget.appointment || docTarget == DocumentTarget.linked { VCWebServices().getLinkedDocumentsForAppointment(theAppointment: theAppointmentRecord!, callBack: getLinkedDocumentResponse) }
        else { alert!.dismiss(); reloadDocumentTable() }
    }
        
    func docsRetrieved () {}
    
    func displayDocument () {
        
        var saveSelection: Int?
        
        switch docTarget {
        
            case .pet:  saveSelection = petController!.selectedPet
            case .appointment:  saveSelection = appointmentController!.selectedPet
            default: break
        }
   
        if theParent!.presentedViewController == nil {
            
            quickLookController.currentPreviewItemIndex = selectedDocument
            quickLookController.reloadData()
            theParent!.present(quickLookController, animated: true, completion: {
                                
                switch self.docTarget {
                
                    case .pet: self.petController!.selectedPet = saveSelection!
                    case .appointment: self.appointmentController?.selectedAppointment = saveSelection!
                    default: break
                }
            })
        }
        else {
            
            theParent!.dismiss(animated: true, completion: {
                
                self.quickLookController.currentPreviewItemIndex = self.selectedDocument
                self.quickLookController.reloadData()
                self.theParent!.present(self.quickLookController, animated: true, completion: {
                                            
                    switch self.docTarget {
                    
                        case .pet: self.petController!.selectedPet = saveSelection!
                        case .appointment: self.appointmentController?.selectedAppointment = saveSelection!
                        default: break
                    }
                })
            })
        }
    }
    
    func reloadDocumentTable() {
        
        guard theTable != nil else { return }
        docMetaData.sort() { $0.fileName < $1.fileName };
        theTable?.reloadData()
    }
    
    func clearLinkFlags () {  for d in 0...docMetaData.count - 1 { docMetaData[d].isLinked = false } }
        
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
        
        if isLinked { cellImage = UIImage(named: imageLinkedFile!) }
        else { cellImage = UIImage(named: imageUnlinkedFile!) }
            
        return cellImage!
    }
   
    /// QUICKLOOK PROTOCOL
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1  /*docMetaData.count*/ }
   
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return (URL(fileURLWithPath: docMetaData[selectedDocument].localURL)) as QLPreviewItem }
        
    /// CALL BACKS
    
    func uploadConfirmationResponse (status: Bool) {
        
        guard status else { return }
        
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
    
    func uploadResponse (json: NSDictionary, status: Bool ) {
        
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { VCPopupAlert(viewController: theParent!).popupOK(aTitle: "", aMessage: success.errorString); return}
        
        // Save the path the the URL array
        if status {
            
            var theDocMetaData = VCDocMetaData()
            
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
            uploadConfirmationResponse(status: true)
        }
    }
    
    func documentsRequestResponse(json: NSDictionary, status: Bool) {
        
        var theDocMetaData = VCDocMetaData()
        var duplicateDocument: Bool?
    
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { VCPopupAlert(viewController: petController!).popupOK(aTitle: "", aMessage: success.errorString); return}
        
        var docNotes: String?
        let documents = json["documents"] as! NSArray
        
        guard documents.count > 0 else { alert?.dismiss(); return }
        
        for d in documents {
            
            // Each array element holds a dictionary
            let document = d as! NSDictionary
            
            if document["notes"] is NSNull { docNotes = "" } else { docNotes = (document["notes"] as! String) }
            
            theDocMetaData.fileID = (document["fileId"] as! Int)
            theDocMetaData.fileName = (document["fileName"] as! String)
            theDocMetaData.fileType = (document["fileType"] as! String)
            theDocMetaData.previewURL = (document["previewURL"] as! String)
            theDocMetaData.downloadURL = (document["downloadURL"] as! String)
            theDocMetaData.notes = docNotes!
            theDocMetaData.docFolderID = (document["docFolderId"] as! String)
            theDocMetaData.docFileID = (document["docFileId"] as! String)
            
            // Fix API problem
            if theDocMetaData.downloadURL[31] == "2" { theDocMetaData.downloadURL = theDocMetaData.downloadURL.replacingOccurrences(of: "v2", with: "v4") }

            // Initialize the duplicate doc flag
            duplicateDocument = false
            
            // Make sure we don't already have this document
            
            if docMetaData.count > 0 {
                
                for d in docMetaData { if d.fileID == theDocMetaData.fileID { duplicateDocument = true; break } }
            }
            
            if !duplicateDocument! { docMetaData.append(theDocMetaData) }
        }
        
        downloadCounter = 0
        getServerDocuments()
    }
    
    func deleteDocumentResponse(json: NSDictionary, status: Bool) {
        
        var indexPaths = [IndexPath]()
        
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { VCPopupAlert(viewController: theParent!).popupOK(aTitle: "", aMessage: success.errorString); return}
        
        docMetaData.remove(at: documentToDelete!.row)
        indexPaths.append(documentToDelete!)
        theTable!.deleteRows(at: indexPaths, with: .fade)
    }
    
    func getLinkedDocumentResponse (json: NSDictionary, status: Bool) {
        
        let success = VCErrorServices().checkForWebServiceError(json: json, status: status)
        guard success.status else { VCPopupAlert(viewController: theParent!).popupOK(aTitle: "", aMessage: success.errorString); return}
        
        // Save the already linked documents into docsLinkedUID array
        let linkedDocs = (json["documents"] as! NSArray)
        
        clearLinkFlags()
     
        for linkInfo in linkedDocs {
            
            let docInfo = (linkInfo as! NSDictionary)
            let fileUID = (docInfo["fileId"] as! Int)
        
            setLinkFlag(withFileID: fileUID, toState: true)
        }
      
        for i in docMetaData { if i.isLinked { linkedDocsMetaData.append(i) } }
        reloadDocumentTable()
        alert?.dismiss()
    }

    /// ACTION HANDLERS
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        
        guard swipeInForm != nil else { return }
        onSwipe(direction: sender.direction)
    }
}

