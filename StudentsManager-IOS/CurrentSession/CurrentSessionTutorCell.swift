//
//  CurrentSessionTutorCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import Firebase
import RxSwift
import RxCocoa


class CurrentSessionTutorCell: UITableViewCell
{
    static let identifier: String = "CurrentSessionTutorCell"
    
    let api = Api.sharedApi
    
    var disposeBag: DisposeBag?
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var phone: UILabel!
    
    @IBOutlet weak var email: UILabel!
    
    var item: DocumentSnapshot?
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
            
            if let name = item.get(ApiUser.displayName) as? String
            {
                self.name.isHidden = false
                self.name.text = name
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
            
            self.api.getImage(for: item.documentID, .UserProfilePhoto).observeOn(MainScheduler.instance).subscribe(
                onNext: { [weak self] image in
                    
                    self?.profileImage.image = image
                    
            }).disposed(by: disposeBag)
            
            self.disposeBag = disposeBag
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
    }
}
