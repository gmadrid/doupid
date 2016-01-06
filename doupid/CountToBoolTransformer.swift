//
//  CountToBoolTransformer.swift
//  doupid
//
//  Created by George Madrid on 1/6/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation


// Given an array, return true if the array is not empty.
// Return false otherwise.
// TODO: rename this.
class CountToBoolTransformer : NSValueTransformer {
  override class func transformedValueClass() -> AnyClass {
    return NSNumber.self
  }

  override class func allowsReverseTransformation() -> Bool {
    return false
  }

  override func transformedValue(value: AnyObject?) -> AnyObject? {
    if let v = value, arr = v as? NSArray {
      return NSNumber(bool: arr.count != 0)
    }
    return NSNumber(bool: false)
  }
}

