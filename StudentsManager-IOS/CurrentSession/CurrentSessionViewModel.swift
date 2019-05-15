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

import PINCache


// MARK: - UITableViewDataSourcePrefetching
extension CurrentSessionModel: UITableViewDataSourcePrefetching
{
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath])
    {
        guard let dataSource = self.dataSource else { return }
        
        let _cachedValues = dataSource.sectionModels
        let api = Api.sharedApi

        for indexPath in indexPaths
        {
            let item = _cachedValues[indexPath.section].items[indexPath.item]

            if item.type == .Participant, let item = item as? CurrentSessionModelParticipantItem
            {
                api.prefetchUserProfilePhoto(for: item.item.documentID)
            }
        }
    }
}

extension CurrentSessionModel
{
    func getCurrentSessionSnapshot() -> DocumentSnapshot?
    {
        return currentSessionSnapshot.value
    }
}

class CurrentSessionModel: NSObject, UITableViewDelegate
{
    private typealias DataSource = RxTableViewSectionedAnimatedDataSourceDynamicWrapper<Section>
    
    private typealias DataSourceInternalType = TableViewSectionedDataSource<Section>
    
    private typealias Section = AnimatableSectionModel<CurrentSessionModelItemType, CurrentSessionModelItemBox>
    
    private weak var dataSource: DataSource?
    
    private static let DefaulfCellReuseIdentifier = "Cell"
    
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
                
