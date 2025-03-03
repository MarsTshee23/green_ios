import UIKit
import gdk

class AccountCell: UITableViewCell {

    @IBOutlet weak var bg: UIView!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var effectView: UIView!
    @IBOutlet weak var innerEffectView: UIView!
    @IBOutlet weak var btcImg: UIImageView!
    @IBOutlet weak var btnSelect: UIButton!
    @IBOutlet weak var btnCopy: UIButton!
    @IBOutlet weak var btnShield: UIButton!
    @IBOutlet weak var btnShieldWide: UIButton!
    @IBOutlet weak var imgMS: UIImageView!
    @IBOutlet weak var lblType: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblFiat: UILabel!
    @IBOutlet weak var lblAmount: UILabel!

    @IBOutlet var icContainers: [UIView]!
    @IBOutlet var icImgViews: [UIImageView]!

    @IBOutlet weak var trailing2_1: NSLayoutConstraint!
    @IBOutlet weak var trailing3_2: NSLayoutConstraint!
    @IBOutlet weak var trailing4_3: NSLayoutConstraint!
    @IBOutlet weak var titlesTrailing: NSLayoutConstraint!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    @IBOutlet weak var ltExperimental: UIView!
    @IBOutlet weak var lblLtEXperimental: UILabel!
    @IBOutlet weak var lblLtExpBg: UIView!
    @IBOutlet weak var ltIconExp: UIImageView!
    @IBOutlet weak var btnExperimental: UIButton!
    @IBOutlet weak var iconLeading: NSLayoutConstraint!

    private var sIdx: Int = 0
    private var cIdx: Int = 0
    private var hideBalance: Bool = false
    private var isLast: Bool = false
    private var onSelect: (() -> Void)?
    private var onCopy: (() -> Void)?
    private var onShield: ((Int) -> Void)?
    private var onExperiental: (() -> Void)?
    private let iconW: CGFloat = 24
    private var cColor: UIColor = .clear

    static var identifier: String { return String(describing: self) }

    override func awakeFromNib() {
        super.awakeFromNib()

        bg.cornerRadius = 5.0
        innerEffectView.layer.cornerRadius = 5.0
        innerEffectView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        btnShield.borderWidth = 1.0
        btnShield.borderColor = .black
        btnShield.cornerRadius = 16.0
        [btnSelect, btnCopy].forEach {
            $0?.borderWidth = 1.5
            $0?.borderColor = .white
            $0?.cornerRadius = 3.0
        }
        btnCopy.setTitle("id_amp_id".localized, for: .normal)
        icContainers.forEach {
            $0.borderWidth = 1.0
            $0.borderColor = UIColor.white
            $0.cornerRadius = $0.frame.size.width / 2.0
            $0.backgroundColor = cColor.darker(by: 10)
        }
        icImgViews.forEach {
            $0.cornerRadius = $0.frame.size.width / 2.0
            $0.clipsToBounds = true
        }
        icContainers.forEach { $0.isHidden = true }
        icImgViews.forEach { $0.image = UIImage() }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        select(selected)
    }

