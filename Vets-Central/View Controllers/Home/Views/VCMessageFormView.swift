//
//  VCMessageFormView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCMessageFormView: VCView, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var messagesTableView: UITableView!
    
    // MARK: INITIALIZATION
    
    override func initView() {
       
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        messagesTableView.separatorInset.left = 0
      
        super.initView()
    }
    
    // MARK: TABLEVIEW DELEGATE PROTOCOL
    
    // Handle delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        var indexPaths = [IndexPath]()
        
        if editingStyle == .delete {
            
            globalData.messageService.deleteNote(atIndex: indexPath.row)
            
            indexPaths.append(indexPath)
            tableView.deleteRows(at: indexPaths, with: .fade)
        }
    }
    
    // Report number of sections
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    // Report the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return globalData.messageService.theMessages.count }
        
    // When asked for row height...
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 44 }
    
    // Capture highlight
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { return true }
    
    // Dequeue the cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        
        let dateStamp = globalData.messageService.theMessages[indexPath.row].timeStamp.components(separatedBy: "-")
        
        // Put the filename from the url into the cell label
        cell.textLabel!.font = UIFont.systemFont(ofSize: 10.0)
        cell.textLabel!.text = dateStamp[0] + "  " +  globalData.messageService.theMessages[indexPath.row].title
    
        // Set the file icon
        if globalData.messageService.theMessages[indexPath.row].unread == true { cell.imageView!.image = UIImage(named: "icon.unreadnote.png") }
        else { cell.imageView!.image = nil }
        
        // Return the cell
        return cell
    }
    
    // Capture selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        globalData.messageService.theMessages[indexPath.row].unread = false
        
        let parent = parentController
        parent.homeController.messageReaderView.setDisplay(index: indexPath.row)
        parent.homeController.messageReaderView.showView()
        
        globalData.messageService.setMessageBadge()
    }
        
   // MARK: ACTION HANDLERS
    @IBAction func trashButtonTapped(_ sender: Any) {
        
        parentController.controllerAlert!.popupYesNo(aMessage: "Are you sure you want to delete all your messages? To delete a single message, swipe left on the message.") { choice in
            
            if choice == 0 {
            
                globalData.messageService.clearMessages(withKeychain: true)
                globalData.messageService.setMessageBadge()
                
                self.messagesTableView.reloadData()
            }
        }
    }
    
    @IBAction func returnButtonTapped(_ sender: Any) {
        
        hideView()
    }
}

