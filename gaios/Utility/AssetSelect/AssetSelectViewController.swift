import UIKit

protocol AssetSelectViewControllerDelegate: AnyObject {
    func didSelectAsset(_ assetId: String)
    func didSelectAnyAsset()
}

class AssetSelectViewController: UIViewController {

    @IBOutlet weak var searchCard: UIView!
    @IBOutlet weak var btnSearch: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchField: UITextField!

    var viewModel: AssetSelectViewModel!
    weak var delegate: AssetSelectViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        ["AssetSelectCell", "AnyAssetCell"].forEach {
            tableView.register(UINib(nibName: $0, bundle: nil), forCellReuseIdentifier: $0)
        }
        searchField.delegate = self
        title = "id_select_asset".localized
        setContent()
        setStyle()

        viewModel.reload = tableView.reloadData
    }

    func setContent() {
        searchField.attributedPlaceholder = NSAttributedString(string: "Search Asset", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.4)])
    }

    func setStyle() {
        searchCard.cornerRadius = 5.0
    }

    @objc func triggerTextChange() {
        viewModel?.search(searchField.text ?? "")
        tableView.reloadData()
    }

    @IBAction func onEditingChange(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.triggerTextChange), object: nil)
        perform(#selector(self.triggerTextChange), with: nil, afterDelay: 0.5)
    }
}

extension AssetSelectViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let cnt = viewModel?.assetSelectCellModelsFilter.count ?? 0
        return cnt + (viewModel?.enableAnyAsset ?? false ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cnt = viewModel?.assetSelectCellModelsFilter.count ?? 0
        if cnt == indexPath.row {
            if let cell = tableView.dequeueReusableCell(withIdentifier: AnyAssetCell.identifier, for: indexPath) as? AnyAssetCell {
                cell.configure()
                cell.selectionStyle = .none
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: AssetSelectCell.identifier, for: indexPath) as? AssetSelectCell {
                let model = viewModel.assetSelectCellModelsFilter[indexPath.row]
                cell.configure(model: model, showEditIcon: false)
                cell.selectionStyle = .none
                return cell
            }
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
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
        AnalyticsManager.shared.selectAsset(account: AccountsRepository.shared.current)
        let cnt = viewModel?.assetSelectCellModelsFilter.count ?? 0
        if cnt == indexPath.row {
            delegate?.didSelectAnyAsset()
            navigationController?.popViewController(animated: true)
            return
        }
        let assetCellModel = viewModel?.assetSelectCellModelsFilter[indexPath.row] as? AssetSelectCellModel
        let asset = assetCellModel?.asset?.assetId
        delegate?.didSelectAsset(asset ?? "")
        navigationController?.popViewController(animated: true)
    }
}

extension AssetSelectViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
