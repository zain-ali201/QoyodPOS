//
//  AppDelegate.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 31/08/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import CoreData
import Reachability
import Bugsnag
//Test Commit
enum PaperSizeIndex: Int {
    case twoInch = 384
}

var rootVC:UITabBarController?

var languageCode:String!
var languageBundle : Bundle?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //star io properties
    var portName:     String!
    var portSettings: String!
    var modelName:    String!
    var macAddress:   String!
    
    var emulation:                StarIoExtEmulation!
    var cashDrawerOpenActiveHigh: Bool!
    var allReceiptsSettings:      Int!
    var selectedIndex:            Int!
    var selectedPaperSize:        Int?
    var selectedModelIndex:       Int?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        languageCode = UserDefaults.standard.string(forKey: "language")
        
        if languageCode == nil || languageCode.isEmpty
        {
            languageCode = Locale.current.languageCode
            if languageCode == "ar"
            {
                UserDefaults.standard.set("ar", forKey: "language")
            }
            else
            {
                UserDefaults.standard.set("en", forKey: "language")
            }
        }
        
        language()
        
        print("LanguageCode: \(languageCode)")
        API.environment = NetworkConfig.environment
        if let token = UserDefaults.standard.string(forKey: UserDefaults.Key.token) , let orgId =  UserDefaults.standard.string(forKey: UserDefaults.Key.identifier){
            API.environment?.params["auth_token"] = token
            API.environment?.params["identifier"] = orgId
        }
        
        if !UserDefaults.standard.bool(forKey: UserDefaults.Key.isLoggedIn) {
            // show login
            showLogin()
        }
        else
        {
            let vc = window?.rootViewController as! UITabBarController
            rootVC = vc
            vc.selectedIndex = 1
        }
        
        //to monitor network
        startMonitoringReachability()
        
        //star io
        self.loadParam()
        self.selectedIndex = 1
        
        //bigsnag init
        Bugsnag.start(withApiKey: "0fc6c1ef54dc0b861f88a7b2953380dd")
    
        return true
    }
    
    func language()
    {
        let languageCode = UserDefaults.standard
        if UserDefaults.standard.value(forKey: "language") != nil {
            let language = languageCode.string(forKey: "language")!
            if let path  = Bundle.main.path(forResource: language, ofType: "lproj") {
                languageBundle =  Bundle(path: path)
            }
            else{
                languageBundle = Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)
            }
        }
        else
        {
            languageCode.set("en", forKey: "language")
            languageCode.synchronize()
            let language = languageCode.string(forKey: "language")!
            if let path  = Bundle.main.path(forResource: language, ofType: "lproj") {
                languageBundle =  Bundle(path: path)
            }
            else{
                languageBundle = Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)
            }
        }
    }

    private func showLogin()
    {
        let vc = UIStoryboard.onboarding.instantiateInitialViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }
    
    private func showPincode() {
        let vc = UIStoryboard.onboarding.instantiateViewController(withIdentifier: "pincode")
        rootVC?.present(vc, animated: false, completion: nil)
    }
    
    private func lockApp() {
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.isLoggedIn) {
           UserDefaults.standard.set(true, forKey: UserDefaults.Key.isLocked)
           UserDefaults.standard.synchronize()
        }
    }
    
    private func startMonitoringReachability() {
        Reachability.startMonitoring()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        lockApp()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        lockApp()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.isLocked) {
            //LOCK THE APP
            showPincode()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        lockApp()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Qoyod_point_of_sale")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    static let settingManager = SettingManager()
    
    static func isSystemVersionEqualTo(_ version: String) -> Bool {
        return UIDevice.current.systemVersion.compare(version, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedSame
    }
    
    static func isSystemVersionGreaterThan(_ version: String) -> Bool {
        return UIDevice.current.systemVersion.compare(version, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedDescending
    }
    
    static func isSystemVersionGreaterThanOrEqualTo(_ version: String) -> Bool {
        return UIDevice.current.systemVersion.compare(version, options: NSString.CompareOptions.numeric) != ComparisonResult.orderedAscending
    }
    
    static func isSystemVersionLessThan(_ version: String) -> Bool {
        return UIDevice.current.systemVersion.compare(version, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedAscending
    }
    
    static func isSystemVersionLessThanOrEqualTo(_ version: String) -> Bool {
        return UIDevice.current.systemVersion.compare(version, options: NSString.CompareOptions.numeric) != ComparisonResult.orderedDescending
    }
    
    static func isIPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
    }
    
    static func isIPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    fileprivate func loadParam() {
        AppDelegate.settingManager.load()
    }
    
    static func getPortName() -> String {
        return settingManager.settings[0]?.portName ?? ""
    }
    
    static func setPortName(_ portName: String) {
        settingManager.settings[0]?.portName = portName
        settingManager.save()
    }
    
    static func getPortSettings() -> String {
        return settingManager.settings[0]?.portSettings ?? ""
    }
    
    static func setPortSettings(_ portSettings: String) {
        settingManager.settings[0]?.portSettings = portSettings
        settingManager.save()
    }
    
    static func getModelName() -> String {
        return settingManager.settings[0]?.modelName ?? ""
    }
    
    static func setModelName(_ modelName: String) {
        settingManager.settings[0]?.modelName = modelName
        settingManager.save()
    }
    
    static func getMacAddress() -> String {
        return settingManager.settings[0]?.macAddress ?? ""
    }
    
    static func setMacAddress(_ macAddress: String) {
        settingManager.settings[0]?.macAddress = macAddress
        settingManager.save()
    }
    
    static func getEmulation() -> StarIoExtEmulation {
        return settingManager.settings[0]?.emulation ?? .starPRNT
    }
    
    static func setEmulation(_ emulation: StarIoExtEmulation) {
        settingManager.settings[0]?.emulation = emulation
        settingManager.save()
    }
    
    static func getCashDrawerOpenActiveHigh() -> Bool {
        return settingManager.settings[0]?.cashDrawerOpenActiveHigh ?? true
    }
    
    static func setCashDrawerOpenActiveHigh(_ activeHigh: Bool) {
        settingManager.settings[0]?.cashDrawerOpenActiveHigh = activeHigh
        settingManager.save()
    }
    
    static func getAllReceiptsSettings() -> Int {
        return settingManager.settings[0]?.allReceiptsSettings ?? 0x07
    }
    
    static func setAllReceiptsSettings(_ allReceiptsSettings: Int) {
        settingManager.settings[0]?.allReceiptsSettings = allReceiptsSettings
        settingManager.save()
    }
    
    static func getSelectedIndex() -> Int {
        let delegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        return delegate.selectedIndex!
    }
    
    static func setSelectedIndex(_ index: Int) {
        let delegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        delegate.selectedIndex = index
    }
    
    static func getSelectedPaperSize() -> PaperSizeIndex {
        return .twoInch
    }
    
    static func getSelectedModelIndex() -> ModelIndex? {
        return AppDelegate.settingManager.settings.first??.selectedModelIndex
    }
    
    static func setSelectedModelIndex(_ modelIndex: ModelIndex?) {
        settingManager.settings[0]?.selectedModelIndex = modelIndex ?? .none
        settingManager.save()
    }
}

func verifyProduct(product: Product) -> Bool
{
    var flag = false
    
    if product.type == "Product" || product.type == "Recipe"
    {
        flag = product.track_quantity
    }
    else if product.type == "Service"
    {
        flag = false
    }
    
    return flag
}
