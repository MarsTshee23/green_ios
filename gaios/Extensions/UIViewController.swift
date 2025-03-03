import Foundation
import UIKit
import gdk
import greenaddress
import BreezSDK
import hw

enum UIAlertOption: String {
    case `continue` = "id_continue"
    case `cancel` = "id_cancel"
}

extension UIViewController {

    @MainActor
    func showAlert(title: String, message: String, completion: @escaping() -> () = { }) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("id_continue", comment: ""), style: .cancel) { _ in completion() })
            self.present(alert, animated: true, completion: nil)
        }
    }

    @MainActor
    func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("id_error", comment: ""), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("id_continue", comment: ""), style: .cancel) { _ in })
            self.present(alert, animated: true, completion: nil)
        }
    }
    @MainActor
    func showError(_ err: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("id_error", comment: ""), message: self.getError(err).localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("id_continue", comment: ""), style: .cancel) { _ in })
            self.present(alert, animated: true, completion: nil)
        }
    }

    func getError(_ err: Error) -> String {
        switch err {
        case AuthenticationTypeHandler.AuthError.CanceledByUser, AuthenticationTypeHandler.AuthError.SecurityError, AuthenticationTypeHandler.AuthError.KeychainError:
            return err.localizedDescription
        case HWError.Abort(let txt), HWError.Declined(let txt), HWError.Disconnected(let txt):
            return txt
        case BleLedgerConnection.LedgerError.IOError,
            BleLedgerConnection.LedgerError.InvalidParameter:
            return "id_operation_failure"
        case LoginError.connectionFailed:
            return "id_connection_failed"
        case LoginError.failed:
            return "id_login_failed"
        case LoginError.walletNotFound:
            return "id_wallet_not_found"
        case LoginError.hostUnblindingDisabled(let txt):
            return txt ?? "id_operation_failed"
        case LoginError.walletMismatch( _):
            return "Wallet mismatch"
        case LoginError.walletsJustRestored(_):
            return "id_wallet_already_restored"
        case LoginError.walletNotFound(_):
            return "id_wallet_not_found"
        case LoginError.invalidMnemonic(_):
            return "id_invalid_mnemonic"
        case GaError.NotAuthorizedError:
            return "Not Authorized Error"
        case GaError.GenericError(let txt):
            return txt ?? "id_operation_failed"
        case TwoFactorCallError.cancel(let txt),
            TwoFactorCallError.failure(let txt):
            return txt
        case TransactionError.invalid(let txt):
            return txt
        case BreezSDK.SdkError.Generic(let msg),
            BreezSDK.SdkError.InitFailed(let msg),
            BreezSDK.SdkError.LspConnectFailed(let msg),
            BreezSDK.SdkError.LspOpenChannelNotSupported(let msg),
            BreezSDK.SdkError.PersistenceFailure(let msg),
            BreezSDK.SdkError.ReceivePaymentFailed(let msg),
            BreezSDK.SdkError.SendPaymentFailed(let msg),
            BreezSDK.SdkError.CalculateOpenChannelFeesFailed(let msg):
            return msg
        default:
            return err.localizedDescription
        }
    }

    @MainActor
    func showOpenSupportUrl(_ request: DialogErrorRequest) {
        Task {
            let url = await ZendeskSdk.shared.createNewTicketUrl(
                subject: request.subject,
                email: nil,
                message: nil,
                error: request.msg,
                network: request.network,
                hw: request.hw)
            if let url = url {
                SafeNavigationManager.shared.navigate(url)
            }
        }
    }

    @MainActor
    func showReportError(account: Account?, wallet: WalletItem?, prettyError: String, screenName: String) {
        let request = DialogErrorRequest(
            account: account,
            networkType: wallet?.networkType ?? .bitcoinSS,
            error: prettyError,
            screenName: screenName)
        let alert = UIAlertController(
            title: "id_error".localized,
            message: prettyError,
            preferredStyle: .alert)
        if AppSettings.shared.gdkSettings?.tor ?? false {
            alert.addAction(UIAlertAction(title: "Contact Support".localized, style: .default) { _ in
                self.showOpenSupportUrl(request)
            })
        } else {
            alert.addAction(UIAlertAction(title: "id_report".localized, style: .default) { _ in
                if let vc = UIStoryboard(name: "Dialogs", bundle: nil)
                    .instantiateViewController(withIdentifier: "DialogErrorViewController") as? DialogErrorViewController {
                    vc.request = request
                    vc.modalPresentationStyle = .overFullScreen
                    self.present(vc, animated: false, completion: nil)
                }
            })
        }
        alert.addAction(UIAlertAction(title: "id_cancel".localized, style: .cancel) { _ in })
        present(alert, animated: true)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboardTappedAround))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboardTappedAround() {
        view.endEditing(true)
    }
}

@nonobjc extension UIViewController {
    func add(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)

        if let frame = frame {
            child.view.frame = frame
        }

        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
