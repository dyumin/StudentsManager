//
//  AppDelegate.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/01/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import Firebase
import FirebaseUI
import GoogleSignIn

import SwiftMessages

import RxSwift
import RxCocoa

import RxFirebase

let CurrentUser = BehaviorRelay<User?>(value: nil)

// https://stackoverflow.com/questions/24402533/is-there-a-swift-alternative-for-nslogs-pretty-function
func pretty_function(_ file: String = #file, function: String = #function, line: Int = #line)
{
    let fileString: NSString = NSString(string: file)
    
    if Thread.isMainThread {
        print("file:\(fileString.lastPathComponent) function:\(function) line:\(line) [M]")
    } else {
        print("file:\(fileString.lastPathComponent) function:\(function) line:\(line) [T]")
    }
}




func show(messageText: String, theme: Theme)
{
    let view = MessageView.viewFromNib(layout: .statusLine)
    
    // Theme message elements with the info style.
    view.configureTheme(theme)
    
    // Add a drop shadow.
    view.configureDropShadow()
    
    view.configureContent(body: messageText)
    
    // Increase the external margin around the card. In general, the effect of this setting
    // depends on how the given layout is constrained to the layout margins.
    view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    
    // Reduce the corner radius (applicable to layouts featuring rounded corners).
    (view.backgroundView as? CornerRoundingView)?.cornerRadius = 20
    
    // Show the message.
    SwiftMessages.show(view: view)
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FUIAuthDelegate
{
    var window: UIWindow?
    
    weak var mainViewController : UIViewController?
    weak var loginViewController : UIViewController?
    weak var stubController : UIViewController?
    
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    let disposeBag = DisposeBag()
    
    var statusDisposable: Disposable?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        self.window?.makeKeyAndVisible()
        
        // empty placeholder controller
        window?.rootViewController = UIViewController()
        
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        FUIAuth.defaultAuthUI()!.delegate = self
        
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { auth, user in
            CurrentUser.accept(user)
        }
        

        Dependencies.sharedDependencies.reachabilityService.reachability.asObservable().debug().skip(1).observeOn(MainScheduler.instance).subscribe(
                onNext: { event in
            
                    switch (event)
                    {
                    case .reachable:
                        // It work half of the times
                        show(messageText: "Network online", theme: .success)
                        break
                    case .unreachable:
                        show(messageText: "Network offline", theme: .info)
                        break
                }
            }).disposed(by: disposeBag)
        
        // combineLatest reachability && CurrentUser
        Observable.combineLatest(Dependencies.sharedDependencies.reachabilityService.reachability.asObservable().skip(1), CurrentUser.asObservable().skip(1))
            .filter({
            !$0.0.reachable && $0.1 == nil
        })
            // TODO scheduler: MainScheduler.instance - I'm not sure about that
            .take(1).delay(1, scheduler: MainScheduler.instance).observeOn(MainScheduler.instance).debug("combineLatest reachability && CurrentUser").subscribe(
                onNext: { event in
                    show(messageText: "Network connection is required to login", theme: .info)
                }
            ).disposed(by: disposeBag)
        
        Observable.zip(CurrentUser.asObservable(), CurrentUser.asObservable().skip(1)).debug().subscribe(
            onNext: { [weak self] (old, new) in
                
                // nil -> value
                if (old == nil && new != nil)
                {
                    Api.configure()
                }
                
                self?.stateDidChanged(new)
                self?.updateRootViewController(user: new)
            }
        ).disposed(by: disposeBag)
        
        return true
    }
    
    func stateDidChanged(_ user: User?)
    {
        statusDisposable?.dispose()
        statusDisposable = nil
        
        if user != nil
        {
            statusDisposable =
                Observable.combineLatest(
                Api.sharedApi.userObservable,
                Observable.combineLatest(Api.sharedApi.ready.asObservable(),
                                         Dependencies.sharedDependencies.reachabilityService.reachability.asObservable()))
                .filter({
                        ($0.1.0 || !$0.1.1.reachable) && $0.0.data() != nil })
                .observeOn(MainScheduler.instance)
                .debug("combineLatest Api.sharedApi.userObservable && Api.sharedApi.ready").subscribe(
                onNext: { [weak self] event in
                    
                    let document = event.0
                                        
                    if let position = document.get("position") as? String, !position.isEmpty, position != UserAccountType.new.rawValue
                    {
                        self?.stubController?.view.removeFromSuperview()
                        self?.stubController?.removeFromParent()
                        print("Current user position: '\(position)'")
                    }
                    else
                    {
                        if (self?.stubController) != nil
                        {
                            
                        }
                        else
                        {
                            let stubController = AdminAprovalStub()
                            self!.stubController = stubController
                            
                            let root = self!.window!.rootViewController!
                            
                            root.addChild(stubController)
                            
                            root.view.frame = UIScreen.main.bounds
                            
                            root.view.addSubview(stubController.view)
                            
                            stubController.didMove(toParent: root)
                        }
                    }
                    
                })
        }
    }
    
    deinit
    {
        pretty_function()
        statusDisposable?.dispose()
        if let authStateDidChangeListenerHandle = authStateDidChangeListenerHandle
        {
            Auth.auth().removeStateDidChangeListener(authStateDidChangeListenerHandle)
        }
    }
    
    func updateRootViewController(user: User?)
    {
        if (user != nil)
        {
            loginViewController = nil

            if (mainViewController == nil)
            {
                mainViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
            }

            if (self.window?.rootViewController != mainViewController)
            {
                DispatchQueue.main.async(execute:
                {
                    show(messageText: user?.displayName ?? "Error Occured!", theme: .success)
                })

                self.window?.rootViewController = mainViewController
            }
        }
        else
        {
            mainViewController = nil
            
            if (loginViewController == nil)
            {
                let authUI = FUIAuth.defaultAuthUI()!
                let providers: [FUIAuthProvider] = [ FUIGoogleAuth() ]

                authUI.providers = providers
                authUI.shouldHideCancelButton = true

                loginViewController = authUI.authViewController()
            }
    
            if (self.window?.rootViewController != loginViewController)
            {
                self.window?.rootViewController = loginViewController
            }
        }
    }

    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?)
    {
        let successful = (error == nil)
        
        if (!successful)
        {
            show(messageText: "Failed to sign in, error: \(error.debugDescription)", theme: .error)
            
            return
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
    {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false
        {
            return true
        }
        
        // other URL handling goes here.
        return false
    }
}
