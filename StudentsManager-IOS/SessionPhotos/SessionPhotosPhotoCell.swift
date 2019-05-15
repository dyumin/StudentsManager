//
//  SessionPhotosPhotoCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

import Firebase

import RxFirebaseStorage

class SessionPhotosPhotoCell: UICollectionViewCell
{
    static let identifier: String = "SessionPhotosPhotoCell"
    
    @IBOutlet weak var image: UIImageView!
    
    private var disposeBag: DisposeBag?
    
    private let api = Api.sharedApi
    
    var item: DocumentSnapshot?
    {
        didSet
        {
            disposeBag = nil
            
            guard let item = item else
            {
                return
            }
            
            let disposeBag = DisposeBag()
            
            self.api.getImage(for: item.documentID, .SessionMediaItem)
                .observeOn(MainScheduler.instance)
                .subscribe(
                onNext: { [weak self] image in
                    
                    self?.image.image = image
                    
                }).disposed(by: disposeBag)
            
            self.disposeBag = disposeBag
        }
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        self.item = nil
        self.disposeBag = nil
        self.image.image = nil
    }
}
