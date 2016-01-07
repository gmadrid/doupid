//
//  Image+CoreDataProperties.swift
//  doupid
//
//  Created by George Madrid on 1/7/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Image {

    @NSManaged var fileHaar: NSData?
    @NSManaged var fileHash: NSData?
    @NSManaged var filename: String?
    @NSManaged var haarDist: Double
    @NSManaged var path: String?
    @NSManaged var size: Int64

}
