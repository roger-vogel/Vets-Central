//
//  VCColor.swift
//  Vets-Central
//
//  Color Related Methods Container
//  Created by Roger Vogel on 6/26/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCColorServices: NSObject {
    
    // MARK: METHODS
    
    func grayColorByPercent (percent: CGFloat) -> UIColor { return UIColor.init(red: percent, green: percent, blue: percent, alpha: 1.0) }
    
    func grayColorByValue (value: CGFloat) -> UIColor { return UIColor.init(red: value/255, green: value/255, blue: value/255, alpha: 1.0) }
}
