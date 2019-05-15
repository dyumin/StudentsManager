//
//  Api.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 23/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

import Firebase

import RxSwift
import RxCocoa
import RxFirebase

import PINCache
import SPTPersistentCache

class Api
{
    enum Errors: Error
    {
        case LifeTimeError
        case DataCorrupted
        case NotFound
    }
    
    
    static var sharedApi: Api
    {
        get
        {
            assert(_sharedApi != nil, "sharedApi called before configure()")
            return _sharedApi!
        }
    }
    
    private static var _sharedApi: Api? = nil
    
    static func configure()
    {
        _sharedApi = Api()
    }
    
    private var disposeBag = DisposeBag()
    
    let editingAllowed: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    // TODO: change to ReplaySubject(1) (no initial value) or use connect()
    let currentSessions: BehaviorRelay<[DocumentSnapshot]> = BehaviorRelay(value: [])
    
    let userObservable: Observable<DocumentSnapshot>
    
    let user: BehaviorRelay<DocumentSnapshot?> = BehaviorRelay(value: nil)

    let selectedSession: BehaviorRelay<DocumentReference?> = BehaviorRelay(value: nil)
    
    let ready = BehaviorRelay<Bool>(value: false)
    
    private init()
    {
        assert(Auth.auth().currentUser != nil, "Api called before auth completed")
        
        mediaObservablesCache = PINMemoryCache()
//        mediaObservablesCache.ageLimit = 10
//        mediaObservablesCache.isTTLCache = true
        
        mediaCache = PINMemoryCache.shared()
        
        let db = Firestore.firestore()
        userObservable = db.document("/users/\(Auth.auth().currentUser!.uid)").rx.listen()
        
        userObservable.takeUntil(.inclusive, predicate: { (event) -> Bool in
            event.exists
        }).debug("userObservable.takeUntil").subscribe(
            onNext: { [weak self] event in
                
                if !event.exists
                {
                    let currentUser = Auth.auth().currentUser!
                    self?.updateFBUserRecord(currentUser)
                }
                else
                {
                    self?.user.accept(event)
                    self?.onUserInitDone() // Bad smell, I know
                    self?.ready.accept(true)
                }

            }
        ).disposed(by: disposeBag)
 
#if DEBUG
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        Observable<Int>.interval(15, scheduler: MainScheduler.instance).subscribe(
            onNext: { [weak self] count in
                
                guard let self = self else { return }
                
                print("Api.mediaStatistics \(formatter.string(from: Date()))")
                print("\tdiskRequestsCount:", self.diskRequestsCount)
                print("\tdiskRead:", ByteCountFormatter().string(fromByteCount: self.diskBytesReadCount))
                
                print("\tserverRequestsCount:", self.serverRequestsCount)
                print("\tserverRead:", ByteCountFormatter().string(fromByteCount: self.serverBytesReadCount))
                
                var mediaObservablesCacheCount: Int64 = 0
                self.mediaObservablesCache.enumerateObjects(block:
                { (_, _, _) in
                    mediaObservablesCacheCount += 1
                })
                
                var mediaObservablesRetainingSubscriptionCacheCount: Int64 = 0
                self.mediaObservablesRetainingSubscriptionCache.enumerateObjects(block:
                    { (_, _, _) in
                        mediaObservablesRetainingSubscriptionCacheCount += 1
                })
                
                var mediaCacheCount: Int64 = 0
                self.mediaCache.enumerateObjects(block:
                    { (_, _, _) in
                        mediaCacheCount += 1
                })
                
                print("\tmediaCacheCount.count:", mediaCacheCount)
                print("\tmediaObservablesCache.count:", mediaObservablesCacheCount)
                print("\tmediaObservablesRetainingSubscriptionCache.count:", mediaObservablesRetainingSubscriptionCacheCount)
                
            }).disposed(by: disposeBag)
#endif
    }
    
