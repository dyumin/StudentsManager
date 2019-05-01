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
    
    var disposeBag: DisposeBag?
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var phone: UILabel!
    
    @IBOutlet weak var email: UILabel!
    
    let imageService = DefaultImageService.sharedImageService
    
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
            item.rx.listen().distinctUntilChanged().debug("CurrentSessionTutorCell.item").observeOn(MainScheduler.instance).subscribe(
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
    
    var downloadableImage: Observable<DownloadableImage>?
    {
        didSet
        {
//            self.downloadableImage?
//                .asDriver(onErrorJustReturn: DownloadableImage.offlinePlaceholder)
//                .drive(profileImage.rx.downloadableImageAnimated(CATransitionType.fade.rawValue))
//                .disposed(by: disposeBag)
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        
//        let reachabilityService = Dependencies.sharedDependencies.reachabilityService
//
//        if let photoURL = Auth.auth().currentUser?.photoURL
//        {
//            downloadableImage = self.imageService.imageFromURL(photoURL, reachabilityService: reachabilityService)
//        }
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
    }
}
