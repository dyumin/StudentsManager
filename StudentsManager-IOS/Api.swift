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

class Api
{
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
    
    let currentSessions: BehaviorRelay<[DocumentSnapshot]> = BehaviorRelay(value: [])
    
    let userObservable: Observable<DocumentSnapshot>
    
    let user: BehaviorRelay<DocumentSnapshot?> = BehaviorRelay(value: nil)
    
    let ready = BehaviorRelay<Bool>(value: false)
    
    private init()
    {
        assert(Auth.auth().currentUser != nil, "Api called before auth completed")
        
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
                    self?.onUserInitDone()
                    self?.ready.accept(true)
                }

            }
        ).disposed(by: disposeBag)
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
    
    // TODO: rewrite on rx using Api
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
}
