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
                self.disposeBag = nil
                return
            }
            
            if item == oldValue { return }
            
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
            
            self.disposeBag = disposeBag
        }
    }
    
}
