import Foundation
import UIKit
import gdk
import greenaddress
import hw
import BreezSDK
import lightning

enum ReceiveType: Int, CaseIterable {
    case address
    case swap
    case bolt11
}

class ReceiveViewModel {
    
    var accounts: [WalletItem]
    var asset: String
    var satoshi: Int64?
    var isFiat: Bool = false
    var account: WalletItem
    var type: ReceiveType
    var description: String?
    var address: Address?
    var invoice: LnInvoice?
    var swap: SwapInfo?
    var inputDenomination: gdk.DenominationType?

    var wm: WalletManager { WalletManager.current! }

    init(account: WalletItem, accounts: [WalletItem]) {
        self.account = account
        self.accounts = accounts
        self.asset = account.gdkNetwork.getFeeAsset()
        self.type = account.gdkNetwork.lightning ? .bolt11 : .address
    }

    func accountType() -> String {
        return account.localizedName
    }

    func newAddress() async throws {
        switch type {
        case .address:
            address = nil
            let session = self.wm.sessions[account.gdkNetwork.network]
            address = try await session?.getReceiveAddress(subaccount: account.pointer)
        case .bolt11:
            invoice = nil
            if satoshi == nil {
                return
            }
            invoice = try await wm.lightningSession?.createInvoice(satoshi: UInt64(satoshi ?? 0), description: description ?? "")
        case .swap:
            swap = try await wm.lightningSession?.lightBridge?.receiveOnchain()
        }
    }

    func isBipAddress(_ addr: String) -> Bool {
        let session = wm.sessions[account.gdkNetwork.network]
        return session?.validBip21Uri(uri: addr) ?? false
    }

    func validateHw() async throws -> Bool {
        guard let addr = address else {
            throw GaError.GenericError()
        }
        let res = try await BleViewModel.shared.validateAddress(account: account, address: addr)
        return res 
    }

    func addressToUri(address: String, satoshi: Int64) -> String {
        var ntwPrefix = "bitcoin"
        if account.gdkNetwork.liquid {
            ntwPrefix = account.gdkNetwork.mainnet ? "liquidnetwork" :  "liquidtestnet"
        }
        if satoshi == 0 {
            return address
        }
        return String(format: "%@:%@?amount=%.8f", ntwPrefix, address, toBTC(satoshi))
    }

    func toBTC(_ satoshi: Int64) -> Double {
        return Double(satoshi) / 100000000
    }

    var amountCellModel: LTAmountCellModel {
        var amountCell = LTAmountCellModel()
        let nodeState = account.lightningSession?.nodeState
        let lspInfo = account.lightningSession?.lspInfo
        amountCell.isFiat = isFiat
        amountCell.satoshi = satoshi
        amountCell.maxLimit = nodeState?.maxReceivableSatoshi
        amountCell.channelFeePercent =  lspInfo?.channelFeePercent
        amountCell.channelMinFee =  lspInfo?.channelMinimumFeeSatoshi
        amountCell.inboundLiquidity =  nodeState?.inboundLiquiditySatoshi
        amountCell.inputDenomination = inputDenomination
        return amountCell
    }

    var infoReceivedAmountCellModel: LTInfoCellModel {
        if let invoice = invoice, let satoshi = invoice.amountSatoshi {
            if let balance = Balance.fromSatoshi(Int64(satoshi), assetId: "btc") {
                let (value, denom) = balance.toDenom()
                let (fiat, currency) = balance.toFiat()
                return LTInfoCellModel(title: "Amount to Receive", hint1: "\(value) \(denom)", hint2: "\(fiat) \(currency)")
            }
        }
        return LTInfoCellModel(title: "Amount to Receive", hint1: "", hint2: "")
    }

    var infoExpiredInCellModel: LTInfoCellModel {
        if let invoice = invoice {
            let numberOfDays = Calendar.current.dateComponents([.day], from: invoice.expireInAsDate, to: Date())
            return LTInfoCellModel(title: "Expiration", hint1: "In \(abs(numberOfDays.day ?? 0)) days", hint2: "")
        }
        return LTInfoCellModel(title: "Expiration", hint1: "", hint2: "")
    }

    var noteCellModel: LTNoteCellModel {
        return LTNoteCellModel(note: description ?? "Some note")
    }

    var assetCellModel: ReceiveAssetCellModel {
        return ReceiveAssetCellModel(assetId: asset, account: account)
    }

    var text: String? {
        switch type {
        case .bolt11:
            if let txt = invoice?.bolt11 {
                return "lightning:\( (txt).uppercased() )"
            }
            return nil
        case .swap:
            return swap?.bitcoinAddress
        case .address:
            var text = address?.address
            if let address = address?.address, let satoshi = satoshi {
                text = addressToUri(address: address, satoshi: satoshi)
            }
            return text
        }
    }

    var addressCellModel: ReceiveAddressCellModel {
        return ReceiveAddressCellModel(text: text, tyoe: type)
    }

    func getAssetSelectViewModel() -> AssetSelectViewModel {
        let isLiquid = account.gdkNetwork.liquid
        let showAmp = accounts.filter { $0.type == .amp }.count > 0
        let showLiquid = accounts.filter { $0.gdkNetwork.liquid }.count > 0
        let showBtc = accounts.filter { !$0.gdkNetwork.liquid }.count > 0
        let assets = WalletManager.current?.registry.all
            .filter {
                (showAmp && $0.amp ?? false) ||
                (showLiquid && $0.assetId != AssetInfo.btcId) ||
                (showBtc && $0.assetId == AssetInfo.btcId)
            }
        let list = AssetAmountList.from(assetIds: assets?.map { $0.assetId } ?? [])
        return AssetSelectViewModel(assets: list, enableAnyAsset: isLiquid)
    }

    func getAssetExpandableSelectViewModel() -> AssetExpandableSelectViewModel {
        let isWO = AccountsRepository.shared.current?.isWatchonly ?? false
        let isLiquid = account.gdkNetwork.liquid
        var assets = WalletManager.current?.registry.all ?? []
        if isWO {
            let showBtc = !(AccountsRepository.shared.current?.gdkNetwork.liquid ?? false)
            let showLiquid = (AccountsRepository.shared.current?.gdkNetwork.liquid ?? false)
            assets = assets.filter {
                (showLiquid && $0.assetId != AssetInfo.btcId) ||
                (showBtc && $0.assetId == AssetInfo.btcId)
            }
        }
        let list = AssetAmountList.from(assetIds: assets.map { $0.assetId })
        return AssetExpandableSelectViewModel(assets: list, enableAnyAsset: true /* isLiquid */, onlyFunded: false)
    }

    func dialogInputDenominationViewModel(inputDenomination: DenominationType?) -> DialogInputDenominationViewModel? {
        guard let session =  account.session else { return nil }

        let list: [DenominationType] = [ .BTC, .MilliBTC, .MicroBTC, .Bits, .Sats]
        var selected = DenominationType.Sats // todo: settings.denomination
        if let inputDenomination = inputDenomination { selected = inputDenomination }
        let network: NetworkSecurityCase = session.gdkNetwork.mainnet ? .bitcoinSS : .testnetSS
        return DialogInputDenominationViewModel(denomination: selected,
                                           denominations: list,
                                           network: network,
                                            isFiat: isFiat)
    }

    func getBalance() -> Balance? {
        return Balance.fromSatoshi(satoshi ?? 0.0, assetId: asset)
    }
}
