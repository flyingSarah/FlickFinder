//
//  LatLonTextDelegate.swift
//  Flick Finder
//
//  Created by Sarah Howe on 8/27/15.
//  Copyright (c) 2015 SarahHowe. All rights reserved.
//

import Foundation
import UIKit

class LatLonTextDelegate: NSObject, UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    {
        var isNumeric: Bool = false
        var isBackspace: Bool = false
        
        //find out if the text field is a number
        let inverseSet = NSCharacterSet(charactersInString: "01234567890-.").invertedSet
        let components = string.componentsSeparatedByCharactersInSet(inverseSet)
        let filtered = join("", components)
        
        isNumeric = (string == filtered)
        
        //find out if the latest character was a backspace
        let scalars = string.unicodeScalars
        
        if(scalars[scalars.startIndex].value == 65533)
        {
            isBackspace = true
        }
        
        //limit text to numbers, periods, and dashes only -- allow backspaces
        if(isNumeric || isBackspace)
        {
            return true
        }
        return false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        let viewController = textField.superview
        
        viewController?.endEditing(true)
        
        return true
    }
}
