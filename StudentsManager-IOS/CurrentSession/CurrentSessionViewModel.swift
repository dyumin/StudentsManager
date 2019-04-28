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
                            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionEventCell.identifier, for: indexPath) as? CurrentSessionEventCell
                            {
                                cell.item = nil
                                return cell
                            }
                        
                        
                        case .Tutor:
                            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionTutorCell.identifier, for: indexPath) as? CurrentSessionTutorCell
                            {
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
                
                sections.asObservable().debug("sections_to_table").bind(to: partialUpdatesTableViewOutlet.rx.items(dataSource: dataSource)).disposed(by: dataSourceDisposeBag)
                
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
            Api.sharedApi.currentSessions.asObservable()).debounce(0.5, scheduler: MainScheduler.instance).debug("editingAllowed && currentSessions").subscribe(
            onNext: { [weak self] event in

                self?.buildItems(editingAllowed: event.0, currentSessions: event.1)

            }
        ).disposed(by: disposeBag)
    }
    
    func buildItems(editingAllowed: Bool, currentSessions: [DocumentSnapshot])
    {
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
            sections.accept([
                Section(model: .Event, items: [CurrentSessionModelEventItem(someEvent: "someEvent")]),
                Section(model: .Tutor, items: [CurrentSessionModelTutorItem(someTutor: "someTutor")])
                ])
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
        
        return self.identity == other.identity
    }
    
    var someEvent: String
    
    init(someEvent: String)
    {
        self.someEvent = someEvent
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
        
        return self.identity == other.identity
    }
    
    var sectionTitle: String { return "Tutor info" }
    
    var someTutor: String
    
    init(someTutor: String)
    {
        self.someTutor = someTutor
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
