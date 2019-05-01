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
                // tableView.register(CurrentSessionEventCell.self, forCellReuseIdentifier: CurrentSessionEventCell.identifier) // Todo: why does this one not working?
                // https://stackoverflow.com/questions/540345/how-do-you-load-custom-uitableviewcells-from-xib-files
                // http://bdunagan.com/2009/06/28/custom-uitableviewcell-from-a-xib-in-interface-builder/
                
                partialUpdatesTableViewOutlet.register(UINib(nibName: CurrentSessionEventCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionEventCell.identifier)
                
                partialUpdatesTableViewOutlet.register(UINib(nibName: CurrentSessionTutorCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionTutorCell.identifier)
                
                partialUpdatesTableViewOutlet.register(UINib(nibName: CurrentSessionNewEventCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionNewEventCell.identifier)
                
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
    
    private var disposeBag: DisposeBag?
    
    private let sections: BehaviorRelay<[Section]> = BehaviorRelay(value: [])
    
    deinit
    {
        pretty_function()
    }

    enum Mode
    {
        case CurrentSession
        case History
    }

    init(_ mode: Mode)
    {
        self.mode = mode
        
        super.init()
    }
    
    private let mode: Mode
    
    var currentSession: DocumentReference?
    {
        didSet
        {
            disposeBag = nil
            
            if let currentSession = currentSession
            {
                let disposeBag = DisposeBag()
                
                currentSession.rx.listen().asObservable().debug("currentSession").subscribe(
                    onNext: { [weak self] event in
                        
                        self?.buildItems(for: event)
                        
                    }).disposed(by: disposeBag)
                
                self.disposeBag = disposeBag
            }
            else
            {
                buildItems(for: nil)
            }
        }
    }
    
    func buildItems(for currentSession: DocumentSnapshot?)
    {
        var _sections = Array<Section>()
        
        if let currentSession = currentSession, currentSession.exists
        {
            _sections.append(Section(model: .Event, items: [CurrentSessionModelEventItem(item: currentSession)]))
            
            if let host = currentSession.get(Session.host) as? DocumentReference
            {
                _sections.append(Section(model: .Tutor, items: [CurrentSessionModelTutorItem(host)]))
            }
        }
        
        sections.accept(_sections)
    }
}

enum CurrentSessionModelItemType: String
{
    case Event
    case Tutor
    case Participants
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
        
        // NOTE: seems to be always false on first call (because of lhs.metadata_ == rhs.metadata_ difference)
        let isEqual = self.item == other.item
        
        return isEqual
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
