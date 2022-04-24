//
//  VCNotesService.swift
//  Vets-Central
//
//  Created by Roger Vogel on 10/31/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCMessageServices: NSObject {
    
    // MARK: PROPERTIES
    
    var parentViewController: VCHomeViewController?
    var theMessages = [VCMessage]()
    
    // MARK: INITIALIZATION

    func setParent (parent: VCHomeViewController) { parentViewController = parent }
       
    // MARK: METHODS
    
    func setMessageBadge(setToZero: Bool? = false) {
        
        guard parentViewController != nil else { return }
        
        var messageCount: Int = 0
     
        if !setToZero! { for c in theMessages { if c.unread == true { messageCount += 1 } }}

        if messageCount > 0 {
            
            parentViewController!.messageBadgeButton.isHidden = false
            parentViewController!.messageBadgeButton.setTitle(String(messageCount), for: .normal)
            parentViewController!.setTabBarMessageBadge(theCount: messageCount)
        }
        
        else {
            
            parentViewController!.messageBadgeButton.isHidden = true
            parentViewController!.setTabBarMessageBadge()
        }
    }
    
    func addMessage(from: String, title: String, messageBody: String) {
        
        theMessages.append(VCMessage(isFrom: from, aTitle: title, aMessage: messageBody, aTimeStamp: VCDate().timeStamp, unreadState: true))
        saveMessages()
        setMessageBadge()
    }

    func markMessageRead(atIndex: Int) {
        
        theMessages[atIndex].unread = false
        saveMessages()
        setMessageBadge() }

    func markMessageUnread(atIndex: Int) {
        
        theMessages[atIndex].unread = true
        saveMessages()
        setMessageBadge() }

    func deleteNote(atIndex: Int) {
        
        theMessages.remove(at: atIndex); setMessageBadge()
        saveMessages()
    }

    func setMessages(messageString: String) {
        
        var encodedNotes = [String]()
        var noteString: [String]?
        var aNote = VCMessage()
      
        guard messageString != "" else { return }
        
        encodedNotes = messageString.components(separatedBy: "<>")
        
        for encodedNote in encodedNotes {
            
            guard encodedNote != "" else { return }
            noteString = encodedNote.components(separatedBy: "|")
            
            if noteString!.first! == globalData.user.data.userEmail {
                
                aNote.title = noteString![1]
                aNote.message = noteString![2]
                aNote.timeStamp = noteString![3]
                aNote.unread = Bool(noteString![4])!
                theMessages.append(aNote)
            }
        }
        
        saveMessages()
        setMessageBadge()
    }
    
    func saveMessages() {
        
        var noteString: String = ""
      
        for n in theMessages { noteString += (globalData.user.data.userEmail + "|" + n.title + "|" + n.message + "|" + n.timeStamp + "|" + String(n.unread) + "<>")  }
        _ = VCKeychainServices().writeData(data: noteString, withKey: "messages")
    }
    
    func clearMessages(withKeychain: Bool? = false) {
        
        theMessages.removeAll()
        if withKeychain! { saveMessages() }
    
        guard parentViewController != nil else { return }
        parentViewController!.messageBadgeButton.isHidden = true
    }
} 

