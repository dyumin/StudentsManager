//
//  File.swift
//  StudentsManager-IOS
//
//  NOTE: CurrentSessionModel expects partialUpdatesTableViewOutlet variable to be set in order to function properly
//
//  Created by Дюмин Алексей on 19/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa

import Firebase

import RxDataSources

class CurrentSessionModel: NSObject
{
    weak var partialUpdatesTableViewOutlet: UITableView!
    {
        didSet
        {
            self.dataSourceDisposeBag = nil
            
            if let partialUpdatesTableViewOutlet = partialUpdatesTableViewOutlet
            {
                let dataSourceDisposeBag = DisposeBag()
                
                let configureCell: TableViewSectionedDataSource<Section>.ConfigureCell =
                { dataSource, tableView, indexPath, item in
                    
                    switch item.type
                    {
                        case .Event:
                            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionEventCell.identifier, for: indexPath) as? CurrentSessionEventCell, let item = item as? CurrentSessionModelEventItem
                            {
                                cell.item = item.item
                                return cell
                            }
                            break
                        case .Tutor:
                            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionTutorCell.identifier, for: indexPath) as? CurrentSessionTutorCell, let item = item as? CurrentSessionModelTutorItem
                            {
                                cell.item = item.host
                                return cell
                            }
                            break
                        case .Participants:
                            return UITableViewCell()
                            break
                        case .NewEvent:
                            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionNewEventCell.identifier, for: indexPath) as? CurrentSessionNewEventCell
                            {
                                return cell
                            }
                            break
                    }
                    
                    return UITableViewCell()
                }
                
                let titleForSection : TableViewSectionedDataSource<Section>.TitleForHeaderInSection =
                { (ds, section) -> String? in
                    
//                    if ds[section].model == .Tutor
//                    {
//                        return nil
//                    }
                    
                    return ds[section].model.rawValue
                }
                
                let dataSource = RxTableViewSectionedAnimatedDataSource<Section>(configureCell:configureCell,
                                                                                 titleForHeaderInSection: titleForSection)
                
                #if DEBUG
                let animationConfiguration = AnimationConfiguration(insertAnimation: .right,
                                                                    reloadAnimation: .middle,
                                                                    deleteAnimation: .left)
                #else
                let animationConfiguration = AnimationConfiguration(insertAnimation: .fade,
                                                                    reloadAnimation: .none,
                                                                    deleteAnimation: .fade)
                #endif
                
                dataSource.animationConfiguration = animationConfiguration
                
                sections.asObservable().debug("sections_to_table").bind(to: partialUpdatesTableViewOutlet.rx.items(dataSource: dataSource)).disposed(by: dataSourceDisposeBag)
                
                // well, maybe it not the best solution, will see
//                partialUpdatesTableViewOutlet.rx.didEndDisplayingCell
//                    .asObservable().debug("didEndDisplayingCell").subscribe(
//                        onNext: { event in
//
//                            let selector = Selector("dispose")
//                            
//                            if event.cell.responds(to: selector)
//                            {
//                                event.cell.perform(selector)
//                            }
//
//                        }).disposed(by: dataSourceDisposeBag)
                
                self.dataSourceDisposeBag = dataSourceDisposeBag
            }
        }
    }
    
    private var dataSourceDisposeBag: DisposeBag?
    
    private var disposeBag = DisposeBag()
    
    private let sections: BehaviorRelay<[Section]> = BehaviorRelay(value: [])
    
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
            Api.sharedApi.currentSessions.asObservable(),
            Api.sharedApi.user.asObservable()).debug("editingAllowed && currentSessions").subscribe(
        onNext: { [weak self] event in

            assert(event.1.count < 2, "Multiple active session not yet supported")
            
            self?.buildItems(event)

        }
        ).disposed(by: disposeBag)
    }
    
    func buildItems(_ event: (Bool, [DocumentSnapshot], DocumentSnapshot?))
    {
        let editingAllowed = event.0
        let currentSessions = event.1
        
        if (currentSessions.isEmpty)
        {
            if editingAllowed
            {
                sections.accept([
                    Section(model: .NewEvent, items: [CurrentSessionModelNewEventItem(someNewEvent: "666 new 666")])
                    ])
            }
        }
        else
        {
            var _sections = Array<Section>()
            
            if let event = currentSessions.first
            {
                _sections.append(Section(model: .Event, items: [CurrentSessionModelEventItem(item: event)]))
                
                if let host = event.get(Session.host) as? DocumentReference
                {
                    _sections.append(Section(model: .Tutor, items: [CurrentSessionModelTutorItem(host)]))
                }
            }
            
            sections.accept(_sections)
        }

//        if (Api.sharedApi.editingAllowed.value)
    }
}

enum CurrentSessionModelItemType: String
{
    case Event
    case Tutor
    case Participants
    
    case NewEvent
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
        return .NewEvent
    }
}

typealias Section = AnimatableSectionModel<CurrentSessionModelItemType, CurrentSessionModelItemBox>

class CurrentSessionModelEventItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .Event }
    override var identity: String { return type.rawValue }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? CurrentSessionModelEventItem else {
            return false
        }
        
        // NOTE: always false on first call (because of lhs.metadata_ == rhs.metadata_ difference)
        let isEqual = self.item == other.item
        
        return isEqual
    }
    
    let item: DocumentSnapshot
    
    init(item: DocumentSnapshot)
    {
        self.item = item
    }
}

class CurrentSessionModelNewEventItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .NewEvent }
    override var identity: String { return type.rawValue }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        pretty_function()
        
        guard let other = object as? CurrentSessionModelNewEventItem else {
            return false
        }
        
        return self.identity == other.identity
    }
    
    var someNewEvent: String
    
    init(someNewEvent: String)
    {
        self.someNewEvent = someNewEvent
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
    
    var host: DocumentReference
    
    init(_ host: DocumentReference)
    {
        self.host = host
    }
}

class CurrentSessionModelParticipantsItem: CurrentSessionModelItemBox
{
    override var type: CurrentSessionModelItemType { return .Participants }
    var sectionTitle: String { return "Participants info" }

    var someParticipants: String

    init(someParticipants: String)
    {
        self.someParticipants = someParticipants
    }
}
