import UIKit
import AsyncBluetooth
import Combine

class PairingSuccessViewController: HWFlowBaseViewController {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblHint: UILabel!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var rememberView: UIView!
    @IBOutlet weak var lblRemember: UILabel!
    @IBOutlet weak var imgDevice: UIImageView!
    @IBOutlet weak var rememberSwitch: UISwitch!
    @IBOutlet weak var btnAppSettings: UIButton!

    var bleViewModel: BleViewModel?
    var scanViewModel: ScanViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        rememberSwitch.isOn = true
        mash.isHidden = true
        setContent()
        setStyle()
        if bleViewModel?.type == .Jade {
            loadNavigationBtns()
        }
        // if account just exist
        if let account = AccountsRepository.shared.accounts.filter({
            $0.isHW && ($0.uuid == bleViewModel?.peripheralID) || ($0.name == bleViewModel?.peripheral?.name) }).first {
            rememberSwitch.isOn = !(account.hidden ?? false)
            rememberView.isHidden = true
        }
        AnalyticsManager.shared.hwwConnect(account: AccountsRepository.shared.current)
    }

    func setContent() {
        lblTitle.text = bleViewModel?.peripheral?.name
        lblHint.text = "id_follow_the_instructions_on_your".localized
        btnContinue.setTitle("id_continue".localized, for: .normal)
        lblRemember.text = "id_remember_device_connection".localized
        imgDevice.image = UIImage(named: bleViewModel?.type == .Jade ? "il_jade_welcome_1" : "il_ledger")
        lblHint.text = bleViewModel?.type == .Jade ? "Blockstream" : ""
        btnAppSettings.setTitle(NSLocalizedString("id_app_settings", comment: ""), for: .normal)
    }

    func setStyle() {
        lblTitle.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
        lblTitle.textColor = .white
        [lblHint, lblRemember].forEach {
            $0?.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
            $0?.textColor = .white
        }
        btnContinue.setStyle(.primary)
        btnAppSettings.setStyle(.inline)
        btnAppSettings.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)
    }

    func loadNavigationBtns() {
        let settingsBtn = UIButton(type: .system)
        settingsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        settingsBtn.tintColor = UIColor.gGreenMatrix()
        settingsBtn.setTitle("id_setup_guide".localized, for: .normal)
        settingsBtn.addTarget(self, action: #selector(setupBtnTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsBtn)
    }

    @objc func setupBtnTapped() {
        let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "SetupJadeViewController") as? SetupJadeViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func btnContinue(_ sender: Any) {
        startLoader(message: "id_logging_in".localized)
        Task {
            if let scanViewModel = scanViewModel {
                await scanViewModel.stopScan()
            }
            guard let bleViewModel = bleViewModel else {
                fatalError()
            }
            do {
                if !bleViewModel.isConnected() {
                    try await bleViewModel.connect()
                }
                try await bleViewModel.ping()
                if bleViewModel.type == .Jade {
                    let version = try await bleViewModel.jade?.version()
                    onJadeConnected(jadeHasPin: version?.jadeHasPin ?? true)
                } else {
                    onLogin()
                }
            } catch {
                try? await bleViewModel.disconnect()
                onError(error)
            }
        }
    }

    @IBAction func btnAppSettings(_ sender: Any) {
        let storyboard = UIStoryboard(name: "OnBoard", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "WalletSettingsViewController") as? WalletSettingsViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @MainActor
    override func onError(_ err: Error) {
        stopLoader()
        let txt = BleViewModel.shared.toBleError(err, network: nil).localizedDescription
        self.showError(txt.localized)
    }

    @MainActor
    func onJadeConnected(jadeHasPin: Bool) {
        let testnetAvailable = AppSettings.shared.testnet
        if !jadeHasPin {
            if testnetAvailable {
                self.selectNetwork()
                return
            }
            self.onJadeInitialize(testnet: false)
        } else {
            self.onLogin()
        }
    }

    @MainActor
    func onLogin() {
        Task {
            do {
                let account = try await bleViewModel?.defaultAccount()
                try? await bleViewModel?.disconnect()
                await MainActor.run {
                    stopLoader()
                    var account = account
                    account?.hidden = !(self.rememberSwitch.isOn)
                    let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
                    if let vc = hwFlow.instantiateViewController(withIdentifier: "ConnectViewController") as? ConnectViewController {
                        vc.account = account
                        vc.bleViewModel = bleViewModel
                        vc.scanViewModel = scanViewModel
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } catch {
                try? await bleViewModel?.disconnect()
                onError(error)
            }
        }
    }

    @MainActor
    func onJadeInitialize(testnet: Bool) {
        Task {
            await MainActor.run {
                stopLoader()
                let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
                if let vc = hwFlow.instantiateViewController(withIdentifier: "PinCreateViewController") as? PinCreateViewController {
                    vc.testnet = testnet
                    vc.bleViewModel = bleViewModel
                    vc.scanViewModel = scanViewModel
                    vc.remember = rememberSwitch.isOn
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

extension PairingSuccessViewController: DialogListViewControllerDelegate {
    func didSwitchAtIndex(index: Int, isOn: Bool, type: DialogType) {}
    

    func selectNetwork() {
        self.stopLoader()
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogListViewController") as? DialogListViewController {
            vc.delegate = self
            vc.viewModel = DialogListViewModel(title: "Select Network", type: .networkPrefs, items: NetworkPrefs.getItems())
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }

    func didSelectIndex(_ index: Int, with type: DialogType) {
        switch NetworkPrefs(rawValue: index) {
        case .mainnet:
            onJadeInitialize(testnet: false)
        case .testnet:
            onJadeInitialize(testnet: true)
        case .none:
            break
        }
    }
}
