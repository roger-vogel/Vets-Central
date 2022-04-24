//
//  VCTimeManager.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/12/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit

class VCScheduleManager: NSObject {
    
    func getTimeSpan(span: [VCTimeWindow]) -> (from: DateComponents, to: DateComponents ) {
        
        var fromTime = DateComponents()
        var toTime = DateComponents()
        
        fromTime.hour = 24
        toTime.hour = 0
        
        for t in span {
            
            // Convert the time strings into components
            let fromTimeData = VCDate(fromTime: t.from).dateComponents
            let toTimeData = VCDate(fromTime: t.to).dateComponents
            
            // Find the earliest start time
            if fromTimeData.hour! < fromTime.hour! { fromTime = fromTimeData }
            
            // Find the latest end time
            if toTimeData.hour! > toTime.hour! { toTime = toTimeData }
        }
    
        return (fromTime, toTime)
    }
}
