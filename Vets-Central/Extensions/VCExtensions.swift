//
//  VCExtensions.swift
//  Vets-Central
//
//  Collections and Class Extensions
//  Created by Roger Vogel on 5/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

extension Array {
    
    mutating func removeIndices (indices: [Int]){
        
        var sortedIndices = indices.sorted()
        
        for i in 0..<sortedIndices.count {
            
            self.remove(at: sortedIndices[i])
            if i != sortedIndices.count - 1 { for r in (i + 1)..<sortedIndices.count { sortedIndices[r] -= 1 } }
        }
    }
}

extension Dictionary {
    
    // Allow the use of a subscript to access a particular dictionary item
    subscript(i: Int) -> (key: Key, value: Value) { return self[index(startIndex, offsetBy: i)] }
    
    var asPrettyJSON : String? {
        
        do {

            let incomingData = try JSONSerialization.data(withJSONObject: self as Any, options: JSONSerialization.WritingOptions.prettyPrinted)
            return (String(data: incomingData, encoding: .utf8)!)
         
        } catch { return nil }
    }
}

extension NSDictionary {
    
    var asPrettyJSON : String? {
        
        do {

            let incomingData = try JSONSerialization.data(withJSONObject: self as Any, options: JSONSerialization.WritingOptions.prettyPrinted)
            return (String(data: incomingData, encoding: .utf8)!)
         
        } catch { return nil }
    }
}

extension Data {
    
    var uiImage: UIImage? { UIImage(data: self) }
    
    var bytesAsArray: [UInt8] { return [UInt8](self) }
   
    var hexString: String {
        
        var hexString = ""
        let byteArray = bytesAsArray
        
        for b in byteArray { hexString += String(format: "%02x", b) }
    
        return hexString
    }
    
    var asPrettyJSON: String? {
        
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else { return nil }

        return prettyPrintedString
    }
}

extension String {
    
    // Validators
    var isBackspace: Bool {
        
        let char = self.cString(using: String.Encoding.utf8)!
        return strcmp(char, "\\b") == -92
    }
    
    var isValidEmail: Bool {
        
        guard self != "" else { return true }
        
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        
        return pred.evaluate(with: self)
    }
    
