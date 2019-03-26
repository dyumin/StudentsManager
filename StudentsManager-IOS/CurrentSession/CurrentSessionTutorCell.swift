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
    
    let disposeBag = DisposeBag()
    @IBOutlet weak var profileImage: UIImageView!
    
    let imageService = DefaultImageService.sharedImageService
    
    var downloadableImage: Observable<DownloadableImage>?
    {
        didSet
        {
            self.downloadableImage?
                .asDriver(onErrorJustReturn: DownloadableImage.offlinePlaceholder)
                .drive(profileImage.rx.downloadableImageAnimated(CATransitionType.fade.rawValue))
                .disposed(by: disposeBag)
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        
        let reachabilityService = Dependencies.sharedDependencies.reachabilityService
            
            
//        let photoURL = URL(string: "https://lh3.googleusercontent.com/-ZT2R2hbTzgA/AAAAAAAAAAI/AAAAAAAAAak/tRG7nFPdsJE/photo.jpg?sz=64")!
        if let photoURL = Auth.auth().currentUser?.photoURL
        {
            downloadableImage = self.imageService.imageFromURL(photoURL, reachabilityService: reachabilityService)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
