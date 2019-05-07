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

class RxTableViewSectionedAnimatedDataSourceDynamicWrapper<S: AnimatableSectionModelType> : RxTableViewSectionedAnimatedDataSource<S>
{
    public typealias DidMoveRowAtSourceIndexPathToDestinationIndexPath = (TableViewSectionedDataSource<S>, IndexPath, IndexPath) -> Void
    
    open var didMoveRowAtSourceIndexPathToDestinationIndexPath: DidMoveRowAtSourceIndexPathToDestinationIndexPath
    
    open override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        didMoveRowAtSourceIndexPathToDestinationIndexPath(self, sourceIndexPath, destinationIndexPath)
    }
    
    public init(
        configureCell: @escaping ConfigureCell,
        titleForHeaderInSection: @escaping  TitleForHeaderInSection = { _, _ in nil },
        titleForFooterInSection: @escaping TitleForFooterInSection = { _, _ in nil },
        canEditRowAtIndexPath: @escaping CanEditRowAtIndexPath = { _, _ in false },
        canMoveRowAtIndexPath: @escaping CanMoveRowAtIndexPath = { _, _ in false },
        sectionIndexTitles: @escaping SectionIndexTitles = { _ in nil },
        sectionForSectionIndexTitle: @escaping SectionForSectionIndexTitle = { _, _, index in index },
        didMoveRowAtSourceIndexPathToDestinationIndexPath: @escaping DidMoveRowAtSourceIndexPathToDestinationIndexPath = { _, _, _ in }
        ) {
        self.didMoveRowAtSourceIndexPathToDestinationIndexPath = didMoveRowAtSourceIndexPathToDestinationIndexPath
        super.init(
            configureCell: configureCell,
            titleForHeaderInSection: titleForHeaderInSection,
            titleForFooterInSection: titleForFooterInSection,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath,
            sectionIndexTitles: sectionIndexTitles,
            sectionForSectionIndexTitle: sectionForSectionIndexTitle
        )
    }
}

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
        guard let currentSessionModelEventItems = dataSource?.sectionModels.first(where:
        {
            $0.model == .Event
        })?.items else { assertionFailure(); return nil }

        assert(currentSessionModelEventItems.count == 1)

        guard let currentSessionModelEventItem = currentSessionModelEventItems.first as? CurrentSessionModelEventItem else { assertionFailure(); return nil }

        return currentSessionModelEventItem.item
    }
}

class CurrentSessionModel: NSObject, UITableViewDelegate
{
    public typealias DataSource = RxTableViewSectionedAnimatedDataSourceDynamicWrapper<Section>
    
    weak var dataSource: DataSource?
    
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
                
                let titleForSection : TableViewSectionedDataSource<Section>.TitleForHeaderInSection =
                { (ds, section) -> String? in
                    
                    let shouldAdjustTitleToIncludeAddNewButton = Api.sharedApi.editingAllowed.value
                    
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
                
                let canEditRowAtIndexPath: TableViewSectionedDataSource<Section>.CanEditRowAtIndexPath =
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
                let canMoveRowAtIndexPath: TableViewSectionedDataSource<Section>.CanMoveRowAtIndexPath =
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
        
        let _ = Api.sharedApi.remove(participants: participants, from: currentSessionSnapshot).debug("delete participants \(participants) from editing mode").subscribe()
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
                        let _ = Api.sharedApi.remove(participants: [ participant.item.reference ], from: currentSessionSnapshot).debug("delete participant \(participant.item.documentID) from UITableViewRowAction").subscribe()
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
            return isEditing ? false : true
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
                
                
                // there is prob a logic race between sharedCurrentSession subscribers, because of sharedCurrentSession and filtration inside scan
                // will see
                let allSnapshotsOfCurrentParticipants = Observable.combineLatest(
                    sharedCurrentSession/*.debug("___currentSession")*/,
                    subjectOfParticipantSnapshots/*.debug("___subject")*/)
                .scan(into: allSnapshots)
                { (allSnapshots, arg1) in
                    let (currentSession, participantSnapshot) = arg1
                    
                    if let participants = currentSession.get(Session.participants) as? Array<DocumentReference>
                    {
                        allSnapshots = allSnapshots.filter(
                        { (arg0) -> Bool in
                            let (key, _) = arg0
                            
                            // "key != participantSnapshot.reference" because tuple is a value type...
                            return participants.contains(key) && key != participantSnapshot.reference
                        })
                        
                        allSnapshots.append((participantSnapshot.reference, participantSnapshot))
                        
                        // not optimal at all :)
                        allSnapshots.sort(by:
                        { lhs, rhs in
                            
                            let one = participants.firstIndex(where:
                            {
                                $0.documentID == lhs.0.documentID
                            })!
                            
                            let two = participants.firstIndex(where:
                            {
                                $0.documentID == rhs.0.documentID
                            })!
                            
                            return one - two < 0
                        })
                    }
                    else
                    {
                        allSnapshots.removeAll()
                    }
                }/*.debug("___scan")*/
                
                Observable.combineLatest(
                    sharedCurrentSession,
                    allSnapshotsOfCurrentParticipants).subscribe(
                    onNext: { [weak self] event in
                        
                        self?.allSnapshots = event.1
                        self?.buildItems(currentSession: event.0, participants: event.1.map({ $0.1 }))
                        
                    }).disposed(by: disposeBag)

                self.disposeBag = disposeBag
            }
            else
            {
                buildItems(currentSession: nil, participants: [])
            }
        }
    }
    
    var allSnapshots: [(DocumentReference, DocumentSnapshot)] = []
    var allSnapshotListeners: [DocumentReference : DisposeBag] = [:]
    
    func buildItems(currentSession: DocumentSnapshot?, participants: Array<DocumentSnapshot>)
    {
        var _sections = Array<Section>()
        
        if let currentSession = currentSession, currentSession.exists
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

enum CurrentSessionModelItemType: String
{
    case Event
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
    
    let item: DocumentSnapshot
    
    // TODO: reference is bad for you...
//    var displayName: String
//    {
//        if let displayName = item.get(ApiUser.displayName) as? String
//        {
//            return displayName
//        }
//        else
//        {
//            return String()
//        }
//    }
    
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