    var isValidURL: Bool {
    
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
    
            if match.range.length == self.utf16.count {  return true } else { return false }
            
        } else { return false }
    }
    
    var isValidUSPhone: Bool {
        
        guard !self.isEmpty else { return false }
        
        if ( self.evaluateFor(Format: [String](repeating: "#", count: 10)) ) { return true }
        if ( self.evaluateFor(Format: ["#","#","#","-","#","#","#","-","#","#","#","#"]) ) { return true }
        if ( self.evaluateFor(Format: ["(","#","#","#",")"," ","#","#","#","-","#","#","#","#"]) ) { return true }
        if ( self.evaluateFor(Format: ["+","#","#","#","#","#","#","#","#","#","#","#"]) ) { return true }
        if ( self.evaluateFor(Format: ["+","#","#","#","#","#","#","#","#","#","#","#","#"]) ) { return true }
        if ( self.evaluateFor(Format: ["+","#","-","#","#","#","-","#","#","#","-","#","#","#","#"]) ) { return true }
        if ( self.evaluateFor(Format: ["+","#","#","-","#","#","#","-","#","#","#","-","#","#","#","#"]) ) { return true }
        if ( self.evaluateFor(Format: ["+","#"," ","(","#","#","#",")"," ","#","#","#","-","#","#","#","#"]) ) { return true }
        if ( self.evaluateFor(Format: ["+","#","#","(","#","#","#",")"," ","#","#","#","-","#","#","#","#"]) ) { return true }
        
        return false
    }
    
    var isValidUSPostalCode: Bool {
        
        let codeBasicFormat = [String](repeating: "#", count: 5)
        let codeExtendedFormat = codeBasicFormat + ["-","#","#","#","#"]
        
        // Test 1: If the field is blank no more tests are required
        guard self.isEmpty else { return true }
        
        // Test 2: Does the postal code entered meet either of the allowed formats?
        if ( self.evaluateFor(Format: codeBasicFormat) == false && self.evaluateFor(Format: codeExtendedFormat) == false ) {return false}
        
        // Test 3: Check the first 5 digits for a valid postal code range
        let codeInt = self.asInteger(StartAtIndex: 0, NumberOfDigits: 5)
        if (codeInt.isInteger == true && (codeInt.intValue < 501 || codeInt.intValue > 99950)) {return false}
        
        // We passed all the tests
        return true
    }
    
    var isValidCAPostalCode: Bool {
        
        let codeFormat1 = [">","#",">","#",">","#"]
        let codeFormat2 = [">","#",">"," ","#",">","#"]
        
        // Test 1: If the field is blank no more tests are required
        guard !self.isEmpty else { return true }
        
        // Test 2: Does the postal code entered meet either of the allowed formats?
        if self.evaluateFor(Format: codeFormat1) == false && self.evaluateFor(Format: codeFormat2) == false {return false}
        
        // We passed all the tests
        return true
    }
    
    var isValidPassword: Bool {
        
        guard self != "" else { return true }
        
        let regEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[d$@$! %*?&#.])[A-Za-z\\dd$@!%* ?&#.]{12,}"
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        
        return pred.evaluate(with: self)
    }
    
    var username: (isValid: Bool, error: String?) {
        
        //let invalidCharacters: [String] = [" ",".","=","&","/","\\"]
        let nameLength : Int = self.count
        
        // Does it meet required length
        if nameLength < 5 { return (false, String(format: "Your username must be at least %d characters long", 5)) }
        
        // Does it have any unusable charactres
        //for c in 0...nameLength-1 {
            
            //let index = invalidCharacters.firstIndex(of: self[c])
            //if index != nil { return (false, "Your username can't contain a " + invalidCharacters[index!] + " character") }
        //}
            
        return (true,nil)
    }
    
    // Formatters
    var cleanedPhone: String {
        
        let noDash = self.replacingOccurrences(of: "-", with: "")
        let noLeftParens = noDash.replacingOccurrences(of: "(", with: "")
        let noRightParens = noLeftParens.replacingOccurrences(of: ")", with: "")
        let noSpace = noRightParens.replacingOccurrences(of: " ", with: "")
        let noPlus = noSpace.replacingOccurrences(of: "+", with: "")
        
        return noPlus
    }
    
    var asFormattedPhone: String {
        
        guard self != "" else { return "" }
        
        let cleanFormat = cleanedPhone
        var format: String?
        
        if cleanFormat.count == 11 {
            
            format = "+" + cleanFormat[0] + " (" + cleanFormat[1] + cleanFormat[2] + cleanFormat[3] + ") " + cleanFormat[4] + cleanFormat[5] + cleanFormat[6] + "-" + cleanFormat[7] +  cleanFormat[8] + cleanFormat[9] + cleanFormat[10]
            
        } else if cleanFormat.count == 12 {
    
            format = "+" + cleanFormat[0] + cleanFormat[1] + " (" + cleanFormat[2] + cleanFormat[3] + cleanFormat[4] + ") " + cleanFormat[5] + cleanFormat[6] + cleanFormat[7] + "-" + cleanFormat[8] +  cleanFormat[9] + cleanFormat[10] + cleanFormat[11]
            
        } else {
        
            format = "(" + cleanFormat[0] + cleanFormat[1] + cleanFormat[2] + ") " + cleanFormat[3] + cleanFormat[4] + cleanFormat[5] + "-" + cleanFormat[6] + cleanFormat[7] + cleanFormat[8] + cleanFormat[9]
        }
        
        return format!
        
    }
   
    // Tester
    func isEqualTo(_ test: String) -> Bool {
        
        guard test != "" else { return true }
        
        if (test != self) {return false}
        else {return true}
    }
    
    // Evaluate the string against a known format
    func evaluateFor( Format: [String] ) -> Bool {
        
        // First, the format count should match the string count
        guard Format.count == self.count else {return false}
        
        // Initialize a set with base 10 digits
        let digits: Set = ["0","1","2","3","4","5","6","7","8","9"]
        let capAlphas: Set = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
        let smallAlphas: Set = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
        
        // Sequence through the string comparing by character to the format string
        for c in 0...(self.count-1) {
            
            // If we're expecting a digit, check for that
            if Format[c] == "#"  {
                let evalChar: Set = [self[c]]
                if  !evalChar.isSubset(of: digits) {return false}
                else { continue }
            }
                
                // If we're expecting a small character
            else if Format[c] == "<"  {
                let evalChar: Set = [self[c]]
                if  !evalChar.isSubset(of: smallAlphas) {return false}
                else { continue }
            }
                
                // If we're expecting a cap character
            else if Format[c] == ">"  {
                let evalChar: Set = [self[c]]
                if  !evalChar.isSubset(of: capAlphas) {return false}
                else { continue }
            }
                
                // Otherwise check to see if it matches the format character
            else if ( self[c] != Format[c] ) {return false}
        }
        
        // Success if we reached this point...
        return true
    }
    
    func containsOnly(characters: [Character]) -> Bool {
        
        for c in self { if !characters.contains(c) { return false } }
        return true
    }
    
    // Evaluate the string of characters for all digits and if so, return its Int value
    func asInteger (StartAtIndex:Int? = nil, NumberOfDigits:Int? = nil) -> (isInteger: Bool, intValue: Int) {
        
        var intValue: Int = 0
        var isInteger: Bool = false
        var start: Int
        var numberOfDigits: Int
        var testString: String = ""
        
        // Grab the start index or set to zero
        if (StartAtIndex == nil) {start = 0}
        else {start = StartAtIndex!}
        
        // Grab the number of digits or set to full length
        if (NumberOfDigits == nil) {numberOfDigits = self.count}
        else {numberOfDigits = NumberOfDigits!}
        
        // Build a test string consisting of the substring in question
        for c in start ... (start+numberOfDigits-1) { testString = testString + self[c] }
        
        // Check if the test string is all digit characters and if so, calculate value
        let intFormat = [String](repeating: "#", count: testString.count)
        
        if ( testString.evaluateFor(Format:intFormat) ) {
            
            for c in 1...numberOfDigits {
                
                let p: Double = Double((c-1))
                let n: Double! = Double(self[start+numberOfDigits-c])
                
                intValue = intValue + (Int)( n! * pow(10.0,p) )
            }
            
            isInteger = true
        }
        
        return (isInteger, intValue)
    }
    
    // Convert from base64
    func fromBase64() -> String? {
       
        guard let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0)) else {
            return nil
        }
        
        return String(data: data as Data, encoding: String.Encoding.utf8)
    }
    
    // Convert to base64
    func toBase64() -> String? {
       
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        
        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
    
    // Return substring as String from offset
    func partial (fromIndex: Int, length: Int) -> String {
        
        let fullString: String = self
        var partialString: String = ""
        
        guard length <= fullString.count else { return "" }
        
        for i in fromIndex...(fromIndex + length - 1) { partialString += fullString[i] }
        
        return partialString
    }
    
    // Do simple math on a string
    func addAsInt(count: Int) -> String {
        
        var p = (self as NSString).intValue
        p += Int32(count)
        
        return String(format: "%d", p)
    }
    
    // Remove certain characters from a string
    func removeCharacters(charsToRemove: [String]) -> String {
        
        var newString: String = ""
        var charStart: Bool = true
        
        for c in charsToRemove {
            
            if charStart {newString = self.replacingOccurrences(of: c, with: ""); charStart = false }
            else { newString = newString.replacingOccurrences(of: c, with: "")}
        }
        
        return newString
    }
    
    // Remove a character from the string
    func removeChar(charToRemove: String) ->String {
        
        let fullString: String = self
        var adjustedString: String = ""
        
        guard fullString.count > 0 else { return "" }
        
        for i in 0...fullString.count - 1 { if fullString[i] != charToRemove {adjustedString += fullString[i] } }
        
        return adjustedString
    }
    
    func width(withFont: UIFont) -> CGFloat {
        
        let theString = NSString(string: self)
        return theString.size(withAttributes: [.font:withFont]).width
    
    }
    
    // Map the string to a specified format ("12345" => "xxx xx" => "123 45"
    func mapToFormat(format: String, padding: String? = "0") -> String {
        
        var formattedString: String = self
       
        // Map the string
        for i in 0...(format.count-1) {
            
            if format[i] != "x" {
                
                let index = formattedString.index(formattedString.startIndex,offsetBy: i)
                let character = Character(format[i])
                formattedString.insert(character, at: index)
            }
        }
            
        return formattedString
    }
    
    // Allow the use of a subscript to access a particular character
    subscript(i: Int) -> String {
        
        return String(self[index(startIndex, offsetBy: i)])
    }
}
 
