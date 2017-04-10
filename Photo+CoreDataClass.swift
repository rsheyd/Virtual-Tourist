//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Roman Sheydvasser on 4/10/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    convenience init(imageData: NSData, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.imageData = imageData
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
