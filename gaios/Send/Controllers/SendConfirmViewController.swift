import Foundation
import UIKit

import BreezSDK
import gdk
import greenaddress
import hw

class SendConfirmViewController: KeyboardViewController {

    enum SendConfirmSection: Int, CaseIterable {
        case remoteAlerts = 0
        case addressee = 1
        case fee = 2
        case change = 3
        case note = 4
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sliderView: SliderView!

    var viewModel: SendConfirmViewModel!

    private var connected = true
    private var updateToken: NSObjectProtocol?
    private var dialogSendHWSummaryViewController: DialogSendHWSummaryViewController?
    private var ltConfirmingViewController: LTConfirmingViewController?

    var inputType: TxType = .transaction // for analytics
    var addressInputType: AnalyticsManager.AddressInputType? = .paste // for analytics

    override func viewDidLoad() {
        super.viewDidLoad()

        sliderView.delegate = self

        updateToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Network.rawValue), object: nil, queue: .main, using: updateConnection)
        setContent()

        view.accessibilityIdentifier = AccessibilityIdentifiers.SendConfirmScreen.view
        sliderView.accessibilityIdentifier = AccessibilityIdentifiers.SendConfirmScreen.viewSlider

        tableView.register(UINib(nibName: "AlertCardCell", bundle: nil), forCellReuseIdentifier: "AlertCardCell")

