//
//  CurrentSession.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 18/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

class CurrentSession: UIViewController
{
    @IBOutlet weak var tableView: UITableView!
    
    let viewModel: CurrentSessionModel = CurrentSessionModel()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // tableView.register(CurrentSessionEventCell.self, forCellReuseIdentifier: CurrentSessionEventCell.identifier) // Todo: why this one not working?
        
        tableView.register(UINib(nibName: CurrentSessionEventCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionEventCell.identifier)
        
        tableView.register(UINib(nibName: CurrentSessionTutorCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionTutorCell.identifier)
        
        tableView.dataSource = viewModel

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
