//
//  SessionPhotosModels.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

import Firebase

import RxDataSources

enum SessionPhotosModelItemType: String
{
    case Photo
    case AddNewPhoto
}

extension SessionPhotosModelItemType: IdentifiableType
{
    var identity: String
    {
        return rawValue
    }
}

protocol SessionPhotosModelItem: IdentifiableType, Equatable
{
    var type: SessionPhotosModelItemType { get }
}

class SessionPhotosModelItemBox: NSObject, SessionPhotosModelItem
{
    // IdentifiableType
    var identity: String
    {
        assertionFailure("Please override")
        return UUID().uuidString
    }
    
    var type: SessionPhotosModelItemType
    {
        assertionFailure("Please override")
        return .AddNewPhoto
    }
}

class SessionPhotosModelPhotoItem: SessionPhotosModelItemBox
{
    override var type: SessionPhotosModelItemType { return .Photo }
    override var identity: String { return "d" }//item.documentID }
    
//    override func isEqual(_ object: Any?) -> Bool
//    {
//        guard let other = object as? SessionPhotosModelPhotoItem else {
//            return false
//        }
//
//        return self.item == other.item
//    }
//
//    let item: DocumentSnapshot
//
//    init(_ item: DocumentSnapshot)
//    {
//        self.item = item
//    }
}

class SessionPhotosModelAddNewPhotoItem: SessionPhotosModelItemBox
{
    override var type: SessionPhotosModelItemType { return .AddNewPhoto }
    override var identity: String { return type.rawValue }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? SessionPhotosModelAddNewPhotoItem else {
            return false
        }
        
        return self.identity == other.identity
    }
}
