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
        print("prefetchRowsAt \(indexPaths)")
        
        for indexPath in indexPaths
        {
            guard let dataSource = self.dataSource else { return }
            
            let item = dataSource[indexPath]
            
            if item.type == .Participant, let item = item as? CurrentSessionModelParticipantItem
            {
                let cache = Dependencies.sharedDependencies.cache
                
                cache.loadData(forKey: item.cachePhotoKey, withCallback:
                { (persistentCacheResponse) in
                    
                    if persistentCacheResponse.result != .operationSucceeded
                    {
                        let reference = Storage.storage().reference(withPath: item.serverPhotoPath).rx
                        
                        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                        reference.getData(maxSize: 1 * 1024 * 1024)/*.debug("CurrentSessionParticipantCell.photo")*/
                            .subscribe(
                                onNext: { data in
                                    
                                    cache.store(data, forKey: item.cachePhotoKey, locked: false, withCallback: nil, on: nil)
                                    
                                }
                        ) // TODO: should it be disposed somehow?
                    }
                }, on: DispatchQueue.global())
                
//                if !PINCache.shared().containsObject(forKey: item.cachePhotoKey)
//                {
//                    let reference = Storage.storage().reference(withPath: item.serverPhotoPath).rx
//                    
//                    // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
//                    reference.getData(maxSize: 1 * 1024 * 1024)/*.debug("CurrentSessionParticipantCell.photo")*/
//                        .subscribe(
//                            onNext: { data in
//                                
//                                guard let image = UIImage(data: data) else { return }
//                                
//                                PINCache.shared().setObject(image, forKey: item.cachePhotoKey)
//                                
//                            }
//                    ) // TODO: should it be disposed somehow?
//                }
                
            }
        }
    }
    
//    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath])
//    {
//        print("cancelPrefetchingForRowsAt \(indexPaths)")
//        indexPaths.forEach { self.cancelDownloadingImage(forItemAtIndex: $0.row) }
//    }
}

class CurrentSessionModel: NSObject
{
    weak var dataSource: RxTableViewSectionedAnimatedDataSource<Section>?
    
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
                    }
                    
                    return UITableViewCell()
                }
                
                let titleForSection : TableViewSectionedDataSource<Section>.TitleForHeaderInSection =
                { (ds, section) -> String? in
                    
                    if ds[section].model == .Participant
                    {
                        return String("Participants")
                    }
                    
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
                
                if #available(iOS 10.0, *)
                {
                    partialUpdatesTableViewOutlet.prefetchDataSource = self
                }
                
                sections.asObservable()/*.debug("sections_to_table")*/.bind(to: partialUpdatesTableViewOutlet.rx.items(dataSource: dataSource)).disposed(by: dataSourceDisposeBag)
                
                self.dataSource = dataSource
                
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
            
            if let participants = currentSession.get(Session.participants) as? Array<DocumentReference>
            {
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
    
    let item: DocumentReference
    
    var cachePhotoKey: String
    {
        return CurrentSessionModelParticipantItem.cachePhotoKey(for: item)
    }
    
    var serverPhotoPath: String
    {
        return "\(item.path)/datasetPhotos/1.JPG"
    }
    
    private static func cachePhotoKey(for id: String) -> String
    {
        return "\(id)_profilePhoto"
    }
    
    static func cachePhotoKey(for documentReference: DocumentReference) -> String
    {
        return cachePhotoKey(for: documentReference.documentID)
    }
    
    static func cachePhotoKey(for documentSnapshot: DocumentSnapshot) -> String
    {
        return cachePhotoKey(for: documentSnapshot.documentID)
    }
    
    init(_ item: DocumentReference)
    {
        self.item = item
    }
}
