//
//  CurrentSession.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 18/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

import Firebase

class CurrentSession: UIViewController
{
    @IBOutlet weak var tableView: UITableView!
    {
        didSet
        {
            self.viewModel.partialUpdatesTableViewOutlet = tableView
        }
    }
    
    var viewModel = CurrentSessionModel(CurrentSessionModel.Mode.CurrentSession)
    
    private var disposeBag = DisposeBag()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        fatalError("\(#function) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        Api.sharedApi.user.debug("CurrentSession.selectedSession").subscribe(
            onNext: { [weak self] event in
            
            let selectedSession = event?.get(ApiUser.selectedSession) as? DocumentReference
            
            self?.viewModel.currentSession = selectedSession
            
        }).disposed(by: disposeBag)
    }
    
    deinit
    {
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
