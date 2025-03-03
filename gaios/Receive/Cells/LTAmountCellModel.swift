import Foundation
import UIKit
import BreezSDK
import gdk
import lightning

struct LTAmountCellModel {
    var satoshi: Int64?
    var maxLimit: UInt64?
    var isFiat: Bool
    var inputDenomination: gdk.DenominationType
    var gdkNetwork: gdk.GdkNetwork?
    var nodeState: NodeState?
    var lspInfo: LspInformation?
    var breezSdk: LightningBridge?

    var amountText: String? { isFiat ? fiat : btc }
    var denomText: String? {
        if isFiat {
            return currency == nil ? defaultCurrency : currency
        } else {
            if let gdkNetwork = gdkNetwork {
                return inputDenomination.string(for: gdkNetwork)
            } else {
                return defaultDenomination
            }
        }
    }
    var toReceiveAmountStr: String {
        if let satoshi = satoshi, let openChannelFee = openChannelFee, let balance = Balance.fromSatoshi(satoshi - openChannelFee, assetId: "btc") {
            let (value, denom) = balance.toDenom(inputDenomination)
            let (fiat, currency) = balance.toFiat()
            return "\(value) \(denom) ~(\(fiat) \(currency))"
        }
        return ""
    }
    var denomUnderlineText: NSAttributedString {
        return NSAttributedString(string: denomText ?? "", attributes:
            [.underlineStyle: NSUnderlineStyle.single.rawValue])
    }
    
    var btc: String? {
        if let satoshi = satoshi {
            return Balance.fromSatoshi(satoshi, assetId: AssetInfo.btcId)?.toDenom(inputDenomination).0
        }
        return nil
    }
    var fiat: String? {
        if let satoshi = satoshi {
            return Balance.fromSatoshi(satoshi, assetId: AssetInfo.btcId)?.toFiat().0
        }
        return nil
    }
    var currency: String? {
        if let satoshi = satoshi {
            return Balance.fromSatoshi(satoshi, assetId: AssetInfo.btcId)?.toFiat().1
        }
        return nil
    }
    
    var maxLimitAmount: String? {
        if let maxLimit = maxLimit {
            let balance = Balance.fromSatoshi(UInt64(maxLimit), assetId: AssetInfo.btcId)
            return isFiat ? balance?.toFiat().0 : balance?.toDenom(inputDenomination).0
        }
        return nil
    }

    var state: LTAmountCellState {
        guard let satoshi = satoshi else {
            return .disabled
        }
        guard let lspInfo = lspInfo, let nodeState = nodeState else {
            return .disconnected
        }
        if satoshi >= nodeState.maxReceivableSatoshi {
            return .tooHigh
        } else if satoshi <= nodeState.inboundLiquiditySatoshi || satoshi >= openChannelFee ?? 0 {
            if nodeState.inboundLiquiditySatoshi == 0 || satoshi > nodeState.inboundLiquiditySatoshi {
                return .validFunding
            } else {
                return .valid
            }
        } else if satoshi <= openChannelFee ?? 0 {
            return .tooLow
        } else {
            return .disabled
        }
    }
    var defaultCurrency: String? = {
        return Balance.fromSatoshi(0, assetId: AssetInfo.btcId)?.toFiat().1
    }()
    var defaultDenomination: String? = {
        return Balance.fromSatoshi(0, assetId: AssetInfo.btcId)?.toDenom().1
    }()

    var openChannelFee: Int64? {
        let channelFee = try? breezSdk?.openChannelFee(satoshi: Long(satoshi ?? 0))?.feeMsat.satoshi
        if let channelFee = channelFee {
            return Int64(channelFee)
        }
        return nil
    }

    func toFiatText(_ amount: Int64?) -> String? {
        if let amount = amount {
            return Balance.fromSatoshi(amount, assetId: AssetInfo.btcId)?.toFiatText()
        }
        return nil
    }
    func toBtcText(_ amount: Int64?) -> String? {
        if let amount = amount {
            return Balance.fromSatoshi(amount, assetId: AssetInfo.btcId)?.toText(inputDenomination)
        }
        return nil
    }
}
