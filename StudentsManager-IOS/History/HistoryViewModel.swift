//
//  HistoryViewModel.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/05/2019.
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
extension HistoryViewModel: UITableViewDataSourcePrefetching
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

class HistoryViewModel: NSObject, UITableViewDelegate
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
                partialUpdatesTableViewOutlet.register(UINib(nibName: CurrentSessionEventCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionEventCell.identifier)
                
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
        guard let owner = owner as? History
            else
        {
            assertionFailure()
            return
        }
        
        guard let item = dataSource?[indexPath] else { return }
        
        switch item.type
        {
        case .Event:
            if let item = item as? CurrentSessionModelEventItem
            {
                _ = Api.sharedApi.setSelectedSession(item.item.reference).subscribe()
            }
            owner.tabBarController?.selectedIndex = 1
            
            break
            
        default:
            break
        }
        
        self.partialUpdatesTableViewOutlet.deselectRow(at: indexPath, animated: true)
    }
    
    override init()
    {
        super.init()
        
        Observable.combineLatest(
            Api.sharedApi.userPastSessions,
            searchQuery)
            .map
            {
                var items = $0.0.map { return CurrentSessionModelEventItem(item: $0) }

                if let searchQuery = $0.1, searchQuery.count > 0
                {
                    items = items.filter{ $0.isRelevantForSearchQuery(searchQuery) }
                }

                return [Section(model: .Event, items: items )]

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


