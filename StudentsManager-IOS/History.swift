//
//  History.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 18/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

import RxCocoa

import Firebase

class History: UIViewController
{
    let disposeBag = DisposeBag()
    
    private let viewModel = HistoryViewModel()
    
    private let DefaultNavItemTitle = "History"
    
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        fatalError("\(#function) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        let logOutButton = UIBarButtonItem()
        logOutButton.title = "Log Out"
        logOutButton.rx.tap.subscribe(onNext:
        {
            try? Auth.auth().signOut()
        }).disposed(by: disposeBag)
        
        self.navigationItem.rightBarButtonItem = logOutButton
        navigationItem.title = DefaultNavItemTitle
        
        viewModel.owner = self
        
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
}
