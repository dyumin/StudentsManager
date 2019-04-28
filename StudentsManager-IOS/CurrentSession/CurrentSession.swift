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
    {
        didSet
        {
            if let tableView = tableView
            {
                // tableView.register(CurrentSessionEventCell.self, forCellReuseIdentifier: CurrentSessionEventCell.identifier) // Todo: why does this one not working?
                
                tableView.register(UINib(nibName: CurrentSessionEventCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionEventCell.identifier)
                
                tableView.register(UINib(nibName: CurrentSessionTutorCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionTutorCell.identifier)
                
                tableView.register(UINib(nibName: CurrentSessionNewEventCell.identifier, bundle: nil), forCellReuseIdentifier: CurrentSessionNewEventCell.identifier)
            }
            
            viewModel.partialUpdatesTableViewOutlet = tableView
        }
    }
    
    let viewModel = CurrentSessionModel()
    
    // viewDidLoad is called twice, be aware...
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        pretty_function()
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