extension UITextField{
    
    // Set the placeholder color for a text field
    @IBInspectable var placeholderColor: UIColor {
        get {
            return self.attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? .lightText
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: [.foregroundColor: newValue])
        }
    }
    
    // Fade in and out control
    func fade (toState: FadeTo, withAlpha: CGFloat, forDuration: Double ) {
        
        switch toState {
            
        case FadeTo.hidden:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in self.isHidden = true } )
            
        case FadeTo.dimmed:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in } )
            
        case FadeTo.visible:
            self.isEnabled = true
            self.isHidden = false
            UIView.animate( withDuration: forDuration, animations: { self.alpha = withAlpha}, completion: { finished in } )
        }
    }
}

extension UILabel {
    
    // Fade in and out control
    func fade (toState: FadeTo, withAlpha: CGFloat, forDuration: Double ) {
        
        switch toState {
            
        case FadeTo.hidden:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in self.isHidden = true } )
            
        case FadeTo.dimmed:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in } )
            
        case FadeTo.visible:
            self.isEnabled = true
            self.isHidden = false
            UIView.animate( withDuration: forDuration, animations: { self.alpha = withAlpha}, completion: { finished in } )
        }
    }
}

extension UIPageControl {
    
    // Fade in and out control
    func fade (toState: FadeTo, withAlpha: CGFloat, forDuration: Double ) {
        
        switch toState {
            
        case FadeTo.hidden:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in self.isHidden = true } )
            
