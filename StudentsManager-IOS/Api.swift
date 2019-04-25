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
            return _sharedApi
        }
    }
    
    private static var _sharedApi = Api()
    
    static func reset()
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
            !event.exists
        }).subscribe(
            onNext: { [weak self] event in
                print(Api.self, "userObservable.takeUntil onNext", event, event.data() as Any)
                
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
            },
            onError: { error in
                print(Api.self, "userObservable.takeUntil onError", error)
                assertionFailure()
            },
            onCompleted: {
                print(Api.self, "userObservable.takeUntil onCompleted")
                
            },
            onDisposed: {
                print(Api.self, "userObservable.takeUntil onDisposed")
            }
        ).disposed(by: disposeBag)
    }
    
    private func onUserInitDone()
    {
        let db = Firestore.firestore()
        
        userObservable.subscribe(
            onNext: { [weak self] event in
                if let data = event.data()
                {
                    print(Api.self, "userObservable onNext", event, event.data() as Any)
                self?.editingAllowed.accept(UserAccountType.AccountTypesWithEditingPermissions.contains(data["position"] as! String))
                    
                    self?.user.accept(event)
                }
                else
                {
                    try! Auth.auth().signOut()
                }
            },
            onError: { error in
                print(Api.self, "userObservable onError", error)
                assertionFailure()
            },
            onCompleted: {
                print(Api.self, "userObservable onCompleted")
                
            },
            onDisposed: {
                print(Api.self, "userObservable onDisposed")
            }
        ).disposed(by: disposeBag)
        
        db.collection("sessions").whereField("host", isEqualTo: user.value!.reference).whereField("active", isEqualTo: true).rx.listen().subscribe(
            onNext: { [weak self] event in
                print(Api.self, "sessions onNext", event)
                for i in event.documents
                {
                    print(i.data())
                }
                
                self?.currentSessions.accept(event.documents)
            },
            onError: { error in
                print(Api.self, "sessions onError", error)
                assertionFailure()
            },
            onCompleted: {
                print(Api.self, "sessions onCompleted")
            },
            onDisposed: {
                print(Api.self, "sessions onDisposed")
            }
        ).disposed(by: disposeBag)
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
            ["displayName" : currentUser.displayName as Any
                ,"email"       : currentUser.email as Any
        ]
        
        user.getDocument { (document, err) in
            if let document = document, document.exists
            {
                user.updateData(userData, completion: { error in
                    if let error = error
                    {
                        print(error)
                        
                        // updateData usually only fails when there is no such document
                        // steps to reproduce:
                        // disable phone internet connection -> open app (updateData block will be added to queue) -> delete user account record on server -> enable phone internet connection
                        // "onDisposed, combineLatest db.collection(\"users\").document(\"\\(user.uid)\") && BackEndIsReady" will handle this
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
                        assertionFailure()
                        
                        show(messageText: "Fatal error on accout creation, restart app", theme: .error)
                    }
                })
            }
        }
    }
}
