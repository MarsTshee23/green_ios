import Foundation
import UIKit
import PromiseKit
import gdk
import greenaddress

class LoginViewController: UIViewController {

    @IBOutlet weak var cardEnterPin: UIView!
    @IBOutlet weak var cardWalletLock: UIView!

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var attempts: UILabel!
    @IBOutlet weak var connectionSettingsButton: UIButton!
    @IBOutlet weak var emergencyButton: UIButton!
    @IBOutlet weak var attemptsView: UIView!
    @IBOutlet weak var attemptsBg: UIView!

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet var keyButton: [UIButton]?
    @IBOutlet var pinLabel: [UILabel]?
    let menuButton = UIButton(type: .system)

    @IBOutlet weak var lblWalletLockHint1: UILabel!
    @IBOutlet weak var lblWalletLockHint2: UILabel!
    @IBOutlet weak var btnWalletLock: UIButton!

    @IBOutlet weak var alertCard: UIView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertHint: UILabel!
    @IBOutlet weak var alertIconWarn: UIImageView!
    @IBOutlet weak var alertBtnDismiss: UIButton!
    @IBOutlet weak var alertBtnRight: UIButton!
    @IBOutlet weak var alertBtnsContainer: UIView!

    private var remoteAlert: RemoteAlert?

    var account: Account!

    private var session: SessionManager?
    private var pinCode = ""
    private let MAXATTEMPTS = 3
    private var emergencyRestore = false {
        didSet {
            emergencyButton.isHidden = !emergencyRestore
        }
    }

    @IBOutlet weak var passphraseView: UIStackView!
    @IBOutlet weak var lblPassphrase: UILabel!

    var bip39passphare: String? {
        didSet {
            passphraseView.isHidden = bip39passphare?.isEmpty ?? true
        }
    }

    var alwaysAsk: Bool = false

