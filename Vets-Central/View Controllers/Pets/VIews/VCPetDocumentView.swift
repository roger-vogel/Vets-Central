//
//  VCPetDocumentView.swift
//  Vets-Central
// 
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved. 
//

import UIKit
import QuickLook

class VCPetDocumentView: VCDocumentView  {
 
    // MARK: OUTLETS
    
    @IBOutlet weak var titleBarLabel: UILabel!
    @IBOutlet weak var documentTableView: UITableView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var noDocumentsLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint! 
    
    // MARK: INITIALIZATION AND OVERRIDES
    
    override func initView() {
        
        subClassType = .pet
        theTitleBarLabel = titleBarLabel
        theNoDocumentsLabel = noDocumentsLabel
        theDocumentTableView = documentTableView
        theTableViewBottomConstraint = tableViewBottomConstraint
        
        super.initView()
    }
    
    override func handleTableSelection(indexPath: IndexPath) { downloadDocument(index: indexPath.row) }
    
    override func setCellImage(indexPath: IndexPath) -> UIImage? {
        
        var imageFile: String?
        let defaultImageFile = "icon.table.document.png"
        
        // Get the file type
        let fileCategory = fileCategories[VCFileServices().getFileExtension(fileName: globalData.user.pets[self.parentController.selectedPet!].docMetadata[indexPath.row].fileName)!.lowercased()]
        
        if fileCategory != nil { imageFile = "icon.table." + fileCategory! + ".png" }
        if imageFile == nil { imageFile = defaultImageFile }
           
        return UIImage(named: imageFile!)!
    }
        
    // MARK: ACTION HANDLERS
    
    @IBAction func plusButtonTapped(_ sender: Any) { onPlus() }
    
    @IBAction func refreshButtonTapped(_ sender: Any) { }
 
    @IBAction func returnButtonTapped(_ sender: Any) { hideView() }
}