    private func onUserInitDone()
    {
        let db = Firestore.firestore()
        
        userObservable.debug("userObservable").subscribe(
            onNext: { [weak self] event in
                
                if event.exists, let data = event.data()
                {
                    self?.editingAllowed.accept(UserAccountType.AccountTypesWithEditingPermissions.contains(data["position"] as! String))
                    
                    self?.user.accept(event)
                }
                else
                {
                    try! Auth.auth().signOut()
                }
            }
        ).disposed(by: disposeBag)
        
        user.debug("CurrentSession.selectedSession").map
        { user -> DocumentReference? in
            return user?.get(ApiUser.selectedSession) as? DocumentReference
        }
        .bind(to: selectedSession)
        .disposed(by: disposeBag)
        
        // TODO add or host back in whereField
        db.collection("sessions").whereField(Session.createdBy, isEqualTo: user.value!.reference).whereField(Session.active, isEqualTo: true).rx.listen()/*.debug("sessions -> currentSessions")*/.subscribe(
            onNext: { [weak self] event in
                
                for i in event.documents
                {
                    print(i.data())
                }
                
                self?.currentSessions.accept(event.documents)
            }
        ).disposed(by: disposeBag)
        
        // reference version
        // TODO add or host back in whereField
//        db.collection("sessions").whereField(Session.createdBy, isEqualTo: user.value!.reference).whereField(Session.active, isEqualTo: true).rx.listen().map(
//            { (querySnapshot) -> [DocumentReference] in
//
//                var currentSessions = Array<DocumentReference>()
//
//                querySnapshot.documents.forEach(
//                    { (queryDocumentSnapshot) in
//                        currentSessions.append(queryDocumentSnapshot.reference)
//                })
//
//                return currentSessions
//
//        }).debug("sessions -> currentSessions").bind(to: currentSessions).disposed(by: disposeBag)
    }
    
    deinit
    {
        pretty_function()
    }
    
    // TODO: rewrite on rx?
    private func updateFBUserRecord(_ currentUser : User)
    {
        let db = Firestore.firestore()
        
        let uid = currentUser.uid
        
        let user = db.document("/users/\(uid)")
        
        var userData : Dictionary =
            [ApiUser.displayName : currentUser.displayName as Any
                ,ApiUser.email   : currentUser.email as Any
        ]
        
        user.getDocument { (document, err) in
            if let document = document, document.exists
            {
                user.updateData(userData, completion: { error in
                    if let error = error
                    {
                        print(error)
                    }
                })
            }
            else
            {
                userData["position"] = UserAccountType.new.rawValue
                
                user.setData(userData, completion: { error in
                    if let error = error
                    {
                        print(error)
                        show(messageText: "Fatal error on accout creation, restart app", theme: .error)
                        
                        assertionFailure()
                    }
                })
            }
        }
    }
    
    
    // MARK: media

    private let mediaCache: PINMemoryCache
    private let persistentCache: SPTPersistentCache = Dependencies.sharedDependencies.cache
    private let mediaObservablesCache: PINMemoryCache
    private let mediaObservablesRetainingSubscriptionCache = PINMemoryCache()
#if DEBUG
    private let testSync = PINMemoryCache()
#endif
    // NOTE: keep if let checks in sync with userProfilePhoto func
    func prefetchUserProfilePhoto(for id: String)
    {
        let cachePhotoKey = Api.cachePhotoKey(for: id)
        
        // what if something inserts object in question just after?? (one more additional memory/disk (depends on observable implementation) read will occur below, or worse, network request)
        // hashtag: #2
        
        // if let image = mediaCache.object(forKey: cachePhotoKey) as? UIImage
        // swift compiler treats "as? UIImage" part as if it were a trailing closure!
        // so         mediaCache.object(forKey: <#T##String#>, block: <#T##PINMemoryCacheObjectBlock?##PINMemoryCacheObjectBlock?##(PINMemoryCache, String, Any?) -> Void#>) gets called
        // instead of mediaCache.object(forKey: <#T##String?#>), which even have different return types
        // omg, Apple
        
        if let image = mediaCache.object(forKey: cachePhotoKey), image is UIImage
        {
            return
        }
        else if let obj = mediaCache.object(forKey: cachePhotoKey), obj is NSNull
        {
            return
        }
        else if let imageObservable = mediaObservablesCache.object(forKey: cachePhotoKey), imageObservable is Observable<UIImage?>
        {
            return
        }
        
        _ = serverMediaRequest(for: id)
    }

    // NOTE: keep if let checks in sync with prefetchUserProfilePhoto func
    func userProfilePhoto(for id: String) -> Observable<UIImage?>
    {
        let cachePhotoKey = Api.cachePhotoKey(for: id)
        
        // what if something inserts object in question just after?? (one more additional memory/disk (depends on observable implementation) read will occur below, or worse, network request)
        // hashtag: #2
        
        // if let image = mediaCache.object(forKey: cachePhotoKey) as? UIImage
        // swift compiler treats "as? UIImage" part as if it were a trailing closure!
        // so         mediaCache.object(forKey: <#T##String#>, block: <#T##PINMemoryCacheObjectBlock?##PINMemoryCacheObjectBlock?##(PINMemoryCache, String, Any?) -> Void#>) gets called
        // instead of mediaCache.object(forKey: <#T##String?#>), which even have different return types
        // omg, Apple
        
        if let image = mediaCache.object(forKey: cachePhotoKey), image is UIImage
        {
            return Observable.just((image as! UIImage))
        }
        else if let obj = mediaCache.object(forKey: cachePhotoKey), obj is NSNull
        {
            return Observable.just(nil)
        }
        else if let imageObservable = mediaObservablesCache.object(forKey: cachePhotoKey), imageObservable is Observable<UIImage?>
        {
            print("Api reuse workingObservable for: \(cachePhotoKey)")
            return imageObservable as! Observable<UIImage?>
        }

        return serverMediaRequest(for: id)
    }
    
