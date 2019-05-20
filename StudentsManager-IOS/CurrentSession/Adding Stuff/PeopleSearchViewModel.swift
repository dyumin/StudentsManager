//
//  PeopleSearchViewModel.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 19/05/2019.
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
extension PeopleSearchViewModel: UITableViewDataSourcePrefetching
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
                api.prefetchImage(for: item.item.documentID, .UserProfilePhoto)
            }
        }
    }
}

class PeopleSearchViewModel: NSObject, UITableViewDelegate
{
    private typealias DataSource = RxTableViewSectionedAnimatedDataSourceDynamicWrapper<Section>
    
    private typealias DataSourceInternalType = TableViewSectionedDataSource<Section>
    
    private typealias Section = AnimatableSectionModel<CurrentSessionModelItemType, CurrentSessionModelItemBox>
    
    private weak var dataSource: DataSource?
    
    private static let DefaulfCellReuseIdentifier = "Cell"
    
    var callback: PublishSubject<DocumentReference>?
    
    weak var partialUpdatesTableViewOutlet: UITableView!
    {
        didSet
        {
            self.dataSourceDisposeBag = nil
            
            if let partialUpdatesTableViewOutlet = partialUpdatesTableViewOutlet
            {
                partialUpdatesTableViewOutlet.register(UINib(nibName: CurrentSessionParticipantCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionParticipantCell.identifier)
 
                let dataSourceDisposeBag = DisposeBag()
                
                let configureCell: DataSourceInternalType.ConfigureCell =
                { dataSource, tableView, indexPath, item in
                    
                    switch item.type
                    {
                    case .Participant:
                        if let cell = tableView.dequeueReusableCell(withIdentifier: CurrentSessionParticipantCell.identifier, for: indexPath) as? CurrentSessionParticipantCell, let item = item as? CurrentSessionModelParticipantItem
                        {
                            cell.item = item.item
                            return cell
                        }
                        break
                    default:
                        assertionFailure()
                        return UITableViewCell()
                    }
                    
                    assertionFailure()
                    return UITableViewCell()
                }
                
                
                let dataSource = DataSource(configureCell:configureCell)
                
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
                
                self.partialUpdatesTableViewOutlet.rx.setDelegate(self).disposed(by: dataSourceDisposeBag)
                
                self.dataSource = dataSource
                
                if #available(iOS 10.0, *)
                {
                    self.partialUpdatesTableViewOutlet.rx.setPrefetchDataSource(self).disposed(by: dataSourceDisposeBag)
                }
                
                sections.asObservable()/*.debug("sections_to_table")*/.bind(to: partialUpdatesTableViewOutlet.rx.items(dataSource: dataSource)).disposed(by: dataSourceDisposeBag)
                
                self.dataSourceDisposeBag = dataSourceDisposeBag
            }
        }
    }
    
    private var dataSourceDisposeBag: DisposeBag?
    
    private var disposeBag = DisposeBag()
    
    private let sections: BehaviorRelay<[Section]> = BehaviorRelay(value: [])
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let owner = owner as? PeopleSearch
        else
        {
            assertionFailure()
            return
        }
        
        guard let item = dataSource?[indexPath] else { return }
        
        switch item.type
        {
        case .Participant:
            if let item = item as? CurrentSessionModelParticipantItem
            {
               owner.callback.onNext(item.item.reference)
            }
            
            break
            
        default:
            break
        }
        
        self.partialUpdatesTableViewOutlet.deselectRow(at: indexPath, animated: true)
    }
    
    override init()
    {
        super.init()
        
        let db = Firestore.firestore()
        
        Observable.combineLatest(
            db.collection("users").rx.getDocuments().asObservable(),
            searchQuery)
            .map
            {
                var items = $0.0.documents.map { return CurrentSessionModelParticipantItem($0) }
                
                if let searchQuery = $0.1, searchQuery.count > 0
                {
                    items = items.filter{ $0.isRelevantForSearchQuery(searchQuery) }
                }
                
                return [Section(model: .Participant, items: items )]
                
            }.bind(to: sections).disposed(by: disposeBag)
    }
    
    deinit
    {
        pretty_function()
    }
    
    weak var owner: UIViewController?
    
//    var filteredValues: BehaviorRelay<[DocumentSnapshot]> = BehaviorRelay(value: [])
    var searchQuery: BehaviorRelay<String?> = BehaviorRelay(value: nil)
}