    private var networkSettings: [String: Any] {
        get {
            UserDefaults.standard.value(forKey: "network_settings") as? [String: Any] ?? [:]
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = account.name
        navigationItem.setHidesBackButton(true, animated: false)

        let ntwBtn = UIButton(type: .system)
        let img = UIImage(named: account.gdkNetwork?.mainnet == true ? "ic_wallet" : "ic_wallet_testnet")!.maskWithColor(color: .white)
        ntwBtn.setImage(img, for: .normal)
        ntwBtn.imageView?.contentMode = .scaleAspectFit
        ntwBtn.addTarget(self, action: #selector(LoginViewController.back), for: .touchUpInside)
        ntwBtn.contentEdgeInsets = UIEdgeInsets(top: 9, left: -10, bottom: 9, right: 0)
        navigationItem.leftBarButtonItems =
            [UIBarButtonItem(image: UIImage.init(named: "backarrow2"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(LoginViewController.back)),
             UIBarButtonItem(customView: ntwBtn)
            ]
        menuButton.setImage(UIImage(named: "ellipses"), for: .normal)
        menuButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: menuButton)
        passphraseView.isHidden = true

        menuButton.contentEdgeInsets = UIEdgeInsets(top: 7.0, left: 7.0, bottom: 7.0, right: 7.0)
        setContent()
        setStyle()

        alertCard.isHidden = true
        self.remoteAlert = RemoteAlertManager.shared.alerts(screen: .login, networks: [NetworkSecurityCase(rawValue: account.networkName) ?? .bitcoinSS]).first
        if remoteAlert != nil {
            alertCard.isHidden = false
            alertTitle.text = remoteAlert?.title
            alertHint.text = remoteAlert?.message
            alertTitle.isHidden = remoteAlert?.title?.isEmpty ?? true
            alertHint.isHidden = remoteAlert?.message?.isEmpty ?? true
            alertIconWarn.isHidden = !(remoteAlert?.isWarning ?? false)
            alertBtnRight.setTitle(NSLocalizedString("id_learn_more", comment: ""), for: .normal)
            alertBtnDismiss.isHidden = !(remoteAlert?.dismissable ?? false)
            alertBtnsContainer.isHidden = true
            if remoteAlert?.link != nil {
                if URL(string: remoteAlert?.link ?? "") != nil {
                    alertBtnsContainer.isHidden = false
                }
            }
        }

        view.accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.view
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.backBtn
        menuButton.accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.menuBtn
        keyButton![0].accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.btn1
        keyButton![1].accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.btn2
        keyButton![2].accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.btn3
        attempts.accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.attemptsLbl
        connectionSettingsButton.accessibilityIdentifier = AccessibilityIdentifiers.LoginScreen.settingsBtn

        AnalyticsManager.shared.recordView(.login, sgmt: AnalyticsManager.shared.sessSgmt(AccountsRepository.shared.current))
    }

    func setContent() {
        lblTitle.text = NSLocalizedString("id_enter_pin", comment: "")
        lblWalletLockHint1.text = NSLocalizedString("id_youve_entered_an_invalid_pin", comment: "") + "\n" + NSLocalizedString("id_youll_need_your_recovery_phrase", comment: "")
        lblWalletLockHint2.isHidden = true
        btnWalletLock.setTitle(NSLocalizedString("id_restore_with_recovery_phrase", comment: ""), for: .normal)
        connectionSettingsButton.setTitle(NSLocalizedString("id_app_settings", comment: ""), for: .normal)
        cancelButton.setTitle(NSLocalizedString("id_cancel", comment: ""), for: .normal)
        lblPassphrase.text = NSLocalizedString("id_bip39_passphrase_login", comment: "")
        emergencyButton.setTitle("id_emergency_recovery_phrase".localized, for: .normal)
    }

    func setStyle() {
        btnWalletLock.setStyle(.primary)
        alertCard.layer.cornerRadius = 6.0
        attemptsBg.layer.cornerRadius = 5.0
        emergencyButton.setTitleColor(.white, for: .normal)
        emergencyButton.borderWidth = 1.0
        emergencyButton.borderColor = .white.withAlphaComponent(0.5)
        emergencyButton.setImage(UIImage(named: "ic_x_circle")!.maskWithColor(color: .white), for: .normal)
        emergencyButton.cornerRadius = 5.0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenLocker.shared.stopObserving()
        NotificationCenter.default.addObserver(self, selector: #selector(progress), name: NSNotification.Name(rawValue: EventType.Tor.rawValue), object: nil)

        cancelButton.addTarget(self, action: #selector(click(sender:)), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(click(sender:)), for: .touchUpInside)
        for button in keyButton!.enumerated() {
            button.element.addTarget(self, action: #selector(keyClick(sender:)), for: .touchUpInside)
        }
        updateAttemptsLabel()
        reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if account.askEphemeral ?? false {
            loginWithPassphrase(isAlwaysAsk: account.askEphemeral ?? false)
        } else if account.hasBioPin {
            loginWithPin(usingAuth: .AuthKeyBiometric, withPIN: nil, bip39passphrase: nil)
        }
        if account?.attempts == self.MAXATTEMPTS  || account?.hasPin == false {
            showLock()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ScreenLocker.shared.startObserving()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: EventType.Tor.rawValue), object: nil)

        cancelButton.removeTarget(self, action: #selector(click(sender:)), for: .touchUpInside)
        deleteButton.removeTarget(self, action: #selector(click(sender:)), for: .touchUpInside)
        for button in keyButton!.enumerated() {
            button.element.removeTarget(self, action: #selector(keyClick(sender:)), for: .touchUpInside)
        }
    }

    @objc func menuButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogListViewController") as? DialogListViewController {

            vc.viewModel = DialogListViewModel(title: "More Options", type: .loginPrefs, items: LoginPrefs.getItems(isWatchOnly: false))
            vc.delegate = self
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }

    @objc func progress(_ notification: NSNotification) {
        if let json = try? JSONSerialization.data(withJSONObject: notification.userInfo!, options: []),
           let tor = try? JSONDecoder().decode(TorNotification.self, from: json),
           self.session != nil {
            var text = NSLocalizedString("id_tor_status", comment: "") + " \(tor.progress)%"
            if tor.progress == 100 {
                text = NSLocalizedString("id_logging_in", comment: "")
            }
            DispatchQueue.main.async {
                self.startLoader(message: text)
            }
        }
    }

    fileprivate func decryptMnemonic(usingAuth: AuthenticationTypeHandler.AuthType, withPIN: String?, bip39passphrase: String?) {
        let bgq = DispatchQueue.global(qos: .background)
        let session = SessionManager(account.gdkNetwork!)
        self.session = session
        firstly {
            self.startLoader(message: NSLocalizedString("id_logging_in", comment: ""))
            return Guarantee()
        }.then(on: bgq) {
            session.connect()
        }.compactMap {
            try self.account.auth(usingAuth)
        }.compactMap {
            DecryptWithPinParams(pin: withPIN ?? "", pinData: $0)
        }.then(on: bgq) {
            session.decryptWithPin($0)
        }.ensure {
            self.stopLoader()
        }.done { credentials in
            let storyboard = UIStoryboard(name: "UserSettings", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ShowMnemonicsViewController") as? ShowMnemonicsViewController {
                vc.credentials = credentials
                self.navigationController?.pushViewController(vc, animated: true)
            }
            self.pinCode = ""
            self.reload()
        }.catch { err in
            self.errorLogin(error: err)
        }
    }

    fileprivate func loginWithPin(usingAuth: AuthenticationTypeHandler.AuthType, withPIN: String?, bip39passphrase: String?) {
        let bgq = DispatchQueue.global(qos: .background)
        let wm = WalletsRepository.shared.getOrAdd(for: account)
        self.session = wm.prominentSession
        firstly {
            return Guarantee()
        }.compactMap {
            try self.account.auth(usingAuth)
        }.get { _ in
            self.startLoader(message: NSLocalizedString("id_logging_in", comment: ""))
        }.then(on: bgq) { pinData -> Promise<Void> in
            let pin = withPIN ?? pinData.plaintextBiometric ?? ""
            return wm.loginWithPin(pin: pin, pinData: pinData, bip39passphrase: bip39passphrase)
        }.get { _ in
            self.startLoader(message: NSLocalizedString("id_loading_wallet", comment: ""))
        }.done { _ in
            if withPIN != nil {
                self.account.attempts = 0
            }
            AnalyticsManager.shared.loginWallet(loginType: (withPIN != nil ? .pin : .biometrics),
                                                ephemeralBip39: self.account.isEphemeral,
                                                account: self.account)
            _ = AccountNavigator.goLogged(account: self.account, nv: self.navigationController)
            self.stopLoader()
        }.catch { error in
            self.errorLogin(error: error)
        }
    }

    func errorLogin(error: Error) {
        var prettyError = "id_login_failed"
        self.stopLoader()
        switch error {
        case AuthenticationTypeHandler.AuthError.CanceledByUser:
            return
        case AuthenticationTypeHandler.AuthError.SecurityError, AuthenticationTypeHandler.AuthError.KeychainError:
            return self.onBioAuthError(error.localizedDescription)
        case LoginError.connectionFailed:
            prettyError = "id_connection_failed"
            DropAlert().error(message: NSLocalizedString(prettyError, comment: ""))
        case LoginError.walletNotFound:
            prettyError = "id_wallet_not_found"
            DropAlert().error(message: NSLocalizedString(prettyError, comment: ""))
        case GaError.NotAuthorizedError(_):
            self.wrongPin()
            prettyError = "NotAuthorizedError"
        case TwoFactorCallError.failure(let localizedDescription):
            if localizedDescription.contains("login failed") || localizedDescription.contains("id_invalid_pin") {
                prettyError = "id_invalid_pin"
                self.wrongPin()
            } else {
                DropAlert().error(message: NSLocalizedString(prettyError, comment: ""))
            }
        default:
            DropAlert().error(message: NSLocalizedString(prettyError, comment: ""))
        }
        self.pinCode = ""
        self.reload()
        AnalyticsManager.shared.failedWalletLogin(account: self.account, error: error, prettyError: prettyError)
    }

    @IBAction func emergencyClick(_ sender: Any) {
        emergencyRestore = false
    }

    func wrongPin() {
        account?.attempts += 1
        AccountsRepository.shared.upsert(account)
        if account?.attempts == self.MAXATTEMPTS {
            WalletsRepository.shared.delete(for: account)
            showLock()
        } else {
            self.pinCode = ""
            self.updateAttemptsLabel()
            self.reload()
        }
    }

    func onBioAuthError(_ message: String) {
        let text = String(format: NSLocalizedString("id_syou_need_ton1_reset_greens", comment: ""), message)
        let alert = UIAlertController(title: NSLocalizedString("id_warning", comment: ""), message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("id_cancel", comment: ""), style: .default) { _ in })
        alert.addAction(UIAlertAction(title: NSLocalizedString("id_reset", comment: ""), style: .destructive) { _ in
            self.account?.removeBioKeychainData()
        })
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    func showLock() {
        cardEnterPin.isHidden = true
        lblTitle.isHidden = true
        cardWalletLock.isHidden = false
    }

    func updateAttemptsLabel() {
        let pinattempts = account?.attempts ?? 0
        if pinattempts == MAXATTEMPTS {
            showLock()
        } else if MAXATTEMPTS - pinattempts == 1 {
            attempts.text = NSLocalizedString("id_last_attempt_if_failed_you_will", comment: "")
        } else {
            attempts.text = String(format: NSLocalizedString("id_attempts_remaining_d", comment: ""), MAXATTEMPTS - pinattempts)
        }
        attempts.isHidden = pinattempts == 0
        attemptsView.isHidden = pinattempts == 0
    }

    @objc func keyClick(sender: UIButton) {
        pinCode += (sender.titleLabel?.text)!
        reload()
        guard pinCode.count == 6 else {
            return
        }
        if emergencyRestore {
            decryptMnemonic(usingAuth: .AuthKeyPIN,
                            withPIN: pinCode,
                            bip39passphrase: bip39passphare)
            return
        }
        loginWithPin(usingAuth: .AuthKeyPIN,
                     withPIN: pinCode,
                     bip39passphrase: bip39passphare)
    }

    func reload() {
        pinLabel?.enumerated().forEach {(index, label) in
            if index < pinCode.count {
                label.textColor = UIColor.customMatrixGreen()
            } else {
                label.textColor = UIColor.black
            }
        }
    }

    @objc func back(sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    @objc func click(sender: UIButton) {
        if sender == deleteButton {
            if pinCode.count > 0 {
                pinCode.removeLast()
            }
        } else if sender == cancelButton {
            pinCode = ""
        }
        reload()
    }

    func walletDelete() {
        let storyboard = UIStoryboard(name: "Shared", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogWalletDeleteViewController") as? DialogWalletDeleteViewController {
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            present(vc, animated: false, completion: nil)
        }
    }

    func walletRename() {
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogRenameViewController") as? DialogRenameViewController {
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.index = nil
            vc.prefill = account.name
            present(vc, animated: false, completion: nil)
        }
    }

    func showEmergencyDialog() {
        let alert = UIAlertController(title: NSLocalizedString("Emergency Recovery Phrase Restore", comment: ""),
                                      message: NSLocalizedString("If for any reason you can't login into your wallet, you can recover your recovery phrase using your PIN/Biometrics.", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("id_cancel", comment: ""), style: .cancel) { (_: UIAlertAction) in })
        alert.addAction(UIAlertAction(title: NSLocalizedString("id_ok", comment: ""), style: .default) { (_: UIAlertAction) in
            self.emergencyRestore = true
        })
        self.present(alert, animated: true, completion: nil)
    }

    func loginWithPassphrase(isAlwaysAsk: Bool) {

        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogPassphraseViewController") as? DialogPassphraseViewController {
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.isAlwaysAsk = isAlwaysAsk
            present(vc, animated: false, completion: nil)
        }
//        let storyboard = UIStoryboard(name: "Shared", bundle: nil)
//        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogLoginPassphraseViewController") as? DialogLoginPassphraseViewController {
//            vc.modalPresentationStyle = .overFullScreen
//            vc.delegate = self
//            vc.isAlwaysAsk = isAlwaysAsk
//            present(vc, animated: false, completion: nil)
//        }
    }

    @IBAction func btnFaceID(_ sender: Any) {
    }

    @IBAction func btnSettings(_ sender: Any) {
        let storyboard = UIStoryboard(name: "OnBoard", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "WalletSettingsViewController") as? WalletSettingsViewController {
            vc.delegate = self
            vc.account = account
            present(vc, animated: true) {}
        }
    }

    @IBAction func btnWalletLock(_ sender: Any) {
        OnBoardManager.shared.flowType = .restore
        OnBoardParams.shared = OnBoardParams(testnet: account?.gdkNetwork?.mainnet,
                                             walletName: account?.name,
                                             accountId: account?.id ?? UUID().uuidString,
                                             xpubHashId: account?.xpubHashId ?? "")
        let storyboard = UIStoryboard(name: "OnBoard", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "MnemonicViewController") as? MnemonicViewController {
            vc.restoredAccount = account
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func alertDismiss(_ sender: Any) {
        alertCard.isHidden = true
    }

    @IBAction func alertLink(_ sender: Any) {
        SafeNavigationManager.shared.navigate(remoteAlert?.link)
    }
}

extension LoginViewController: DialogRenameViewControllerDelegate, DialogWalletDeleteViewControllerDelegate {
    func didRename(name: String, index: String?) {
        self.account?.name = name
        if let account = self.account {
            AccountsRepository.shared.upsert(account)
            navigationItem.title = account.name
            AnalyticsManager.shared.renameWallet()
        }
    }
    func didDelete(_ index: String?) {
        if let account = self.account {
            AccountsRepository.shared.remove(account)
            navigationController?.popViewController(animated: true)
            AnalyticsManager.shared.deleteWallet()
        }
    }
    func didCancel() {
    }
}

extension LoginViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
}

extension LoginViewController: WalletSettingsViewControllerDelegate {
    func didSet(tor: Bool) {
        //
    }
    func didSet(testnet: Bool) {
        //
    }
}

//extension LoginViewController: DialogLoginPassphraseViewControllerDelegate {
//    func didConfirm(passphrase: String, alwaysAsk: Bool) {
//        bip39passphare = passphrase
//        account.askEphemeral = alwaysAsk
//        AccountsRepository.shared.upsert(account)
//        if account.hasBioPin {
//            loginWithPin(usingAuth: .AuthKeyBiometric, withPIN: nil, bip39passphrase: passphrase)
//        }
//    }
//}

extension LoginViewController: DialogPassphraseViewControllerDelegate {
    func didConfirm(passphrase: String, alwaysAsk: Bool) {
        bip39passphare = passphrase
        account.askEphemeral = alwaysAsk
        AccountsRepository.shared.upsert(account)
        if account.hasBioPin {
            loginWithPin(usingAuth: .AuthKeyBiometric, withPIN: nil, bip39passphrase: passphrase)
        }
    }
}

extension LoginViewController: DialogListViewControllerDelegate {
    func didSelectIndex(_ index: Int, with type: DialogType) {
        switch type {
        case .loginPrefs:
            switch LoginPrefs(rawValue: index) {
            case .emergency:
                showEmergencyDialog()
            case .passphrase:
                loginWithPassphrase(isAlwaysAsk: false)
            case .edit:
                walletRename()
            case .delete:
                walletDelete()
            case .none:
                break
            }
        default:
            break
        }
    }
}
