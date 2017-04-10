//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Roman Sheydvasser on 4/10/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
