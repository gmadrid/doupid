//
//  Image.swift
//  doupid
//
//  Created by George Madrid on 1/7/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation
import CoreData


class Image: NSManagedObject {

  func isObviouslyDifferentFromAttrs(attrs: [String:AnyObject]) -> Bool {
    let attrDict = attrs as NSDictionary
    return self.modDate != attrDict.fileModificationDate() ||
      self.size?.unsignedLongLongValue != attrDict.fileSize()
  }

  func setRequiredPathFields(path: String) {
    self.path = path
    self.filename = (path as NSString).lastPathComponent
  }

  func clearDynamicFields() {
    self.fileHaar = nil
    self.fileHash = nil
    self.haarDist = nil
    self.modDate = nil
    self.size = nil
  }

}
