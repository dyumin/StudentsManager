//
//  File.swift
//  StudentsManager-IOS
//
//  NOTE: CurrentSessionModel expects tableView variable to be set in order to function properly
//
//  Created by Дюмин Алексей on 19/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation
import UIKit

import RxSwift

import Firebase

class CurrentSessionModel: NSObject
{
    private var items = [CurrentSessionModelItem]()
    
    weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()
    
    deinit
    {
        pretty_function()
    }
    
    override init()
    {
        super.init()
        
//        Api.sharedApi.editingAllowed.asObservable().distinctUntilChanged().subscribe(
//        { [weak self] event in
//
//            self?.buildItems()
//
//            DispatchQueue.main.async
//            {
//                self?.tableView.reloadData()
//            }
//
//        }).disposed(by: disposeBag)
        
        Observable.combineLatest(
            Api.sharedApi.editingAllowed.asObservable().distinctUntilChanged(),
            Api.sharedApi.currentSessions.asObservable()).debug("currentSessions").subscribe(
            onNext: { [weak self] event in
            
                self?.buildItems(editingAllowed: event.0, currentSessions: event.1)
                
                DispatchQueue.main.async
                {
                    self?.tableView.reloadData()
                }
            
            }
        ).disposed(by: disposeBag)
    }
    
    func buildItems(editingAllowed: Bool, currentSessions: [DocumentSnapshot])
    {
        items.removeAll(keepingCapacity: true)
        
        if (currentSessions.isEmpty)
        {
            if editingAllowed
            {
                items.append(CurrentSessionModelNewEventItem(someNewEvent: "someNewEvent"))
            }
        }
        else
        {
            items.append(CurrentSessionModelEventItem(someEvent: "someEvent"))
            items.append(CurrentSessionModelTutorItem(someTutor: "someTutor"))
        }
        
//        if (Api.sharedApi.editingAllowed.value)
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
        case .NewEvent:
            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionNewEventCell.identifier, for: indexPath) as? CurrentSessionNewEventCell
            {
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
}

enum CurrentSessionModelItemType
{
    case Event
    case Tutor
    case Participants
    
    case NewEvent
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

class CurrentSessionModelNewEventItem: CurrentSessionModelItem
{
    var type: CurrentSessionModelItemType { return .NewEvent }
    
    var sectionTitle: String { return "New event" }
    
    var someNewEvent: String
    
    init(someNewEvent: String)
    {
        self.someNewEvent = someNewEvent
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
