//
//  PRStringExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension String {
    
    // MARK: COMPUTED PROPERTIES
    
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
    
    var cleanedURL: String {
    
        var cleanString = self.removePhrase(phraseToRemove: "www.")
        if cleanString.partial(fromIndex: 0, length: 8) != "https://" { cleanString = "https://" + cleanString }
        
        return cleanString
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
    
    var cleanedPhone: String {
        
        let noDash = self.replacingOccurrences(of: "-", with: "")
        let noLeftParens = noDash.replacingOccurrences(of: "(", with: "")
        let noRightParens = noLeftParens.replacingOccurrences(of: ")", with: "")
        let noSpace = noRightParens.replacingOccurrences(of: " ", with: "")
        let noPlus = noSpace.replacingOccurrences(of: "+", with: "")
        
        return noPlus
    }
    
    var fromBase64: String? {
       
        guard let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0)) else {
            return nil
        }
        
        return String(data: data as Data, encoding: String.Encoding.utf8)
    }
    
    var toBase64: String? {
       
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        
        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
   
    // MARK: METHODS
    
    func isEqualTo(_ test: String) -> Bool {
        
        guard test != "" else { return true }
        
        if (test != self) {return false}
        else {return true}
    }
    
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
                let n: Double = Double(self[start+numberOfDigits-c])!
                
                intValue = intValue + (Int)( n * pow(10.0,p) )
            }
            
            isInteger = true
        }
        
        return (isInteger, intValue)
    }
    
    func partial (fromIndex: Int, length: Int) -> String {
        
        let fullString: String = self
        var partialString: String = ""
        
        guard length <= fullString.count && fromIndex <= (fullString.count - length) else { return "" }
        
        for i in fromIndex...(fromIndex + length - 1) { partialString += fullString[i] }
        
        return partialString
    }
    
    func addAsInt(count: Int) -> String {
        
        var p = (self as NSString).intValue
        p += Int32(count)
        
        return String(format: "%d", p)
    }
    
    func removeChar(charToRemove: String) -> String {
        
        let fullString: String = self
        var adjustedString: String = ""
        
        guard fullString.count > 0 else { return "" }
        
        for i in 0...fullString.count - 1 { if fullString[i] != charToRemove {adjustedString += fullString[i] } }
        
        return adjustedString
    }
    
    func removeCharacters(charsToRemove: [String]) -> String {
        
        var newString: String = ""
        var charStart: Bool = true
        
        for c in charsToRemove {
            
            if charStart {newString = self.replacingOccurrences(of: c, with: ""); charStart = false }
            else { newString = newString.replacingOccurrences(of: c, with: "")}
        }
        
        return newString
    }
    
    func removePhrase(phraseToRemove: String) -> String {
        
        guard phraseToRemove.count < self.count else { return self }
     
        var index: Int = 0
        var cleanedString: String = ""
        var operationComplete: Bool = false
        let phraseLength = phraseToRemove.count
        let cutoff = self.count - phraseLength
        
        while !operationComplete {
            
            if index > cutoff {
                
                if index != self.count - 1 {
                  
                    let tail = self.partial(fromIndex: index, length: self.count - index)
                    cleanedString += tail
                }
                
                operationComplete = true
                
            } else {
        
                let sourcePhrase = self.partial(fromIndex: index, length: phraseLength)
              
                if sourcePhrase == phraseToRemove { index += phraseLength }
                else { cleanedString += self[index]; index += 1 }
            }
        }
   
        return cleanedString
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
    
    // MARK: SUBSCRIPTING
    
    subscript(i: Int) -> String {
        
        return String(self[index(startIndex, offsetBy: i)])
    }
}
