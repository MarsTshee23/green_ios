import UIKit
import PromiseKit

enum AccountArchiveSection: Int, CaseIterable {
    case account = 0
}

class AccountArchiveViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var headerH: CGFloat = 44.0
    var footerH: CGFloat = 54.0

    private var subAccounts = [WalletItem]()

    var isLoading = false
    var accounts: [WalletItem] {
        get {
            if subAccounts.count == 0 {
                return []
            }
            let activeWallet = SessionsManager.current?.activeWallet ?? 0
            return subAccounts.filter { $0.pointer == activeWallet} + subAccounts.filter { $0.pointer != activeWallet}
        }
    }
    var account = AccountsManager.shared.current
    private var isLiquid: Bool { account?.gdkNetwork?.liquid ?? false }
//    private var isAmp: Bool {
//        guard let wallet = presentingWallet else { return false }
//        return AccountType(rawValue: wallet.type) == AccountType.amp
//    }
    private var btc: String {
        return account?.gdkNetwork?.getFeeAsset() ?? ""
    }

    var color: UIColor = .clear

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = account?.name ?? ""
        navigationItem.setHidesBackButton(true, animated: false)

        let ntwBtn = UIButton(type: .system)
        let img = account?.icon ?? UIImage()
        ntwBtn.setImage(img.withRenderingMode(.alwaysOriginal), for: .normal)
        ntwBtn.imageView?.contentMode = .scaleAspectFit
        ntwBtn.addTarget(self, action: #selector(AccountArchiveViewController.back), for: .touchUpInside)
        ntwBtn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        navigationItem.leftBarButtonItems =
            [UIBarButtonItem(image: UIImage.init(named: "backarrow"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(LoginViewController.back)),
             UIBarButtonItem(customView: ntwBtn)
            ]

        setContent()
        setStyle()

        startAnimating()
    }

    @objc func back(sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    func reloadSections(_ sections: [AccountArchiveSection], animated: Bool) {
        if animated {
            tableView.reloadSections(IndexSet(sections.map { $0.rawValue }), with: .none)
        } else {
            UIView.performWithoutAnimation {
                tableView.reloadSections(IndexSet(sections.map { $0.rawValue }), with: .none)
            }
        }
    }

    func setContent() {
    }

    func setStyle() {
        if account?.network == AvailableNetworks.bitcoin.rawValue { color = AvailableNetworks.bitcoin.color() }
        if account?.network == AvailableNetworks.liquid.rawValue { color = AvailableNetworks.liquid.color() }
        if account?.network == AvailableNetworks.testnet.rawValue { color = AvailableNetworks.testnet.color() }
        if account?.network == AvailableNetworks.testnetLiquid.rawValue { color = AvailableNetworks.testnetLiquid.color() }
    }

    @objc func handleRefresh(_ sender: UIRefreshControl? = nil) {
        Promise().asVoid().then { _ -> Promise<Void> in
            return self.discoverySubaccounts(singlesig: self.account?.isSingleSig ?? false).asVoid()
        }.then {
            self.loadSubaccounts()
        }.done { [weak self] _ in
            if self?.accounts.count == 0 {
                self?.navigationController?.popViewController(animated: true)
            }
        }.catch { e in
            DropAlert().error(message: e.localizedDescription)
            print(e.localizedDescription)
        }
    }

//    func onNewBlock(_ notification: Notification) {
//        // update txs only if pending txs > 0
//        if transactions.filter({ $0.blockHeight == 0 }).first != nil {
//            handleRefresh()
//        }
//    }

//    func onAssetsUpdated(_ notification: Notification) {
//        guard let session = SessionsManager.current else { return }
//        Guarantee()
//            .compactMap { Registry.shared.cache(session: session) }
//            .done {
//                self.reloadSections([AccountArchiveSection.asset], animated: true)
//                self.showTransactions()
//            }
//            .catch { err in
//                print(err.localizedDescription)
//        }
//    }

//    func onNewTransaction(_ notification: Notification) {
//        if let dict = notification.userInfo as NSDictionary?,
//           let subaccounts = dict["subaccounts"] as? [UInt32],
//           let session = SessionsManager.current,
//           subaccounts.contains(session.activeWallet) {
//            handleRefresh()
//        }
//    }

//    @objc func onNetworkEvent(_ notification: Notification) {
//        guard let dict = notification.userInfo as NSDictionary? else { return }
//        guard let connected = dict["connected"] as? Bool else { return }
//        guard let loginRequired = dict["login_required"] as? Bool else { return }
//        if connected == true && loginRequired == false {
//            DispatchQueue.main.async { [weak self] in
//                self?.handleRefresh()
//            }
//        }
//    }

    func refresh(_ notification: Notification) {
        reloadSections([AccountArchiveSection.account], animated: true)
    }

    func discoverySubaccounts(singlesig: Bool) -> Promise<Void> {
        if let session = SessionsManager.current, singlesig {
            return session.subaccounts(true).asVoid()
        }
        return Promise().asVoid()
    }

    func loadSubaccounts() -> Promise<Void> {
        let bgq = DispatchQueue.global(qos: .background)
        guard let session = SessionsManager.current else { return Promise().asVoid() }
        return Guarantee().then(on: bgq) {
                session.subaccounts()
            }.then(on: bgq) { wallets -> Promise<[WalletItem]> in
                let balances = wallets.map { wallet in { wallet.getBalance() } }
                return Promise.chain(balances).compactMap { _ in wallets }
            }.map { wallets in
                self.subAccounts = wallets.filter { $0.hidden == true }
                self.reloadSections([AccountArchiveSection.account], animated: false)
            }.ensure {
                self.stopAnimating()
            }
    }

    func unarchiveAccount(_ index: Int) {

        let bgq = DispatchQueue.global(qos: .background)
        guard let session = SessionsManager.current else { return }
        firstly {
            self.startAnimating()
            return Guarantee()
        }.compactMap(on: bgq) {
            try session.updateSubaccount(details: ["subaccount": self.accounts[index].pointer, "hidden": false]).resolve()
        }.ensure {
            self.stopAnimating()
        }.done { _ in
            self.handleRefresh()
        }.catch { e in
            DropAlert().error(message: e.localizedDescription)
            print(e.localizedDescription)
        }
    }

    func presentUnarchiveMenu(frame: CGRect, index: Int) {
        let storyboard = UIStoryboard(name: "PopoverMenu", bundle: nil)
        if let popover  = storyboard.instantiateViewController(withIdentifier: "PopoverMenuUnarchiveViewController") as? PopoverMenuUnarchiveViewController {
            popover.delegate = self
            popover.index = index
            popover.modalPresentationStyle = .popover
            let popoverPresentationController = popover.popoverPresentationController
            popoverPresentationController?.backgroundColor = UIColor.customModalDark()
            popoverPresentationController?.delegate = self
            popoverPresentationController?.sourceView = self.tableView
            popoverPresentationController?.sourceRect = CGRect(x: self.tableView.frame.width - 80.0, y: frame.origin.y, width: 60.0, height: 60.0)
            popoverPresentationController?.permittedArrowDirections = .up
            self.present(popover, animated: true)
        }
    }
}

extension AccountArchiveViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return AccountArchiveSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case AccountArchiveSection.account.rawValue:
            return accounts.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case AccountArchiveSection.account.rawValue:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "AccountArchiveCell") as? AccountArchiveCell {
                var action: VoidToVoid?
                    action = { [weak self] in
                        self?.presentUnarchiveMenu(frame: cell.frame, index: indexPath.row)
                    }
                cell.configure(account: accounts[indexPath.row], action: action, color: color, isLiquid: isLiquid)
                cell.selectionStyle = .none
                return cell
            }
        default:
            break
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

