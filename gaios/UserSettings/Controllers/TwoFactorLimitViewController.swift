import Foundation
import UIKit

import gdk

class TwoFactorLimitViewController: KeyboardViewController {

    @IBOutlet weak var limitTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var fiatButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var convertedLabel: UILabel!
    @IBOutlet weak var limitButtonConstraint: NSLayoutConstraint!

    fileprivate var isFiat = false
    var session: SessionManager!

    var amount: String? {
        var amount = limitTextField.text!
        amount = amount.isEmpty ? "0" : amount
        amount = amount.unlocaleFormattedString(8)
        guard let number = Double(amount) else { return nil }
        if number < 0 { return nil }
        return amount
    }

    var satoshi: Int64? {
        guard amount != nil else { return nil }
        if isFiat {
            return Balance.fromFiat(amount ?? "0")?.satoshi
        } else {
            let assetId = session.gdkNetwork.getFeeAsset()
            return Balance.fromDenomination(amount ?? "0", assetId: assetId)?.satoshi
        }
    }

    var limits: TwoFactorConfigLimits? {
        guard let dataTwoFactorConfig = try? session.session?.getTwoFactorConfig() else { return nil }
        guard let twoFactorConfig = try? JSONDecoder().decode(TwoFactorConfig.self, from: JSONSerialization.data(withJSONObject: dataTwoFactorConfig, options: [])) else { return nil }
        return twoFactorConfig.limits
    }

    var denomination: DenominationType {
        return session.settings?.denomination ?? .BTC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("id_twofactor_threshold", comment: "")
        nextButton.setTitle(NSLocalizedString("id_set_twofactor_threshold", comment: ""), for: .normal)
        nextButton.addTarget(self, action: #selector(nextClick), for: .touchUpInside)
        fiatButton.addTarget(self, action: #selector(currencySwitchClick), for: .touchUpInside)
        limitTextField.becomeFirstResponder()
        limitTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        setStyle()
        reload()
    }

    func setStyle() {
        nextButton.setStyle(.primary)
    }

    override func keyboardWillShow(notification: Notification) {
        let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        nextButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -keyboardFrame.height).isActive = true
    }

    func reload() {
        guard let limits = limits else { return }
        isFiat = limits.isFiat
        if limits.isFiat {
            let (amount, denom) = Balance.fromFiat(limits.fiat ?? "0")?.toValue() ?? ("", "")
            descriptionLabel.text = String(format: NSLocalizedString("id_your_twofactor_threshold_is_s", comment: ""), "\(amount) \(denom)")
        } else {
            let denom = denomination.rawValue
            let value: String? = limits.get(TwoFactorConfigLimits.CodingKeys(rawValue: denom)!)
            let assetId = session.gdkNetwork.getFeeAsset()
            let (amount, _) = Balance.fromDenomination(value ?? "0", assetId: assetId)?.toFiat() ?? ("", "")
            descriptionLabel.text = String(format: NSLocalizedString("id_your_twofactor_threshold_is_s", comment: ""), "\(amount) \(denom)")
        }
        refresh()
    }

    func refresh() {
        if let balance = Balance.fromSatoshi(satoshi ?? 0, assetId: session.gdkNetwork.getFeeAsset()) {
            let (amount, denom) = isFiat ? balance.toDenom() : balance.toFiat()
            let denomination = isFiat ? balance.toFiat().1 : balance.toDenom().1
            convertedLabel.text = "≈ \(amount) \(denom)"
            fiatButton.setTitle(denomination, for: UIControl.State.normal)
            fiatButton.backgroundColor = isFiat ? UIColor.clear : UIColor.customMatrixGreen()
        }
    }

    @objc func currencySwitchClick(_ sender: UIButton) {
        if let balance = Balance.fromSatoshi(satoshi ?? 0, assetId: session.gdkNetwork.getFeeAsset()) {
            let amount = isFiat ? balance.toFiat().0 : balance.toDenom().0
            limitTextField.text = amount
        }
        isFiat = !isFiat
        refresh()
    }

    @objc func nextClick(_ sender: UIButton) {
        guard amount != nil else { return }
        let details = isFiat ? ["is_fiat": isFiat, "fiat": amount!] : ["is_fiat": isFiat, denomination.rawValue: amount!]
        self.startAnimating()
        Task {
            do {
                try await self.session.setTwoFactorLimit(details: details)
                self.navigationController?.popViewController(animated: true)
            } catch {
                if let twofaError = error as? TwoFactorCallError {
                    switch twofaError {
                    case .failure(let localizedDescription), .cancel(let localizedDescription):
                        DropAlert().error(message: localizedDescription)
                    }
                } else {
                    DropAlert().error(message: error.localizedDescription)
                }
            }
            self.stopAnimating()
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        refresh()
    }
}
