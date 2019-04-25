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
        
        userObservable.debug().takeUntil(.inclusive, predicate: { (event) -> Bool in
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
            }
        ).disposed(by: disposeBag)
    }
    
    private func onUserInitDone()
    {
        let db = Firestore.firestore()
        
        userObservable.debug().subscribe(
            onNext: { [weak self] event in
                
                if event.exists, let data = event.data()
                {
                    print(Api.self, "userObservable onNext", event, event.data() as Any)
                self?.editingAllowed.accept(UserAccountType.AccountTypesWithEditingPermissions.contains(data["position"] as! String))
                    
                    self?.user.accept(event)
                }
                else
                {
                    try! Auth.auth().signOut()
                }
            }
        ).disposed(by: disposeBag)
        
        db.collection("sessions").whereField("host", isEqualTo: user.value!.reference).whereField("active", isEqualTo: true).rx.listen().debug().subscribe(
            onNext: { [weak self] event in
                print(Api.self, "sessions onNext", event)
                for i in event.documents
                {
                    print(i.data())
                }
                
                self?.currentSessions.accept(event.documents)
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
