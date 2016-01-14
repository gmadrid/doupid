//
//  MultiDict.swift
//  duptool
//
//  Created by George Madrid on 1/1/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

struct MultiDict<Key : Hashable, Value> {
  var dict : [Key: [Value]]

  init() {
    dict = [Key : [Value]]()
  }

  // Return nil or the most recent value set for the key.
  // Assigning a value will add it to the end of the list.
  // Assigning nil will clear the list.
  subscript(index : Key) -> Value? {
    get {
      guard let val = dict[index] else {
        return nil
      }
      return val.last
    }

    set(newValue) {
      guard let newValue = newValue else {
        dict[index] = []
        return
      }

      // TODO: investigate making this faster by modifying in place.
      var arr : [Value] = dict[index] ?? []
      arr.append(newValue)
      dict[index] = arr
    }
  }

  // TODO: why is this call to map necessary?
  var values : [[Value]] {
    return dict.values.map { $0 }
  }

  // TODO: why can't I return just [Value] here?
  var uniqueValues : [[Value]] {
    return dict.values.filter { arr in
      arr.count == 1
    }
  }

  var nonUniqueValues : [[Value]] {
    // TODO: look into ways to make this lazy.
    return dict.values.filter { arr in
      return arr.count > 1
    }
  }
}
