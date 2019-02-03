//
//  ViewController.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/01/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import FirebaseUI

import SwiftMessages

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func onPress(_ sender: Any)
    {
//        ref!.child("lastAccessTime").setValue("hi")
        
//        let db = Firestore.firestore()
        
        // Add a new document in collection "cities"
//        db.collection("cities")
//            .document("SF")
//            .rx
//            .setData([
//                "name": "San Francisco",
//                "state": "CA",
//                "country": "USA",
//                "capital": false,
//                "population": 860000
//                ]).subscribe(onError: { error in
//                    print("Error setting data: \(error)")
//                }).disposed(by: disposeBag)
        
//        let ref = Database.database().reference()
//
//        ref.child("users")
//            .child("1")
//            .rx
//            .setValue(["username": "Arnonymous"])
//            .subscribe(onNext: { _ in
//                print("Document successfully updated")
//            }).disposed(by: disposeBag)
        
        
        // Add a new document with a generated ID
//        var ref: DocumentReference? = nil
//        ref = db.collection("users").addDocument(data: [
//            "first": "Ada",
//            "last": "Lovelace",
//            "born": 1815
//        ]) { err in
//            if let err = err {
//                print("Error adding document: \(err)")
//            } else {
//                print("Document added with ID: \(ref!.documentID)")
//            }
//        }
        
//        ref = db.collection("users").document("helloGoodPath")
//
//        ref?.setData(["0" : 9955])
//
//        print(ref)
        
//        db.collection("").
        
        
        
        // Instantiate a message view from the provided card view layout. SwiftMessages searches for nib
        // files in the main bundle first, so you can easily copy them into your project and make changes.
        let view = MessageView.viewFromNib(layout: .messageView)
        
        // Theme message elements with the info style.
        view.configureTheme(.info)
        
        // Add a drop shadow.
        view.configureDropShadow()
        
        let instructress = UIImage(named: "Instructress")!
        let instructressScaled = UIImage(cgImage: instructress.cgImage!, scale: 10.0, orientation: instructress.imageOrientation)
        
//        view.configureContent(title: "Warning", body: "Consider yourself warned.", iconText:"🏫")
        view.configureContent(title: "Warning", body: "Consider yourself warned.", iconImage:instructressScaled)
        // Increase the external margin around the card. In general, the effect of this setting
        // depends on how the given layout is constrained to the layout margins.
        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Reduce the corner radius (applicable to layouts featuring rounded corners).
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 20
        
        view.buttonTapHandler = {(_ button: UIButton) -> Void in
            print(button)
        }
        
        // Show the message.
        SwiftMessages.show(view: view)
        
        
    }
    
}

