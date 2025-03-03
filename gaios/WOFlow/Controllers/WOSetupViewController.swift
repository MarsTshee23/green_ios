import Foundation
import UIKit

import gdk

enum SecurityOption: String {
    case single = "SingleSig"
    case multi = "MultiSig"
}

class WOSetupViewController: KeyboardViewController {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblHint: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var btnSettings: UIButton!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblPassword: UILabel!
    @IBOutlet weak var remView: UIView!
    @IBOutlet weak var iconRem: UIImageView!
    @IBOutlet weak var btnRem: UIButton!
    @IBOutlet weak var lblRem: UILabel!
    
    private var buttonConstraint: NSLayoutConstraint?
    private var progressToken: NSObjectProtocol?
    private var networks = [NetworkSecurityCase]()
    private let viewModel = WOViewModel()
    private var network: AvailableNetworks?
    private var isRem: Bool = false
    var watchOnlySecurityOption: SecurityOption = .multi

    override func viewDidLoad() {
        super.viewDidLoad()

        setContent()
        setStyle()
        refresh()

        loginButton.addTarget(self, action: #selector(click), for: .touchUpInside)
        usernameTextField.addDoneButtonToKeyboard(myAction: #selector(self.usernameTextField.resignFirstResponder))
        passwordTextField.addDoneButtonToKeyboard(myAction: #selector(self.usernameTextField.resignFirstResponder))
        view.accessibilityIdentifier = AccessibilityIdentifiers.WatchOnlyScreen.view
        usernameTextField.accessibilityIdentifier = AccessibilityIdentifiers.WatchOnlyScreen.usernameField
        passwordTextField.accessibilityIdentifier = AccessibilityIdentifiers.WatchOnlyScreen.passwordField
        loginButton.accessibilityIdentifier = AccessibilityIdentifiers.WatchOnlyScreen.loginBtn

        AnalyticsManager.shared.recordView(.onBoardWatchOnlyCredentials)
    }

    func setContent() {
        lblTitle.text = NSLocalizedString("id_login", comment: "")
        lblHint.text = NSLocalizedString("id_log_in_via_watchonly_to_receive", comment: "")
        warningLabel.text = NSLocalizedString("id_watchonly_mode_can_be_activated", comment: "")
        loginButton.setTitle(NSLocalizedString("id_log_in", comment: ""), for: .normal)
        lblUsername.text = "id_username".localized
        lblPassword.text = "id_password".localized
        lblRem.text = NSLocalizedString("id_remember_me", comment: "")
    }

    func setStyle() {
        lblTitle.setStyle(.title)
        lblHint.setStyle(.txt)
        warningLabel.setStyle(.txt)
        lblUsername.setStyle(.sectionTitle)
        lblPassword.setStyle(.sectionTitle)
        warningLabel.textColor = UIColor.gW40()
        loginButton.setStyle(.primary)
        btnSettings.setTitle(NSLocalizedString("id_app_settings", comment: ""), for: .normal)
        usernameTextField.setLeftPaddingPoints(10.0)
        usernameTextField.setRightPaddingPoints(10.0)
        passwordTextField.setLeftPaddingPoints(10.0)
        passwordTextField.setRightPaddingPoints(10.0)
        usernameTextField.leftViewMode = .always
        passwordTextField.leftViewMode = .always
        usernameTextField.layer.cornerRadius = 5.0
        passwordTextField.layer.cornerRadius = 5.0
        remView.borderWidth = 1.0
        remView.borderColor = .white.withAlphaComponent(0.7)
        remView.layer.cornerRadius = 5.0
    }

    func refresh() {
        iconRem.image = isRem ? UIImage(named: "ic_checkbox_on")! : UIImage(named: "ic_checkbox_off")!
    }
    
    @objc func rememberSwitchChange(_ sender: UISwitch) {
        if sender.isOn {
            let alert = UIAlertController(title: NSLocalizedString("id_warning_watchonly_credentials", comment: ""), message: NSLocalizedString("id_your_watchonly_username_and", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("id_cancel", comment: ""), style: .cancel) { _ in
                sender.isOn = false
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("id_ok", comment: ""), style: .default) { _ in
                sender.isOn = true
            })
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    @objc func testnetSwitchChange(_ sender: UISwitch) {
    }

    @objc func back(sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Tor.rawValue), object: nil, queue: .main, using: progress)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = progressToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    @objc func progress(_ notification: Notification) {
        if let json = try? JSONSerialization.data(withJSONObject: notification.userInfo!, options: []),
           let tor = try? JSONDecoder().decode(TorNotification.self, from: json) {
            var text = NSLocalizedString("id_tor_status", comment: "") + " \(tor.progress)%"
            if tor.progress == 100 {
                text = NSLocalizedString("id_logging_in", comment: "")
            }
            DispatchQueue.main.async {
                self.startLoader(message: text)
            }
        }
    }

    override func keyboardWillShow(notification: Notification) {
        super.keyboardWillShow(notification: notification)
    }

    override func keyboardWillHide(notification: Notification) {
        super.keyboardWillShow(notification: notification)
    }

    @objc func click(_ sender: Any) {
        selectNetwork()
    }


    @IBAction func btnRem(_ sender: Any) {
        isRem = !isRem
        refresh()
    }

    @IBAction func btnSettings(_ sender: Any) {
        let storyboard = UIStoryboard(name: "OnBoard", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "WalletSettingsViewController") as? WalletSettingsViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func login(for network: GdkNetwork) {
        let account = viewModel.newAccountMultisig(
            for: network,
            username: self.usernameTextField.text ?? "",
            password: isRem ? self.passwordTextField.text ?? "" : "",
            remember: isRem)
        dismissKeyboard()
        self.startLoader(message: NSLocalizedString("id_logging_in", comment: ""))
        Task {
            do {
                try await self.viewModel.loginMultisig(for: account, password: self.passwordTextField.text)
                success(account: account)
            } catch {
                failure(error, account: account)
            }
        }
    }
    
    @MainActor
    func success(account: Account) {
        stopLoader()
        AccountNavigator.goLogged(account: account)
    }
    
    @MainActor
    func failure(_ error: Error, account: Account) {
        var prettyError = "id_login_failed"
        switch error {
        case TwoFactorCallError.failure(let localizedDescription):
            prettyError = localizedDescription
        case LoginError.connectionFailed:
            prettyError = "id_connection_failed"
        case LoginError.failed:
            prettyError = "id_login_failed"
        default:
            break
        }
        stopLoader()
        DropAlert().error(message: NSLocalizedString(prettyError, comment: ""))
        AnalyticsManager.shared.failedWalletLogin(account: account, error: error, prettyError: prettyError)
        WalletsRepository.shared.delete(for: account)
    }
}

extension WOSetupViewController: DialogListViewControllerDelegate {
    func didSwitchAtIndex(index: Int, isOn: Bool, type: DialogType) {}

    func selectNetwork() {
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogListViewController") as? DialogListViewController {
            let testnet = OnBoardManager.shared.chainType == .testnet
            networks = testnet ? [.testnetMS, .testnetLiquidMS] : [.bitcoinMS, .liquidMS]
            let cells = networks.map { DialogListCellModel(type: .list,
                                                           icon: nil,
                                                           title: $0.name()) }
            vc.viewModel = DialogListViewModel(title: "Select Network", type: .watchOnlyPrefs, items: cells)
            vc.delegate = self
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }

    func didSelectIndex(_ index: Int, with type: DialogType) {
        if let network = NetworkSecurityCase(rawValue: networks[index].rawValue) {
            login(for: network.gdkNetwork)
        }
    }
}