//        switch indexPath.section {
//        case AccountArchiveSection.account.rawValue:
//            UIView.setAnimationsEnabled(true)
//            if indexPath.row == 0 {
//                showAccounts = !showAccounts
//                reloadSections([AccountArchiveSection.account], animated: true)
//                return
//            } else {
//                SessionsManager.current?.activeWallet = accounts[indexPath.row].pointer
//                presentingWallet = accounts[indexPath.row]
//                showAccounts = !showAccounts
//                reloadData()
//            }
//        default:
//            break
//        }
    }
}

extension AccountArchiveViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        if !userWillLogout {
//            transactionToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Transaction.rawValue), object: nil, queue: .main, using: onNewTransaction)
//            blockToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Block.rawValue), object: nil, queue: .main, using: onNewBlock)
//            assetsUpdatedToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.AssetsUpdated.rawValue), object: nil, queue: .main, using: onAssetsUpdated)
//            settingsUpdatedToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Settings.rawValue), object: nil, queue: .main, using: refresh)
//            tickerUpdatedToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Ticker.rawValue), object: nil, queue: .main, using: refresh)
//            networkToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Network.rawValue), object: nil, queue: .main, using: onNetworkEvent)
//            reset2faToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.TwoFactorReset.rawValue), object: nil, queue: .main, using: refresh)

//            if subAccounts.count > 0 {
                handleRefresh()
//            }
//        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if let token = transactionToken {
//            NotificationCenter.default.removeObserver(token)
//            transactionToken = nil
//        }
//        if let token = blockToken {
//            NotificationCenter.default.removeObserver(token)
//            blockToken = nil
//        }
//        if let token = assetsUpdatedToken {
//            NotificationCenter.default.removeObserver(token)
//            assetsUpdatedToken = nil
//        }
//        if let token = settingsUpdatedToken {
//            NotificationCenter.default.removeObserver(token)
//            settingsUpdatedToken = nil
//        }
//        if let token = tickerUpdatedToken {
//            NotificationCenter.default.removeObserver(token)
//            tickerUpdatedToken = nil
//        }
//        if let token = networkToken {
//            NotificationCenter.default.removeObserver(token)
//            networkToken = nil
//        }
//        if let token = reset2faToken {
//            NotificationCenter.default.removeObserver(token)
//            reset2faToken = nil
//        }
    }
}

extension AccountArchiveViewController: DialogWalletNameViewControllerDelegate {

    func didSave(_ name: String) {
//        let bgq = DispatchQueue.global(qos: .background)
//        guard let session = SessionsManager.current else { return }
//        firstly {
//            self.startAnimating()
//            return Guarantee()
//        }.compactMap(on: bgq) {
//            try session.renameSubaccount(subaccount: session.activeWallet, newName: name)
//        }.ensure {
//            self.stopAnimating()
//        }.done { _ in
//            self.reloadData()
//        }.catch { e in
//            DropAlert().error(message: e.localizedDescription)
//            print(e.localizedDescription)
//        }
    }
    func didCancel() {
    }
}

extension AccountArchiveViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
}

extension AccountArchiveViewController: PopoverMenuUnarchiveDelegate {
    func didSelectionMenuOption(option: MenuUnarchiveOption, index: Int) {
        switch option {
        case .unarchive:
            unarchiveAccount(index)
        }
    }
}