                partialUpdatesTableViewOutlet.register(UINib(nibName: CurrentSessionParticipantCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionParticipantCell.identifier)
                
                partialUpdatesTableViewOutlet.register(UITableViewCell.self, forCellReuseIdentifier: CurrentSessionModel.DefaulfCellReuseIdentifier)
                
                partialUpdatesTableViewOutlet.allowsMultipleSelectionDuringEditing = true
                
                let dataSourceDisposeBag = DisposeBag()
                
                let configureCell: DataSourceInternalType.ConfigureCell =
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
                        case .Participant:
                            if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionParticipantCell.identifier, for: indexPath) as? CurrentSessionParticipantCell, let item = item as? CurrentSessionModelParticipantItem
                            {
                                cell.item = item.item
                                return cell
                            }
                        break
                        case .AddNewParticipant:
                            let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionModel.DefaulfCellReuseIdentifier, for: indexPath)
                            
                            cell.textLabel?.text = "Add new Participant"
                            cell.accessoryType = .disclosureIndicator
                            
                            return cell
                    }
                    
                    assertionFailure()
                    return UITableViewCell()
                }
                
                let titleForSection : DataSourceInternalType.TitleForHeaderInSection =
                { [weak self] (ds, section) -> String? in
                    
                    let shouldAdjustTitleToIncludeAddNewButton = Api.sharedApi.editingAllowed.value && self?.searchQuery == nil
                    
                    switch ds[section].model
                    {
                    case .Participant:
                        return shouldAdjustTitleToIncludeAddNewButton ? nil : "Participants"
                    case .AddNewParticipant:
                        return shouldAdjustTitleToIncludeAddNewButton ? "Participants" : nil
                    case .Event:
                        return nil
                    case .Tutor:
                        return ds[section].model.rawValue
                    }
                }
                
                let dataSource = DataSource(configureCell:configureCell,
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
                
                let canEditRowAtIndexPath: DataSourceInternalType.CanEditRowAtIndexPath =
                { [weak self] (ds, ip) in
                    
                    guard let item = self?.dataSource?[ip] else
                    {
                        return false
                    }
                    
                    if !Api.sharedApi.editingAllowed.value
                    {
                        return false
                    }
                    
                    switch item.type
                    {
                    case .Participant, .Tutor:
                        return true
                    default:
                        return false
                    }
                    
                }
                let canMoveRowAtIndexPath: DataSourceInternalType.CanMoveRowAtIndexPath =
                { [weak self] (ds, ip) in
                    
                    guard let item = self?.dataSource?[ip] else
                    {
                        return false
                    }
                    
                    switch item.type
                    {
                    case .Participant:
                        return true
                    default:
                        return false
                    }
                }
                
                let didMoveRowAtSourceIndexPathToDestinationIndexPath: DataSource.DidMoveRowAtSourceIndexPathToDestinationIndexPath =
                { [weak self] (ds, sIp, dIp) in
                    
                    if !(ds[sIp].type == .Participant && ds[dIp].type == .Participant)
                    {
                        assertionFailure("Not implemented (You can reorder only inside Participants section)")
                        return
                    }
                    
                    guard let currentSession = self?.currentSession else { return }
                    
                    guard let participantsModel = ds.sectionModels.first(where:
                    { model -> Bool in
                        model.model == .Participant
                    }) else { return }
                    
                    let participantsWithOrderFromTableView = participantsModel.items.map(
                    { (currentSessionModelItemBox) -> DocumentReference in
                        let participantItem = currentSessionModelItemBox as! CurrentSessionModelParticipantItem
                        return participantItem.item.reference
                    })
                    
                    currentSession.updateData([Session.participants : participantsWithOrderFromTableView])
                }
                
                dataSource.canEditRowAtIndexPath = canEditRowAtIndexPath
                dataSource.canMoveRowAtIndexPath = canMoveRowAtIndexPath
                dataSource.didMoveRowAtSourceIndexPathToDestinationIndexPath = didMoveRowAtSourceIndexPathToDestinationIndexPath

                self.partialUpdatesTableViewOutlet.rx.setDelegate(self).disposed(by: dataSourceDisposeBag)
                
                if #available(iOS 10.0, *)
                {
                    self.partialUpdatesTableViewOutlet.rx.setPrefetchDataSource(self).disposed(by: dataSourceDisposeBag)
                }
                
                sections.asObservable()/*.debug("sections_to_table")*/.bind(to: partialUpdatesTableViewOutlet.rx.items(dataSource: dataSource)).disposed(by: dataSourceDisposeBag)
                
                self.dataSource = dataSource
                
                self.dataSourceDisposeBag = dataSourceDisposeBag
            }
        }
    }
    
    private var dataSourceDisposeBag: DisposeBag?
    
    private var disposeBag: DisposeBag?
    
    private let sections: BehaviorRelay<[Section]> = BehaviorRelay(value: [])
    
    // https://www.hackingwithswift.com/example-code/uikit/how-to-customize-swipe-edit-buttons-in-a-uitableview
    // https://medium.com/ios-os-x-development/enable-slide-to-delete-in-uitableview-9311653dfe2
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        guard let item = dataSource?[indexPath] else { return nil }
        
        switch item.type
        {
        case .Tutor:
            fallthrough
        case .Participant:
            return [ getDeleteActionFor(item) ]
        
        default:
            return nil
        }
    }
    
    func deleteCurrentlySelectedRows()
    {
        guard let indexPathsForSelectedRows = partialUpdatesTableViewOutlet.indexPathsForSelectedRows, let dataSource = dataSource, let currentSessionSnapshot = self.getCurrentSessionSnapshot() else
        {
            assertionFailure(); return
        }
        
        let participants = indexPathsForSelectedRows.map
        { (indexPath) -> DocumentReference? in
            
            let item: CurrentSessionModelItemBox = dataSource[indexPath]
            
            switch item.type
            {
            case .Participant:
                return (item as? CurrentSessionModelParticipantItem)?.item.reference
            default:
                return nil
            }
        }.filter { $0 != nil }.map { $0! }
        
        let hosts = indexPathsForSelectedRows.map
        { (indexPath) -> DocumentReference? in
            
            let item: CurrentSessionModelItemBox = dataSource[indexPath]
            
            switch item.type
            {
            case .Tutor:
                return (item as? CurrentSessionModelTutorItem)?.host
            default:
                return nil
            }
        }.filter { $0 != nil }.map { $0! }
        
        let _ = Api.sharedApi.remove(participants: participants, from: currentSessionSnapshot.reference).debug("delete participants \(participants) from editing mode").subscribe()
        let _ = Api.sharedApi.remove(hosts: hosts, from: currentSessionSnapshot).debug("delete hosts \(hosts) from editing mode").subscribe()
    }
        
    private func getDeleteActionFor(_ participant: CurrentSessionModelItemBox) -> UITableViewRowAction
    {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete")
        { (action, indexPath) in
            
            let actionSheet = UIAlertController(title: "Are you sure?", message: "You can add him back later", preferredStyle: UIAlertController.Style.actionSheet)
            
            let delete = UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive)
            { [weak self] _ in
                
                if let currentSessionSnapshot = self?.getCurrentSessionSnapshot()
                {
                    switch participant.type
                    {
                    case .Tutor:
                        guard let participant = participant as? CurrentSessionModelTutorItem else { return }
                        let _ = Api.sharedApi.remove(hosts: [ participant.host ], from: currentSessionSnapshot).debug("delete host \(participant.host.documentID) from UITableViewRowAction").subscribe()
                        return
                        
                    case .Participant:
                        guard let participant = participant as? CurrentSessionModelParticipantItem else { return }
                        // it is ok, remove sequences will terminate in finite time
                        let _ = Api.sharedApi.remove(participants: [ participant.item.reference ], from: currentSessionSnapshot.reference).debug("delete participant \(participant.item.documentID) from UITableViewRowAction").subscribe()
                        return
                        
                    default:
                        assertionFailure()
                        return
                    }
                }
            }
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
            
            actionSheet.addAction(delete)
            actionSheet.addAction(cancel)
            
            // hacky I know :)
            if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController
            {
                rootViewController.present(actionSheet, animated: true, completion: nil)
            }
        }
        
        return delete
    }
    
    // https://stackoverflow.com/questions/849926/how-to-limit-uitableview-row-reordering-to-a-section
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath
    {
        if (sourceIndexPath.section != proposedDestinationIndexPath.section)
        {
            return sourceIndexPath
        }
        
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
    {
        guard let item = dataSource?[indexPath] else { return false }
        
        let isEditing = tableView.isEditing
        
        switch item.type
        {
        case .Tutor:
            return isEditing ? true : false
        case .Participant:
            return isEditing ? true : false
        case .AddNewParticipant:
            return isEditing ? false : true
        case .Event:
            let shouldHighlight = isEditing ? false : true
            if shouldHighlight
            {
                return Api.sharedApi.editingAllowed.value
            }
            return shouldHighlight
        }
    }

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
    
    let subjectOfParticipantSnapshots = PublishSubject<DocumentSnapshot>()
    
    var currentSession: DocumentReference?
    {
        didSet
        {
            disposeBag = nil
            allSnapshotListeners = [:]
            
            if let currentSession = currentSession
            {
                let disposeBag = DisposeBag()
                
                let sharedCurrentSession = currentSession.rx.listen().asObservable().share(replay: 1)
                sharedCurrentSession.subscribe(
                onNext: { [weak self] event in
                    
                    guard let self = self else { return }
                    
                    
                    // some kind of self implemented FlatMap
                    if let participants = event.get(Session.participants) as? Array<DocumentReference>
                    {
                        self.allSnapshotListeners = self.allSnapshotListeners.filter(
                        { (arg0) -> Bool in
                            let (key, _) = arg0
                            
                            return participants.contains(key)
                        })
                        
                        participants.forEach(
                        { (participant) in
                            
                            if !self.allSnapshotListeners.keys.contains(participant)
                            {
                                let _bag = DisposeBag()
                                participant.rx.listen()/*.debug("___participant.\(participant.documentID)")*/
                                .bind(to:self.subjectOfParticipantSnapshots).disposed(by: _bag)
                                self.allSnapshotListeners[participant] = _bag
                            }
                        })
                    }
                        
                }).disposed(by: disposeBag)
                
                sharedCurrentSession.bind(to: currentSessionSnapshot).disposed(by: disposeBag)
                
                // there is prob a logic race between sharedCurrentSession subscribers, because of sharedCurrentSession and filtration inside scan
                // will see
                let allSnapshotsOfCurrentParticipants = Observable.combineLatest(
                    sharedCurrentSession/*.debug("___currentSession")*/,
                    subjectOfParticipantSnapshots/*.debug("___subject")*/)
                .scan(into: _allSnapshots)
                { (allSnapshots, arg1) in
                    let (currentSession, participantSnapshot) = arg1
                    
                    if let participants = currentSession.get(Session.participants) as? Array<DocumentReference>
                    {
                        if let index = allSnapshots.firstIndex(where:
                        {
                            $0.documentID == participantSnapshot.documentID
                        })
                        {
                            allSnapshots[index] = participantSnapshot
                        }
                        else
                        {
                            allSnapshots.append(participantSnapshot)
                        }
                        
                        allSnapshots = allSnapshots.filter(
                        { _participantSnapshot -> Bool in
                            
                            if let _ = participants.firstIndex(where:
                            {
                                $0.documentID == _participantSnapshot.documentID
                            })
                            {
                                return true
                            }
                            
                            return false
                        })
                        
                        // not optimal at all :)
                        allSnapshots.sort(by:
                        { lhs, rhs in
                            
                            let one = participants.firstIndex(where:
                            {
                                $0.documentID == lhs.documentID
                            })!
                            
                            let two = participants.firstIndex(where:
                            {
                                $0.documentID == rhs.documentID
                            })!
                            
                            return one - two < 0
                        })
                    }
                    else
                    {
                        allSnapshots.removeAll()
                    }
                }.startWith([])/*.debug("___scan")*/ // startWith([]) because if there are no participants, then there are no snapshots

                Observable.combineLatest(
                    sharedCurrentSession,
                    allSnapshotsOfCurrentParticipants).subscribe(
                    onNext: { [weak self] event in

                        self?.currentSessionSnapshot.accept(event.0)
                        self?._allSnapshots = event.1
                        self?.buildItems()
                        
                    }).disposed(by: disposeBag)

                self.disposeBag = disposeBag
            }
            else
            {
                currentSessionSnapshot.accept(nil)
                _allSnapshots = []
                buildItems()
            }
        }
    }
    
    var _allSnapshots: [DocumentSnapshot] = []
    var allSnapshotListeners: [DocumentReference : DisposeBag] = [:]
    
    var searchQuery: String?
    
    let currentSessionSnapshot: BehaviorRelay<DocumentSnapshot?> = BehaviorRelay(value: nil)
    
    func buildItems(/*participants: Array<DocumentSnapshot>*/)
    {
        let _currentSession = currentSessionSnapshot.value
        let participants = _allSnapshots // .map({ $0.1 })
    
        guard let currentSession = _currentSession, currentSession.exists else
        {
            sections.accept(Array<Section>())
            return
        }
        
        var _sections = Array<Section>()
        
        if let searchQuery = searchQuery
        {
            if searchQuery.isEmpty
            {
                if let host = currentSession.get(Session.host) as? DocumentReference
                {
                    _sections.append(Section(model: .Tutor, items: [CurrentSessionModelTutorItem(host)]))
                }
                if participants.count > 0
                {
                    print("Session.participants.count: \(participants.count)")
                    _sections.append(Section(model: .Participant, items: participants.map({ CurrentSessionModelParticipantItem($0) })))
                }
            }
            else
            {
                let par = participants.map({ CurrentSessionModelParticipantItem($0)}).filter({ $0.isRelevantForSearchQuery(searchQuery) })
                
                _sections.append(Section(model: .Participant, items: par))
            }
        }
        else
        {
            _sections.append(Section(model: .Event, items: [CurrentSessionModelEventItem(item: currentSession)]))
            
            if let host = currentSession.get(Session.host) as? DocumentReference
            {
                _sections.append(Section(model: .Tutor, items: [CurrentSessionModelTutorItem(host)]))
            }
            else
            {
                // todo: Add
            }
            
            if Api.sharedApi.editingAllowed.value
            {
                _sections.append(Section(model: .AddNewParticipant, items: [CurrentSessionModelAddNewParticipantItem()]))
            }
            
            if participants.count > 0
            {
                print("Session.participants.count: \(participants.count)")
                _sections.append(Section(model: .Participant, items: participants.map({ CurrentSessionModelParticipantItem($0) })))
            }
        }
        
        sections.accept(_sections)
    }
}
