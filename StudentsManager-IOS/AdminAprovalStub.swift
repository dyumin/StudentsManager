//
//  AdminAprovalStub.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 21/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit
import Firebase

class AdminAprovalStub: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    deinit
    {
        pretty_function()
    }

    @IBAction func onLogoutPressed(_ sender: Any)
    {
        try! Auth.auth().signOut()
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
