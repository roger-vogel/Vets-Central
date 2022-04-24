//
//  VCDocumentsManager.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/26/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit

class VCDocumentsManager: NSObject, UIDocumentPickerDelegate {
    
    // MARK: PROPERTIES
    
    var anAlert: VCAlertServices?
    var counter: Int = 0
    var thePetUID: String?
    var theViewController: VCViewController?
    var theMetadata = [VCDocMetadata]()
    var documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
    var documentWebService: VCWebServices?
    
    // MARK: COMPUTED PROPERTIES
    
    public var metadata: [VCDocMetadata] { return theMetadata }
    
    // MARK: INITIALIZATION
    
    init(viewController: VCViewController) {
        
        theViewController = viewController
        anAlert = VCAlertServices(viewController: theViewController!)
      
        super.init()
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        
        documentWebService = VCWebServices(parent: self.theViewController!)
    }
    
    // MARK: METHODS
    
    func getMetadataFor(petUID: Int, callBack: @escaping ([VCDocMetadata]?) -> Void) {
        
        theMetadata.removeAll()
        
        documentWebService!.requestDocumentsMetadata(theTarget: "pet", theUID: petUID) { (json,status) in
            
            guard self.documentWebService!.isErrorFree(json: json, status: status ) else { return }
       
            var docNotes: String?
            var metadata = VCDocMetadata()
            let documents = json["documents"] as! NSArray
            
            for d in documents {
                
                // Each array element holds a dictionary
                let document = d as! NSDictionary
                
                if document["notes"] is NSNull { docNotes = "" } else { docNotes = (document["notes"] as! String) }
                
                metadata.fileID = (document["fileId"] as! Int)
                metadata.fileName = (document["fileName"] as! String)
                metadata.fileType = (document["fileType"] as! String)
                metadata.previewURL = (document["previewURL"] as! String)
                metadata.downloadURL = (document["downloadURL"] as! String)
                metadata.notes = docNotes!
                metadata.docFolderID = (document["docFolderId"] as! String)
                metadata.docFileID = (document["docFileId"] as! String)
                
                // Fix API problem
                if metadata.downloadURL[31] == "2" { metadata.downloadURL = metadata.downloadURL.replacingOccurrences(of: "v2", with: "v4") }

                self.theMetadata.append(metadata)
            }
            
            let index = VCRecordGetter().petIndexWith(uid: petUID)
            
            globalData.user.pets[index!].docMetadata = self.theMetadata
            globalData.user.pets[index!].metadataIsDownloaded = true
            
            callBack(self.theMetadata)
        }
    }
    
    func getPetDocument(someMetadata: VCDocMetadata, callBack: @escaping (String?) -> Void) {
        
        self.documentWebService!.downloadDocument(documentUID: someMetadata.fileID) { (docData: Data?, status: Bool) in
            
            guard status else { callBack(nil); return }
            
            let path = VCFileServices().createFile(theContents: docData!, name: someMetadata.fileName)
            callBack(path)
        }
    }
    
    func getLinkedDocumentsFor(apptUID: Int, callBack: @escaping ([Int]) -> Void) {
        
        var fileUIDS = [Int]()
        
        documentWebService!.getLinkedDocumentsForAppointment(apptUID: apptUID) { (json,status) in
            
            guard self.theViewController!.webServices!.isErrorFree(json: json, status: status ) else { return }
            
            let linkedDocs = (json["documents"] as! NSArray)
        
            for linkInfo in linkedDocs {
                
                let docInfo = (linkInfo as! NSDictionary)
                let fileUID = (docInfo["fileId"] as! Int)
                
                fileUIDS.append(fileUID)
            }
               
            callBack(fileUIDS)
        }
    }
    
    func linkPetDocumentsTo(apptUID: Int) { }
 
    func uploadPetDocumentFor(petUID: Int, urls: [URL], callBack: @escaping (String,UploadProgress,Int,Int?) -> Void) {
        
        uploadDocument(thePetUID: petUID, theURLS: urls, theCallBack: callBack)
    }
    
    func cancel() {
        
        if globalData.webServiceQueue.last != nil {
           
            globalData.webServiceQueue.last!.dataTask!.cancel()
            globalData.webServiceQueue.removeLast()
            
        }
    }
    
    // MARK: PRIVATE METHOD
    
    private func uploadDocument(index: Int? = 0, thePetUID: Int, theURLS: [URL], theCallBack: @escaping (String,UploadProgress,Int,Int?) -> Void ) {
        
        // Operation complete so exit the recursion
        guard index! < theURLS.count else { theCallBack("", .complete, index!, nil); return }
 
        var fileData: Data?
        var error: NSError? = nil
        let url = theURLS[index!]
        let fileType = fileTypes[url.pathExtension.lowercased()]
    
        // Get permission to read the file
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { (url) in
            
            let accessGranted = url.startAccessingSecurityScopedResource()
            
            if !accessGranted  {
                
                NSLog("*** ACCESS NOT GRANTED ***")
                theCallBack("It appears that you don't have permission to access " + url.lastPathComponent, .failed, index!, nil)
                self.uploadDocument(index: index! + 1, thePetUID: thePetUID, theURLS: theURLS, theCallBack: theCallBack)

            } else {
                
                do {
                    
                    try fileData = Data(contentsOf: url)
                    
                    documentWebService!.uploadDocument(theTarget: "pet", theUID: thePetUID, theFileType: fileType!, theFileData: fileData!, theFileName: url.lastPathComponent) { (json, status) in
                        
                        if self.documentWebService!.isErrorFree(json: json, status: status) {
                         
                            theCallBack("Uploading " + url.lastPathComponent + "has failed, upload will continue with other documents",.failed,index!,nil)
                            
                        } else {
                            
                            let documentUID = (json["documentInstance"] as! NSDictionary)["id"] as! Int
                            theCallBack("", .inprogress, index!, documentUID)
                        }
                        
                        url.stopAccessingSecurityScopedResource()
                        self.uploadDocument(index: index! + 1, thePetUID: thePetUID, theURLS: theURLS, theCallBack: theCallBack)
                    }
                    
                } catch {
                    
                    NSLog("FILE READ ERROR")
                    theCallBack("There was an error reading " + url.lastPathComponent,.failed,counter,nil)
                    self.uploadDocument(index: index! + 1, thePetUID: thePetUID, theURLS: theURLS, theCallBack: theCallBack)
                }
            }
        }
    }
}
