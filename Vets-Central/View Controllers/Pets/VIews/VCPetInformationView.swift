//
//  VCPetInformationView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.  
//

import UIKit

class VCPetInformationView: VCView, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // MARK: OUTLETS
    
    // Scroll controls
    @IBOutlet weak var petScrollView: UIScrollView!
    @IBOutlet weak var petContentHeight: NSLayoutConstraint!
    
    // Pet name labels
    @IBOutlet weak var petInfoTitleLabel: UILabel!
    @IBOutlet weak var petInfoAgeLabel: UILabel!
    @IBOutlet weak var petInfoOwnLabel: UILabel!
    @IBOutlet weak var petInfoDocLabel: UILabel!
    @IBOutlet weak var petAgeLabel: UILabel!
    
    // Pet image management
    @IBOutlet weak var petImageView: UIImageView!
    @IBOutlet weak var petImageBackground: UIButton!
    @IBOutlet weak var addPetImageButton: UIButton!
    @IBOutlet weak var updatePetImageButton: UIButton!
    @IBOutlet weak var deletePetImageButton: UIButton!
    
    // Pet info text fields
    @IBOutlet weak var petNameTextField: UITextField!
    @IBOutlet weak var petSpeciesTextField: UITextField!
    @IBOutlet weak var petBreedTextField: UITextField!
    @IBOutlet weak var petGenderTextField: UITextField!
    @IBOutlet weak var petOwnDateTextField: UITextField!
  
    // Stepper and segmented control
    @IBOutlet weak var petAgeStepper: UIStepper!
   
    // Form buttons
    @IBOutlet weak var petDocsButton: UIButton!
    @IBOutlet weak var savePetInfoButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var deletePetButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: PROPERTIES
    
    var petName: String = ""
    var currentYear: Int?
    var currentMonth: Int?
    
    // Pickers
    var petImagePicker = UIImagePickerController()
    var ownSincePickerView = UIPickerView()
    var speciesPickerView = UIPickerView()
    var genderPickerView = UIPickerView()
    var breedPickerView = UIPickerView()
    
    // Tool bar
    var toolBar: UIToolbar = UIToolbar()
    var doneButton: UIBarButtonItem?
  
    // Indices
    var selectedSpecies: Int = 0
    var selectedGender: Int = 0
    var selectedBreed: Int = 0
    var selectedMonth: Int = 0
    var selectedYear: Int = 0
    
    // Flags and Counters
    var isNewPet = true
    var cancelCounter: Int = 0
    
    // Containers
    var selectedCell : VCPetCollectionViewCell?
    var localPetRecord: VCPetRecord?
    var localValidAppointments = [VCAppointmentRecord]()
    var speciesData = [String]()
    var genderData = [String]()
    var breedData = [String]()
    var indicesToCancel = [Int]()
    var isFirstLoad: Bool = true
     
    // MARK: INITIALIZATION
    
    override func initView() {
    
        // Attach the common controls
        scrollView = petScrollView
        contentHeight = petContentHeight
 
        petSpeciesTextField.delegate = self
        petGenderTextField.delegate = self
        petOwnDateTextField.delegate = self
      
        // Setup the image picker
        petImagePicker.delegate = self
        petImagePicker.sourceType = .photoLibrary
        petImagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        
        // Setup the buttons
        petImageView.roundAllCorners(value: 15.0)
        petImageBackground.roundAllCorners(value: 15.0)
        
        updatePetImageButton.alpha = 0.30
        deletePetImageButton.alpha = 0.30
        
        petDocsButton.roundAllCorners(value: 4.0)
        petDocsButton.setBorder(width: 1.0, color: UIColor.lightGray.cgColor)
        savePetInfoButton.roundAllCorners(value: 10.0)
        deletePetButton.roundAllCorners(value: 10.0)
        
        localPetRecord = VCPetRecord()
        activityIndicator.isHidden = true
        
        setupPickers()
    
        // Perform the remaining common initialization
        super.initView()
    }
    
    // MARK: METHODS
    
    func setupPickers() {
        
        for l in globalData.lookups.speciesLookups { speciesData.append( l.displayName ) }
        for l in globalData.lookups.genderLookups { genderData.append( l.displayName ) }
        for l in globalData.lookups.breedLookups { breedData.append( l.displayName ) }
        
        // Get the current month and date for error checking purposes
        let calendar = Calendar.current
        currentYear = calendar.component(.year, from: Date())
        currentMonth = calendar.component(.month, from: Date())
        selectedYear = currentYear!
        selectedMonth = currentMonth!
        
        // Set up the picker with this view as the delegate
        ownSincePickerView.delegate = self
        ownSincePickerView.dataSource = self
        ownSincePickerView.setValue(UIColor.white, forKeyPath: "textColor")
        ownSincePickerView.backgroundColor = .black
        ownSincePickerView.frame.size.height = 0.25 * self.frame.size.height
        
        // Set up the picker with this view as the delegate
        speciesPickerView.delegate = self
        speciesPickerView.dataSource = self
        speciesPickerView.setValue(UIColor.white, forKeyPath: "textColor")
        speciesPickerView.backgroundColor = .black
        speciesPickerView.frame.size.height = 0.25 * self.frame.size.height
        
        // Set up the picker with this view as the delegate
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        genderPickerView.setValue(UIColor.white, forKeyPath: "textColor")
        genderPickerView.backgroundColor = .black
        genderPickerView.frame.size.height = 0.25 * self.frame.size.height
        
        // MARK: MARK - BREED WILL BE FILL-IN FOR NOW
        // Set up the picker with this view as the delegate
//      breedPickerView.delegate = self
//      breedPickerView.dataSource = self
//      breedPickerView.setValue(UIColor.white, forKeyPath: "textColor")
//      breedPickerView.backgroundColor = .black
//      breedPickerView.frame.size.height = 0.25 * self.frame.size.height
        
        // Create Done button UIPicker
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(dismissPicker))
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = false
        toolBar.tintColor = .white
        toolBar.barTintColor = UIColor(displayP3Red: 67/255, green: 146/255, blue: 203/255, alpha: 1.0)
        toolBar.sizeToFit()
        toolBar.setItems([doneButton!], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        // Connect pickers and toolbar
        petOwnDateTextField.inputView = ownSincePickerView
        petOwnDateTextField.inputAccessoryView = toolBar
        
        petSpeciesTextField.inputView = speciesPickerView
        petSpeciesTextField.inputAccessoryView = toolBar
        
        petGenderTextField.inputView = genderPickerView
        petGenderTextField.inputAccessoryView = toolBar
        
        // MARK: MARK - BREED WILL BE FILL-IN FOR NOW
        
        if isNewPet {
            
            if speciesData.count > 0 { petSpeciesTextField.text = speciesData[selectedSpecies] }
            if genderData.count > 0 { petGenderTextField.text = genderData[selectedGender] }
            if breedData.count > 0 { petBreedTextField.text = breedData[selectedBreed] }
        }
    }
    
    func personalizeFormLabels(petName: String) {
        
        petInfoTitleLabel.text = petName + "'s Information"
        petNameTextField.text = petName
        petSpeciesTextField.placeholder = "What type of animal is " + petName + "?"
        petBreedTextField.placeholder = "What breed is " + petName + "?"
        petGenderTextField.placeholder = "What gender is " + petName + "?"
        petInfoAgeLabel.text = "How old is " + petName + "?"
        petInfoOwnLabel.text = "When did " + petName + " join your family?"
        petInfoDocLabel.text = "Documents for " + petName
    }
    
    func setSelectedPetData () {
        
        localPetRecord = globalData.user.pets[parentController.petController.selectedPet!]
        
        petNameTextField.text = localPetRecord!.petName
        petSpeciesTextField.text = localPetRecord!.petSpecies
        petBreedTextField.text = localPetRecord!.petBreed
        petAgeStepper.value = Double(localPetRecord!.petAge)
        petOwnDateTextField.text = localPetRecord!.ownSince
        petGenderTextField.text = localPetRecord!.petGender
        
        if Int(petAgeStepper.value) > 1 { petAgeLabel.text = String(format: "%d yrs", Int(petAgeStepper.value)) } else { petAgeLabel.text = "1 yr" }
    }

    func createPetImage(anImage: UIImage, imageURL: NSURL) {
    
        self.petImageView.changeDisplayState(toState: .hidden, forDuration: 0.25, atCompletion: {
            
            self.petImageView.image = anImage
            self.petImageView.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { self.petImageBackground.alpha = 0.0 } )
        })
    
        addPetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
        updatePetImageButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {return} )
        deletePetImageButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {return} )
    }
    
    func setPetImage(selectedCell : VCPetCollectionViewCell?) {
        
        let petImage = selectedCell!.petImageView.image
        
        if globalData.user.pets[parentController.petController.selectedPet!].hasImage {
            
            if isFirstLoad {
                
                isFirstLoad = false
                petImageView.image = petImage
                
                petImageBackground.alpha = 0.0
                petImageView.alpha = 1.0
            }
            
            else  {
                
                self.petImageView.changeDisplayState(toState: .hidden, forDuration: 0.25, atCompletion: {
                    
                    self.petImageView.image = petImage
                    self.petImageView.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { self.petImageBackground.alpha = 0.0 } )
                })
            }
            
            addPetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
            updatePetImageButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {return} )
            deletePetImageButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {return} )
            
        }
        
        else {
        
            addPetImageButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {return} )
            updatePetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
            deletePetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
        }
    }
    
    func deletePetImage() {
        
        petImageBackground.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {self.petImageView.image = nil} )
        localPetRecord?.hasImage = false
        globalData.user.petImages.removeValue(forKey: globalData.user.pets[parentController.petController.selectedPet!].petUID!)
        
        // TODO:  DELETE SERVER PHOTO HERE
        
        addPetImageButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {return} )
        updatePetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
        deletePetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
    }
    
    func clearPetInfo () {
        
        petNameTextField.text!.removeAll()
        petSpeciesTextField.text!.removeAll()
        petBreedTextField.text!.removeAll()
        petGenderTextField.text!.removeAll()
        petOwnDateTextField.text!.removeAll()
        petAgeLabel.text = "1 yr"
        petAgeStepper.value = 1
       
        petImageView.image = nil
        
        personalizeFormLabels(petName: "")
        
        petImageView.alpha = 0.0
        petImageBackground.alpha = 1.0
        
        addPetImageButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: {return} )
        updatePetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
        deletePetImageButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: {return} )
    }
    
    func validateFields() -> Bool {
        
        localPetRecord!.petName = petNameTextField.text!
        localPetRecord!.petSpecies = petSpeciesTextField.text!
        localPetRecord!.petBreed = petBreedTextField.text!
        localPetRecord!.petGender = petGenderTextField.text!
        localPetRecord!.ownSince = petOwnDateTextField.text!
        localPetRecord!.petAge = Int(petAgeStepper!.value)
        
        if !localPetRecord!.isComplete() { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Please complete all the information for your pet"); return false }

        return true
    }
    
    func setActivityIndicator(_ state: Bool) {
        
        if state { savePetInfoButton.setTitle("", for: .normal);  activityIndicator.isHidden = false }
        else { savePetInfoButton.setTitle("SAVE", for: .normal);  activityIndicator.isHidden = true }
    }
    
    func cancelAppointments() {
        
        if cancelCounter < indicesToCancel.count {
            
            let appointmentToCancel = globalData.user.currentAppointments[indicesToCancel[cancelCounter]]
          
            webServices!.cancelAppointment(apptUID: appointmentToCancel.apptUID!) { (json, status) in
                
                guard self.webServices!.isErrorFree(json: json, status: status) else { return }
                
                self.cancelCounter += 1
                self.cancelAppointments()
            }
        }
        
        else {
            
            globalData.user.currentAppointments.removeIndices(indices: indicesToCancel)
            webServices!.deletePet(thePetData: globalData.user.pets[parentController.petController.selectedPet!]) { json, status in
                
                guard self.webServices!.isErrorFree(json: json, status: status) else { return }
                
                self.parentController.petController.controllerAlert!.dismiss()
      
                globalData.user.petImages.removeValue(forKey: globalData.user.pets[self.parentController.petController.selectedPet!].petUID!)
                globalData.user.pets.remove(at: self.parentController.petController.selectedPet!)
            
                if globalData.user.pets.count == 0 { self.parentController.petController.selectedPet = nil }
                self.parentController.petController.reloadCollectionData()
                
                self.parentController.petController.controllerAlert!.dismiss()
                self.parentController.homeController.setBadges()
                self.returnToCollection()
            }
        }
    }
    
    func returnToCollection () { isFirstLoad = true; hideView() }
    
    // MARK: TEXTFIELD DELEGATE PROTOCOL
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == petSpeciesTextField || textField == petGenderTextField || textField == petOwnDateTextField { return false }
        else { return true }
    }
    
    // MARK: DATE PICKER DELEGATE PROTOCOL
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
    
        switch pickerView {
        
            case ownSincePickerView: return 2
            case speciesPickerView: return 1
            case genderPickerView: return 1
            case breedPickerView: return 1
            default: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        switch pickerView {
        
            case ownSincePickerView: if component == 0 { return 12 } else { return 30 }
            case speciesPickerView: return speciesData.count
            case genderPickerView: return genderData.count
            case breedPickerView: return breedData.count
            default: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch pickerView {
        
            case ownSincePickerView:  if component == 0 { return DateFormatter().monthSymbols[row] } else { return String(format: "%d", currentYear! - row) }
            case speciesPickerView: return speciesData[row]
            case genderPickerView: return genderData[row]
            case breedPickerView: return breedData[row]
            default: return ""
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerView {
        
            case ownSincePickerView: if component == 0 { selectedMonth = row + 1 } else { selectedYear = currentYear! - row }
            case speciesPickerView: selectedSpecies = speciesPickerView.selectedRow(inComponent: 0); petSpeciesTextField.text = speciesData[row]
            case genderPickerView: selectedGender = genderPickerView.selectedRow(inComponent: 0); petGenderTextField.text = genderData[row]
            case breedPickerView: selectedBreed = breedPickerView.selectedRow(inComponent: 0); petBreedTextField.text = breedData[row]
            default: break
        }
    }
    
    // MARK: IMAGE PICKER DELEGATE PROTOCOL
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let selectedImage = info[.originalImage]
        let selectedURL = info[.imageURL]
        localPetRecord!.hasImage = true
        parentController.dismiss(animated: true, completion: { () -> Void in self.createPetImage(anImage: (selectedImage as! UIImage), imageURL: (selectedURL as! NSURL)) })
    }
    
    // MARK: CALL BACKS
    
    func savePetResponse(json: NSDictionary, status: Bool) {
        
        guard webServices!.isErrorFree(json: json, status: status) else { return }
        
        // If this is a new pet we need to capture the ID
        if isNewPet {
            
            let petData = json["petDetails"] as! NSDictionary
            localPetRecord!.petUID = (petData["id"] as! Int)
     
            globalData.user.pets.append(localPetRecord!)
            parentController.petController.selectedPet = globalData.user.pets.count - 1
        }
    
        // Save the pet image if there is one
        if localPetRecord!.hasImage && petImageView.image != nil { self.webServices!.uploadPetPhoto(thePetRecord: localPetRecord!, thePetImage: petImageView.image!.jpegData(compressionQuality: 0.30)!, callBack:savePetImageResponse) }
      
        else {
            
            // Save off doc status
            let docsAreDownloaded = globalData.user.pets[parentController.petController.selectedPet!].metadataIsDownloaded
            let docMetadata = globalData.user.pets[parentController.petController.selectedPet!].docMetadata
            
            globalData.user.pets[parentController.petController.selectedPet!] = localPetRecord!
            
            // Reset doc status
            globalData.user.pets[parentController.petController.selectedPet!].metadataIsDownloaded = docsAreDownloaded
            globalData.user.pets[parentController.petController.selectedPet!].docMetadata = docMetadata
            
            setActivityIndicator(false)
            
            if !isNewPet { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Your pet's information has been updated", callBack: petSaveComplete) }
            else { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Your pet has been saved to your account", callBack: petSaveComplete) }
        }
    }
    
    func savePetImageResponse(json: NSDictionary, status: Bool) {
        
        setActivityIndicator(false)
        guard webServices!.isErrorFree(json: json, status: status) else { return }
    }
    
    func petSaveComplete () {
        
        globalData.user.pets[parentController.petController.selectedPet!] = localPetRecord!
        parentController.petController.selectedPet = nil
        globalData.flags.petPhotosOnBoard = true
        parentController.petController.reloadCollectionData()
        parentController.petController.homeController.setBadges()
        
        returnToCollection()
    }
    
    func deletePetResponse (json: NSDictionary, status: Bool) {
        
        parentController.petController.controllerAlert!.dismiss()
        guard webServices!.isErrorFree(json: json, status: status) else { return }
       
        globalData.user.petImages.removeValue(forKey: globalData.user.pets[parentController.petController.selectedPet!].petUID!)
        globalData.user.pets.remove(at: parentController.petController.selectedPet!)
    
        if globalData.user.pets.count == 0 { parentController.petController.selectedPet = nil }
        parentController.petController.reloadCollectionData()
        
        parentController.petController.controllerAlert!.dismiss()
        parentController.homeController.setBadges()
        returnToCollection()
    }
 
    // MARK: ACTION HANDLERS
    
    @objc func dismissPicker () {
        
        if selectedYear == currentYear! && selectedMonth > currentMonth! { VCAlertServices(viewController: parentController).popupMessage(aMessage: "You selected a date in the future, please try again") }
        else { petOwnDateTextField.text = String(format: "%02d/%4d",selectedMonth,selectedYear); endEditing()}
    }
   
    @IBAction func editingDidBegin(_ sender: UITextField) {
        
        switch sender {
            
            case petSpeciesTextField: if speciesData.count > 0 { petSpeciesTextField.text = speciesData[selectedSpecies] }
            case petBreedTextField:   if breedData.count > 0 { petBreedTextField.text = breedData[selectedBreed] }
            case petGenderTextField:  if genderData.count > 0 { petGenderTextField.text = genderData[selectedGender] }
            default: break
        }
    }
    
    @IBAction func petNameChanged(_ sender: Any) { personalizeFormLabels(petName: petNameTextField.text!) }
  
    @IBAction func endOfEditing(_ sender: UITextField) { endEditing() }
    
    @IBAction func addPetImageButtonTapped(_ sender: Any) { parentController.present(petImagePicker, animated: true, completion: nil) }
    
    @IBAction func updatePetImageButtonTapped(_ sender: Any) { parentController.present(petImagePicker, animated: true, completion: nil) }
    
    @IBAction func deletePetImageButtonTapped(_ sender: Any) { deletePetImage() }
    
    @IBAction func ageStepperTapped(_ sender: Any) {
        
        if Int(petAgeStepper.value) > 1 { petAgeLabel.text = String(format: "%d yrs", Int(petAgeStepper.value)) }
        else { petAgeLabel.text = "1 yr" }
    }
    
    @IBAction func petDocsButtonTapped(_ sender: Any) {
        
        guard localPetRecord!.petUID != nil else { VCAlertServices(viewController: parentController).popupMessage(aMessage: "Please save this pet before uploading documents"); return }
        
        parentController.petController.petDocumentView.subClassType = .pet
        parentController.petController.petDocumentView.downloadMetadata()
    }
        
    @IBAction func savePetInfoButtonTapped(_ sender: Any) {
        
        if validateFields() {
            
            if globalData.flags.refreshInProgress { globalData.abortRefresh() }
            
            setActivityIndicator(true)
       
            if parentController.petController.selectedPet == nil {

                isNewPet = true
                self.webServices!.createPet(thePetData: localPetRecord!, callBack: savePetResponse)
            }
            else {
                            
                isNewPet = false
                self.webServices!.updatePet(thePetData: localPetRecord!, callBack: savePetResponse)
            }
        }
    }
    
    @IBAction func returnButtonTapped(_ sender: Any) {
        
        returnToCollection()
        parentController.petController.petDocumentView.documentTableView.reloadData()
        
    }
    
    @IBAction func deletePetButtonTapped(_ sender: Any) {
        
        var message: String?
        
        if globalData.user.hasAppointment(petUID: localPetRecord!.petUID!) {
            
            message = "Are you sure you to delete " + localPetRecord!.petName + "'s record?\n\n" + localPetRecord!.petName + " has an active appointment(s). All active appointments will be canceled."
            
        } else { message = "Are you sure you to delete " + localPetRecord!.petName + "'s record?" }
     
        VCAlertServices(viewController: parentController).popupYesNo(aMessage: message!, aStyle: [.destructive,.default]) { choice in
            
            if choice == 0 {
                
                self.parentController.petController.controllerAlert!.popupPendingMsg(aMessage: "Deleting this pet record")
                self.indicesToCancel = globalData.user.getAppointmentsFor(petUID: self.localPetRecord!.petUID!)
                
                if self.indicesToCancel.count > 0 { self.cancelCounter = 0; self.cancelAppointments() }
                else { self.webServices!.deletePet(thePetData: globalData.user.pets[self.parentController.petController.selectedPet!], callBack: self.deletePetResponse) }
            }
        }
    }
}
  

 

