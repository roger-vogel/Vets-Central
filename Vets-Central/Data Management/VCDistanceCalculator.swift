//
//  VCDistanceCalculator.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/26/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit

class VCDistanceCalculator: NSObject {

    func distanceRadius(clinicLat: Double, clinicLng: Double, compareLat: Double, compareLng: Double ) -> Double {
        
        let deltaLat = clinicLat - compareLat
        let deltaLng = clinicLng - compareLng
        let radius = pow((pow(deltaLat,2.0)+pow(deltaLng,2.0)),0.5) * 111
        
        return radius
    }
}