        case FadeTo.dimmed:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in } )
            
        case FadeTo.visible:
            self.isEnabled = true
            self.isHidden = false
            UIView.animate( withDuration: forDuration, animations: { self.alpha = withAlpha}, completion: { finished in } )
        }
    }
}

extension UIScrollView {
    
    func scrollsToBottom(animated: Bool) {
        
        let bottomOffset = CGPoint(x: contentOffset.x, y: contentSize.height - bounds.height + adjustedContentInset.bottom)
        setContentOffset(bottomOffset, animated: animated)
    }
    
    func scrollsToTop(animated: Bool) {
        
        let topOffset = CGPoint(x: contentOffset.x, y: 0)
        setContentOffset(topOffset, animated: animated)
    }
    
    // Fade in and out control
    func fade (toState: FadeTo, withAlpha: CGFloat, forDuration: Double ) {
        
        switch toState {
            
        case FadeTo.hidden:
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in self.isHidden = true } )
            
        case FadeTo.dimmed:
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in } )
            
        case FadeTo.visible:
            self.isHidden = false
            UIView.animate( withDuration: forDuration, animations: { self.alpha = withAlpha}, completion: { finished in } )
        }
    }
}

extension UINavigationController {
    
    func addCustomBackButton(title: String = "Back") {
        
        let backButton = UIBarButtonItem()
        backButton.title = title
        navigationBar.topItem?.backBarButtonItem = backButton
    }
}

