//
//  VCWebServices.swift
//  Vets-Central
//
//  Web Services Methods Container
//  Created by Roger Vogel on 6/9/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import Foundation
import UIKit

class VCWebServices: NSObject, URLSessionDelegate {
    
    var isCallFromRefresh: Bool?
    var dataTask: URLSessionDataTask?
    var retryCounter: Int = 0
    var callBack: ( (NSDictionary, Bool) -> Void )?
    var theParentController: VCViewController?
    var testURLV4: String = "https://47.52.45.237:3000/api/v4/"
    var prodURL: String = "https://app.vets-central.com/api/v4/"
    var apiDiagnostics =  VCAPIDiagnostics()
        
    // For testing purposes
    var theJSON: (shouldBePrinted: Bool, withID: String) = (false,"")
    
    // MARK: INITIALIZATION
    
    init(parent: VCViewController? = nil, callFromRefresh: Bool? = false) {
        
        theParentController = parent
        isCallFromRefresh = callFromRefresh
      
        super.init()
    }
    
    // MARK: AUTHORIZATION AND SIGN OUT
    
    func authorizeUser(dbCredentials: VCDBCredentials, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "auth"
        
        do {
            
            let httpBody = try JSONEncoder().encode(dbCredentials)
            buildHTTPTask(apiName: "AUTHORIZE", endPoint: endPoint, method: "POST", body: httpBody, callBack: callBack)
            
        }  catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func logout(callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "signout"
        buildHTTPTask(apiName: "LOGOUT", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    func logoutAtTermination() {
        
        let callURL: String = prodURL + "signout"
        
        // Create URL request
        let request = NSMutableURLRequest(url: NSURL(string: callURL)! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval:  30.0)
      
        request.setValue(globalData.tokens.bearerToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        executeTerminationDataTask(withRequest: request as URLRequest)
    }
    
    // MARK: CLINIC CALLS
    
    func getClinicsNear (long: Double, lat: Double, radius: Int?, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        var searchRadius: String = ""
        
        if radius != nil { searchRadius = String(radius!) }
        let endPoint: String = prodURL + "clinic-near-me?lng=" + String(long) + "&lat=" + String(lat) + "&radius=" + searchRadius
        
        buildHTTPTask(apiName: "GET CLINICS NEAR", endPoint: endPoint, method: "GET", callBack: callBack)
    }
    
    func getDoctorsForClinic (theClinicUID: String, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "veterinarian/" + theClinicUID
        buildHTTPTask(apiName: "GET DOCTORS FOR CLINIC", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    func getClinicScheduleAndVets (theClinicRecord: VCClinicRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "schedule/clinic-with-vets/" + String(theClinicRecord.clinicUID!)
        buildHTTPTask(apiName: "GET SCHEDULE AND VETS", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    func getClinicServiceTypes (theClinicRecord: VCClinicRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "clinicConsultType/" + String(theClinicRecord.clinicUID!)
        buildHTTPTask(apiName: "GET CLINIC SERVICE TYPES", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    // MARK: USER CALLS
    
    func createUser (theUserCredentials: VCDBCreateUser, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "register"

        do {
            
            let httpBody = try JSONEncoder().encode(theUserCredentials)
            buildHTTPTask(apiName: "CREATE USER", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, body: httpBody,  callBack: callBack)
        
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func getUser (userUID: Int, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "pet-owner-with-pets/" + String(userUID)
        buildHTTPTask(apiName: "GET USER", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }

    func updateUser (theUserData: VCUserRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "members/details/" + String(theUserData.userUID!)
        let dataInAPIFormat = VCAPITranslator().formatForUserUpdate(userData: theUserData)
        
        do {
            
            let httpBody = try JSONEncoder().encode(dataInAPIFormat)
            buildHTTPTask(apiName: "UPDATE USER", endPoint: endPoint, method: "PUT", bearerToken: globalData.tokens.bearerToken, body: httpBody,  callBack: callBack)
            
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func deleteUser (ttheUserData: VCUserRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {}
    
    func setUserContactPreferences(callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        var email: String?
        var sms: String?
        let endPoint: String = prodURL + "members/subscription/" + String(globalData.user.data.userUID!)
        
        if globalData.settings.emailContact { email = "true" } else { email = "false" }
        if globalData.settings.textContact { sms = "true" } else { sms = "false" }
        let preferences = VCDBContactPreferences(smsEnabled: sms!, emailEnabled: email!)
        
        do {
            
            let httpBody = try JSONEncoder().encode(preferences)
            buildHTTPTask(apiName: "CONTACT PREFERENCES", endPoint: endPoint, method: "PUT", bearerToken: globalData.tokens.bearerToken, body: httpBody,  callBack: callBack)
       
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    // MARK: PET CALLS
    
    func createPet (thePetData: VCPetRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "pet/" + String(globalData.user.data.userUID!)
        let dataInAPIFormat = VCAPITranslator().formatForCreatePet(petRecord: thePetData )
        
        do {
            
            let httpBody = try JSONEncoder().encode(dataInAPIFormat)
            buildHTTPTask(apiName: "CREATE PET", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, body: httpBody,  callBack: callBack)
            
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func updatePet (thePetData: VCPetRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "pet/" + String(thePetData.petUID!)
        let dataInAPIFormat = VCAPITranslator().formatForPetUpdate(petRecord: thePetData)
        
        do {
            
            let httpBody = try JSONEncoder().encode(dataInAPIFormat)
            buildHTTPTask(apiName: "UPDATE PET", endPoint: endPoint, method: "PUT", bearerToken: globalData.tokens.bearerToken, body: httpBody,  callBack: callBack)
           
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func uploadPetPhoto (thePetRecord: VCPetRecord, thePetImage: Data, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let callURL: String = prodURL + "pet/" + String(thePetRecord.petUID!) + "/profileImage"
        let fileName = "VCMobile"+String(thePetRecord.petUID!)+".jpg"
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        body.append ("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\("document")\"".data(using: .utf8)!)
        body.append("; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \"content-type image/jpeg\"\r\n\r\n".data(using: .utf8)!)
        body.append(thePetImage)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
      
        var request = NSMutableURLRequest(url: NSURL(string: callURL)! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval:  30.0) as URLRequest
        request.addValue(globalData.tokens.bearerToken, forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = body
     
        executeDataTask(withRequest: request as URLRequest, withCallBack: callBack)
    }
    
    func downloadPetPhoto (thePetRecord: VCPetRecord, callBack: @escaping (Data?, Bool) -> Void) {
        
        let callURL: String = prodURL + "pet/" + String(thePetRecord.petUID!) + "/profileImage"
        let boundary = "Boundary-\(UUID().uuidString)"
    
        var request = NSMutableURLRequest(url: NSURL(string: callURL)! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval:  30.0) as URLRequest
        request.addValue(globalData.tokens.bearerToken, forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        executeDataTask(withRequest: request as URLRequest, withCallBack: callBack )
    }
    
    func getAllPets (callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "pet"
        buildHTTPTask(apiName: "GET ALL PETS", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    func deletePet (thePetData: VCPetRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "pet/" + String(thePetData.petUID!)
        buildHTTPTask(apiName: "DELETE PET", endPoint: endPoint, method: "DELETE", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    func getPetLookups (callBack: @escaping (NSDictionary, Bool) -> Void) {
       
        let endPoint: String = prodURL + "lookup?lookupType=species,gender"
        buildHTTPTask(apiName: "GET PET LOOKUPS", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    // MARK: APPPOINTMENT CALLS
    
    func getAppointments (userUID: Int, startDate: String, endDate: String, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "calendar/member/" + String(userUID) + "?start=" + startDate + "&end=" + endDate
        buildHTTPTask(apiName: "GET APPOINTMENTS", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, timezone: true, callBack: callBack)
    }
    
    func createAppointment (theApptData: VCAppointmentRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "clinic-appointment/" + String(theApptData.clinicUID!)
        let dataInAPIFormat = VCAPITranslator().formatForCreateAppt(apptRecord: theApptData)
        
        do {
            
            let httpBody = try JSONEncoder().encode(dataInAPIFormat)
            buildHTTPTask(apiName: "CREATE APPOINTMENT", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, body: httpBody, timezone: true, callBack: callBack)
     
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func rescheduleAppointment (theApptData: VCAppointmentRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "b2c-appointment/reschedule/" + String(theApptData.apptUID!)
        let dataInAPIFormat = VCAPITranslator().formatForRescheduleAppt(apptRecord: theApptData)
        
        do {
            
            let httpBody = try JSONEncoder().encode(dataInAPIFormat)
            buildHTTPTask(apiName: "RESCHEDULE APPOINTMENT", endPoint: endPoint, method: "PUT", bearerToken: globalData.tokens.bearerToken, body: httpBody, timezone: true, callBack: callBack)
            
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func cancelAppointment (apptUID: Int, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "appointment_cancel/" + String(apptUID)
        buildHTTPTask(apiName: "CANCEL APPOINTMENT", endPoint: endPoint, method: "PUT", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    func getVideoCredentials (theAppointment: VCAppointmentRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "appointment/start/" + String(theAppointment.apptUID!)
        buildHTTPTask(apiName: "GET VIDEO CREDENTIALS", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    // MARK: DOCUMENTS
    
    func requestDocumentsMetadata (theTarget: String, theUID: Int, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let callURL: String = prodURL + theTarget + "/document/" + String(theUID)
    
        var request = NSMutableURLRequest(url: NSURL(string: callURL)! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: .infinity) as URLRequest
        request.addValue(globalData.tokens.bearerToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        executeDataTask(withRequest: request as URLRequest, withCallBack: callBack)
    }
    
    func uploadDocument (theTarget: String, theUID: Int, theFileType: String, theFileData: Data, theFileName: String, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let callURL: String = prodURL + theTarget + "/document/" + String(theUID)
        let fileName = theFileName
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let contentType = "Content-Type: \"content-type " + theFileType + "\"\r\n\r\n"
       
        body.append ("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\("document")\"".data(using: .utf8)!)
        body.append("; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append(contentType.data(using: .utf8)!)
        body.append(theFileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
      
        var request = NSMutableURLRequest(url: NSURL(string: callURL)! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval:  30.0) as URLRequest
        request.addValue(globalData.tokens.bearerToken, forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = body
     
        executeDataTask(withRequest: request as URLRequest, withCallBack: callBack)
    }
    
    func downloadDocument (documentUID: Int, callBack: @escaping (Data?, Bool) -> Void) {
        
        let callURL = prodURL + "appointment/document/download/" + String(format: "%d",documentUID)
       
        // Create URL request
        let request = NSMutableURLRequest(url: NSURL(string: callURL)! as URL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval:  30.0)
        
        request.setValue(globalData.tokens.bearerToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        executeDataTask(withRequest: request as URLRequest, withCallBack: callBack)
    }
    
    func deleteDocument (theDocument: VCDocMetadata, callBack: @escaping (NSDictionary, Bool) -> Void) { }
    
    func linkDocuments (theDocuments: VCDBLinkDocuments, theAppointment: VCAppointmentRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "appointment/link-document/" + String(theAppointment.apptUID!)
       
        do {
            
            let httpBody = try JSONEncoder().encode(theDocuments)
            buildHTTPTask(apiName: "LINK DOCUMENTS", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, body: httpBody, callBack: callBack)
     
        }  catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func unlinkDocuments (theDocuments: VCDBLinkDocuments, theAppointment: VCAppointmentRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "appointment/unlink-document/" + String(theAppointment.apptUID!)
       
        do {
            
            let httpBody = try JSONEncoder().encode(theDocuments)
            buildHTTPTask(apiName: "UNLINK DOCUMENTS", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, body: httpBody, callBack: callBack)

        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    func getLinkedDocumentsForAppointment(apptUID: Int, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "appointment/document/" + String(apptUID)
        buildHTTPTask(apiName: "GET LINKED DOCUMENTS FOR APPOINTMENT", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    // MARK: NOTES
    
    func getAppointmentNotes(theAppointment: VCAppointmentRecord, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "appointment/notes/" + String(theAppointment.apptUID!)
        buildHTTPTask(apiName: "GET APPOINTMENT NOTES", endPoint: endPoint, method: "GET", bearerToken: globalData.tokens.bearerToken, callBack: callBack)
    }
    
    func setAppointmentNotes(theAppointment: VCAppointmentRecord, theNote: VCDBAppointmentNote, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "appointment/notes/" + String(theAppointment.apptUID!)
        
        do {
            
            let httpBody = try JSONEncoder().encode(theNote)
            buildHTTPTask(apiName: "SET APPOINTMENT NOTES", endPoint: endPoint, method: "POST", bearerToken: globalData.tokens.bearerToken, body: httpBody, callBack: callBack)
        
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    // MARK: CHANGE PASSWORD
    
    func changePassword(thePassword: VCDBPassword, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        let endPoint: String = prodURL + "user/changepassword"
        
        do {
            
            let httpBody = try JSONEncoder().encode(thePassword)
            buildHTTPTask(apiName: "CHANGE PASSWORD", endPoint: endPoint, method: "PUT", bearerToken: globalData.tokens.bearerToken, body: httpBody, callBack: callBack)
            
        } catch { callBack(["status":"JSON Encode Error"],false) }
    }
    
    // MARK: WEB SERVICE DATATASK EXECUTION
    
    func buildHTTPTask(apiName: String, endPoint: String, method: String, bearerToken: String? = nil, body: Data? = nil, timezone: Bool? = false, callBack: @escaping (NSDictionary, Bool) -> Void) {
        
        // Record the parameters for this task
        apiDiagnostics.userName = globalData.user.data.userEmail
        apiDiagnostics.apiName = apiName
        apiDiagnostics.apiEndpoint = endPoint
        apiDiagnostics.apiMethod = method
        apiDiagnostics.postDate = VCDate().dateAndTimeString
        
        let request = NSMutableURLRequest(url: NSURL(string: endPoint)! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
      
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if bearerToken != nil { request.setValue(bearerToken, forHTTPHeaderField: "Authorization") }
        if timezone! { request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "timeZone") }
            
        if (method == "GET" || method == "DELETE") && theJSON.shouldBePrinted { print( theJSON.withID + "\n\n" + endPoint) }
     
        if body != nil {
            
            request.httpBody = body
            let prettyPrintedJSON = body!.asPrettyJSON
            
            if prettyPrintedJSON != nil { apiDiagnostics.jsonSent = body!.asPrettyJSON! }
            else { apiDiagnostics.jsonSent = String(data: body!, encoding: .utf8)! }
            if theJSON.shouldBePrinted{ printOutgoingJSON(jsonData: body!) }
        }
        
        executeDataTask(withRequest: request as URLRequest, withCallBack: callBack)
    }
    
    func buildHTTPTask(endPoint: String, method: String, bearerToken: String? = nil, body: Data? = nil, timezone: Bool? = false, callBack: @escaping (Data?, Bool) -> Void) {
        
        let request = NSMutableURLRequest(url: NSURL(string: endPoint)! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
      
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if bearerToken != nil { request.setValue(bearerToken, forHTTPHeaderField: "Authorization") }
        if timezone! { request.setValue((TimeZone.current).identifier, forHTTPHeaderField: "timeZone") }
        
        if (method == "GET" || method == "DELETE") && theJSON.shouldBePrinted { print( theJSON.withID + "\n\n" + endPoint) }
     
        if body != nil {
            
            request.httpBody = body
            if theJSON.shouldBePrinted{ printOutgoingJSON(jsonData: body!) }
        }
        
        executeDataTask(withRequest: request as URLRequest, withCallBack: callBack)
    }
    
    func executeDataTask(withRequest: URLRequest, withCallBack: @escaping (NSDictionary, Bool) -> Void) {
        
        var json : NSDictionary?
        var session: URLSession?
        
        // Create an asynchronous data task with completion handler - in test mode skip SSL certificate check
        if globalData.flags.isTestMode { session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil) }
        else { session = URLSession.shared }
        
        globalData.webServiceQueue.append(self)
        
        dataTask = session!.dataTask(with: withRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            for (index, value) in globalData.webServiceQueue.enumerated() { if value == self { globalData.webServiceQueue.remove(at: index) }; break }
            
            guard error == nil else { NSLog(error!.localizedDescription); DispatchQueue.main.async(execute: { () -> Void in withCallBack(["error":error!.localizedDescription],false) } ); return }
            
            do { json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary }
            catch { DispatchQueue.main.async(execute: { () -> Void in withCallBack(["error":error.localizedDescription],false); self.apiDiagnostics.errorDescription = error.localizedDescription; return } ) }
            
            guard json != nil else {
                
                DispatchQueue.main.async(execute: { () -> Void in withCallBack( ["error":"JSON Decode Error"],false) } )
                
                if error != nil { self.apiDiagnostics.errorDescription = error!.localizedDescription }
                return
                
            }
            
            let jsonReceived = json!.asPrettyJSON
            if jsonReceived != nil { self.apiDiagnostics.jsonReceived = jsonReceived! }
            
            DispatchQueue.main.async(execute: { () -> Void in withCallBack(json!,true); return } )
        })
        
        if !self.isCallFromRefresh! && globalData.flags.refreshInProgress { globalData.taskQueue.append(dataTask!) }
       
        else {
            
            if self.theParentController != nil && !self.isCallFromRefresh! {
                
                globalData.webServiceTimer = Timer(timeInterval: 30.0, repeats: true, block: { (timer) in
                    
                    VCAlertServices(viewController: self.theParentController!).popupWithCustomButtons(
                        
                        aTitle: "Slow Connection", aMessage: "It seems the internet connection is very slow, you may want to try again later", buttonTitles: ["CONTINUE","CANCEL"], theStyle: [.default,.cancel]) { choice in
                        
                        if choice == 1 {
                       
                            globalData.webServiceTimer.invalidate()
                            if self.dataTask!.state != .completed { self.dataTask!.cancel() }
                            withCallBack( ["error":"userTimeout"],false)
                        }
                    }
                })
            }
        }
        
        dataTask!.resume()
    }
    
    func executeDataTask(withRequest: URLRequest, withCallBack: @escaping (NSArray, Bool) -> Void) {
        
        var json : NSArray?
        var session: URLSession?
        
        // Create an asynchronous data task with completion handler - in test mode skip SSL certificate check
        if globalData.flags.isTestMode { session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil) }
        else { session = URLSession.shared }
        
        globalData.webServiceQueue.append(self)
        
        dataTask = session!.dataTask(with: withRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            for (index, value) in globalData.webServiceQueue.enumerated() { if value == self {globalData.webServiceQueue.remove(at: index) }; break }
            
            guard error == nil else { DispatchQueue.main.async(execute: { () -> Void in withCallBack([error!.localizedDescription],false) } ); return }
            
            do { json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSArray }
            catch { DispatchQueue.main.async(execute: { () -> Void in withCallBack([error.localizedDescription],false); return } ) }
            
            guard json != nil else {  DispatchQueue.main.async(execute: { () -> Void in withCallBack( ["JSON Decode Error"],false) } ); return }
            
            DispatchQueue.main.async(execute: { () -> Void in withCallBack(json!,true); return } )
        })
        
        // Kick off the task
        if !self.isCallFromRefresh! && globalData.flags.refreshInProgress { globalData.taskQueue.append(dataTask!) }
        
        else {
            
            if self.theParentController != nil && !self.isCallFromRefresh! {
                
                globalData.webServiceTimer = Timer(timeInterval: 30.0, repeats: true, block: { (timer) in
                    
                    VCAlertServices(viewController: self.theParentController!).popupWithCustomButtons(
                        
                        aTitle: "Slow Connection", aMessage: "It seems the internet connection is very slow, you may want to try again later", buttonTitles: ["CONTINUE","CANCEL"], theStyle: [.default,.cancel]) { choice in
                        
                        if choice == 1 {
                       
                            globalData.webServiceTimer.invalidate()
                            if self.dataTask!.state != .completed { self.dataTask!.cancel() }
                            withCallBack( ["userTimeout"],false)
                        }
                    }
                })
            }
        }
        
        dataTask!.resume()
    }
    
    func executeDataTask(withRequest: URLRequest, withCallBack: @escaping (Data?, Bool) -> Void) {
        
        var session: URLSession?
        
        if globalData.flags.isTestMode { session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil) }
        else { session = URLSession.shared }
        
        globalData.webServiceQueue.append(self)
        
        dataTask = session!.dataTask(with: withRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            for (index, value) in globalData.webServiceQueue.enumerated() { if value == self {globalData.webServiceQueue.remove(at: index) }; break }
            
            guard error == nil && data != nil else { DispatchQueue.main.async(execute: { () -> Void in withCallBack(nil,false) } ); return }
       
            DispatchQueue.main.async(execute: { () -> Void in withCallBack(data,true); return } )
        })
        
        // Kick off the task
        if !self.isCallFromRefresh! && globalData.flags.refreshInProgress { globalData.taskQueue.append(dataTask!) }
       
        else {
            
            if self.theParentController != nil && !self.isCallFromRefresh! {
                
                globalData.webServiceTimer = Timer(timeInterval: 30.0, repeats: true, block: { (timer) in
                    
                    VCAlertServices(viewController: self.theParentController!).popupWithCustomButtons(
                        
                        aTitle: "Slow Connection", aMessage: "It seems the internet connection is very slow, you may want to try again later", buttonTitles: ["CONTINUE","CANCEL"], theStyle: [.default,.cancel]) { choice in
                        
                        if choice == 1 {
                       
                            globalData.webServiceTimer.invalidate()
                            if self.dataTask!.state != .completed { self.dataTask!.cancel() }
                            withCallBack(nil,false)
                        }
                    }
                })
            }
        }
        
        dataTask!.resume()
    }
    
    func executeTerminationDataTask(withRequest: URLRequest) {
        
        var session: URLSession?
        
        if globalData.flags.isTestMode { session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil) }
        else { session = URLSession.shared }
        
        dataTask = session!.dataTask(with: withRequest as URLRequest, completionHandler: { (data, response, error) -> Void in })
            
        // Kick off the task
        dataTask!.resume()
    }
    
    // MARK: ERROR HANDLING
    
    func isErrorFree(json: NSDictionary, status: Bool, showAlert: Bool? = true ) -> Bool {
        
        let delay: TimeInterval = 3.5
       
        globalData.activeController!.controllerAlert!.dismiss()
        
        // Guard against communication errors
        guard status else {
            
            postErrorToServer()
            
            if showAlert! && globalData.flags.loginState != .loggedOut {
                
                globalData.activeController!.controllerAlert!.popupMessage(aMessage: (json["error"] as! String), aViewDelay: delay)
            }
            
            return false
        }
        
        // Guard against API errors
        guard json["success"] != nil else {
            
            postErrorToServer()
            
            if showAlert! && globalData.flags.loginState != .loggedOut {
                
                globalData.activeController!.controllerAlert!.popupMessage(aMessage: "The server returned an unknown error response, please try again", aViewDelay: delay)
            }
            
            return false
        }
        
        // Guard against an error return from the server
        guard (json["success"] as! Bool) else {
            
            postErrorToServer()
            
            if showAlert! && globalData.flags.loginState != .loggedOut {
                
                if json["error"] != nil { globalData.activeController!.controllerAlert!.popupMessage(aMessage: (json["error"] as! String), aViewDelay: delay) }
                else { globalData.activeController!.controllerAlert!.popupMessage(aMessage: "The server returned an unknown error response, please try again", aViewDelay: delay) }
            }
           
            return false
        }
        
        return true
    }
    
    // MARK: SSL CERTIFICATE BYPASS (TEST MODE)
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
       
        //Trust the certificate even if not valid
       let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
       completionHandler(.useCredential, urlCredential)
    }
    
    // MARK: DEBUG ASSISTANCE
    
    func printOutgoingJSON (jsonData: Data) { print (String(data: jsonData, encoding: .utf8)!) }
    
    func printIncomingJSON(jsonData: Data) {
        
        do {

            var incomingData: Data?
                
            try incomingData = JSONSerialization.data(withJSONObject: jsonData, options: JSONSerialization.WritingOptions.prettyPrinted)
            print (String(data: incomingData!, encoding: .utf8)!)
        }
        
        catch { return }
    }
    
    func postErrorToServer() {
        
        var body: Data?
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: NSURL(string: "https://starfish-api.com/vc_test/")! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
       
        do { body = try JSONEncoder().encode(apiDiagnostics) } catch { return }
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body!
    
        dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in return })
        if dataTask != nil { dataTask!.resume() }
    }
}
