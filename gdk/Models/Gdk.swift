import Foundation
import greenaddress

public struct WalletIdentifier: Codable {
    enum CodingKeys: String, CodingKey {
        case walletHashId = "wallet_hash_id"
        case xpubHashId = "xpub_hash_id"
    }
    public let walletHashId: String
    public let xpubHashId: String
}

public struct SystemMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case text
        case network
    }
    public let text: String
    public let network: String

    public init(text: String,
                network: String) {
        self.text = text
        self.network = network
    }
}

public struct TwoFactorResetMessage: Codable {
    public enum CodingKeys: String, CodingKey {
        case twoFactorReset
        case network
    }
    public let twoFactorReset: TwoFactorReset
    public let network: String
    public init(twoFactorReset: TwoFactorReset, network: String) {
        self.twoFactorReset = twoFactorReset
        self.network = network
    }
}

public struct DecryptWithPinParams: Codable {
    enum CodingKeys: String, CodingKey {
        case pin
        case pinData  = "pin_data"
    }
    public let pin: String
    public let pinData: PinData

    public init(pin: String, pinData: PinData) {
        self.pin = pin
        self.pinData = pinData
    }
}

public struct EncryptWithPinParams: Codable {
    enum CodingKeys: String, CodingKey {
        case pin
        case plaintext
    }
    public let pin: String
    public let plaintext: Credentials

    public init(pin: String, credentials: Credentials) {
        self.pin = pin
        self.plaintext = credentials
    }
}

public struct EncryptWithPinResult: Codable {
    enum CodingKeys: String, CodingKey {
        case pinData = "pin_data"
    }
    public let pinData: PinData
}

public struct LoginUserResult: Codable {
    enum CodingKeys: String, CodingKey {
        case xpubHashId = "xpub_hash_id"
        case walletHashId = "wallet_hash_id"
    }
    public let xpubHashId: String
    public let walletHashId: String
    public init(xpubHashId: String, walletHashId: String) {
        self.xpubHashId = xpubHashId
        self.walletHashId = walletHashId
    }
}

public struct GetSubaccountsParams: Codable {
    enum CodingKeys: String, CodingKey {
        case refresh
    }
    public let refresh: Bool

    public init(refresh: Bool) {
        self.refresh = refresh
    }
}

public struct GetSubaccountsResult: Codable {
    enum CodingKeys: String, CodingKey {
        case subaccounts
    }
    public let subaccounts: [WalletItem]
}

public struct GetSubaccountParams: Codable {
    enum CodingKeys: String, CodingKey {
        case pointer
    }
    public let pointer: UInt32
}

public struct GetAssetsParams: Codable {
    enum CodingKeys: String, CodingKey {
        case assetsId = "assets_id"
    }
    public let assetsId: [String]

    public init(assetsId: [String]) {
        self.assetsId = assetsId
    }
}

public struct GetAssetsResult: Codable {
    public let assets: [String: AssetInfo]
    public let icons: [String: String]
}

public struct ValidateAddresseesParams: Codable {
    public let addressees: [Addressee]
    public init(addressees: [Addressee]) {
        self.addressees = addressees
    }
}

public struct SignMessageParams: Codable {
    enum CodingKeys: String, CodingKey {
        case address
        case message
    }
    public let address: String
    public let message: String
    public init(address: String, message: String) {
        self.address = address
        self.message = message
    }
}

public struct SignMessageResult: Codable {
    enum CodingKeys: String, CodingKey {
        case signature
    }
    public let signature: String
    public init(signature: String) {
        self.signature = signature
    }
}

public struct GetPreviousAddressesParams: Codable {
    enum CodingKeys: String, CodingKey {
        case subaccount
        case lastPointer = "last_pointer"
    }
    public let subaccount: Int
    public let lastPointer: Int?
    public init(subaccount: Int, lastPointer: Int?) {
        self.subaccount = subaccount
        self.lastPointer = lastPointer
    }
}

public struct GetPreviousAddressesResult: Codable {
    enum CodingKeys: String, CodingKey {
        case list
        case lastPointer = "last_pointer"
    }
    public let list: [Address]
    public let lastPointer: Int?
    public init(list: [Address], lastPointer: Int?) {
        self.list = list
        self.lastPointer = lastPointer
    }
}

