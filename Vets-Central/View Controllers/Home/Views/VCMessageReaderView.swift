//
//  VCMessageReaderView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCMessageReaderView: VCView, UITextViewDelegate {
   
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var messageBodyTextView: UITextView!
    
    // MARK: INITIALIZATION
    
    override func initView() {
        
        super.initView()
    }
    
    // MARK: METHODS
   
    func setDisplay (index: Int) {
        
        let aMessage = globalData.messageService.theMessages[index]
        
        dateLabel.text = "Date: " + aMessage.timeStamp
        fromLabel.text = "From: " + aMessage.from
        subjectLabel.text = "Subject: " + aMessage.title
        messageBodyTextView.text = aMessage.message
    }
    
    // MARK: TEXTVIEW DELEGATE PROTOCOL
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {  return false }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func returnButtonTapped(_ sender: Any) { parentController.homeController.messagesFormView.messagesTableView.reloadData();  hideView() }
}

