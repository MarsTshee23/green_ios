import UIKit

enum HomeSection: Int, CaseIterable {
    case remoteAlerts = 0
    case swWallet = 1
    case ephWallet = 2
    case hwWallet = 3
}

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnAbout: UIButton!
    @IBOutlet weak var btnSettings: UIButton!
    @IBOutlet weak var newWalletView: UIView!
    @IBOutlet weak var lblNewWallet: UILabel!

    var headerH: CGFloat = 44.0
    var footerH: CGFloat = 54.0

    private var remoteAlert: RemoteAlert?

    private var ephAccounts: [Account] {
        AccountsRepository.shared.ephAccounts.filter { account in
            account.isEphemeral && !WalletsRepository.shared.wallets.filter {$0.key == account.id }.isEmpty
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setContent()
        setStyle()
        updateUI()
        view.accessibilityIdentifier = AccessibilityIdentifiers.HomeScreen.view
        btnSettings.accessibilityIdentifier = AccessibilityIdentifiers.HomeScreen.appSettingsBtn

        tableView.register(UINib(nibName: "WalletListCell", bundle: nil), forCellReuseIdentifier: "WalletListCell")
        tableView.register(UINib(nibName: "AlertCardCell", bundle: nil), forCellReuseIdentifier: "AlertCardCell")

        remoteAlert = RemoteAlertManager.shared.alerts(screen: .home, networks: []).first

        AnalyticsManager.shared.delegate = self
        AnalyticsManager.shared.recordView(.home)
        AnalyticsManager.shared.appLoadingFinished()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func setContent() {
        btnSettings.setTitle(NSLocalizedString("id_app_settings", comment: ""), for: .normal)
        btnSettings.setTitleColor(.lightGray, for: .normal)
        btnAbout.setTitle(NSLocalizedString("id_about", comment: ""), for: .normal)
        btnAbout.setImage(UIImage(named: "ic_about")!, for: .normal)
        btnAbout.setTitleColor(.lightGray, for: .normal)
        lblNewWallet.text = "id_setup_a_new_wallet".localized
    }

    func setStyle() {
        newWalletView.cornerRadius = 5.0
    }

    func updateUI() {
    }

    func remoteAlertDismiss() {
        remoteAlert = nil
        tableView.reloadData()
    }

    func remoteAlertLink() {
        SafeNavigationManager.shared.navigate(remoteAlert?.link)
    }

    func walletDelete(_ index: String) {
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogDeleteViewController") as? DialogDeleteViewController {
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.index = index
            present(vc, animated: false, completion: nil)
        }
    }

    func walletRename(_ index: String) {
        let account = AccountsRepository.shared.get(for: index)
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogRenameViewController") as? DialogRenameViewController {
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.index = index
            vc.prefill = account?.name ?? ""
            present(vc, animated: false, completion: nil)
        }
    }

    func getAccountFromTableView(_ indexPath: IndexPath) -> Account? {
        switch HomeSection(rawValue: indexPath.section) {
        case .swWallet:
            return AccountsRepository.shared.swAccounts[indexPath.row]
        case .ephWallet:
            return ephAccounts[indexPath.row]
        case .hwWallet:
            return AccountsRepository.shared.hwVisibleAccounts[indexPath.row]
        default:
            return nil
        }
    }
    
    func onTap(_ indexPath: IndexPath) {
        if let account = getAccountFromTableView(indexPath) {
            AccountNavigator.goLogin(account: account)
        }
    }
    
    func onTapOverview(_ indexPath: IndexPath) {
        if let account = getAccountFromTableView(indexPath) {
            AccountNavigator.goLogin(account: account)
        }
    }
    
    func onTapLightShort(_ indexPath: IndexPath) {
        if let account = getAccountFromTableView(indexPath) {
            if let lightning = account.getDerivedLightningAccount() {
                AccountNavigator.goLogin(account: lightning)
            }
        }
    }

    func isOverviewSelected(_ account: Account) -> Bool {
        WalletsRepository.shared.get(for: account.id)?.activeSessions.count ?? 0 > 0
    }

    func isLightningSelected(_ account: Account) -> Bool {
        if let account = account.getDerivedLightningAccount() {
            return WalletsRepository.shared.get(for: account.id)?.activeSessions.count ?? 0 > 0
        }
        return false
    }

    @IBAction func btnNewWallet(_ sender: Any) {
        let hwFlow = UIStoryboard(name: "OnBoard", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "SelectOnBoardTypeViewController") as? SelectOnBoardTypeViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func btnAbout(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogAboutViewController") as? DialogAboutViewController {
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }

    @IBAction func btnSettings(_ sender: Any) {
        let storyboard = UIStoryboard(name: "OnBoard", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "WalletSettingsViewController") as? WalletSettingsViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return HomeSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch HomeSection(rawValue: section) {
        case .remoteAlerts:
            return remoteAlert != nil ? 1 : 0
        case .swWallet:
            return AccountsRepository.shared.swAccounts.count
        case .ephWallet:
            return ephAccounts.count
        case .hwWallet:
            return AccountsRepository.shared.hwVisibleAccounts.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch HomeSection(rawValue: indexPath.section) {

        case .remoteAlerts:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCardCell", for: indexPath) as? AlertCardCell, let remoteAlert = self.remoteAlert {
                cell.configure(AlertCardCellModel(type: .remoteAlert(remoteAlert)),
                               onLeft: nil,
                               onRight: (remoteAlert.link ?? "" ).isEmpty ? nil : {[weak self] in
                    self?.remoteAlertLink() // to solve cylomatic complexity
                },
                               onDismiss: {[weak self] in
                    self?.remoteAlertDismiss()
                })
                cell.selectionStyle = .none
                return cell
            }
        case .swWallet:
            let account = AccountsRepository.shared.swAccounts[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "WalletListCell") as? WalletListCell {

                cell.configure(item: account,
                               isOverviewSelected: isOverviewSelected(account),
                               isLightningSelected: isLightningSelected(account),
                               indexPath: indexPath,
                               onLongpress: { [weak self] () in self?.popover(for: cell, account: account) },
                               onTap: { [weak self] indexPath in self?.onTap(indexPath) },
                               onTapOverview: { [weak self] indexPath in self?.onTapOverview(indexPath) },
                               onTapLightShort: { [weak self] indexPath in self?.onTapLightShort(indexPath) }
                )
                cell.selectionStyle = .none
                return cell
            }
        case .ephWallet:
            let account = ephAccounts[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "WalletListCell") as? WalletListCell {
                cell.configure(item: account,
                               isOverviewSelected: isOverviewSelected(account),
                               isLightningSelected: isLightningSelected(account),
                               indexPath: indexPath,
                               onLongpress: nil,
                               onTap: { [weak self] indexPath in self?.onTap(indexPath) },
                               onTapOverview: { [weak self] indexPath in self?.onTapOverview(indexPath) },
                               onTapLightShort: { [weak self] indexPath in self?.onTapLightShort(indexPath) }
                )
                cell.selectionStyle = .none
                return cell
            }
        case .hwWallet:
            let account = AccountsRepository.shared.hwVisibleAccounts[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "WalletListCell") as? WalletListCell {
                cell.configure(item: account,
                               isOverviewSelected: isOverviewSelected(account),
                               isLightningSelected: isLightningSelected(account),
                               indexPath: indexPath,
                               onLongpress: { [weak self] () in self?.popover(for: cell, account: account) },
                               onTap: { [weak self] indexPath in self?.onTap(indexPath) },
                               onTapOverview: { [weak self] indexPath in self?.onTapOverview(indexPath) },
                               onTapLightShort: { [weak self] indexPath in self?.onTapLightShort(indexPath) }
                )
                cell.selectionStyle = .none
                return cell
            }
        default:
            break
        }

        return UITableViewCell()
    }

    func popover(for cell: UITableViewCell, account: Account) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let storyboard = UIStoryboard(name: "PopoverMenu", bundle: nil)
        if let popover  = storyboard.instantiateViewController(withIdentifier: "PopoverMenuHomeViewController") as? PopoverMenuHomeViewController {
            popover.delegate = self
            popover.index = account.id
            popover.menuOptions = [.edit, .delete]
            popover.modalPresentationStyle = .popover
            let popoverPresentationController = popover.popoverPresentationController
            popoverPresentationController?.backgroundColor = UIColor.customModalDark()
            popoverPresentationController?.delegate = self
            popoverPresentationController?.sourceView = cell
            popoverPresentationController?.sourceRect = cell.bounds
            present(popover, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch HomeSection(rawValue: section) {
        case .ephWallet:
            if ephAccounts.isEmpty {
                return 0.1
            }
        case .swWallet:
            if AccountsRepository.shared.swAccounts.isEmpty {
                return 0.1
            }
        case .hwWallet:
            if AccountsRepository.shared.hwVisibleAccounts.isEmpty {
                return 0.1
            }
        case .remoteAlerts:
            return 0.1
        default:
            break
        }
        return headerH
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch HomeSection(rawValue: section) {
        case .remoteAlerts:
            return nil
        case .swWallet:
            if AccountsRepository.shared.swAccounts.isEmpty {
                return nil
            }
            return headerView(NSLocalizedString("id_digital_wallets", comment: ""))
        case .ephWallet:
            if ephAccounts.isEmpty {
                return nil
            }
            return headerView(NSLocalizedString("id_ephemeral_wallets", comment: ""))
        case .hwWallet:
            if AccountsRepository.shared.hwVisibleAccounts.isEmpty {
                return nil
            }
            return headerView(NSLocalizedString("id_hardware_wallets", comment: ""))
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension HomeViewController {
    func headerView(_ txt: String) -> UIView {
        let section = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: headerH))
        section.backgroundColor = UIColor.customTitaniumDark()
        let title = UILabel(frame: .zero)
        title.font = .systemFont(ofSize: 14.0, weight: .semibold)
        title.text = txt
        title.textColor = UIColor.customGrayLight()
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(title)
        NSLayoutConstraint.activate([
            title.centerYAnchor.constraint(equalTo: section.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -24)
        ])
        return section
    }
}

extension HomeViewController: AnalyticsManagerDelegate {
    func remoteConfigIsReady() {
        DispatchQueue.main.async {
            self.remoteAlert = RemoteAlertManager.shared.alerts(screen: .home, networks: []).first
            self.tableView.reloadData()
        }
    }
}

extension HomeViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
}

extension HomeViewController: PopoverMenuHomeDelegate {
    func didSelectionMenuOption(menuOption: MenuWalletOption, index: String?) {
        guard let index = index else { return }
        switch menuOption {
        case .edit:
            walletRename(index)
        case .delete:
            walletDelete(index)
        default:
            break
        }
    }
}

extension HomeViewController: DialogRenameViewControllerDelegate, DialogDeleteViewControllerDelegate {
    func didRename(name: String, index: String?) {
        if let index = index, var account = AccountsRepository.shared.get(for: index) {
            account.name = name
            AccountsRepository.shared.upsert(account)
            AnalyticsManager.shared.renameWallet()
            tableView.reloadData()
        }
    }
    func didDelete(_ index: String?) {
        if let index = index, let account = AccountsRepository.shared.get(for: index) {
            AccountsRepository.shared.remove(account)
            AnalyticsManager.shared.deleteWallet()
            tableView.reloadData()
        }
    }
    func didCancel() {
    }
}
