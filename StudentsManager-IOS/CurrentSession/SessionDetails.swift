//
//  SessionDetails.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 18/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

import RxCocoa

import Firebase

class SessionDetails: UITableViewController
{
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var date: UIDatePicker!
    
    @IBOutlet weak var placeText: UITextField!
    
    var currentSessionSnapshot: DocumentSnapshot?
    {
        didSet
        {
            currentSessionReference = currentSessionSnapshot?.reference
        }
    }
    
    var currentSessionReference: DocumentReference?
    
    private var disposeBag = DisposeBag()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        fatalError("\(#function) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.hidesBottomBarWhenPushed = true;
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let currentSessionSnapshot = currentSessionSnapshot
        {
            let shared = currentSessionSnapshot.reference.rx.listen().share(replay: 1)
            
            shared.map
            {
                $0.get(Session.name) as? String
            }.filter
            { [weak self] in
                $0 != self?.nameText.text
            }.asDriver(onErrorJustReturn: nil)
                .drive(nameText.rx.text).disposed(by: disposeBag)
            
            shared.map
            { d -> Date in
                if let timestamp = d.get(Session.startTime) as? Timestamp
                {
                    return timestamp.dateValue()
                }
                return Date.init()
            }.filter
            { [weak self] in
                $0 != self?.date?.date
            }.asDriver(onErrorJustReturn: Date.init())
                .drive(date.rx.date).disposed(by: disposeBag)
            
            shared.map
            {
                $0.get(Session.room) as? String
            }.filter
            { [weak self] in
                $0 != self?.placeText.text
            }.asDriver(onErrorJustReturn: nil)
                .drive(placeText.rx.text).disposed(by: disposeBag)
        }
        else
        {
            let db = Firestore.firestore()
            
            let currentSessionReference = db.collection("sessions").document()
            self.currentSessionReference = currentSessionReference
            
            _ = currentSessionReference.rx.setData(
                [Session.createdBy : Api.sharedApi.user.value!.reference,
                 Session.startTime : Timestamp.init()], merge: true).subscribe()
            
            _ = Api.sharedApi.setSelectedSession(currentSessionReference).subscribe()
            
            self.navigationItem.title = "New event"
            self.navigationItem.setHidesBackButton(true, animated: true)
            
        }
        
        let doneButton = UIBarButtonItem()
        doneButton.title = "Done"
        doneButton.rx.tap.subscribe(onNext:
        { [weak self] in
            
            self?.navigationController?.popViewController(animated: true)
                
        }).disposed(by: disposeBag)
        
        self.navigationItem.rightBarButtonItem = doneButton
        
        nameText.rx.text.orEmpty.skip(1).throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] event in
                
                _ = self?.currentSessionReference?.rx.updateData([Session.name : event]).subscribe()
                
            }).disposed(by: disposeBag)
        
        date.rx.date.skip(1).throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] event in
                
                _ = self?.currentSessionReference?.rx.updateData([Session.startTime : Timestamp.init(date: event)]).subscribe()
                
            }).disposed(by: disposeBag)
        
        placeText.rx.text.orEmpty.skip(1).throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] event in
                
                _ = self?.currentSessionReference?.rx.updateData([Session.room : event]).subscribe()
                
            }).disposed(by: disposeBag)
    }
}
