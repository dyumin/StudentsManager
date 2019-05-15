//
//  SessionPhotosViewModel.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import Firebase

import RxDataSources

// MARK: - UICollectionViewDataSourcePrefetching
extension SessionPhotosViewModel: UICollectionViewDataSourcePrefetching
{
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])
    {
        guard let dataSource = self.dataSource else { return }
        
        let _cachedValues = dataSource.sectionModels
        let api = Api.sharedApi
        
        for indexPath in indexPaths
        {
            let item = _cachedValues[indexPath.section].items[indexPath.item]
            
            if item.type == .Photo, let item = item as? SessionPhotosModelPhotoItem
            {
                api.prefetchImage(for: item.item.documentID, .SessionMediaItem)
            }
        }
    }
}

class SessionPhotosViewModel: NSObject, UICollectionViewDelegateFlowLayout
{
    private typealias DataSource = RxCollectionViewSectionedAnimatedDataSource<Section>
    private typealias DataSourceInternalType = CollectionViewSectionedDataSource<Section>
    
    private typealias Section = AnimatableSectionModel<SessionPhotosModelItemType, SessionPhotosModelItemBox>
    
    private weak var dataSource: DataSource?
    
    private var disposeBag: DisposeBag?
    
    private var dataSourceDisposeBag: DisposeBag?
    
    private let sections: BehaviorRelay<[Section]> = BehaviorRelay(value: [])
    
    weak var partialUpdatesCollectionViewOutlet: UICollectionView!
    {
        didSet
        {
            self.dataSourceDisposeBag = nil
            
            if let partialUpdatesCollectionViewOutlet = partialUpdatesCollectionViewOutlet
            {
                partialUpdatesCollectionViewOutlet.register(UINib(nibName: SessionPhotosAddNewPhotoCell.identifier, bundle: nil), forCellWithReuseIdentifier: SessionPhotosAddNewPhotoCell.identifier)
                partialUpdatesCollectionViewOutlet.register(UINib(nibName: SessionPhotosPhotoCell.identifier, bundle: nil), forCellWithReuseIdentifier: SessionPhotosPhotoCell.identifier)
                
                let dataSourceDisposeBag = DisposeBag()
                
                let configureCell: DataSourceInternalType.ConfigureCell =
                { dataSource, collectionView, indexPath, item in
                    
                    switch item.type
                    {
                    case .AddNewPhoto:
                        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SessionPhotosAddNewPhotoCell.identifier, for: indexPath) as? SessionPhotosAddNewPhotoCell
                        {
                            return cell
                        }
                        break
                    case .Photo:
                        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SessionPhotosPhotoCell.identifier, for: indexPath) as? SessionPhotosPhotoCell, let item = item as? SessionPhotosModelPhotoItem
                        {
                            cell.item = item.item
                            return cell
                        }
                        break
                    }
                    
                    return UICollectionViewCell()
                }
                
                let dataSource = DataSource(configureCell: configureCell)
                
                partialUpdatesCollectionViewOutlet.rx.setDelegate(self).disposed(by: dataSourceDisposeBag)
                
                self.dataSource = dataSource
                
                if #available(iOS 10.0, *)
                {
                    partialUpdatesCollectionViewOutlet.rx.setPrefetchDataSource(self).disposed(by: dataSourceDisposeBag)
                }
                sections.asObservable().debug("sections_to_collection").bind(to: partialUpdatesCollectionViewOutlet.rx.items(dataSource: dataSource)).disposed(by: dataSourceDisposeBag)
                
                self.dataSourceDisposeBag = dataSourceDisposeBag
            }
        }
    }
    
    var allSnapshots: [DocumentSnapshot] = []
    
    var currentSession: DocumentReference?
    {
        didSet
        {
            disposeBag = nil
            
            if let currentSession = currentSession
            {
                let disposeBag = DisposeBag()
                
                let sharedCurrentSession = currentSession.rx.listen().asObservable().share(replay: 1)
                sharedCurrentSession.debug("SessionPhotosViewModel currentSession").subscribe(
                onNext: { [weak self] event in

                    let resources = event.reference.collection(Session.resources)
                    
                    // literally all records
                    Observable.combineLatest(
                    resources.whereField(ResourceRecord.processed, isEqualTo: true).rx.listen(),
                    resources.whereField(ResourceRecord.processed, isEqualTo: false).rx.listen())
                    .map { ($0.0.documents + $0.1.documents)
                        .sorted(by: { (lhs, rhs) -> Bool in
                            if let _lhs = lhs.get(ResourceRecord.createdTime) as? Timestamp, let _rhs = rhs.get(ResourceRecord.createdTime) as? Timestamp
                            {
                                return _lhs.seconds > _rhs.seconds
                            }
                            
                            return false
                        })
                    }
                    .subscribe(
                    onNext: { [weak self] event in

                        self?.allSnapshots = event
                        self?.buildItems()

                    }).disposed(by: disposeBag)
                    
                    
                }).disposed(by: disposeBag)
                
                self.disposeBag = disposeBag
            }
            else
            {
                allSnapshots = []
                buildItems()
            }
        }
    }
    
    func buildItems()
    {
        var _sections = Array<Section>()
        
        _sections.append(Section(model: .AddNewPhoto, items: [SessionPhotosModelAddNewPhotoItem()]))
        
        if allSnapshots.count > 0
        {
            _sections.append(Section(model: .Photo, items: allSnapshots.map { SessionPhotosModelPhotoItem($0) }))
        }
        
        sections.accept(_sections)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        if dataSource?[indexPath].type == .AddNewPhoto
        {
            return CGSize(width: collectionView.frame.width - 50, height: collectionView.frame.height)
        }
        
        return collectionView.frame.size
    }
}
