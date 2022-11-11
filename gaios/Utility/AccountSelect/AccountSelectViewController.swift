import UIKit
import PromiseKit

enum AccountSelectSection: Int, CaseIterable {
    case account
    case footer
}

class AccountSelectViewController: UIViewController {

    enum FooterType {
        case none
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnAdvanced: UIButton!

    private var headerH: CGFloat = 54.0
    private var footerH: CGFloat = 54.0

    var viewModel: AccountSelectViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        let reloadSections: (([AccountSelectSection], Bool) -> Void)? = { [weak self] (sections, animated) in
            self?.reloadSections(sections, animated: true)
        }
        viewModel?.reloadSections = reloadSections

        ["AccountSelectCell" ].forEach {
            tableView.register(UINib(nibName: $0, bundle: nil), forCellReuseIdentifier: $0)
        }

        setContent()
        setStyle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    func reloadSections(_ sections: [AccountSelectSection], animated: Bool) {
        if animated {
            tableView.reloadSections(IndexSet(sections.map { $0.rawValue }), with: .none)
        } else {
            UIView.performWithoutAnimation {
                tableView.reloadSections(IndexSet(sections.map { $0.rawValue }), with: .none)
            }
        }
    }

    func setContent() {
        title = "Select Account"
        btnAdvanced.setTitle("Create a new account", for: .normal)
    }

    func setStyle() {
    }

    @IBAction func btnAdvanced(_ sender: Any) {
        print("btnAdvanced")
    }
}

extension AccountSelectViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return AccountSelectSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch AccountSelectSection(rawValue: section) {
        case .account:
            return viewModel?.accountSelectCellModels.count ?? 0
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch AccountSelectSection(rawValue: indexPath.section) {
        case .account:
            if let cell = tableView.dequeueReusableCell(withIdentifier: AccountSelectCell.identifier, for: indexPath) as? AccountSelectCell,
               let model = viewModel {
                cell.configure(model: model.accountSelectCellModels[indexPath.row])
                cell.selectionStyle = .none
                return cell
            }
        default:
            break
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch AccountSelectSection(rawValue: section) {
        default:
            return headerH
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch AccountSelectSection(rawValue: section) {
        case .footer:
            return 100.0
        default:
            return 0.1
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        switch AccountSelectSection(rawValue: indexPath.section) {
        default:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        switch AccountSelectSection(rawValue: section) {
        case .account:
            return headerView( "Accounts" )
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch AccountSelectSection(rawValue: section) {
        default:
            return footerView(.none)
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch AccountSelectSection(rawValue: indexPath.section) {
        default:
            return indexPath
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch AccountSelectSection(rawValue: indexPath.section) {
        case .account:
            /// handle selection
            navigationController?.popToViewController(ofClass: ReceiveViewController.self)
        default:
            break
        }
    }
}

extension AccountSelectViewController {

    func headerView(_ txt: String) -> UIView {

        let section = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: headerH))
        section.backgroundColor = UIColor.clear
        let title = UILabel(frame: .zero)
        title.font = .systemFont(ofSize: 14.0, weight: .semibold)
        title.text = txt
        title.textColor = .white.withAlphaComponent(0.6)
        title.numberOfLines = 1

        title.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(title)

        NSLayoutConstraint.activate([
            title.centerYAnchor.constraint(equalTo: section.centerYAnchor, constant: 10.0),
            title.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 30),
            title.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: 30)
        ])

        return section
    }

    func footerView(_ type: FooterType) -> UIView {

        switch type {
        default:
            let section = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 1.0))
            section.backgroundColor = .clear
            return section
        }
    }
}
