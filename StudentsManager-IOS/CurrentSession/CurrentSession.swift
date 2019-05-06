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

    // viewDidLoad is called twice, be aware...
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        navigationItem.title = "Current Event"
        
        if #available(iOS 11.0, *)
        {
            let searchController = UISearchController(searchResultsController: nil)
            navigationItem.searchController = searchController
        }
    }
    
    var viewModel = CurrentSessionModel(CurrentSessionModel.Mode.CurrentSession)
    
    private var disposeBag = DisposeBag()
    
    private static let EditingAnimationDuration: TimeInterval = 0.3
    
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
        
        let newButton = UIBarButtonItem()
        newButton.title = "New"
        
        Api.sharedApi.editingAllowed.distinctUntilChanged().map
        { [weak self] (editingAllowed) -> (UIBarButtonItem?, UIBarButtonItem?, Bool) in
            
            if editingAllowed
            {
                return (self?.editButtonItem, newButton, editingAllowed)
            }
            
            return (nil, nil, editingAllowed)
        }
        .observeOn(MainScheduler.instance).subscribe(
        onNext: { [weak self] (leftBarButtonItem, rightBarButtonItem, editingAllowed) in
            
            guard let self = self else { return }
            
            self.navigationItem.leftBarButtonItem = leftBarButtonItem
            self.navigationItem.rightBarButtonItem = rightBarButtonItem
            
            if self.isEditing && !editingAllowed
            {
                self.setEditing(false, animated: true)
            }
                
        }).disposed(by: disposeBag)
    }
    
    private weak var toolbar: UIToolbar?
    
    override func setEditing(_ editing: Bool, animated: Bool)
    {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
        
        // probably it's time for animation group in code below
        
        if #available(iOS 11.0, *), let searchBar = navigationItem.searchController?.searchBar
        {
            searchBar.isUserInteractionEnabled = !editing
            
            if (animated)
            {
                UIView.animate(withDuration: CurrentSession.EditingAnimationDuration)
                {
                    searchBar.alpha = editing ? 0.7 : 1
                }
            }
            else
            {
                searchBar.alpha = editing ? 0.7 : 1
            }
        }
        
        if editing
        {
            if toolbar != nil
            {
                assertionFailure("setEditing: true called multiply times")
            }
            else if let tabBarController = self.tabBarController
            {
                let toolbar = UIToolbar(frame: tabBarController.tabBar.frame)
                
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
                let delete = UIBarButtonItem(title: "Delete", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
                
                toolbar.items = [flexibleSpace, flexibleSpace, delete]
                
                tabBarController.view.addSubview(toolbar)
                
                self.toolbar = toolbar
                
                if animated
                {
                    toolbar.alpha = 0
                    UIView.animate(withDuration: CurrentSession.EditingAnimationDuration)
                    {
                        toolbar.alpha = 1
                    }
                }
            }
        }
        else
        {
            if let toolbar = self.toolbar
            {
                self.toolbar = nil
                
                if animated
                {
                    UIView.animate(withDuration: CurrentSession.EditingAnimationDuration, animations:
                    {
                        toolbar.alpha = 0
                    })
                    { _ in
                        toolbar.removeFromSuperview()
                    }
                }
                else
                {
                    toolbar.removeFromSuperview()
                }
            }
        }
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
