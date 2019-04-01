//
//  Main.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 04/02/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit
import Firebase
import SwiftMessages



class Main: UIViewController
{
    @IBAction func onLogout(_ sender: UIButton)
    {
        try! Auth.auth().signOut()
    }
    
    @IBAction func testPressed(_ sender: Any)
    {
        let db = Firestore.firestore()
        
        let uid = Auth.auth().currentUser?.uid

        let user = db.document("/users/\(uid!)")
        
        user.getDocument { (document, err) in
            if let document = document, document.exists
            {
                let groupField = document.get("group")!
                
                let schedulesCol = db.collection("/schedules")
                
                schedulesCol.whereField("group", isEqualTo: groupField).getDocuments { (querySnapshot, err) in
                    if let err = err
                    {
                        print(err)
                        assert(false)
                    }
                    else if let querySnapshot = querySnapshot
                    {
                        assert(querySnapshot.count == 1)
                        
                        let scheduleCol = querySnapshot.documents.first!.reference.collection("schedule")
                            .whereField("normalizedDay", isEqualTo: "monday").getDocuments { (querySnapshot, err) in
                           
                            assert(querySnapshot!.count == 1)
                            
                            print(querySnapshot!.documents.first!.data())
                        
                            
                                
                                let scheduleCol = querySnapshot!.documents.first!.reference.collection("schedule")
                                    .whereField("normalizedDay", isEqualTo: "monday").getDocuments { (querySnapshot, err) in
                                        
                                        assert(querySnapshot!.count == 1)
                                        
                                        print(querySnapshot!.documents.first!.data())
                                        
                                        
                                }
                        }
                    }
                }
            }
            else
            {
                if let err = err
                {
                    print(err)
                    
                }
                assert(false)
            }
        }
        
       
        
//
        
//        schedules.child("schedules")
//            .queryOrderedByChild("value")
//            .queryEqual(toValue: "def")
//            .observeSingleEvent(of: .value, with: {(snapshot) in
//                print(snapshot) })
        
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        performSegue(withIdentifier: "showMainTabBar", sender: self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
//        onLogout(UIButton())
        
        
//        showMessage("AAAA")
//
//        let db = Firestore.firestore()
//        
//        // Create a reference to the cities collection
//        let users = db.collection("users")
//
//        let uid = Auth.auth().currentUser?.uid
//
//        let user = users.document("\(uid)")
//
//        user.getDocument { (document, error) in
//            if let document = document, document.exists {
//                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                print("Document data: \(dataDescription)")
//            } else {
//                print("Document does not exist")
//            }
//        }

        // Do any additional setup after loading the view.
    }
    
    func showMessage(_ text : String)
    {
        let view = MessageView.viewFromNib(layout: .statusLine)
        
        // Theme message elements with the info style.
        view.configureTheme(.success)
        
        // Add a drop shadow.
        view.configureDropShadow()
        
        view.configureContent(body: text)
        
        // Increase the external margin around the card. In general, the effect of this setting
        // depends on how the given layout is constrained to the layout margins.
        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Reduce the corner radius (applicable to layouts featuring rounded corners).
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 20
        
        // Show the message.
        SwiftMessages.show(view: view)
    }
    
    deinit
    {
        print("Main deinit")
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
