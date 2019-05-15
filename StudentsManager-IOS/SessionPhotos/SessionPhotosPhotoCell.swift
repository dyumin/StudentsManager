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
    
    var disposeBag: DisposeBag?
    
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
            
            if let imagePath = item.get(ResourceRecord.imagePath) as? String
            {
                let storage = Storage.storage()
                // Download in memory with a maximum allowed size of 100MB (100 * 1024 * 1024 bytes) (why not)
                storage.reference(withPath: imagePath).rx
                    .getData(maxSize: 100 * 1024 * 1024)
                    .debug("downloading \(imagePath)")
                    .subscribe(
                    onNext: { [weak self] event in
                        
                        DispatchQueue.main.async
                        { [weak self] in
                            
                            self?.image.image = UIImage(data: event)
                        }
                        
                    }).disposed(by: disposeBag)
            }
            
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
