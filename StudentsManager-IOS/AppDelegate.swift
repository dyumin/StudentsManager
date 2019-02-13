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

func UpdateFBUserRecord(_ auth : Auth)
{
    let db = Firestore.firestore()
    
    let userDB = db.document("users/\(auth.currentUser!.uid)")
    
    userDB.updateData(
        ["displayName" : auth.currentUser?.displayName as Any
        ,"email" : auth.currentUser?.email as Any
//        ,"email" : auth.currentUser?.email as Any
        ]
    )
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FUIAuthDelegate
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        FUIAuth.defaultAuthUI()!.delegate = self
        
        Auth.auth().addStateDidChangeListener { [unowned self] (auth, user) in
            
            if (auth.currentUser != nil)
            {
                let rootController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
                self.window?.rootViewController = rootController
                
                self.showCurrentUserMessage()
                
                DispatchQueue.main.async(execute:
                {
                    UpdateFBUserRecord(auth)
                })
            }
            else
            {
                let authUI = FUIAuth.defaultAuthUI()!
                let providers: [FUIAuthProvider] = [ FUIGoogleAuth() ]
                
                authUI.providers = providers
                authUI.shouldHideCancelButton = true
                
                let authViewController = authUI.authViewController()
                
                self.window?.rootViewController = authViewController
            }
        }
        
        return true
    }

    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?)
    {
        let successful = (error == nil);
        
        if (!successful)
        {
            let view = MessageView.viewFromNib(layout: .statusLine)
            
            // Theme message elements with the info style.
            view.configureTheme(.error)
            
            // Add a drop shadow.
            view.configureDropShadow()
            
            view.configureContent(body: "Failed to sign in, error: \(error.debugDescription)")
            
            // Increase the external margin around the card. In general, the effect of this setting
            // depends on how the given layout is constrained to the layout margins.
            view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            
            // Reduce the corner radius (applicable to layouts featuring rounded corners).
            (view.backgroundView as? CornerRoundingView)?.cornerRadius = 20
            
            // Show the message.
            SwiftMessages.show(view: view)
        }
    }
    
    func showCurrentUserMessage()
    {
        let view = MessageView.viewFromNib(layout: .statusLine)
        
        // Theme message elements with the info style.
        view.configureTheme(.success)
        
        // Add a drop shadow.
        view.configureDropShadow()
        
        view.configureContent(body: "User: \(Auth.auth().currentUser?.displayName ?? "Error Occured!")")
        
        // Increase the external margin around the card. In general, the effect of this setting
        // depends on how the given layout is constrained to the layout margins.
        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Reduce the corner radius (applicable to layouts featuring rounded corners).
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 20
        
        // Show the message.
        SwiftMessages.show(view: view)
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