extension UIView {
    
    func changeDisplayState(toState: FadeTo, withAlpha: CGFloat? = 0.0, forDuration: Double, atCompletion: @escaping ()-> Void ) {
        
        switch toState {
            
        case FadeTo.hidden:
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = 0.0 }, completion: { finished in self.isHidden = true; atCompletion() } )
            
        case FadeTo.dimmed:
            if self is UIButton { (self as! UIButton).isEnabled = false }
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha! }, completion: { finished in atCompletion() } )
            
        case FadeTo.visible:
            self.isHidden = false
            if self is UIButton { (self as! UIButton).isEnabled = true }
            UIView.animate( withDuration: forDuration, animations: { self.alpha = 1.0}, completion: { finished in atCompletion() } )
        }
    }
    
    func slideIn (forDuration: Double, fromDirection: SlideIn? = .parentl, atCompletion: @escaping ()-> Void) {
        
        self.alpha = 1.0
        UIView.animate( withDuration: forDuration, animations: { self.frame.origin.x = 0 }, completion: { finished in atCompletion() } )
    }
    
    func slideOut (forDuration: Double, inDirection: SlideIn? = .parentl, atCompletion: @escaping ()-> Void) {
        
        if inDirection == .parentr { UIView.animate( withDuration: forDuration, animations: { self.frame.origin.x = self.frame.size.width }, completion: { finished in atCompletion() } ) }
        else { UIView.animate( withDuration: forDuration, animations: { self.frame.origin.x = -self.frame.size.width }, completion: { finished in atCompletion() } ) }
    }
    
    func roundCorners(corners: UIRectCorner, radius: Int = 5) {
        
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
                                     
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    
    func setCornerRadius(value: CGFloat) { self.layer.cornerRadius = value }
    
    func setBorder(width: CGFloat, color: CGColor? = nil) {
        
        self.layer.borderWidth = width
        if color != nil { self.layer.borderColor = color }
    }
}

extension UIImage {
    
    var jpeg: Data? { jpegData(compressionQuality: 1) }  // QUALITY min = 0 / max = 1
    var png: Data? { pngData() }
}

extension Date {
    
    static var currentTimeStamp: Int64{ return Int64(Date().timeIntervalSince1970 * 1000) }
   
}

extension UIResponder {
  
    func getParentViewController() -> UIViewController? {
        
        var nextResponder = self
        
        while let next = nextResponder.next {
            
            nextResponder = next
            if let viewController = nextResponder as? UIViewController { return viewController }
        }
        
        return nil
    }
}

extension UIDevice {
    
