//
//  VCDateFormat.swift
//  Vets-Central
//
//  Date Related Methods Container
//  Created by Roger Vogel on 7/9/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
// 

import UIKit

class VCDateServices: NSObject {
    
    // MARK: PROPERTIES
    
    let dateFormatter = DateFormatter()

    let us = "E MM/dd/yyyy 'at' h:mm a"
    let eu = "E dd/MM/yyyy 'at' HH:mm"
    let ust = "h:mm a"
    let eut = "HH:mm"
    let usd = "E MM/dd/yyyy"
    let eud = "E dd/MM/yyyy"
    let api = "yyyy-MM-dd HH:mm"
    var clockMode: ClockMode?
    
    // MARK: INITIALIZATION
    
    init (clock: ClockMode? = globalData.settings.clock) { super.init(); clockMode = clock!; dateFormatter.amSymbol = "AM"; dateFormatter.pmSymbol = "PM" }
    
    // MARK: METHODS
        
    func convertServerTimeToDateComponents(json: String) -> DateComponents {
        
        var dateComponents = DateComponents()
        
        if json.count == 5 {
            
            dateComponents.hour = Int(json.partial(fromIndex: 0, length: 2))!
            dateComponents.minute = Int(json.partial(fromIndex: 3, length: 2))!
        }
        
        else {
            
            dateComponents.hour = Int(json.partial(fromIndex: 0, length: 1))!
            dateComponents.minute = Int(json.partial(fromIndex: 2, length: 2))!
        }
           
        return dateComponents
    }
    
    func convertServerDateAndTimetoDateComponents (json: String) -> DateComponents {
        
        var dateComponents = DateComponents()
        
        dateComponents.year = Int(json.partial(fromIndex: 0, length: 4))!
        dateComponents.month = Int(json.partial(fromIndex: 5, length: 2))!
        dateComponents.day = Int(json.partial(fromIndex: 8, length: 2))!
        dateComponents.hour = Int(json.partial(fromIndex: 11, length: 2))!
        dateComponents.minute = Int(json.partial(fromIndex: 14, length: 2))!
        
        return dateComponents
    }
    
    func getCurrentTimeStamp () -> String {
        
        let usTimeStamp = us
        let euTimeStamp = eu
        
        let dateFormatter = DateFormatter()
        
        if clockMode! == .c12 { dateFormatter.dateFormat = usTimeStamp }
        else { dateFormatter.dateFormat = euTimeStamp }
       
        let date = Date()
        return dateFormatter.string(from: date)
    }
    
    func getTimeAndDateString (dateComponents: DateComponents) -> String {
        
        let date = NSCalendar.current.date(from: dateComponents)
        
        if clockMode! == .c12 { dateFormatter.dateFormat = us } else {dateFormatter.dateFormat = eu }
        return dateFormatter.string(from: date!)
    }
    
    func getTimeAndDateString (date: Date) -> String {
        
        if clockMode! == .c12 { dateFormatter.dateFormat = us } else { dateFormatter.dateFormat = eu }
        return dateFormatter.string(from: date)
    }
    
    func getDateString (dateComponents: DateComponents) -> String {
        
        let date = NSCalendar.current.date(from: dateComponents)
    
        if clockMode! == .c12 { dateFormatter.dateFormat = usd } else { dateFormatter.dateFormat = eud }
        
        return dateFormatter.string(from: date!)
    }
    
    func getDateString (date: Date) -> String {
        
        if clockMode! == .c12 { dateFormatter.dateFormat = usd } else { dateFormatter.dateFormat = eud }
        return dateFormatter.string(from: date)
    }
    
    func getTimeString (dateComponents: DateComponents) -> String {
        
        let date = NSCalendar.current.date(from: dateComponents)
    
        if clockMode! == .c12 { dateFormatter.dateFormat = ust } else {dateFormatter.dateFormat = eut }
        return dateFormatter.string(from: date!)
    }
    
    func getTimeString (time: Date) -> String {
   
        if clockMode! == .c12 { dateFormatter.dateFormat = ust } else {dateFormatter.dateFormat = eut }
        return dateFormatter.string(from: time)
    }
    
    func getAPITimeAndDateString (date: Date) -> String {
        
        dateFormatter.dateFormat = api
        return dateFormatter.string(from: date)
    }
    
    func scheduleString (forClinic: VCClinicRecord) -> String {
        
        var scheduleString = forClinic.clinicSchedule
        
        if forClinic.startTimeComponents.hour == forClinic.endTimeComponents.hour { scheduleString += "Clinic hours not specified - please contact the clinic" }
        
        else if forClinic.startTimeComponents.hour == 0 && forClinic.startTimeComponents.minute == 0 && forClinic.endTimeComponents.hour == 23 && forClinic.startTimeComponents.minute == 59 { scheduleString += " Open 24 Hours"}
        
        else {
            
            let startDate = NSCalendar.current.date(from: forClinic.startTimeComponents)
            let endDate = NSCalendar.current.date(from: forClinic.endTimeComponents)
            
            if clockMode! == .c12 { dateFormatter.dateFormat = ust } else {dateFormatter.dateFormat = eut }
            
            scheduleString += ("from " + dateFormatter.string(from: startDate!) + " to " + dateFormatter.string(from: endDate!))
        }
        
        return scheduleString
    }
    
