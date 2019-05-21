//
//  TabBarController.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 17/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

import Firebase

class TabBarController: UITabBarController
{
//    var initialViewControllers: [UIViewController]?
    
    var disposeBag: DisposeBag?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let disposeBag = DisposeBag()
        
        Api.sharedApi.user.map(
        { (documentSnapshot) -> Bool in
            
            return documentSnapshot?.get(ApiUser.selectedSession) as? DocumentReference != nil
            
        }).debug("CurrentSession.selectedSession").subscribe(
            onNext: { [weak self] event in
            
            self?.viewControllers?.first?.tabBarItem.isEnabled = event
            
        }).disposed(by: disposeBag)
        
        Api.sharedApi.selectedSession.observeOn(MainScheduler.instance).subscribe(
        onNext: { [weak self] event in
            
            let eventDoesNotExist = event == nil
            
            self?.viewControllers?.first?.tabBarItem.isEnabled = eventDoesNotExist ? false : true
            
            if eventDoesNotExist && self?.selectedIndex == 0
            {
                self?.selectedIndex = 1
            }
                
        }).disposed(by: disposeBag)
        
        self.disposeBag = disposeBag
        
//        if initialViewControllers == nil {
//            initialViewControllers = viewControllers
//        }
//
//        Api.sharedApi.editingAllowed.distinctUntilChanged().subscribe(
//        onNext:{ [weak self] (editingAllowed) in
//
//            guard let self = self else { return }
//
//            if editingAllowed
//            {
//                self.setViewControllers(self.initialViewControllers, animated: true)
//            }
//            else
//            {
//                let viewControllers = self.initialViewControllers?.filter(
//                { (viewController) -> Bool in
//
//                    if let viewController = viewController as? EditingRequirementsProvider
//                    {
//                        return !viewController.isEditingRightsNeeded()
//                    }
//
//                    return true
//                })
//
//               self.setViewControllers(viewControllers, animated: true)
//            }
//
//        }).disposed(by: disposeBag)
//
//        self.disposeBag = disposeBag
    }
    
    deinit
    {
        pretty_function()
    }
}
