//
//  VCEnumerations.swift
//  Vets-Central
//
//  Enumerations
//  Created by Roger Vogel on 7/11/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
// 

import Foundation

enum ApptFields: Int { case nofield, patient, clinic, doctor, type, date, time, reason }
enum AlertMessageButtons: Int { case first, second }
enum ApptSegment: Int { case closedDate, beforeOpen, afterClose }
enum ApptTimeFrame: Int { case current, past }
enum CallFromView: String { case appointment, consultation }
enum ClinicLocale: Int { case location, home }
enum ClockMode: Int { case c12, c24}
enum Corners { case topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom, all }
enum DateString: Int { case date, dayAndDate, dayDateAndTime }
enum DeviceModel : String {

    case simulator     = "simulator",

    iPod1              = "iPod 1",
    iPod2              = "iPod 2",
    iPod3              = "iPod 3",
    iPod4              = "iPod 4",
    iPod5              = "iPod 5",

    iPad2              = "iPad 2",
    iPad3              = "iPad 3",
    iPad4              = "iPad 4",
    iPadAir            = "iPad Air ",
    iPadAir2           = "iPad Air 2",
    iPadAir3           = "iPad Air 3",
    iPad5              = "iPad 5",
    iPad6              = "iPad 6",
    iPad7              = "iPad 7",

    iPadMini           = "iPad Mini",
    iPadMini2          = "iPad Mini 2",
    iPadMini3          = "iPad Mini 3",
    iPadMini4          = "iPad Mini 4",
    iPadMini5          = "iPad Mini 5",

    iPadPro9_7         = "iPad Pro 9.7\"",
    iPadPro10_5        = "iPad Pro 10.5\"",
    iPadPro11          = "iPad Pro 11\"",
    iPadPro12_9        = "iPad Pro 12.9\"",
    iPadPro2_12_9      = "iPad Pro 2 12.9\"",
    iPadPro3_12_9      = "iPad Pro 3 12.9\"",

    iPhone4            = "iPhone 4",
    iPhone4S           = "iPhone 4S",
    iPhone5            = "iPhone 5",
    iPhone5S           = "iPhone 5S",
    iPhone5C           = "iPhone 5C",
    iPhone6            = "iPhone 6",
    iPhone6Plus        = "iPhone 6 Plus",
    iPhone6S           = "iPhone 6S",
    iPhone6SPlus       = "iPhone 6S Plus",
    iPhone7            = "iPhone 7",
    iPhone7Plus        = "iPhone 7 Plus",
    iPhoneSE           = "iPhone SE",
    iPhone8            = "iPhone 8", //37
    iPhone8Plus        = "iPhone 8 Plus",
    iPhoneX            = "iPhone X",
    iPhoneXS           = "iPhone XS",
    iPhoneXSMax        = "iPhone XS Max",
    iPhoneXR           = "iPhone XR",
    iPhone11           = "iPhone 11",
    iPhone11Pro        = "iPhone 11 Pro",
    iPhone11ProMax     = "iPhone 11 Pro Max",
    iPhoneSE2          = "iPhone SE2",
    iPhone12           = "iPhone 12",
    iPhone12Pro        = "iPhone 12 Pro",
    iPhone12ProMax     = "iPhone 12 Pro Max",
    iPhone12Mini       = "iPhone 12 Mini",
    iPhone13           = "iPhone 13",
    iPhone13Pro        = "iPhone 13 Pro",
    iPhone13ProMax     = "iPhone 13 Pro Max",
    
    AppleTV            = "Apple TV",
    AppleTV_4K         = "Apple TV 4K",
    unrecognized       = "?unrecognized?"
}
enum DocumentSource: Int { case download, upload }
enum DocumentRequester: Int { case pet, appointment, linked }
enum FadeTo: Int { case visible, hidden, dimmed }
enum LoginAction: Int {case create, login }
enum LoginState: Int { case bootUp, awaitingLogin, loggedIn, loggedOut }
enum MenuState: Int { case open, closed }
enum PickerProtocol: Int { case load, components, rows, titles, selected }
enum PickerType: Int { case country, state }
enum SlideIn: Int { case disabled, parentr, parentl, childr, childl}
enum SortType: Int { case ascending, descending }
enum UploadProgress : String { case cancelled, inprogress, complete, failed }




