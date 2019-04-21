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
let BackEndIsReady = BehaviorRelay<Bool>(value: false)

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

func updateFBUserRecord(_ currentUser : User)
{
    let db = Firestore.firestore()
    
    let uid = currentUser.uid
    
    let user = db.document("/users/\(uid)")
    
    var userData : Dictionary =
        ["displayName" : currentUser.displayName as Any
        ,"email"       : currentUser.email as Any
    ]
    
    user.getDocument { (document, err) in
        if let document = document, document.exists
        {
            user.updateData(userData, completion: { error in
                if let error = error
                {
                    print(error)
                    
                    // updateData usually only fails when there is no such document
                    // steps to reproduce:
                    // disable phone internet connection -> open app (updateData block will be added to queue) -> delete user account record on server -> enable phone internet connection
                    // "onDisposed, combineLatest db.collection(\"users\").document(\"\\(user.uid)\") && BackEndIsReady" will handle this
                }

                BackEndIsReady.accept(true)
            })
        }
        else
        {
            userData["position"] = UserAccountType.new.rawValue
            
            user.setData(userData, completion: { error in
                if let error = error
                {
                    print(error)
                    assertionFailure()
                    
                    show(messageText: "Fatal error on accout creation, restart app", theme: .error)
                }
                else
                {
                    BackEndIsReady.accept(true)
                }
            })
        }
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
    
    let bag = DisposeBag()
    
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
        
        CurrentUser.asObservable().skip(1).subscribe(onNext: { [weak self] userEvent in
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let userEvent = userEvent
                {
                    updateFBUserRecord(userEvent)
                }
            }

            self?.updateRootViewController(user: userEvent)
            
        }).disposed(by: bag)
        
        Dependencies.sharedDependencies.reachabilityService.reachability.asObservable().skip(1).observeOn(MainScheduler.instance).subscribe(onNext: { event in
            
            switch (event)
            {
            case .reachable:
                show(messageText: "Network online", theme: .success)
                break
            case .unreachable:
                show(messageText: "Network offline", theme: .info)
                break
            }
            
            print(event)
            
        }, onDisposed: {
            pretty_function()
        }).disposed(by: bag)
        
        // combineLatest reachability && CurrentUser
        Observable.combineLatest(Dependencies.sharedDependencies.reachabilityService.reachability.asObservable().skip(1), CurrentUser.asObservable().skip(1))
            .filter({
            !$0.0.reachable && $0.1 == nil
        })
            // TODO scheduler: MainScheduler.instance - I'm not sure about that
            .take(1).delay(1, scheduler: MainScheduler.instance).observeOn(MainScheduler.instance).subscribe(
                onNext: { event in
            show(messageText: "Network connection is required to login", theme: .info)
            },
                onError: { print("onError: \($0), combineLatest reachability && CurrentUser") },
                onCompleted: { print("onCompleted, combineLatest reachability && CurrentUser") },
                onDisposed: { print("onDisposed, combineLatest reachability && CurrentUser") }
        ).disposed(by: bag)
        
        CurrentUser.asObservable().skip(1).subscribe(onNext: { [weak self] event in
            self?.stateDidChanged(event)
        }).disposed(by: bag)
        
        return true
    }
    
    func stateDidChanged(_ user: User?)
    {
        statusDisposable?.dispose()
        statusDisposable = nil
        
        if let user = user
        {
            let db = Firestore.firestore()
            statusDisposable =
                
                Observable.combineLatest(
                db.collection("users").document("\(user.uid)").rx.listen(),
                Observable.combineLatest(BackEndIsReady.asObservable(),
                                         Dependencies.sharedDependencies.reachabilityService.reachability.asObservable()))
                .filter({
                        ($0.1.0 || !$0.1.1.reachable) })
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] event in
                    
                    let document = event.0
                    
                    print("Current data: \(document.data())")
                    
                    if (document.data() == nil)
                    {
                        print("User account was removed from server! Logout...")
                        try? Auth.auth().signOut()
                        return
                    }
                    
                    if let position = document.get("position") as? String, !position.isEmpty, position != UserAccountType.new.rawValue
                    {
                        self?.stubController?.view.removeFromSuperview()
                        self?.stubController?.removeFromParent()
                        print("Current user position: '\(position)'")
                    }
                    else
                    {
                        if let stubController = self?.stubController
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
                    
                }, onError: { error in
                    print("Error fetching snapshots: \(error)")
                    assertionFailure()
                },
                   onCompleted: { print("onCompleted, combineLatest db.collection(\"users\").document(\"\\(user.uid)\") && BackEndIsReady") },
                   onDisposed: {
                    print("onDisposed, combineLatest db.collection(\"users\").document(\"\\(user.uid)\") && BackEndIsReady")
                    BackEndIsReady.accept(false)
                })
        }
    }
    
    deinit
    {
        statusDisposable?.dispose()
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