        AnalyticsManager.shared.recordView(.sendConfirm, sgmt: AnalyticsManager.shared.subAccSeg(AccountsRepository.shared.current, walletItem: viewModel.account))
    }

    func setContent() {
        title = NSLocalizedString("id_review", comment: "")
    }

    func editNote() {
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogEditViewController") as? DialogEditViewController {
            vc.modalPresentationStyle = .overFullScreen
            vc.prefill = viewModel.tx.memo ?? ""
            vc.delegate = self
            present(vc, animated: false, completion: nil)
        }
    }

    func remoteAlertDismiss() {
        viewModel.remoteAlert = nil
        reloadSections([SendConfirmSection.remoteAlerts], animated: true)
    }

    @MainActor
    func reloadSections(_ sections: [SendConfirmSection], animated: Bool) {
        DispatchQueue.main.async {
            if animated {
                self.tableView.reloadSections(IndexSet(sections.map { $0.rawValue }), with: .none)
            } else {
                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(IndexSet(sections.map { $0.rawValue }), with: .none)
                }
            }
        }
    }

    func presentHWSummary() {
        let storyboard = UIStoryboard(name: "Shared", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogSendHWSummaryViewController") as? DialogSendHWSummaryViewController {
            vc.modalPresentationStyle = .overFullScreen
            vc.transaction = viewModel.tx
            vc.isLedger = viewModel.isLedger
            vc.account = viewModel.account
            present(vc, animated: false, completion: nil)
            dialogSendHWSummaryViewController = vc
        }
    }

    func presentLightning() {
        let ltFlow = UIStoryboard(name: "LTFlow", bundle: nil)
        if let vc = ltFlow.instantiateViewController(withIdentifier: "LTConfirmingViewController") as? LTConfirmingViewController {
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: false, completion: nil)
            ltConfirmingViewController = vc
        }
    }

    @MainActor
    func presentProgress() {
        if viewModel.isLightning {
            presentLightning()
        } else if viewModel.isHW {
            presentHWSummary()
        } else {
            startAnimating()
        }
    }

    @MainActor
    func dismissProgress(_ completion: @escaping (()->Void)) {
        if viewModel.isLightning {
            ltConfirmingViewController?.dismiss(animated: true, completion: completion)
        } else if viewModel.isHW {
            dialogSendHWSummaryViewController?.dismiss(animated: true, completion: completion)
        } else {
            stopAnimating()
            completion()
        }
    }

    func send() {
        AnalyticsManager.shared.startSendTransaction()
        AnalyticsManager.shared.startFailedTransaction()
        sliderView.isUserInteractionEnabled = false
        presentProgress()
        Task {
            do {
                try await self.viewModel.send()
                executeOnDone()
            } catch {
                failure(error)
            }
        }
    }

    @MainActor
    func failure(_ error: Error) {
        let prettyError = getError(error)
        
        dismissProgress() {
            self.sliderView.isUserInteractionEnabled = true
            self.sliderView.reset()
            switch error {
            case TwoFactorCallError.cancel(_):
                break
            default:
                self.showReportError(
                    account: AccountsRepository.shared.current,
                    wallet: self.viewModel.account,
                    prettyError: prettyError.localized,
                    screenName: "FailedTransaction")
            }
        }
        let isSendAll = self.viewModel.tx.addressees.first?.isGreedy ?? false
        let withMemo = !(self.viewModel.tx.memo?.isEmpty ?? true)
        let transSgmt = AnalyticsManager.TransactionSegmentation(transactionType: self.inputType,
                                                                 addressInputType: self.addressInputType,
                                                                 sendAll: isSendAll)
        AnalyticsManager.shared.failedTransaction(
            account: AccountsRepository.shared.current,
            walletItem: self.viewModel.account,
            transactionSgmt: transSgmt,
            withMemo: withMemo,
            prettyError: prettyError.localized)
    }

    @MainActor
    func executeOnDone() {
        let isSendAll = viewModel.tx.addressees.first?.isGreedy ?? false
        let withMemo = !(viewModel.tx.memo?.isEmpty ?? true)
        let transSgmt = AnalyticsManager.TransactionSegmentation(transactionType: inputType,
                                                                 addressInputType: addressInputType,
                                                                 sendAll: isSendAll)
        AnalyticsManager.shared.endSendTransaction(account: AccountsRepository.shared.current,
                                                   walletItem: viewModel.account,
                                                   transactionSgmt: transSgmt, withMemo: withMemo)
        dismissProgress() {
            DropAlert().success(message: "id_transaction_sent".localized)
            StoreReviewHelper
                .shared
                .request(isSendAll: isSendAll,
                         account: AccountsRepository.shared.current,
                         walletItem: self.viewModel.account)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    func updateConnection(_ notification: Notification) {
        if let data = notification.userInfo,
              let json = try? JSONSerialization.data(withJSONObject: data, options: []),
              let connection = try? JSONDecoder().decode(Connection.self, from: json) {
            self.connected = connection.connected
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = updateToken {
            NotificationCenter.default.removeObserver(token)
            updateToken = nil
        }
    }
}

extension SendConfirmViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return SendConfirmSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {
        case SendConfirmSection.remoteAlerts.rawValue:
            return viewModel.remoteAlert != nil ? 1 : 0
        case SendConfirmSection.addressee.rawValue:
            return viewModel.tx.addressees.count
        case SendConfirmSection.fee.rawValue:
            return viewModel.account.type == .lightning ? 0 : 1
        case SendConfirmSection.change.rawValue:
            return 0
        case SendConfirmSection.note.rawValue:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case SendConfirmSection.remoteAlerts.rawValue:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCardCell", for: indexPath) as? AlertCardCell, let remoteAlert = viewModel.remoteAlert {
                cell.configure(AlertCardCellModel(type: .remoteAlert(remoteAlert)),
                                   onLeft: nil,
                                   onRight: (remoteAlert.link ?? "" ).isEmpty ? nil : { () in
                    SafeNavigationManager.shared.navigate(remoteAlert.link)
                },
                                   onDismiss: {[weak self] in
                                 self?.remoteAlertDismiss()
                    })
                cell.selectionStyle = .none
                return cell
            }
        case SendConfirmSection.addressee.rawValue:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "AddresseeCell") as? AddresseeCell {
                cell.configure(cellModel: viewModel.addresseeCellModels[indexPath.row])
                cell.selectionStyle = .none
                return cell
            }
        case SendConfirmSection.fee.rawValue:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "FeeSummaryCell") as? FeeSummaryCell {
                cell.configure(viewModel.tx, inputDenomination: viewModel.inputDenomination)
                cell.selectionStyle = .none
                return cell
            }
        case SendConfirmSection.change.rawValue:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "ChangeCell") as? ChangeCell {
                cell.configure(viewModel.tx)
                cell.selectionStyle = .none
                return cell
            }
        case SendConfirmSection.note.rawValue:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as? NoteCell {
                cell.configure(note: viewModel.tx.memo ?? "", isLightning: viewModel.isLightning)
                cell.delegate = self
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

    }
}

extension SendConfirmViewController: DialogEditViewControllerDelegate {

    func didSave(_ note: String) {
        viewModel.tx.memo = note
        reloadSections([SendConfirmSection.note], animated: false)
    }

    func didClose() { }
}

extension SendConfirmViewController: NoteCellDelegate {

    func noteAction() {
        if !viewModel.isLightning {
            editNote()
        }
    }
}

extension SendConfirmViewController: SliderViewDelegate {
    func sliderThumbIsMoving(_ sliderView: SliderView) {
    }

    func sliderThumbDidStopMoving(_ position: Int) {
        if position == 1 {
            send()
        }
    }
}
