//
//  SessionPhotos.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 11/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//
//  Created by Segii Shulga on 1/5/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import UIKit

import RxSwift

import RxCocoa

import Firebase

import RxFirebaseStorage

class SessionPhotos: UIViewController
{
    private var disposeBag = DisposeBag()
    
    private let DefaultNavItemTitle = "Photos"
    
    private let viewModel = SessionPhotosViewModel()
    
    @IBOutlet weak var collectionView: UICollectionView!
    {
        didSet
        {
            self.viewModel.partialUpdatesCollectionViewOutlet = collectionView
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        fatalError("\(#function) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        navigationItem.title = DefaultNavItemTitle
        
        Api.sharedApi.user.debug("CurrentSession.selectedSession").subscribe(
        onNext: { [weak self] event in
                
                // TODO: leave view if no session
                
        }).disposed(by: disposeBag)
        
        let newButton = UIBarButtonItem()
        newButton.title = "New"
        newButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        newButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx.createWithParent(self) { picker in
                    picker.sourceType = .camera
                    picker.allowsEditing = false
                    }
                    .flatMap { $0.rx.didFinishPickingMediaWithInfo }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage
            }
            .debug().subscribe(
            onNext: { [weak self] image in
                
                if let image = image
                {
                    self?.photoTaken(photo: image)
                }
                
            })
            .disposed(by: disposeBag)
        
        Api.sharedApi.editingAllowed.distinctUntilChanged().map
            { (editingAllowed) -> (UIBarButtonItem?, UIBarButtonItem?, Bool) in
                
                if editingAllowed
                {
                    return (nil, newButton, editingAllowed)
                }
                
                return (nil, nil, editingAllowed)
            }
            .observeOn(MainScheduler.instance).subscribe(
            onNext: { [weak self] (leftBarButtonItem, rightBarButtonItem, editingAllowed) in
                    
                guard let self = self else { return }
                
                self.navigationItem.leftBarButtonItem = leftBarButtonItem
                self.navigationItem.rightBarButtonItem = rightBarButtonItem
                
            }).disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func photoTaken(photo: UIImage)
    {
        guard let selectedSession = Api.sharedApi.selectedSession.value else { return }
        
        // TODO: think about disposable
        _ = selectedSession.rx.getDocument().subscribe(onNext:
        { selectedSessionSnapshot in
            
            guard selectedSessionSnapshot.exists else { return }
            
            let storage = Storage.storage()
            
            let name = "\(UUID().uuidString)"
            let imageName = "\(name).jpg"
            
            let path = "/sessions/\(selectedSession.documentID)/media/\(imageName)"
            
            guard let jpegData = photo.jpegData(compressionQuality: 1) else { return }
            
            // TODO: think about disposable
            storage.reference(withPath: path).rx.putData(jpegData).subscribe(
            onNext:
            { metadata in
                print(metadata)
                
                let db = Firestore.firestore()
                
                let batch = db.batch()
                
                let resourceRecordData = [ ResourceRecord.name : imageName,
                                           ResourceRecord.processed : false] as [String : Any]
                let resourceRecordRef = selectedSession.collection(Session.resources).document()
                
                let processingQueueRecordData = [ ProcessingQueue.imageMeta : resourceRecordRef,
                                                  ProcessingQueue.imagePath : path,
                                                  ProcessingQueue.session : selectedSession,
                                                  ProcessingQueue.active : false,
                                                  ProcessingQueue.lastUpdateTime : Timestamp.init() ] as [String : Any]
                let processingQueueRecordRef = db.collection("processingQueue").document()
                
                batch.setData(resourceRecordData, forDocument: resourceRecordRef)
                batch.setData(processingQueueRecordData, forDocument: processingQueueRecordRef)
                
                // TODO: think about disposable
                _ = batch.rx.commit().subscribe(
                onNext: { error in
                    print(error)
                    assertionFailure()
                })
            },
            onError:
            { error in
                print(error)
                assertionFailure()
            })
        })
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
