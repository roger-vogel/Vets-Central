//
//  VCPetsViewController.swift
//  Vets-Central
//
//  Pets Scene Controller and Views
//  Created by Roger Vogel on 5/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit
import MobileCoreServices
import QuickLook

class VCPetViewController: VCViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
   
    // MARK: OUTLETS
    
    @IBOutlet var petInformationView: VCPetInformationView!
    @IBOutlet var petDocumentView: VCPetDocumentView!
    @IBOutlet var petSettingsView: VCPetSettingsView!
    
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var petCollectionView: UICollectionView!
    @IBOutlet weak var noPetsMessage: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var settingsButton: UIButton!
  
    // MARK: PROPERTIES
    
    var petCounter: Int = 0
    var isCallFromAppointments: Bool = false
    var isCallFromRefresh: Bool = false
    var selectedCell = VCPetCollectionViewCell()
    var petPhotoWatchTimer = Timer()
    var cumulativeTime: Int?
   
    // MARK: INITIALIZATION AND OVERRIDES
    
    override func viewDidLoad() { super.viewDidLoad()
    
        setSubViews(subviews: [petInformationView,petDocumentView])
        
        // Setup product collection view
        petCollectionView.dataSource = self
        petCollectionView.delegate = self
             
        // Initialize the pet information and document view form
        view.addSubview(petInformationView)
        petInformationView.initView()
    
        view.addSubview(petDocumentView)
        petDocumentView.initView()
        
        view.addSubview(petSettingsView)
        petSettingsView.initView()
       
        noPetsMessage.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated);
        
        guard globalData.user.pets.count > 0 else { noPetsMessage.isHidden = false; return }
        noPetsMessage.isHidden = true
        
        globalData.activeController = self
        
        if !globalData.flags.petPhotosOnBoard {
            
            cumulativeTime = 0
            
            controllerAlert!.popupPendingMsg(aMessage: "Downloading your pet photos")
            petPhotoWatchTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(watchForPhotoLoad), userInfo: nil, repeats: true )
            
        } else { petDocumentView.documentTableView.reloadData() }
    }
    
    override func doLogoutTasks() {
        
        if petCollectionView != nil { petCollectionView.reloadData() }
        if petDocumentView.documentManager != nil { petDocumentView.documentManager!.theMetadata.removeAll() }
     
        petInformationView.hideView()
        petDocumentView.hideView()
        petSettingsView.hideView()
    }
        
    // MARK: METHODS

    func reloadCollectionData () {
        
         // Reload the collection view when the data changes
        if  globalData.flags.loginState == .loggedIn {
             
             // Enable plus button
             plusButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { return })
             
             // Set message
            if globalData.user.pets.count > 0 { noPetsMessage.isHidden = true }
             else { noPetsMessage.text = "You have no pets on file"; noPetsMessage.isHidden = false }
         }
         
         else {
             
            // If user is not logged in, remind them they have to do that to use this function
             plusButton.isHidden = true
             noPetsMessage.text = "Please login to view or add your pets"; noPetsMessage.isHidden = false
         }
             
         petCollectionView.reloadData()
    }
    
    // MARK: COLLECTION DELEGATE PROTOCOL
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if globalData.flags.petPhotosOnBoard { return globalData.user.pets.count }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var petImage: UIImage?
        let petData = globalData.user.pets[indexPath.item]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PetImage", for: indexPath) as! VCPetCollectionViewCell
        
        if petData.hasImage && globalData.flags.petPhotosOnBoard && globalData.user.petImages[petData.petUID!] != nil { petImage = globalData.user.petImages[petData.petUID!] }
        else { petImage = UIImage(named: "image.nopic.png") }
            
        cell.petImageView.image = petImage
        cell.petNameLabel.text = petData.petName
       
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) { }
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedCell = collectionView.cellForItem(at: indexPath) as! VCPetCollectionViewCell
        selectedPet = indexPath.item
       
        // Set pet record with information for the collection view choice
        let thePetRecord = globalData.user.pets[indexPath.item]
        
        petInformationView.deletePetButton.alpha = 1.0
        petInformationView.deletePetButton.isEnabled = true
        petInformationView.personalizeFormLabels(petName: thePetRecord.petName)
        petInformationView.setPetImage(selectedCell: selectedCell)
  
        petInformationView.setSelectedPetData()
        petInformationView.petInfoDocLabel.alpha = 1.0
        petInformationView.petDocsButton.alpha = 1.0
        petInformationView.showView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize { return CGSize(width: 150, height: 128) }
    
    // MARK: PET PHOTO LOAD WATCHER
    
    @objc func watchForPhotoLoad() {
        
        cumulativeTime! += 1
        
        if globalData.flags.petPhotosOnBoard {
            
            self.controllerAlert!.dismiss()
            self.petPhotoWatchTimer.invalidate()
            self.petCollectionView.reloadData()
            
            if self.appointmentController.appointmentTable != nil { self.appointmentController.appointmentTable.reloadData() }
         
        } else {
            
            if cumulativeTime! > 30 {
                
                self.controllerAlert!.dismiss()
                self.petPhotoWatchTimer.invalidate()
                
                DispatchQueue.main.async {
                    
                    self.controllerAlert!.popupMessage(aTitle: "Download Error", aMessage: "There seems to be a problem downloading your pet photos. The app will retry the next time you navigate to this tab.") { () in self.gotoHome()}
                }
            }
        }
    }
        
    // MARK: ACTION HANDLERS
    
    @IBAction func settingsButtonTapped(_ sender: Any) { petSettingsView.initControls(); petSettingsView.showView() }
    
    @IBAction func plusButtonTapped(_ sender: UIButton) {
        
        selectedPet = nil
        petInformationView.clearPetInfo()
        petInformationView.petInfoDocLabel.alpha = 0.20
        petInformationView.petDocsButton.alpha = 0.20
        petInformationView.localPetRecord!.reinit()
        petInformationView.deletePetButton.alpha = 0.20
        petInformationView.deletePetButton.isEnabled = false
        
        // Before showing pet info form, ask for the pet name; if none provided then ignore it, user can fill out in the form
        controllerAlert!.popupWithTextField(aTitle: "Please Enter Your Pet's Name", aMessage: "", aPlaceholder: "Your pet's name", aDefault: "", buttonTitles: ["OK","CANCEL"], aStyle: [.default,.cancel]) { (doPresent, petName) in
            
            if doPresent == 0 {
                
                guard petName != "" else { return }
                
                self.petInformationView.personalizeFormLabels(petName: petName)
                self.petInformationView.showView()
            }
        }
    }
}

 
 
 
 
