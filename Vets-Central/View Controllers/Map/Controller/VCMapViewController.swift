//
//  ClinicMapViewController.swift
//  Vets-Central
//
//  Clinic Scene Controller
//  Created by Roger Vogel on 6/14/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CallKit

protocol VCClinicMapDelegate: AnyObject {
    
    func getDirections()
    func refreshLocations()
    func getSegmentControl() -> UISegmentedControl
    func clinicsToShowTapped(_ sender: UISegmentedControl)
}

class VCMapViewController: VCViewController, MKMapViewDelegate, CLLocationManagerDelegate, VCClinicMapDelegate {
    
    // MARK: OUTLETS
    
    @IBOutlet var mapView: VCMapView!
    @IBOutlet var clinicInfoView: VCClinicInformationView!
    @IBOutlet var mapSettingsView: VCMapSettingsView!
    
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var centerButtonBackground: UIButton!
    @IBOutlet weak var centerButtonForeground: UIButton!
    @IBOutlet weak var clinicsToShow: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var drawerHandleButton: UIButton!
    @IBOutlet weak var blueKey: UIButton!
    @IBOutlet weak var redKey: UIButton!
    @IBOutlet weak var grayKey: UIButton!
    @IBOutlet weak var blueKeyHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var redKeyHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var grayKeyHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var closedDrawer: UILabel!
    
    // MARK: PROPERTIES
    
    var locationManager:CLLocationManager!
    var homeLocale: CLLocationCoordinate2D?
    var locationsPlotted: Bool = false
    var baseHeightConstraint: CGFloat?
    var keyDrawerIsOpen = true
    var thePlacemarkName: String?
    var theClinicRecord: VCClinicRecord?
    var thePlacemarkRecord = VCPlacemark()
    var isVCClinic: Bool?
   
    // MARK: INITIALIZATION
    
