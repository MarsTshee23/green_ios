import UIKit
import PromiseKit
import RxBluetoothKit

func getAppDelegate() -> AppDelegate? {
    return UIApplication.shared.delegate as? AppDelegate
}

func getNetwork() -> String {
    AccountsManager.shared.current?.network ?? "mainnet"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var navigateWindow: UIWindow?

    func instantiateViewControllerAsRoot(storyboard: String, identifier: String) {
        let storyboard = UIStoryboard(name: storyboard, bundle: nil)
        let firstVC = storyboard.instantiateViewController(withIdentifier: identifier)
        window?.rootViewController?.navigationController?.popToRootViewController(animated: true)
        window?.rootViewController?.dismiss(animated: false, completion: nil)
        window?.rootViewController = firstVC
        window?.makeKeyAndVisible()
    }

    func logout(with pin: Bool) {
        let account = AccountsManager.shared.current
        if let account = account {
            WalletManager.delete(for: account.id)
        }
        if account?.isWatchonly ?? false {
            let homeS = UIStoryboard(name: "Home", bundle: nil)
            let onBoardS = UIStoryboard(name: "OnBoard", bundle: nil)
            if let nav = homeS.instantiateViewController(withIdentifier: "HomeViewController") as? UINavigationController,
                let vc = onBoardS.instantiateViewController(withIdentifier: "WatchOnlyLoginViewController") as? WatchOnlyLoginViewController {
                    vc.account = AccountsManager.shared.current
                    nav.pushViewController(vc, animated: false)
                    UIApplication.shared.keyWindow?.rootViewController = nav
//                    nav.pushViewController(vc, animated: false)
            }
        } else if account?.isHW ?? false {
            let homeS = UIStoryboard(name: "Home", bundle: nil)
            let hwwS = UIStoryboard(name: "HWW", bundle: nil)
            if let nav = homeS.instantiateViewController(withIdentifier: "HomeViewController") as? UINavigationController,
                let vc = hwwS.instantiateViewController(withIdentifier: "HWWScanViewController") as? HWWScanViewController {
                    vc.jade = AccountsManager.shared.current?.isJade == true
                    nav.pushViewController(vc, animated: false)
                    UIApplication.shared.keyWindow?.rootViewController = nav
//                    nav.pushViewController(vc, animated: false)
            }
        } else {
            let homeS = UIStoryboard(name: "Home", bundle: nil)
            if let nav = homeS.instantiateViewController(withIdentifier: "HomeViewController") as? UINavigationController,
                let vc = homeS.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                vc.account = AccountsManager.shared.current
                nav.pushViewController(vc, animated: false)
                UIApplication.shared.keyWindow?.rootViewController = nav
//                nav.pushViewController(vc, animated: false)
            }
        }
    }

    func setupAppearance() {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor.customTitaniumDark()
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            appearance.shadowImage = UIImage.imageWithColor(color: UIColor.customTitaniumDark())
            appearance.backgroundImage = UIImage()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().isTranslucent = false
        }
        UINavigationBar.appearance().barTintColor = UIColor.customTitaniumDark()
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UINavigationBar.appearance().isTranslucent = false
        UITextField.appearance().keyboardAppearance = .dark
        UITextField.appearance().tintColor = UIColor.customMatrixGreen()
        // To hide the bottom line of the navigation bar.
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        // Hide the top line of the tab bar
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupAppearance()

        // Load custom window to handle touches event
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.endEditing(true)

        // Initialize gdk and accounts
        try! gdkinitialize()
        MigratorManager.shared.migrate()

        // Set screen lock
        instantiateViewControllerAsRoot(storyboard: "Home", identifier: "HomeViewController")
        ScreenLockWindow.shared.setup()
        ScreenLocker.shared.startObserving()

        #if targetEnvironment(simulator)
        // Disable hardware keyboards.
        let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
        UITextInputMode.activeInputModes
            .filter({ $0.responds(to: setHardwareLayout) })
            .forEach { $0.perform(setHardwareLayout, with: nil) }
        #endif

        AnalyticsManager.shared.countlyStart()
        applicationWillEnterForeground(application)

        return true
    }

    func gdkinitialize() throws {
        let params = GdkInit.defaults()
        // check gdk datadir migration
        if !UserDefaults.standard.bool(forKey: "AppDataDir") {
            // move cache dir to the app support
            let url = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
            if let atPath = url?.path, let toPath = params.datadir,
                FileManager.default.fileExists(atPath: atPath) {
                let files = try FileManager.default.contentsOfDirectory(atPath: atPath)
                files.forEach { file in
                    try? FileManager.default.moveItem(atPath: "\(atPath)/\(file)", toPath: "\(toPath)/\(file)")
                }
            }
            UserDefaults.standard.set(true, forKey: "AppDataDir")
        }
        #if DEBUG
        let datadir = try? FileManager.default.contentsOfDirectory(atPath: params.datadir ?? "")
        print("gdk datadir:", (datadir ?? []).map { $0 })
        #endif
        try gdkInit(config: params.toDict() ?? [:])
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        WalletManager.wallets.forEach { _, wm in
            wm.pause()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        WalletManager.wallets.forEach { _, wm in
            wm.resume()
        }
        AnalyticsManager.shared.setupSession(session: WalletManager.current?.prominentSession?.session)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        ScreenLocker.shared.stopObserving()
    }

}