public struct ValidateAddresseesResult: Codable {
    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case errors
        case addressees
    }
    public let isValid: Bool
    public let errors: [String]
    public let addressees: [Addressee]
    public init(isValid: Bool, errors: [String], addressees: [Addressee]) {
        self.isValid = isValid
        self.errors = errors
        self.addressees = addressees
    }
}

public struct CreateSubaccountParams: Codable {
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case type = "type"
        case recoveryMnemonic = "recovery_mnemonic"
        case recoveryXpub = "recovery_xpub"
    }

    public let name: String
    public let type: AccountType
    public let recoveryMnemonic: String?
    public let recoveryXpub: String?

    public init(name: String, type: AccountType, recoveryMnemonic: String? = nil, recoveryXpub: String? = nil) {
        self.name = name
        self.type = type
        self.recoveryMnemonic = recoveryMnemonic
        self.recoveryXpub = recoveryXpub
    }
}

public struct UnspentOutputsForPrivateKeyParams: Codable {
    enum CodingKeys: String, CodingKey {
        case privateKey = "private_key"
        case password
    }

    public let privateKey: String
    public let password: String?

    public init(privateKey: String, password: String?) {
        self.privateKey = privateKey
        self.password = password
    }
}

public struct ResolveCodeData: Codable {
    enum CodingKeys: String, CodingKey {
        case attemptsRemaining = "attempts_remaining"
        case status
        case name
        case method
        case action
    }
    let attemptsRemaining: Int64?
    let status: String?
    let name: String?
    let method: String?
    let action: String?
}

public struct BcurDecodeParams: Codable {
    enum CodingKeys: String, CodingKey {
        case part
    }
    public let part: String
    public init(part: String) {
        self.part = part
    }
}

public struct BcurEncodedData: Codable {
    enum CodingKeys: String, CodingKey {
        case parts
    }
    public let parts: [String]
    public init(parts: [String]) {
        self.parts = parts
    }
}

public struct BcurEncodeParams: Codable {
    enum CodingKeys: String, CodingKey {
        case urType = "ur_type"
        case data
        case numWords = "num_words"
        case index
        case privateKey = "private_key"
        case maxFragmentLen = "max_fragment_len"
    }
    public let urType: String
    public let data: String?
    public let numWords: Int?
    public let index: Int?
    public let privateKey: String?
    public let maxFragmentLen: Int?
    public init(urType: String, data: String? = nil, numWords: Int? = nil, index: Int? = nil, privateKey: String? = nil, maxFragmentLen: Int = 48) {
        self.urType = urType
        self.data = data
        self.numWords = numWords
        self.index = index
        self.privateKey = privateKey
        self.maxFragmentLen = maxFragmentLen
    }
}

public struct BcurDecodedData: Codable {
    enum CodingKeys: String, CodingKey {
        case urType = "ur_type"
        case data
        case psbt
        case descriptor
        case descriptors
        case masterFingerprint = "master_fingerprint"
        case encrypted
        case publicΚey = "public_key"
    }
    public let urType: String
    public let data: String?
    public let psbt: String?
    public let descriptor: String?
    public let descriptors: [String]?
    public let masterFingerprint: String?
    public let encrypted: String?
    public let publicΚey: String?
    public var result: String {
        descriptors?.joined(separator: ",") ?? descriptor ?? psbt ?? data ?? ""
    }
}

public struct GdkInit: Codable {
    enum CodingKeys: String, CodingKey {
        case datadir
        case tordir
        case registrydir
        case logLevel = "log_level"
    }
    public let datadir: String?
    public let tordir: String?
    public let registrydir: String?
    public let logLevel: String
    public var breezSdkDir: String { "\(datadir ?? "")/breezSdk" }

    public static func defaults() -> GdkInit {
        let appSupportDir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let cacheDir = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var logLevel = "none"
#if DEBUG
        logLevel = "info"
#endif
        return GdkInit(datadir: appSupportDir?.path,
                       tordir: cacheDir?.path,
                       registrydir: cacheDir?.path,
                       logLevel: logLevel)
    }

    public func run() {
        try? gdkInit(config: self.toDict() ?? [:])
    }
}
