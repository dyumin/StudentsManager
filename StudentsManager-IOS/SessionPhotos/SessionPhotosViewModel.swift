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


class SessionPhotosViewModel: NSObject, UICollectionViewDelegateFlowLayout
{
    private typealias DataSource = RxCollectionViewSectionedAnimatedDataSource<Section>
    private typealias DataSourceInternalType = CollectionViewSectionedDataSource<Section>
    
    private typealias Section = AnimatableSectionModel<SessionPhotosModelItemType, SessionPhotosModelItemBox>
    
    private weak var dataSource: DataSource?
    
    private var dataSourceDisposeBag: DisposeBag?
    
    private let sections: PublishSubject<[Section]> = PublishSubject()
    
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
                        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SessionPhotosPhotoCell.identifier, for: indexPath) as? SessionPhotosPhotoCell
                        {
                            
                            return cell
                        }
                        break
                    }
                    
                    return UICollectionViewCell()
                }
                
                let dataSource = DataSource(configureCell: configureCell)
                
                partialUpdatesCollectionViewOutlet.rx.setDelegate(self).disposed(by: dataSourceDisposeBag)
                
                sections.asObservable().debug("sections_to_collection").bind(to: partialUpdatesCollectionViewOutlet.rx.items(dataSource: dataSource)).disposed(by: dataSourceDisposeBag)
                
                self.dataSource = dataSource
                
                self.dataSourceDisposeBag = dataSourceDisposeBag
                
                sections.onNext([Section(model: .AddNewPhoto, items: [SessionPhotosModelAddNewPhotoItem(), SessionPhotosModelPhotoItem()])])
            }
        }
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
