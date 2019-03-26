//
//  File.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 19/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation
import UIKit

class CurrentSessionModel: NSObject
{
    var items = [CurrentSessionModelItem]()
    
    override init()
    {
        items.append(CurrentSessionModelEventItem(someEvent: "def init 666"))
        items.append(CurrentSessionModelTutorItem(someTutor: "tutor init 666"))
    }
}

extension CurrentSessionModel: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return items.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return items[section].rowCount
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        // we will configure the cells here
        let item = items[indexPath.section]
        
        switch item.type
        {
        case .Event:
            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionEventCell.identifier, for: indexPath) as? CurrentSessionEventCell
            {
                cell.item = item
                return cell
            }
        
            
        case .Tutor:
            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionTutorCell.identifier, for: indexPath) as? CurrentSessionTutorCell
            {
//                cell.item = item
                return cell
            }
        case .Participants:
            return UITableViewCell()
        }
        
        return UITableViewCell()
    }
}

enum CurrentSessionModelItemType
{
    case Event
    case Tutor
    case Participants
}

protocol CurrentSessionModelItem
{
    var type: CurrentSessionModelItemType { get }
    var rowCount: Int { get }
    var sectionTitle: String { get }
}

extension CurrentSessionModelItem
{
    var rowCount: Int
    {
        return 1
    }
}

class CurrentSessionModelEventItem: CurrentSessionModelItem
{
    var type: CurrentSessionModelItemType { return .Event }
    var sectionTitle: String { return "Event info" }
    
    var someEvent: String
    
    init(someEvent: String)
    {
        self.someEvent = someEvent
    }
}

class CurrentSessionModelTutorItem: CurrentSessionModelItem
{
    var type: CurrentSessionModelItemType { return .Tutor }
    var sectionTitle: String { return "Tutor info" }
    
    var someTutor: String
    
    init(someTutor: String)
    {
        self.someTutor = someTutor
    }
}

class CurrentSessionModelParticipantsItem: CurrentSessionModelItem
{
    var type: CurrentSessionModelItemType { return .Participants }
    var sectionTitle: String { return "Participants info" }
    
    var someParticipants: String
    
    init(someParticipants: String)
    {
        self.someParticipants = someParticipants
    }
}
