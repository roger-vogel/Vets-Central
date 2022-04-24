//
//  PRDate.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 10/24/21.
//

import UIKit



class VCDate: NSObject {
    
    // MARK: PROPERTIES
    
    var theDate: Date?
    var dateFormatter = DateFormatter()
   
    let usd = "MM/dd/yyyy"
    let eud = "dd/MM/yyyy"
    let ust = "h:mm a"
    let eut = "HH:mm"
    let usdd = "E MM/dd/yyyy"
    let eudd = "E dd/MM/yyyy"
    let usddt = "E MM/dd/yyyy 'at' h:mm a"
    let euddt = "E dd/MM/yyyy 'at' HH:mm"
    let api = "yyyy-MM-dd HH:mm"
    
    // MARK: COMPUTED PROPERTIES
    
    var dateNumeric: UInt64 {
        
        get { return theDate!.timeIntervalSince1970.uint64Value }
    }
    
    var timeNumeric: Float {
        
        get { return Float(dateComponents.hour!) + Float(dateComponents.minute!)/60 }
    }
    
    var localDate: Date {
        
        get { return theDate! }
        set { theDate = newValue }
    }
  
    var serverDateAndTime: String {
        
        get {
            
            dateFormatter.dateFormat = api
            return dateFormatter.string(from: localDate)
        }
           
        set {
            
            dateFormatter.dateFormat = api
            theDate = dateFormatter.date(from: newValue)!
        }
    }
    
    var dateComponents: DateComponents {
        
        get {
            
            var dateComponents = DateComponents()
            let calendar = Calendar.current
            
            // Convert and store as date components in appointment record
            dateComponents.year = calendar.component(.year, from: theDate!)
            dateComponents.month = calendar.component(.month, from: theDate!)
            dateComponents.weekday = calendar.component(.weekday, from: theDate!)
            dateComponents.day = calendar.component(.day, from: theDate!)
            dateComponents.hour = calendar.component(.hour, from: theDate!)
            dateComponents.minute = calendar.component(.minute, from: theDate!)
            
            return dateComponents
        }
        
        set { theDate = NSCalendar.current.date(from: newValue)! }
    }
    
    var dayDateAndTimeString: String {
        
        get {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usddt } else {dateFormatter.dateFormat = euddt }
            return dateFormatter.string(from: theDate!)
        }
        
        set {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usddt }
            else { dateFormatter.dateFormat = euddt }
            
            theDate = dateFormatter.date(from: newValue)
        }
    }
    
    var dayAndDateString: String {
        
        get {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usdd } else {dateFormatter.dateFormat = eudd }
            return dateFormatter.string(from: theDate!)
        }
        
        set {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usdd }
            else { dateFormatter.dateFormat = eudd }
            
            theDate = dateFormatter.date(from: newValue)
        }
    }
    
    var dateString: String {
        
        get {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usd } else {dateFormatter.dateFormat = eud }
            return dateFormatter.string(from: theDate!)
        }
        
        set {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usd } else { dateFormatter.dateFormat = eud }
            theDate = dateFormatter.date(from: newValue)
        }
    }
    
    var timeString: String {
   
        get {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = ust } else {dateFormatter.dateFormat = eut }
            return dateFormatter.string(from: theDate!)
        }
    }
    
    var dateAndTimeString: String {
   
        get {
            
            if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usddt } else {dateFormatter.dateFormat = euddt }
            return dateFormatter.string(from: theDate!)
        }
    }
    
    var APITimeAndDateString: String {
        
        dateFormatter.dateFormat = api
        return dateFormatter.string(from: localDate)
    }
    
    var timeStamp: String {
        
        let dateFormatter = DateFormatter()
        
        if globalData.settings.clock == .c12 { dateFormatter.dateFormat = usddt }
        else { dateFormatter.dateFormat = euddt }
       
        return dateFormatter.string(from: theDate!)
    }
    
    // MARK: INITIALIZATION
    
    init (date: Date? = Date()) {
        
        super.init()

        theDate = date
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
    }
    
    init (date: VCDate) {
        
        super.init()

        theDate = date.theDate!
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
    }
    
    init (fromServerDateAndTime: String) {
        
        super.init()
        serverDateAndTime = fromServerDateAndTime
    }
    
    init (fromDayDateAndTime: String) {
        
        super.init()
        
        dayDateAndTimeString = fromDayDateAndTime
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
    }
    
    init (fromDayAndDate: String) {
        
        super.init()
    
        dayAndDateString = fromDayAndDate
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
    }
    
    init (fromDate: String) {
        
        super.init()
        
        dateString = fromDate
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
    }
    
    init(fromTime: String) {
        
        super.init()
        
        var hour: Int?
        var minute: Int?
        var components = DateComponents()
        
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        theDate = Date()
        
        let hourAndMinute = fromTime.split(separator: ":")
        
        if hourAndMinute.first != nil { hour = Int(NSString(string: String(hourAndMinute.first!)).intValue) }
        else { hour = 0 }
        
        if hourAndMinute.last != nil { minute = Int(NSString(string: String(hourAndMinute.last!)).intValue) }
        else { minute = 0 }
        
        components = dateComponents
     
        components.hour = hour
        components.minute = minute
      
        dateComponents = components
    }
    
    init (fromDateComponents: DateComponents) {
        
        super.init()
        
        dateComponents = fromDateComponents
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
    }
    
    // MARK: METHJODS
    
    func roundupTime(withSegments: Int? = 15) -> VCDate {
        
        var theTimeInterval: TimeInterval?
        let nextTimeSlot = VCDate(date: theDate!.addingTimeInterval(1800))
        let nextMinutes = nextTimeSlot.dateComponents.minute!
        let modulus = nextMinutes % 15
        
        if modulus != 0 {
            
            theTimeInterval = Double(15 - modulus) * 60.0
            let newSlot = VCDate(date: nextTimeSlot.theDate!.addingTimeInterval(theTimeInterval!))
            return newSlot
            
        } else { return nextTimeSlot }
    }
    
    func updateDateTo(newDate: VCDate) {
        
        dateComponents.year = newDate.dateComponents.year!
        dateComponents.month = newDate.dateComponents.month!
        dateComponents.day = newDate.dateComponents.day!
        dateComponents.weekday = newDate.dateComponents.weekday!
        
        theDate = NSCalendar.current.date(from: dateComponents)!
    }
    
    func updateTimeTo(newTime: VCDate) {
        
        dateComponents.hour = newTime.dateComponents.hour!
        dateComponents.minute = newTime.dateComponents.minute!
        
        theDate = NSCalendar.current.date(from: dateComponents)!
    }
}
