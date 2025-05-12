//
//  AppDelegate.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//

import UIKit
import CoreData
import CommonCollection

var applicationName      : String = ""
var applicationVersion   : String = ""
let applicationCopyright : String = "© Ingenieurbüro Halbritter 2025"


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        /// App-Informationen auslesen
        let dictionary = Bundle.main.infoDictionary!
        applicationName    = dictionary["CFBundleName"] as! String
        applicationVersion = dictionary["CFBundleShortVersionString"] as! String
        
        /// Textfarben der Controls werden über die Appearance gesetzt.
        UITextField .appearance().textColor = .systemBlue
        UITextView  .appearance().textColor = .label
        UIDatePicker.appearance().tintColor = .systemBlue
        
        /// PersistentContainer laden. Der Name der Applikation MUSS mit dem Namen des Models übereinstimmen!
        Persistence.shared = Persistence(appName: applicationName, appVersion: applicationVersion,
                                         appCopyright: applicationCopyright, inMemory: false, useUndo: false)
        _ = Persistence.shared.persistentContainer
        
        /// In einem neuen Projekt macht es Sinn, eine Reihe von Entities zu Testzwecken anzulegen.
        if Settings.fetch(context: Persistence.shared.persistentContainer.viewContext).isEmpty {
            typealias M = Markdown
            
            let settings = Settings(context: Persistence.shared.persistentContainer.viewContext)
            settings.textSizeView       = M.textSize
            settings.textSizePDF        = M.PDF.textSize
            settings.headIndent         = M.headIndent
            settings.tailIndent         = M.tailIndent
            settings.lineHeightMultiple = M.lineHeightMultiple
            
            Persistence.shared.saveContext()
        }
        
        return true
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

