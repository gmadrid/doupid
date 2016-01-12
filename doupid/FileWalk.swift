//
//  FileWalk.swift
//  itools
//
//  Created by George Madrid on 12/14/15.
//  Copyright © 2015 George Madrid. All rights reserved.
//

import CoreServices
import Foundation

private enum Errors : ErrorType {
  case BadPath(path: String)
  case MissingSize(path: String)
}

public struct FileInfo {
  let name: String
  let size: UInt64
}

public func GetFileInfoUnderPath(path: String) throws -> [FileInfo] {
  return try GetFilesUnderPath(path) { path, attrs in
    guard let fileSize = attrs[NSFileSize] as? NSNumber else {
      throw Errors.MissingSize(path: path)
    }
    return FileInfo(name: path, size: fileSize.unsignedLongLongValue)
  }
}

public func PathRefersToImageFile(path: String) -> Bool {
  let ext = (path as NSString).pathExtension
  guard !ext.isEmpty else {
    return false
  }

  let maybeUtis = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, ext, nil)
  guard let cfutis = maybeUtis else {
    return false
  }

  let utis = cfutis.takeRetainedValue() as [AnyObject]
  for uti in utis {
    guard let utiString = uti as? String else {
      continue
    }

    if UTTypeConformsTo(utiString, kUTTypeImage) {
      return true
    }
  }
  return false
}

public func GetFilesUnderPath<T>(path: String, recursive: Bool = true, _ cb: (String, [String : AnyObject]) throws -> T) throws -> [T] {
  var result = [T]()

  let mgr = NSFileManager.defaultManager()
  guard let e = mgr.enumeratorAtPath(path) else {
    throw Errors.BadPath(path: path)
  }

  while let fn = e.nextObject() {
    if fn.hasSuffix(".DS_Store") {
      continue
    }

    let attrs = e.fileAttributes!
    if !recursive && (attrs as NSDictionary).fileType() == NSFileTypeDirectory {
      e.skipDescendants()
      continue
    }
    if attrs[NSFileType] as! String != NSFileTypeRegular {
      continue
    }

    let components = [path, fn as! String]
    let fullname = NSString.pathWithComponents(components)
    result.append(try cb(fullname, attrs))
  }

  return result
}
