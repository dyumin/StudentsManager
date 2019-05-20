//
//  CurrentSession.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 18/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

import RxCocoa

import Firebase


class CurrentSession: UIViewController
{
    // I do expect that at least  this setter will be called once (viewDidLoad called twice)
    @IBOutlet weak var tableView: UITableView!
    {
        didSet
        {
            self.viewModel.partialUpdatesTableViewOutlet = tableView
            
            if #available(iOS 11.0, *)
            {
                tableView.rx.contentOffset.asDriver()
                .drive(
                onNext:{ [weak self] _ in
                    
                    guard let self = self, let searchBar = self.navigationItem.searchController?.searchBar else { return }
                    
                    if searchBar.isFirstResponder
                    {
                        _ = searchBar.resignFirstResponder()
                    }
                    
                }).disposed(by: disposeBag)
            }
        }
    }
    
    private let DefaultNavItemTitle = "Current Event"

    // viewDidLoad is called twice, be aware...
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    let viewModel = CurrentSessionModel()
    
    private var disposeBag = DisposeBag()
    
    private static let EditingAnimationDuration: TimeInterval = 0.3
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        fatalError("\(#function) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        viewModel.owner = self
        
        Api.sharedApi.selectedSession.subscribe(
        onNext: { [weak self] event in
            
            self?.viewModel.currentSession = event
                
        }).disposed(by: disposeBag)
        
        let newButton = UIBarButtonItem()
        newButton.title = "New"
        newButton.rx.tap.subscribe(onNext:
        { [weak self] in
            
            guard let sessionDetails = UIStoryboard(name: "SessionDetails", bundle: Bundle.main).instantiateInitialViewController() as? SessionDetails else { return }
            
            self?.navigationController?.pushViewController(sessionDetails, animated: true)
                
        }).disposed(by: disposeBag)
        
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
        
        navigationItem.title = DefaultNavItemTitle
        
        if #available(iOS 11.0, *)
        {
            let searchController = UISearchController(searchResultsController: nil)
            
            // https://www.raywenderlich.com/472-uisearchcontroller-tutorial-getting-started
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.placeholder = "Search Attendees"
            definesPresentationContext = true
            
            let searchQueryRetranslator = BehaviorRelay<String?>(value: "")
            
            searchController.searchBar.rx.text/*.throttle(0.3, scheduler: MainScheduler.instance)*/.distinctUntilChanged()
                .bind(to: searchQueryRetranslator).disposed(by: disposeBag)
            
            searchController.searchBar.rx.textDidBeginEditing.asObservable()
            .filter({ searchQueryRetranslator.value == nil })
            .map({ "" }).bind(to: searchQueryRetranslator).disposed(by: disposeBag)
            
            let anyEditingEvent = Observable.merge(
                searchController.searchBar.rx.textDidBeginEditing.asObservable(),
                searchController.searchBar.rx.textDidEndEditing.asObservable().filter(
                {
                    searchController.searchBar.isFirstResponder
                }))
            
            Observable.combineLatest(
            searchQueryRetranslator,
            anyEditingEvent)
                .subscribe(
            onNext: { [weak self] event in
                
                var finalQuery: String? = nil
                
                if !searchController.searchBar.isFirstResponder && event.0?.isEmpty ?? false
                {}
                else
                {
                    finalQuery = event.0
                }
                self?.viewModel.searchQuery.accept(finalQuery)
                
            }).disposed(by: disposeBag)
            
            // searchBar.text does not updated to nil (empty) if searchBar.resignFirstResponder() were called (keyboard is hidden) and user presses Cancel button
            searchController.searchBar.rx.cancelButtonClicked
            .subscribe(
            onNext: { [weak self] _ in
                    
                if let searchQuery = self?.viewModel.searchQuery.value
                {
                    searchQueryRetranslator.accept(nil)
                }
                    
            }).disposed(by: disposeBag)
            
            navigationItem.searchController = searchController
        }
    }
    
    // toolbar and his friend dispose bag for polling sequence, since Apple, apparently, does not want us to be able to obtain selected rows in any appropriate way
    private weak var toolbar: UIToolbar?
    private var toolbarDisposable: DisposeBag?
    
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
                    searchBar.alpha = editing ? 0.6 : 1
                }
            }
            else
            {
                searchBar.alpha = editing ? 0.6 : 1
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
                let toolbarDisposable = DisposeBag()
                
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
                let delete = UIBarButtonItem(title: "Delete", style: UIBarButtonItem.Style.done, target: nil, action: nil)
                
                delete.rx.tap.subscribe(
                onNext: { [weak self] event in
                    
                    self?.viewModel.deleteCurrentlySelectedRows()
                    
                    DispatchQueue.main.async
                    {
                        self?.setEditing(false, animated: true)
                    }
                        
                }).disposed(by: toolbarDisposable)
                
                toolbar.items = [flexibleSpace, flexibleSpace, delete]
                
                // TODO: background scheduler?
                // we can use didSelectRowAt/didDeselectRowAt magic in UITableViewDataSource, but there are too much edge cases
                
                var previousSelectedRowsValue = self.tableView.indexPathsForSelectedRows
                delete.isEnabled = false
                
                Observable<Int64>.interval(0.1, scheduler: MainScheduler.instance)/*.debug("indexPathsForSelectedRows")*/.subscribe(
                onNext: { [weak self] _ in
                    
                    guard let self = self else { return }
                    
                    let indexPathsForSelectedRows = self.tableView.indexPathsForSelectedRows
                    if indexPathsForSelectedRows == previousSelectedRowsValue
                    {
                        return
                    }
                    
                    previousSelectedRowsValue = indexPathsForSelectedRows
                    
                    if let indexPathsForSelectedRows = indexPathsForSelectedRows
                    {
                        let selectedRowsCount = indexPathsForSelectedRows.count
                        let pluralisation = selectedRowsCount == 1 ? "" : "s"
                        
                        self.navigationItem.title = "\(selectedRowsCount) Participant\(pluralisation) Selected"
                        delete.isEnabled = true
                    }
                    else
                    {
                        self.navigationItem.title = self.DefaultNavItemTitle
                        delete.isEnabled = false
                    }
                    
                },
                onDisposed: { [weak self] in
                    self?.navigationItem.title = self?.DefaultNavItemTitle
                }).disposed(by: toolbarDisposable)
                
                
                tabBarController.view.addSubview(toolbar)
                self.toolbar = toolbar
                self.toolbarDisposable = toolbarDisposable
                
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
            toolbarDisposable = nil
            
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
