//
//  CurrentSessionParticipantCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 02/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

import Firebase

import SPTPersistentCache

import PINCache

class CurrentSessionParticipantCell: UITableViewCell
{
    static let identifier: String = "CurrentSessionParticipantCell"
    
    var disposeBag: DisposeBag?
    
    let cache = Dependencies.sharedDependencies.cache
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var phone: UILabel!
    
    @IBOutlet weak var email: UILabel!
    
    @IBOutlet weak var userImage: UIImageView!
    
    var item: DocumentReference?
    {
        didSet
        {
            guard let item = item else
            {
                return
            }
            
            self.userImage.image = UIImage(named: "Instructress")
            
            let disposeBag = DisposeBag()
            item.rx.listen().distinctUntilChanged()/*.debug("CurrentSessionParticipantCell.item")*/.observeOn(MainScheduler.instance).subscribe(
                onNext: { [weak self] event in
                    
                    if let name = event.get(ApiUser.displayName) as? String
                    {
                        self?.name.isHidden = false
                        self?.name.text = name
                    }
                    else
                    {
                        self?.name.isHidden = true
                    }
                    
                    if let email = event.get(ApiUser.email) as? String
                    {
                        self?.email.isHidden = false
                        self?.email.text = email
                    }
                    else
                    {
                        self?.email.isHidden = true
                    }
                    
                    if let phone = event.get(ApiUser.phone) as? String
                    {
                        self?.phone.isHidden = false
                        self?.phone.text = phone
                    }
                    else
                    {
                        self?.phone.isHidden = true
                    }
                    
            }).disposed(by: disposeBag)
            
            cache.loadData(forKey: CurrentSessionModelParticipantItem.cachePhotoKey(for: item), withCallback:
            { (persistentCacheResponse) in

                if persistentCacheResponse.result == .operationSucceeded
                {
                    self.userImage.image = UIImage(data: persistentCacheResponse.record.data)
                }

            }, on: DispatchQueue.main)
            
//            PINCache.shared().object(forKey: CurrentSessionModelParticipantItem.cachePhotoKey(for: item))
//            { (cache, key, object) in
//                if let image = object as? UIImage
//                {
//                    DispatchQueue.main.async
//                    {
//                        self.userImage.image = image
//                    }
//                }
//            }
            
            self.disposeBag = disposeBag
        }
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        self.item = nil
        self.disposeBag = nil
    }
}
