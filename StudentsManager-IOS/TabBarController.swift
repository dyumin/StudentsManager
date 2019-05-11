//
//  TabBarController.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 17/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

class TabBarController: UITabBarController
{
//    var initialViewControllers: [UIViewController]?
    
//    var disposeBag: DisposeBag?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
//        if initialViewControllers == nil {
//            initialViewControllers = viewControllers
//        }
//
//        let disposeBag = DisposeBag()
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
