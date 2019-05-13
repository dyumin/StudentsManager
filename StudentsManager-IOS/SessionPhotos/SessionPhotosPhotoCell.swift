//
//  SessionPhotosPhotoCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

class SessionPhotosPhotoCell: UICollectionViewCell
{
    static let identifier: String = "SessionPhotosPhotoCell"
    
    @IBOutlet weak var image: UIImageView!
    

    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        image.image = UIImage(named: "eesample")
    }
}
