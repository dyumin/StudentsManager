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
    
    let api = Api.sharedApi
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var phone: UILabel!
    
    @IBOutlet weak var email: UILabel!
    
    @IBOutlet weak var avatarView: AvatarView!
    
    var item: DocumentReference?
    {
        didSet
        {
            guard let item = item else
            {
                return
            }

            let disposeBag = DisposeBag()
            
            // todo: use more stable hash
            avatarView.parameters = (item.documentID.hashValue, [])
            avatarView.image = nil
            
            item.rx.listen().distinctUntilChanged()
                /*.debug("CurrentSessionParticipantCell.item")*/
                .observeOn(MainScheduler.instance).subscribe(
                onNext: { [weak self] event in
                    
                    if let name = event.get(ApiUser.displayName) as? String
                    {
                        self?.name.isHidden = false
                        self?.name.text = name
                        
                        let letters = name.components(separatedBy: " ").map({ $0.first != nil ? String($0.first!) : String() })
                        self?.avatarView.parameters.letters = letters
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
            
            api.userProfilePhoto(for: item.documentID).observeOn(MainScheduler.instance).subscribe(
                onNext: { [weak self] image in
                    
                    self?.avatarView.image = image
                    
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
