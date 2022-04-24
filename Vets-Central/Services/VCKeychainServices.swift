//
//  VCKeychainServices.swift
//  Vets-Central
//
//  Created by Roger Vogel on 8/7/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCKeychainServices: NSObject {
    
    var vcKeychain: KeychainWrapper?
   
    // MARK:INITIALIZATION
    
    init (aServiceName: String? = "vetscentral") {
        
        vcKeychain = KeychainWrapper(serviceName: aServiceName!)
        super.init()
    }
    
    // MARK: AGGREGATE METHODS
    
    // Read stored version
    func readLastVersion() -> String? {
        
        let version = readString(withKey: "version")
        if version == nil { _ = writeData(data: globalData.settings.appVersion, withKey: "version") }
       
        return version
    }
    
    // Read or establish keychain entries
    func readKeychain() {
             
        doVersionKeychainProcessing()
        
        // Text switch
        let text = readBool(withKey: "text")
        if text == nil { _ = writeData(data: false, withKey: "text") }
        else { globalData.settings.textContact = text! }
        
        // Email switch
        let email = readBool(withKey: "email")
        if email == nil { _ = writeData(data: false, withKey: "email") }
        else { globalData.settings.emailContact = email! }
        
        // Map switch
        let map = readBool(withKey: "map")
        if map == nil { _ = writeData(data: false, withKey: "map") }
        else { globalData.settings.onlyMapVC = map! }
        
        // Auto Login
        let auto = readBool(withKey: "auto")
        if auto == nil { _ = writeData(data: false, withKey: "auto") }
        else { globalData.settings.rememberMe = auto! }
        
        // Clock
        let clock = readInt(withKey: "clock")
        if clock == nil { _ = writeData(data: "", withKey: "clock") }
        else { globalData.settings.clock = ClockMode(rawValue: clock!)! }
        
        // Alert minutes
        let alert = readInt(withKey: "alert")
        if alert == nil { _ = writeData(data: 15, withKey: "alert") }
        else { globalData.settings.alertMinutes = alert! }
        
        // Preferred Clinic
        let preference = readInt(withKey: "preference")
        if preference == nil { _ = writeData(data: "", withKey: "preferencce") }
        else { globalData.user.data.preferredClinicUID = preference! }
        
        // UserId
        let user = readString(withKey: "user")
        if user == nil { _ = writeData(data: "", withKey: "user") }
        else { globalData.user.data.userEmail = user! }
        
        // Password
        let password = readString(withKey: "password")
        if password == nil { _ = writeData(data: "", withKey: "user") }
        else { globalData.user.passwords.currentPassword = password! }
        
        // Internal messages
        let messages = readString(withKey: "messages")
        if messages == nil { _ = writeData(data: "", withKey: "messages") }
        else { globalData.messageService.setMessages(messageString: messages!) }
        
        // Display record counts
        let counts = readBool(withKey: "counts")
        if counts == nil { _ = writeData(data: "", withKey: "counts") }
        else { globalData.settings.recordCountsAreHidden = counts! }
        
        let seconds = readInt64(withKey: "elapsedSeconds")
        if seconds == nil { _ = writeData(data: Int64(0), withKey: "elapsedSeconds") }
        
        let timestamp = readInt64(withKey: "timestamp")
        if timestamp == nil { _ = writeData(data: Int64(0), withKey: "timestamp") }
        
        let conferenceID = readInt(withKey: "conferenceID")
        if conferenceID == nil {_ = writeData(data: Int(0), withKey: "conferenceID") }
    }
    
    // Clear the keychain values
    func resetKeyChain() {
        
        // Text switch
        _ = writeData(data: false, withKey: "text")
        _ = writeData(data: false, withKey: "email")
        _ = writeData(data: false, withKey: "map")
        _ = writeData(data: false, withKey: "auto")
        _ = writeData(data: "", withKey: "clock")
        _ = writeData(data: 15, withKey: "alert")
        _ = writeData(data: "", withKey: "preferencce")
        _ = writeData(data: "", withKey: "user")
        _ = writeData(data: "", withKey: "messages")
        _ = writeData(data: "", withKey: "counts")
        
        readKeychain()
    }
    
    // Clear the complete keychain
    func clearKeychain (withMessages: Bool? = true) {
        
        if withMessages! {
            
            deleteKeys(["version","text","email","map","auto","clock","alert","preference","user","password","messages","timestamp","conferenceID","elaspedTime"])
            
        } else {
            
            deleteKeys(["version","text","email","map","auto","clock","alert","preference","user","password","timestamp","conferenceID","elaspedTime"])
        }
    }
    
    // Available to change keychain with version if necessary
    func doVersionKeychainProcessing () {
        
        let version = readString(withKey: "version")
        let currentVersion = VCSystemInfo().buildLevel
        
        if version != nil {
            
            let versionAsValue = Int(version!.removeChar(charToRemove: "."))
            let currentVersionAsValue = Int(currentVersion.removeChar(charToRemove: "."))
            
            // If this is uplevel, do any specific processing the new level might need to do
            if versionAsValue! < currentVersionAsValue! {
                
                // Save the current version
                _ = writeData(data: currentVersion, withKey: "version")
               
                // Version specific actions
                switch currentVersion {
                    
                    default: break
                }
            }
        }
    }
    
    // MARK: BASE METHODS
    
    func writeData (data: Bool, withKey: String ) -> Bool {
        return KeychainWrapper.standard.set(data, forKey: withKey) }
        
    func writeData (data: String , withKey: String) -> Bool {
        return KeychainWrapper.standard.set(data, forKey: withKey)  }
    
    func writeData (data: Int, withKey: String ) -> Bool {
        let r = KeychainWrapper.standard.set(data, forKey: withKey)
        return r
    }
    
    func writeData (data: Int64, withKey: String ) -> Bool { return KeychainWrapper.standard.set(data, forKey: withKey) }
    
    func writeData (data: Float, withKey: String ) -> Bool { return KeychainWrapper.standard.set(data, forKey: withKey) }
        
    func writeData (data: Double, withKey: String ) -> Bool { return KeychainWrapper.standard.set(data, forKey: withKey) }
    
    func readBool (withKey: String) -> Bool? {
        return KeychainWrapper.standard.bool(forKey: withKey) }
    
    func readString (withKey: String) -> String? { return KeychainWrapper.standard.string(forKey: withKey) }
        
    func readInt (withKey: String) -> Int? {  return KeychainWrapper.standard.integer(forKey: withKey) }
    
    func readInt64 (withKey: String) -> Int64? {
        
        let value = KeychainWrapper.standard.integer(forKey: withKey)
        
        if value != nil { return Int64(value!) }
        else { return nil }
    }
    
    func readFloat (withKey: String) -> Float? { return KeychainWrapper.standard.float(forKey: withKey) }
        
    func readDouble (withKey: String) -> Double? {   return KeychainWrapper.standard.double(forKey: withKey) }
      
    func deleteKeys (_ keyName: [String]) {
        
        for k in keyName { KeychainWrapper.standard.removeObject(forKey: k) }
    }
}
 