    override func viewDidLoad() { super.viewDidLoad()
        
        setSubViews(subviews: [clinicInfoView])
        
        centerButtonBackground.roundAllCorners(value: centerButton.frame.height/2)
        
        clinicInfoView.delegate = self
        
        view.addSubview(clinicInfoView)
        clinicInfoView.initView()
        
        view.addSubview(mapSettingsView)
        mapSettingsView.initView()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
       
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.delegate = self
        mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        mapView.initView(parent: self)
        
        blueKey.roundCorners(corners: .top, radius: 3)
        grayKey.roundCorners(corners: .bottom, radius: 3)
        drawerHandleButton.roundCorners(corners:.top)
        closedDrawer.isHidden = true
        
       // drawerHandleButton.isEnabled = false
      
        baseHeightConstraint = blueKeyHeightConstraint.constant
    }
    
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated)
        
        if globalData.settings.onlyMapVC { clinicsToShow.selectedSegmentIndex = 0 }
        else { clinicsToShow.selectedSegmentIndex = 1 }
        
        activityIndicator.isHidden = true
        clinicInfoView.alpha = 0.0
       
        refreshLocations()

        
        if globalData.flags.loginState == .loggedIn { settingsButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { self.settingsButton.isEnabled = true })}
        else { settingsButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { self.settingsButton.isEnabled = false }) }
        
        globalData.activeController = self
    }
    
    override func doLogoutTasks() {
        
        clinicInfoView.hideView()
        mapSettingsView.hideView()
    }
    
    // MARK: METHODS
    
    func getSegmentControl() -> UISegmentedControl { return clinicsToShow }
    
    func openCloseKeyDrawer() {
        
        if keyDrawerIsOpen {
            
            UIView.animate(withDuration: 0.25, animations: { self.blueKeyHeightConstraint.constant = 0 }, completion: { finished in
                
                self.blueKey.isHidden = true
                
                UIView.animate(withDuration: 0.25, animations: { self.redKeyHeightConstraint.constant = 0 }, completion: { finished in
                    
                    self.redKey.isHidden = true
                    
                    UIView.animate(withDuration: 0.25, animations: { self.grayKeyHeightConstraint.constant = 0 }, completion: { finished in
                        
                        self.grayKey.isHidden = true
                        self.drawerHandleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
                        self.closedDrawer.isHidden = false
                        self.keyDrawerIsOpen = false
                    })
                })
            })
        }
        
        else {
            
            self.blueKey.isHidden = false
            
            UIView.animate(withDuration: 0.25, animations: { self.blueKeyHeightConstraint.constant = self.baseHeightConstraint! }, completion: { finished in
                
                self.redKey.isHidden = false
                
                UIView.animate(withDuration: 0.25, animations: { self.redKeyHeightConstraint.constant = self.baseHeightConstraint! }, completion: { finished in
                    
                    self.grayKey.isHidden = false
                    
                    UIView.animate(withDuration: 0.25, animations: { self.grayKeyHeightConstraint.constant = self.baseHeightConstraint! }, completion: { finished in
                        
                        self.keyDrawerIsOpen = true
                        self.drawerHandleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
                        self.closedDrawer.isHidden = true
                    })
                })
            })
        }
    }
    
    func gotoCurrentLocation() {  if CLLocationManager.locationServicesEnabled() { locationsPlotted = false; locationManager.startUpdatingLocation() } }
    
    func gotoHomeLocation () {
        
        activityIndicator.isHidden = true
        
        guard globalData.flags.loginState == .loggedIn else { VCAlertServices(viewController: self).popupMessage(aMessage: "Please log in to use your home address", callBack: { () in } ); clinicsToShow.selectedSegmentIndex = 0;  return }
        
        CLGeocoder().geocodeAddressString(globalData.user.data.getAddressString(), completionHandler: {(placemarks, error) -> Void in
            
            if error == nil {
                
                let homeLocation = MKPointAnnotation()
                let place = placemarks![0]
                let longitude = place.location?.coordinate.longitude
                let latitude = place.location?.coordinate.latitude
                
                homeLocation.title = "Home"
                homeLocation.coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            
                self.mapView.addAnnotation(homeLocation)
                self.homeLocale = homeLocation.coordinate
                
                self.locationsPlotted = false
                self.locationManager.startUpdatingLocation()
            }
        })
    }
    
    func centerMap() {
        
        locationsPlotted = false
        
        if clinicsToShow.selectedSegmentIndex == 0 { gotoCurrentLocation() }
        else { gotoHomeLocation() }
    }
    
    // MARK: VCMAP DELEGATE PROTOCOL
    
    func getDirections() {
        
        if !isVCClinic! {
            
            let mapItem = mapView.locationData[thePlacemarkName!]
            guard mapItem != nil else { VCAlertServices(viewController: self).popupMessage(aMessage: "Directions to this clinic are not available"); return}
            
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem!.openInMaps(launchOptions: launchOptions)
         
        } else {

            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: theClinicRecord!.clinicLat, longitude: theClinicRecord!.clinicLng))
            let mapItem = MKMapItem(placemark: placemark)
        
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
        
        //22.380488, 114.271753
    }
    
    func refreshLocations() {
        
        mapView.clearAnnotations()
        mapView.showVCClinics()
        
        if clinicsToShow.selectedSegmentIndex == 1 { mapView.findOtherClinics() }
        
        locationManager.startUpdatingLocation()
    }
        
    // MARK: LOCATION DELEGATE PROTOCOL
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopUpdatingLocation()
        
        if !locationsPlotted {
            
             _ = mapView.centerToLocation(locations[0] as CLLocation)
           
            if !globalData.settings.onlyMapVC { mapView.findOtherClinics() }
          
            mapView.showVCClinics()
            locationsPlotted = true
        }
        
        else { mapView.showVCClinics() }
        
        activityIndicator.isHidden = true
    }
        
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        NSLog("Error - locationManager: \(error.localizedDescription)")
    }
        
    // MARK: MAPVIEW DELEGATE PROTOCOL
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      
        if annotation is MKUserLocation { return nil }
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        
        let button = UIButton(type: .infoDark)
        button.addTarget(self, action: #selector(showLocationDetails), for: .touchUpInside)
        
        pinView?.canShowCallout = true
        if annotation.title != "Home" { pinView?.leftCalloutAccessoryView = button }
        
        let clinicRecord = VCRecordGetter().clinicRecordWith(name: annotation.title!!)
       
        if clinicRecord != nil {
            
            if globalData.flags.loginState == .loggedIn {
                
                if clinicRecord!.clinicUID == globalData.user.data.preferredClinicUID { pinView?.pinTintColor = UIColor(displayP3Red: 231/255, green: 0/255, blue: 1/255, alpha: 1.0) }
                else { pinView?.pinTintColor = UIColor(displayP3Red: 15/255, green: 100/255, blue: 178/255, alpha: 1.0) }
            }
            
            else { pinView?.pinTintColor = UIColor(displayP3Red: 15/255, green: 100/255, blue: 178/255, alpha: 1.0) }
        }
        
        else { pinView?.pinTintColor = .lightGray }

        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        theClinicRecord = VCRecordGetter().clinicRecordWith(name: view.annotation!.title!!)
       
        if theClinicRecord != nil { isVCClinic = true }
        else { thePlacemarkName = view.annotation!.title!!; isVCClinic = false }
    }
   
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        
        (mapView as! VCMapView).clearAnnotations()
        (mapView as! VCMapView).showVCClinics()
        
        if clinicsToShow.selectedSegmentIndex == 1 && mapView.region.span.latitudeDelta <= 2.0 { (mapView as! VCMapView).findOtherClinics() }
    }
        
    // MARK: ACTION HANDLERS
    
    @objc func showLocationDetails () {
        
        if isVCClinic! { clinicInfoView.setClinicInfo(clinicRecord: theClinicRecord!) }
            
        else {
            
            thePlacemarkRecord.mapItem = mapView.locationData[thePlacemarkName!]!
            clinicInfoView.setClinicInfo(vcPlacemark: thePlacemarkRecord)
        }
    
        clinicInfoView.showView()
    }
       
    @IBAction func menuDrawer(_ sender: Any) { openCloseKeyDrawer() }
   
    @IBAction func clinicsToShowTapped(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            
            mapView.clearAnnotations()
            mapView.showVCClinics()
            
        }
        
        else {
        
            mapView.clearAnnotations()
            mapView.showVCClinics()
            mapView.findOtherClinics()
        }
    }
  
    @IBAction func centerButtonTapped(_ sender: Any) { centerMap() }
  
    @IBAction func settingsButtonTapped(_ sender: Any) { mapSettingsView.initControls(); mapSettingsView.showView() }
}

