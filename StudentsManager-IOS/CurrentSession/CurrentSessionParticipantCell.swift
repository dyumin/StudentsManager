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
    
    var item: DocumentSnapshot?
    {
        didSet
        {
            disposeBag = nil
            
            guard let item = item else
            {
                return
            }
            
            DispatchQueue.main.async
            { [weak self] in
                
                guard let self = self else { return }
                
                let disposeBag = DisposeBag()

                self.avatarView.parameters = (item.documentID.hashValue, [])
                self.avatarView.image = nil

                if let name = item.get(ApiUser.displayName) as? String
                {
                    self.name.isHidden = false
                    self.name.text = name
                    
                    let letters = name.components(separatedBy: " ").map({ $0.first != nil ? String($0.first!) : String() })
                    self.avatarView.parameters.letters = letters
                }
                else
                {
                    self.name.isHidden = true
                }
                
                if let email = item.get(ApiUser.email) as? String
                {
                    self.email.isHidden = false
                    self.email.text = email
                }
                else
                {
                    self.email.isHidden = true
                }
                
                if let phone = item.get(ApiUser.phone) as? String
                {
                    self.phone.isHidden = false
                    self.phone.text = phone
                }
                else
                {
                    self.phone.isHidden = true
                }
                
                self.api.userProfilePhoto(for: item.documentID, .UserProfilePhoto).observeOn(MainScheduler.instance).subscribe(
                    onNext: { [weak self] image in
                        
                        self?.avatarView.image = image
                        
                }).disposed(by: disposeBag)
        
                self.disposeBag = disposeBag
            }
        }
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        self.item = nil
        self.disposeBag = nil
    }
}