    func stringForAttachment() -> NSAttributedString {
        if #available(iOS 13.0, *) {
            let attachment = NSTextAttachment()
            let image = UIImage(systemName: "asterisk")?.withTintColor(.white)
            attachment.image = image
            let fullString = NSMutableAttributedString(string: "")
            fullString.append(NSAttributedString(attachment: attachment))
            return fullString
        } else {
            return NSAttributedString()
        }
    }

    // swiftlint:disable function_parameter_count
    func configure(model: AccountCellModel,
                   cIdx: Int,
                   sIdx: Int,
                   hideBalance: Bool,
                   isLast: Bool,
                   onSelect: (() -> Void)?,
                   onCopy: (() -> Void)?,
                   onShield: ((Int) -> Void)?,
                   onExperiental: (() -> Void)?
    ) {
        setIsLoading(model.satoshi == nil)
        self.cIdx = cIdx
        self.sIdx = sIdx
        self.hideBalance = hideBalance
        self.isLast = isLast
        self.onSelect = onSelect
        self.onCopy = onCopy
        self.onShield = onShield
        self.onExperiental = onExperiental
        
        lblType.text = model.lblType
        lblName.text = NSLocalizedString(model.name, comment: "")
        
        if hideBalance {
            lblFiat.attributedText = Common.obfuscate(color: .white, size: 12, length: 5)
            lblAmount.attributedText = Common.obfuscate(color: .white, size: 16, length: 5)
        } else {
            lblFiat.text = model.fiatStr
            lblAmount.text = model.balanceStr
        }
        let network = model.networkType
        let session = model.account.session
        let watchOnly = WalletManager.current?.account.isWatchonly ?? false
        let enabled2FA = session?.twoFactorConfig?.anyEnabled ?? false
        let hideShield = onSelect == nil || !network.multisig || enabled2FA || watchOnly
        btnShield.isHidden = hideShield
        btnShieldWide.isHidden = hideShield
        cColor = color(network: network)
        btcImg.isHidden = network.liquid
        btcImg.image = backgroundImage(network: network)
        imgMS.image = backgroundIcon(network: network)
        
        ltExperimental.isHidden = !(model.networkType.lightning && AppSettings.shared.lightningEnabled)
        lblLtEXperimental.text = "id_experimental".localized
        ltIconExp.image = UIImage(named: "ic_lightning_info")?.maskWithColor(color: .white)
        lblLtExpBg.layer.cornerRadius = 4.0
        
        [bg, effectView, btnShield].forEach {
            $0?.backgroundColor = cColor
        }
        btnSelect.isHidden = onSelect == nil
        btnCopy.isHidden = onCopy == nil || model.account.type != .amp // only for amp
        reloadAmounts(model)
    }

    func reloadAmounts(_ model: AccountCellModel) {
        let list = model.hasTxs ? model.account.satoshi ?? [:] : [:]
        let assets = AssetAmountList(list)
        let registry = WalletManager.current?.registry
        var icons = [UIImage]()
        assets.amounts.compactMap {
            if model.networkType.lightning && $0.0 == "btc" {
                return UIImage(named: "ic_lightning_btc")
            }
            return registry?.image(for: $0.0)
        }
        .forEach { if !icons.contains($0) { icons += [$0] } }

        icContainers.forEach { $0.isHidden = true }
        icImgViews.forEach { $0.image = UIImage() }
        let padding: CGFloat = icons.count > 4 ? -20 : -10
        [trailing2_1, trailing3_2, trailing4_3].forEach {
            $0?.constant = padding
        }

        titlesTrailing.constant = 0.0
        let width = icContainers[0].frame.width

        if icons.count > 4 {
            [icImgViews[0], icImgViews[1], icImgViews[2]].forEach {
                $0.image = UIImage()
                $0.backgroundColor = cColor
            }
            for n in 3..<7 {
                icContainers[n].isHidden = false
                icImgViews[n].image = icons[7 - 1 - n]
            }
            titlesTrailing.constant = -width * 4.0 - 10.0 + 30.0 - 30.0
            icContainers.forEach { $0.isHidden = false }
        } else {
            for n in 0..<icons.count {
                icContainers[n].isHidden = false
                icImgViews[n].image = icons[(icons.count - 1) - n]
            }
            titlesTrailing.constant = -width * CGFloat(icons.count) - 10.0 + CGFloat(icons.count - 1) * 10.0
        }
    }

    func color(network: NetworkSecurityCase) -> UIColor {
        if network.liquid {
            return network.testnet ? UIColor.gAccountTestLightBlue() : UIColor.gAccountLightBlue()
        } else if network.lightning {
            return UIColor.gLightning()
        } else {
            return network.testnet ? UIColor.gAccountTestGray() : UIColor.gAccountOrange()
        }
    }

    func backgroundImage(network: NetworkSecurityCase) -> UIImage? {
        if network.lightning {
            return UIImage(named: "ic_lightning_bg")
        } else {
            return UIImage(named: "ic_btc_outlined")
        }
    }

    func backgroundIcon(network: NetworkSecurityCase) -> UIImage? {
        iconLeading.constant = 0.0
        if network.lightning {
            iconLeading.constant = -2.0
            return UIImage(named: "ic_lightning_plain")
        } else if network.multisig {
            return UIImage(named: "ic_key_ms")
        } else if network.singlesig {
            return UIImage(named: "ic_key_ss")
        }
        return nil
    }

    func updateUI(_ value: Bool) {
        self.detailView.alpha = value ? 1.0 : 0.0
        if self.isLast {
            self.effectView.alpha = 0.0
        } else {
            self.effectView.alpha = 0.0 // value ? 0.0 : 1.0
        }
    }

    func select(_ value: Bool) {
        if cIdx == sIdx {
            self.updateUI(value)
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.updateUI(value)
            })
        }
    }

    func setIsLoading(_ state: Bool) {
        state ? loader.startAnimating() : loader.stopAnimating()
        lblAmount.isHidden = state
        lblFiat.isHidden = state
    }

    @IBAction func btnSelect(_ sender: Any) {
        onSelect?()
    }

    @IBAction func btnCopy(_ sender: Any) {
        onCopy?()
    }

    @IBAction func btnShieldWide(_ sender: Any) {
        onShield?(cIdx)
    }

    @IBAction func btnExperimental(_ sender: Any) {
        onExperiental?()
    }
}
