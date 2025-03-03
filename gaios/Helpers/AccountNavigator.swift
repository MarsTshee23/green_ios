import Foundation
import UIKit
import AsyncBluetooth

class AccountNavigator {

    @MainActor
    // open the account if just logged or redirect to login
    static func goLogin(account: Account) {
        let nv = UINavigationController()
        let vcHome: HomeViewController? = instantiateViewController(storyboard: "Home", identifier: "Home")
        let vcLogin: LoginViewController? = instantiateViewController(storyboard: "Home", identifier: "LoginViewController")
        let vcConnect: ConnectViewController? = instantiateViewController(storyboard: "HWFlow", identifier: "ConnectViewController")
        let vcWatch: WOLoginViewController? = instantiateViewController(storyboard: "WOFlow", identifier: "WOLoginViewController")

        // switch on selected active session
        if WalletsRepository.shared.get(for: account.id)?.activeSessions.isEmpty == false {
            goLogged(account: account)
            return
        } else if account.isDerivedLightning {
            vcLogin?.account = account
            nv.setViewControllers([vcHome!, vcLogin!], animated: true)
        } else if account.isHW {
            vcConnect?.account = account
            vcConnect?.bleViewModel = BleViewModel.shared
            vcConnect?.scanViewModel = ScanViewModel()
            nv.setViewControllers([vcHome!, vcConnect!], animated: true)
        } else if account.isWatchonly {
            vcWatch?.account = account
            nv.setViewControllers([vcHome!, vcWatch!], animated: true)
        } else {
            vcLogin?.account = account
            nv.setViewControllers([vcHome!, vcLogin!], animated: true)
        }
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = nv
    }

    @MainActor
    static func goLogged(account: Account) {
        AccountsRepository.shared.current = account
        Task {
            let isLightning = account.isDerivedLightning
            let accountViewModel = isLightning ? await accountViewModel(account: account) : nil
            let walletViewModel = !isLightning ? WalletViewModel() : nil
            await MainActor.run {
                if let vc: ContainerViewController = instantiateViewController(storyboard: "Wallet", identifier: "Container") {
                    vc.accountViewModel = accountViewModel
                    vc.walletViewModel = walletViewModel
                    let appDelegate = UIApplication.shared.delegate
                    appDelegate?.window??.rootViewController = vc
                    vc.stopLoader()
                }
            }
        }
    }

    @MainActor
    static func accountViewModel(account: Account) async -> AccountViewModel? {
        guard let session = WalletManager.current?.lightningSession else {
            return nil
        }
        guard let subaccount = try? await session.subaccount(0) else {
            return nil
        }
        let balance = try? await session.getBalance(subaccount: 0, numConfs: 0)
        let assetAmounts = AssetAmountList(balance ?? [:])
        let accountCellModel = AccountCellModel(account: subaccount, satoshi: balance?.first?.value ?? 0)
        let accountViewModel = AccountViewModel(model: accountCellModel, account: subaccount, cachedBalance: assetAmounts)
        return accountViewModel
    }

    @MainActor
    static func goLogout(account: Account?) {
        if let account = account {
            goLogin(account: account)
        } else {
            goHome()
        }
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.resolve2faOff()
        }
    }

    @MainActor
    static func goHome() {
        let nv = UINavigationController()
        let home: HomeViewController? = instantiateViewController(storyboard: "Home", identifier: "Home")
        nv.setViewControllers([home!], animated: true)
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = nv
    }

    @MainActor
    static func goFirstPage() {
        let nv = UINavigationController()
        if AccountsRepository.shared.accounts.isEmpty {
            let onboard: SelectOnBoardTypeViewController? = instantiateViewController(storyboard: "OnBoard", identifier: "SelectOnBoardTypeViewController")
            nv.setViewControllers([onboard!], animated: true)
        } else {
            let home: HomeViewController? = instantiateViewController(storyboard: "Home", identifier: "Home")
            nv.setViewControllers([home!], animated: true)
        }
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = nv
    }

    @MainActor
    static func goAddWallet(nv: UINavigationController?) -> UINavigationController {
        nv?.popToRootViewController(animated: false)
        nv?.dismiss(animated: false, completion: nil)
        let nv = nv ?? UINavigationController()
        let home: HomeViewController? = instantiateViewController(storyboard: "Home", identifier: "Home")
        let onboard: SelectOnBoardTypeViewController? = instantiateViewController(storyboard: "OnBoard", identifier: "SelectOnBoardTypeViewController")
        nv.setViewControllers([home!, onboard!], animated: true)
        return nv
    }

    static func instantiateViewController<K>(storyboard: String, identifier: String) -> K? {
        let storyboard = UIStoryboard(name: storyboard, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: identifier) as? K
    }
}
