//
//  SessionPhotosAddNewPhotoCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//
//  Created by Segii Shulga on 1/5/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import UIKit

import RxSwift

class SessionPhotosAddNewPhotoCell: UICollectionViewCell {
    
    static let identifier: String = "SessionPhotosAddNewPhotoCell"
    
    var disposeBag = DisposeBag()

    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var cropButton: UIButton!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        
        // hacky I know :)
        let rootViewController = UIApplication.shared.delegate?.window??.rootViewController
        
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        cameraButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx.createWithParent(rootViewController) { picker in
                    picker.sourceType = .camera
                    picker.allowsEditing = false
                    }
                    .flatMap { $0.rx.didFinishPickingMediaWithInfo }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage
            }
            .subscribe(onNext:
            { [weak self] image in
                
                if let image = image
                {
                    self?.photoTaken(photo: image)
                }
                    
            })
            .disposed(by: disposeBag)
        
        galleryButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx.createWithParent(rootViewController) { picker in
                    picker.sourceType = .photoLibrary
                    picker.allowsEditing = false
                    }
                    .flatMap {
                        $0.rx.didFinishPickingMediaWithInfo
                    }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage
            }
            .subscribe(onNext:
            { [weak self] image in
                
                if let image = image
                {
                    self?.photoTaken(photo: image)
                }
                    
            })
            .disposed(by: disposeBag)
        
        cropButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx.createWithParent(rootViewController) { picker in
                    picker.sourceType = .photoLibrary
                    picker.allowsEditing = true
                    }
                    .flatMap { $0.rx.didFinishPickingMediaWithInfo }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerController.InfoKey.editedImage.rawValue] as? UIImage
            }
            .subscribe(onNext:
            { [weak self] image in
                
                if let image = image
                {
                    self?.photoTaken(photo: image)
                }
                    
            })
            .disposed(by: disposeBag)
    }

    func photoTaken(photo: UIImage)
    {
        guard let selectedSession = Api.sharedApi.selectedSession.value else { return }
        
        Api.sharedApi.AddSessionPhoto(photo, for: selectedSession)
    }
}