    var type: Model {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let modelCode = withUnsafePointer(to: &systemInfo.machine) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in String.init(validatingUTF8: ptr) } }
     
        let modelMap : [String: Model] = [
            
            "i386"      : .simulator,
            "x86_64"    : .simulator,
            
            "iPod1,1"   : .iPod1,
            "iPod2,1"   : .iPod2,
            "iPod3,1"   : .iPod3,
            "iPod4,1"   : .iPod4,
            "iPod5,1"   : .iPod5,
            
            "iPad2,1"   : .iPad2,
            "iPad2,2"   : .iPad2,
            "iPad2,3"   : .iPad2,
            "iPad2,4"   : .iPad2,
            "iPad3,1"   : .iPad3,
            "iPad3,2"   : .iPad3,
            "iPad3,3"   : .iPad3,
            "iPad3,4"   : .iPad4,
            "iPad3,5"   : .iPad4,
            "iPad3,6"   : .iPad4,
            "iPad6,11"  : .iPad5,
            "iPad6,12"  : .iPad5,
            "iPad7,5"   : .iPad6,
            "iPad7,6"   : .iPad6,
            "iPad7,11"  : .iPad7,
            "iPad7,12"  : .iPad7,
            
            "iPad2,5"   : .iPadMini,
            "iPad2,6"   : .iPadMini,
            "iPad2,7"   : .iPadMini,
            "iPad4,4"   : .iPadMini2,
            "iPad4,5"   : .iPadMini2,
            "iPad4,6"   : .iPadMini2,
            "iPad4,7"   : .iPadMini3,
            "iPad4,8"   : .iPadMini3,
            "iPad4,9"   : .iPadMini3,
            "iPad5,1"   : .iPadMini4,
            "iPad5,2"   : .iPadMini4,
            "iPad11,1"  : .iPadMini5,
            "iPad11,2"  : .iPadMini5,
            
            "iPad6,3"   : .iPadPro9_7,
            "iPad6,4"   : .iPadPro9_7,
            "iPad7,3"   : .iPadPro10_5,
            "iPad7,4"   : .iPadPro10_5,
            "iPad6,7"   : .iPadPro12_9,
            "iPad6,8"   : .iPadPro12_9,
            "iPad7,1"   : .iPadPro2_12_9,
            "iPad7,2"   : .iPadPro2_12_9,
            "iPad8,1"   : .iPadPro11,
            "iPad8,2"   : .iPadPro11,
            "iPad8,3"   : .iPadPro11,
            "iPad8,4"   : .iPadPro11,
            "iPad8,5"   : .iPadPro3_12_9,
            "iPad8,6"   : .iPadPro3_12_9,
            "iPad8,7"   : .iPadPro3_12_9,
            "iPad8,8"   : .iPadPro3_12_9,
            
            "iPad4,1"   : .iPadAir,
            "iPad4,2"   : .iPadAir,
            "iPad4,3"   : .iPadAir,
            "iPad5,3"   : .iPadAir2,
            "iPad5,4"   : .iPadAir2,
            "iPad11,3"  : .iPadAir3,
            "iPad11,4"  : .iPadAir3,
            
            "iPhone3,1" : .iPhone4,
            "iPhone3,2" : .iPhone4,
            "iPhone3,3" : .iPhone4,
            "iPhone4,1" : .iPhone4S,
            "iPhone5,1" : .iPhone5,
            "iPhone5,2" : .iPhone5,
            "iPhone5,3" : .iPhone5C,
            "iPhone5,4" : .iPhone5C,
            "iPhone6,1" : .iPhone5S,
            "iPhone6,2" : .iPhone5S,
            "iPhone7,1" : .iPhone6Plus,
            "iPhone7,2" : .iPhone6,
            "iPhone8,1" : .iPhone6S,
            "iPhone8,2" : .iPhone6SPlus,
            "iPhone8,4" : .iPhoneSE,
            "iPhone9,1" : .iPhone7,
            "iPhone9,3" : .iPhone7,
            "iPhone9,2" : .iPhone7Plus,
            "iPhone9,4" : .iPhone7Plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,4" : .iPhone8,
            "iPhone10,2" : .iPhone8Plus,
            "iPhone10,5" : .iPhone8Plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSMax,
            "iPhone11,6" : .iPhoneXSMax,
            "iPhone11,8" : .iPhoneXR,
            "iPhone12,1" : .iPhone11,
            "iPhone12,3" : .iPhone11Pro,
            "iPhone12,5" : .iPhone11ProMax,
            "iPhone12,8" : .iPhoneSE2,
            "iPhone13,1" : .iPhone12Mini,
            "iPhone13,2" : .iPhone12,
            "iPhone13,3" : .iPhone12Pro,
            "iPhone13,4" : .iPhone12ProMax,
            
            "AppleTV5,3" : .AppleTV,
            "AppleTV6,2" : .AppleTV_4K
        ]
        
        if let model = modelMap[String.init(validatingUTF8: modelCode!)!] {
            
            if model == .simulator {
                
                if let simModelCode = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                    
                    if let simModel = modelMap[String.init(validatingUTF8: simModelCode)!] {
                        
                        return simModel
                    }
                }
            }
            
            return model
        }
        
        return Model.unrecognized
    }
}

