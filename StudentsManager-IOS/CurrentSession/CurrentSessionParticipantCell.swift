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

import FirebaseStorage

class CurrentSessionParticipantCell: UITableViewCell
{
    static let identifier: String = "CurrentSessionParticipantCell"
    
    var disposeBag: DisposeBag?
    
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
            item.rx.listen().distinctUntilChanged().debug("CurrentSessionParticipantCell.item").observeOn(MainScheduler.instance).subscribe(
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
            
            let d = item.path
            
            let reference = Storage.storage().reference(withPath: "\(d)/photo.jpeg")
                .rx
            
            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
            reference.getData(maxSize: 1 * 1024 * 1024)/*.debug("CurrentSessionParticipantCell.photo")*/.observeOn(MainScheduler.instance)
                .subscribe(
                onNext: { [weak self] data in
                    
                    let image = UIImage(data: data)
                    self?.userImage.image = image
                    
                }).disposed(by: disposeBag)
            
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
