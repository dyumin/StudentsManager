//
//  CurrentSessionModels.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation
import Firebase
import RxDataSources


enum CurrentSessionModelItemType: String
{
    case Event
    case AddNewTutor
    case Tutor
    case AddNewParticipant
    case Participant
}

extension CurrentSessionModelItemType: IdentifiableType
{
    var identity: String
    {
        return rawValue
    }
}

// https://medium.com/@stasost/ios-how-to-build-a-table-view-with-multiple-cell-types-2df91a206429
protocol CurrentSessionModelItem: IdentifiableType, Equatable
{
    var type: CurrentSessionModelItemType { get }
}

// https://stackoverflow.com/questions/33112559/protocol-doesnt-conform-to-itself
// https://medium.com/@thenewt15/equatable-pitfalls-in-ios-d250534bd7cc
// Because IdentifiableType has associated type inside, things get really,
// really messy, sorry for that
class CurrentSessionModelItemBox: NSObject, CurrentSessionModelItem
{
    // IdentifiableType
    var identity: String
    {
        assertionFailure("Please override")
        return UUID().uuidString
    }
    
    var type: CurrentSessionModelItemType
    {
        assertionFailure("Please override")
        return .Event
    }
}



class CurrentSessionModelEventItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .Event }
    override var identity: String { return item.documentID }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? CurrentSessionModelEventItem else {
            return false
        }
        
        // NOTE: seems to be always false on first call (because of lhs.metadata_ == rhs.metadata_ difference)
        let isEqual = self.item == other.item
        
        return isEqual
    }
    
    func isRelevantForSearchQuery(_ query: String?) -> Bool
    {
        guard let query = query else {
            return false
        }
        
        if let name = item.get(Session.name) as? String
        {
            let _name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let _query = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            return _name.contains(_query)
        }
        
        return false
    }
    
    let item: DocumentSnapshot
    
    init(item: DocumentSnapshot)
    {
        self.item = item
    }
}

class CurrentSessionModelTutorItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .Tutor }
    override var identity: String { return type.rawValue }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? CurrentSessionModelTutorItem else {
            return false
        }
        
        return self.host == other.host
    }
    
    func isRelevantForSearchQuery(_ query: String?) -> Bool
    {
        guard let query = query else {
            return false
        }
        
        if let name = host.get(ApiUser.displayName) as? String
        {
            let _name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let _query = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            return _name.contains(_query)
        }
        
        return false
    }
    
    var host: DocumentSnapshot
    
    init(_ host: DocumentSnapshot)
    {
        self.host = host
    }
}

class CurrentSessionModelAddNewTutorItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .AddNewTutor }
    override var identity: String { return type.rawValue }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? CurrentSessionModelAddNewTutorItem else {
            return false
        }
        
        return self.identity == other.identity
    }
}

class CurrentSessionModelParticipantItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .Participant }
    override var identity: String { return item.documentID }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? CurrentSessionModelParticipantItem else {
            return false
        }
        
        return self.item == other.item
    }
    
    func isRelevantForSearchQuery(_ query: String?) -> Bool
    {
        guard let query = query else {
            return false
        }
        
        if let name = item.get(ApiUser.displayName) as? String
        {
            let _name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let _query = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            return _name.contains(_query)
        }
        
        return false
    }
    
    let item: DocumentSnapshot
    
    init(_ item: DocumentSnapshot)
    {
        self.item = item
    }
}

class CurrentSessionModelAddNewParticipantItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .AddNewParticipant }
    override var identity: String { return type.rawValue }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? CurrentSessionModelAddNewParticipantItem else {
            return false
        }
        
        return self.identity == other.identity
    }
}


