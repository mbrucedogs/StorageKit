//
//  StorageType.swift
//  Example
//
//  Created by Bruce, Matt R on 10/30/18.
//  Copyright © 2018 MarcoSantaDev. All rights reserved.
//

import Foundation
import StorageKit
import StorageKitRealm
import StorageKitCoreData

public enum StorageType: Storagable {
    /**
     CoreData storage. It has as associated value the data model name.
     Example:
     
     ```
     .CoreData("myDataModel")
     ```
     */
    case CoreData(dataModelName: String)
    
    /**
     Realm storage type
     */
    case Realm
    
    
    public var storage: Storage {
        switch self {
        case .CoreData(let dataModelName):
            var configuration = CoreDataConfiguration()
            configuration.dataModelName = dataModelName
            return CoreDataStorage(configuration: configuration)
        case .Realm:
            return RealmDataStorage()
        }
    }
}