    private func serverMediaRequest(for id: String) -> Observable<UIImage?>
    {
        let cachePhotoKey = Api.cachePhotoKey(for: id)
#if DEBUG
        assert(!self.testSync.containsObject(forKey: cachePhotoKey))
        self.testSync.setObject(cachePhotoKey, forKey: cachePhotoKey, block: nil)
#endif
        let workingObservable = _serverMediaRequest(for: id)
        
        // subscribe immediately to keep observable "connected" to avoid creation of duplicate internal resources that compute sequence elements
        // since underlying sequence terminates in finite time, subscription will be completed automatically
        // but lets add it to dispose bag anyway
        // underlying sequence will clear this subscription itself on dispose (yep, it prob reminds you of of cyclic reference, but it's not)
        // TODO: think about autoconnect() operator
        let bag = DisposeBag()
        workingObservable.subscribe().disposed(by: bag)
        
        mediaObservablesCache.setObject(workingObservable, forKey: cachePhotoKey)
        
        mediaObservablesRetainingSubscriptionCache.setObject(bag, forKey: cachePhotoKey)
        
        return workingObservable
    }
    
    private func _serverMediaRequest(for id: String) -> Observable<UIImage?>
    {
        let cachePhotoKey = Api.cachePhotoKey(for: id)
        
        let workingObservable: Observable<UIImage?> = (Observable.create
        { [weak self] observer -> Disposable in
            
            var serverRequestDisposeBag: DisposeBag?
            let disposable = Disposables.create(with:
            {
                serverRequestDisposeBag = nil // drop server request if exists
                self?.mediaObservablesCache.removeObject(forKey: cachePhotoKey)
                self?.mediaObservablesRetainingSubscriptionCache.removeObject(forKey: cachePhotoKey)
            })
            
            guard let self = self else
            {
                let message = "Api.Error Cache lifetime failure"
                print(message)
                assertionFailure(message)
                
                observer.onError(Errors.LifeTimeError)
                return disposable
            }
            
            // TODO: do we need weak self below?
#if DEBUG
            if let image = self.mediaCache.object(forKey: cachePhotoKey), image is UIImage
            {
                let message = "Api.Error Caches synchronisation failure occurred"
                print(message)
                assertionFailure(message) // occured 3
                
                observer.onNext((image as! UIImage)) // force because of check in condition
                observer.onCompleted()
                
                return disposable
            }
#endif

            self.diskRequestsCount += 1
            self.persistentCache.loadData(forKey: cachePhotoKey, withCallback:
            { (persistentCacheResponse) in
                
                if persistentCacheResponse.result == .operationSucceeded
                    , let image = UIImage(data: persistentCacheResponse.record.data)
                {
                    // TODO: is a little bit inaccurate count, only data suitable for UIImage creation is counted
                    self.diskBytesReadCount += Int64(persistentCacheResponse.record.data.count)
                    
                    self.mediaCache.setObject(image, forKey: cachePhotoKey)
                    observer.onNext(image)
                    observer.onCompleted()
                }
                else // start server request
                {
                    self.serverRequestsCount += 1
                    
                    let serverPhotoPath = Api.serverPhotoPath(for: id)
                    let reference = Storage.storage().reference(withPath: serverPhotoPath).rx
                    serverRequestDisposeBag = DisposeBag()
                    
                    // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                    reference.getData(maxSize: 1 * 1024 * 1024).debug("Api.userProfilePhoto: \(serverPhotoPath)")
                    .subscribe(
                        onNext: { [weak self] data in
                            
                            self?.serverBytesReadCount += Int64(data.count)
                            
                            // TODO add caches synchronisation check?
                            guard let image = UIImage(data: data) else
                            {
                                observer.onError(Errors.DataCorrupted)
                                return
                            }
                            
                            observer.onNext(image)
                            observer.onCompleted()
                            
                            self?.mediaCache.setObject(image, forKey: cachePhotoKey)
                            self?.persistentCache.store(data, forKey: cachePhotoKey, locked: false, withCallback:
                                { (persistentCacheResponse) in
                                    
                                    print("Api.persistentCache.store got result: \(persistentCacheResponse.result.rawValue) for \(cachePhotoKey)")
                                    if persistentCacheResponse.result == .operationError
                                    {
                                        print("Api.persistentCache.store error: \(persistentCacheResponse.error)")
                                    }
                                    
                                    assert(persistentCacheResponse.result == .operationSucceeded, "Failed to store server request result")
                                    
                                }, on: DispatchQueue.global())
                            
                        },
                        onError: { error in
                            
                            if let error = error as? NSError, let code = error.userInfo["ResponseErrorCode"] as? Int
                            {
                                if code == 404 // not found on server
                                {
                                    // contextual type
                                    // let nilImage: UIImage? = nil
                                    self.mediaCache.setObject(NSNull(), forKey: cachePhotoKey)
                                }
                            }
                            
                            if !disposable.isDisposed
                            {
                                observer.onError(error)
                            }
                        },
                        onCompleted: {
                            if !disposable.isDisposed
                            {
                                observer.onCompleted()
                            }
                        }
                    ).disposed(by: serverRequestDisposeBag!)
                }
            }, on: DispatchQueue.global())
            return disposable
        }).share(replay: 1) // NOTE: BEWARE!, shared later from mediaObservablesCache until it is complete, think of it as some kind of singleton
        // Also, .forever SubjectLifetimeScope has some strange behaviour and it seems like generally is not recommended to use
        // https://github.com/ReactiveX/RxSwift/issues/1615
        
        return workingObservable
    }
        
