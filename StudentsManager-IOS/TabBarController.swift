//
//  TabBarController.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 17/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit


class TabBarController: UITabBarController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let _ = Api.sharedApi.editingAllowed.value
    }
    
    deinit
    {
        pretty_function()
    }
}
