//
//  VCMapView.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CallKit

class VCMapView: MKMapView {
    
    // MARK: PROPERTIES
    
    var vcClinics: Int?
    var parentController: VCMapViewController?
    var locationData = [String : MKMapItem]()
    
    func initView (parent: VCMapViewController) { parentController = parent }
   
    // MARK: METHODS
    
    func centerToLocation(_ location: CLLocation ) -> MKCoordinateRegion {
        
        let coordinateRegion = MKCoordinateRegion( center: location.coordinate, span: self.region.span)
        
        self.setRegion(coordinateRegion, animated: false)
        
        return coordinateRegion
    }
    
    func findOtherClinics () {
        
        let searchRequest = MKLocalSearch.Request()
        
        searchRequest.naturalLanguageQuery = "veterinary clinics"
        searchRequest.region = self.region
        
        locationData.removeAll()
     
        MKLocalSearch(request: searchRequest).start(completionHandler: { (response, error) in
            
            guard error == nil else { return }
            
            for item in response!.mapItems {
                
                let uid = VCRecordGetter().isVCMember(clinicName: item.name!, latitude: item.placemark.location!.coordinate.latitude, longitude:  item.placemark.location!.coordinate.longitude)
                guard uid == nil else { return }
            
                self.addPin(title: item.name, latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                self.locationData[item.name!] = item
            }
        })
    }
    
    func showVCClinics () {
        
        for c in globalData.clinics {  addPin(title: c.clinicName, latitude: c.clinicLat, longitude: c.clinicLng) }
    }
    
    func addPin(title: String?, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        
        if let title = title {
            
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
          
            annotation.coordinate = location
            annotation.title = title
            
            self.addAnnotation(annotation)
        }
    }
    
    func clearAnnotations() { for a in annotations { removeAnnotation(a) } }
}
 