    private static func serverPhotoPath(for id: String) -> String
    {
        return "/users/\(id)/datasetPhotos/\(id).jpg"
    }
    
    private static func cachePhotoKey(for id: String) -> String
    {
        return "\(id)_profilePhoto"
    }
    
    private var diskRequestsCount: Int64 = 0
    private var diskBytesReadCount: Int64 = 0
    
    private var serverRequestsCount: Int64 = 0
    private var serverBytesReadCount: Int64 = 0
    
    // MARK: data manipulation
    
    func remove(participants: [DocumentReference], from session: DocumentReference) -> Observable<Void>
    {
        guard participants.count != 0 else { return Observable.empty() }
        
        let sessionData = [ Session.participants : FieldValue.arrayRemove(participants) ]
                
        return session.rx.updateData(sessionData)
    }
    
    func remove(hosts: [DocumentReference], from session: DocumentSnapshot) -> Observable<Void>
    {
        guard hosts.count != 0 else { return Observable.empty() }
        
        assert(hosts.count < 2, "Multiple hosts not yet implemented")
        
        return session.reference.rx.updateData([Session.host : FieldValue.delete()])
    }
    
    func AddSessionPhoto(_ photo: UIImage, for session: DocumentReference)
    {
        // TODO: think about disposable
        _ = session.rx.getDocument().subscribe(
        onNext:
        { selectedSessionSnapshot in
                
            guard selectedSessionSnapshot.exists else { assertionFailure(); return }
            
            let resourceRecordRef = session.collection(Session.resources).document()
            
            let storage = Storage.storage()
            
            let imageName = "\(resourceRecordRef.documentID).jpg"
            
            let path = "/sessions/\(session.documentID)/media/\(imageName)"
            
            guard let jpegData = photo.jpegData(compressionQuality: 1) else { return }
            
            let storageMetadata = StorageMetadata()
            storageMetadata.contentType = "image/jpeg"
            // TODO: think about disposable
            _ = storage.reference(withPath: path).rx.putData(jpegData, metadata: storageMetadata).subscribe(
            onNext:
                { metadata in
                    print(metadata)
                    
                    let db = Firestore.firestore()
                    
                    let batch = db.batch()
                    
                    let resourceRecordData = [ ResourceRecord.imagePath : path,
                                               ResourceRecord.processed : false] as [String : Any]
                    
                    let processingQueueRecordData = [ ProcessingQueue.imageMeta : resourceRecordRef,
                                                      ProcessingQueue.imagePath : path,
                                                      ProcessingQueue.session : session,
                                                      ProcessingQueue.active : false,
                                                      ProcessingQueue.lastUpdateTime : Timestamp.init() ] as [String : Any]
                    let processingQueueRecordRef = db.collection("processingQueue").document()
                    
                    batch.setData(resourceRecordData, forDocument: resourceRecordRef)
                    batch.setData(processingQueueRecordData, forDocument: processingQueueRecordRef)
                    
                    // TODO: think about disposable
                    _ = batch.rx.commit().subscribe(
                        onError: { error in
                            print(error)
                            assertionFailure()
                    })
            },
            onError: { error in
                    print(error)
                    assertionFailure()
            })
        })
    }
}
