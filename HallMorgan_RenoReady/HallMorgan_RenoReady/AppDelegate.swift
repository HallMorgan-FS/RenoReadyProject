//
//  AppDelegate.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/22/23.
//

import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //Change navigation bar color
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .darkBrown
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.cremeWhite]
            appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.cremeWhite]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().barTintColor = .darkBrown
            UINavigationBar.appearance().isTranslucent = false
            UINavigationBar.appearance().tintColor = UIColor.cremeWhite
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.cremeWhite]
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.userDidLogout), name: .didLogout, object: nil)

        FirebaseApp.configure()

        return true
    }
    
    @objc func userDidLogout(_ notification: NSNotification){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        window?.rootViewController = loginViewController
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

