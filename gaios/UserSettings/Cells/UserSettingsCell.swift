import UIKit

class UserSettingsCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblHint: UILabel!
    @IBOutlet weak var bg: UIView!
    @IBOutlet weak var actionSwitch: UISwitch!
    @IBOutlet weak var disclosure: UIImageView!
    @IBOutlet weak var copyImg: UIImageView!

    class var identifier: String { return String(describing: self) }

    override func awakeFromNib() {
        super.awakeFromNib()
        lblTitle.textColor = .white
        lblHint.textColor = .white.withAlphaComponent(0.4)
        bg.layer.cornerRadius = 7.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    var viewModel: UserSettingsCellModel? {
        didSet {
            lblTitle.text = viewModel?.title
            lblHint.text = viewModel?.subtitle
            actionSwitch.isEnabled = false
            actionSwitch.isOn = viewModel?.switcher ?? false
            actionSwitch.isHidden = viewModel?.switcher == nil
            disclosure.isHidden = !(viewModel?.disclosure ?? false)
            disclosure.image = viewModel?.disclosureImage
            copyImg.isHidden = viewModel?.type != .SupportID
        }
    }
}
