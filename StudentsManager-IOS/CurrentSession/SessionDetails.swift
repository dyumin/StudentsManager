//
//  SessionDetails.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 18/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

class SessionDetails: UITableViewController
{
    
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var date: UIDatePicker!
    
    @IBOutlet weak var placeText: UITextField!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.hidesBottomBarWhenPushed = true;

        // Do any additional setup after loading the view.
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