    func convertDateToDateComponents(date: Date, components: inout DateComponents) {
        
        let calendar = Calendar.current
        
        // Convert and store as date components in appointment record
        components.year = calendar.component(.year, from: date)
        components.month = calendar.component(.month, from: date)
        components.day = calendar.component(.day, from: date)
        components.hour = calendar.component(.hour, from: date)
        components.minute = calendar.component(.minute, from: date)
            
        components.minute = roundupTime(minutes: components.minute!, withSegments: 15)
        
    }
    
    func convertTimeToDateComponents(date: Date, components: inout DateComponents, roundMinutes: Bool? = true) {
        
        let calendar = Calendar.current
        
        // Convert and store as date components in appointment record
        components.hour = calendar.component(.hour, from: date)
        components.minute = calendar.component(.minute, from: date)
        
        components.minute = roundupTime(minutes: components.minute!, withSegments: 15)
    }
        
    func getTimeSpan(span: [VCTimeWindow]) -> (from: DateComponents, to: DateComponents ) {
        
        var fromTime = DateComponents()
        var toTime = DateComponents()
        
        fromTime.hour = 24
        toTime.hour = 0
        
        for t in span {
            
            // Convert the time strings into components
            let fromTimeData = convertServerTimeToDateComponents(json: t.from)
            let toTimeData = convertServerTimeToDateComponents(json: t.to)
            
            // Find the earliest start time
            if fromTimeData.hour! < fromTime.hour! { fromTime = fromTimeData }
            
            // Find the latest end time
            if toTimeData.hour! > toTime.hour! { toTime = toTimeData }
        }
    
        return (fromTime, toTime)
        
    }
    
    func getCurrentDateAndTime() -> VCTime {
        
        var vcTime = VCTime()
        
        let date = Date()
        let calendar = Calendar.current
        
        vcTime.year = calendar.component(.year, from: date)
        vcTime.month = calendar.component(.month, from: date)
        vcTime.day = calendar.component(.day, from: date)
        vcTime.hour = calendar.component(.hour, from: date)
        vcTime.minute = calendar.component(.minute, from: date)
        
        return vcTime
    }
    
    func convertDateComponentsToDate (components: DateComponents) -> Date { return NSCalendar.current.date(from: components)! }
        
    func appointmentWindowIsOpen (theAppointment: VCAppointmentRecord) -> Bool {
        
        let apptDate = convertDateComponentsToDate(components: theAppointment.startDateComponents)
        let currentDate = Date()
        
        if apptDate > currentDate {
            
            let timeInterval = DateInterval(start: currentDate, end: apptDate)
            
            if timeInterval.duration <= 900 { return true }
            else { return false }
        }
        
        return true
    }
    
    func roundupTime(minutes: Int, withSegments: Int) -> Int {
        
        var valueToRound = minutes
        var segmentCounter = 1
        var segmentStart: Int?
        var segmentValue: Int = 0
        
        while segmentValue < 60 {
            
            segmentValue = withSegments * segmentCounter
            segmentStart = withSegments * (segmentCounter - 1)
            
            if valueToRound > segmentStart! && valueToRound < segmentValue { valueToRound = segmentValue }
            
            segmentCounter += 1
        }
       
        return valueToRound
    }
    
    func isValidApptTime (apptDate: Date, clinic: VCClinicRecord) -> Bool {
        
        let weekdays = ["Su","Mo","Tu","We","Th","Fr","Sa"]
        let apptComponents = Calendar.current.dateComponents([.day,.hour,.minute,.weekday], from: apptDate)
        
        guard clinic.clinicSchedule.contains(weekdays[apptComponents.weekday!-1]) else { return false }
        
        // Test for making appointments right on the open and close hours; must make sure the minutes fall within the schedule
        if apptComponents.hour! == clinic.startTimeComponents.hour! && apptComponents.minute! < clinic.startTimeComponents.minute! { return false }
        if apptComponents.hour! == clinic.endTimeComponents.hour! && apptComponents.minute! > clinic.endTimeComponents.minute! { return false }
        
        // It's not equal so test if early or late
        if apptComponents.hour! < clinic.startTimeComponents.hour! || apptComponents.hour! > clinic.endTimeComponents.hour! { return false }
     
        // It's a good appointment
        return true
    }
    
    func nextValidAppointment(clinic: VCClinicRecord) -> Date {
        
        var theApptDate = Date()
        var dateComponents = DateComponents()
        
        convertDateToDateComponents(date: Date(), components: &dateComponents)
        
        dateComponents.minute! = roundupTime(minutes: dateComponents.minute! + 30, withSegments: 4)
        theApptDate = convertDateComponentsToDate(components: dateComponents)
        
        while !isValidApptTime(apptDate: theApptDate, clinic: clinic) {
            
            convertDateToDateComponents(date: theApptDate, components: &dateComponents)
            
            dateComponents.minute! += 15
            theApptDate = convertDateComponentsToDate(components: dateComponents)
        }
        
        return theApptDate
        
    }
}
 
