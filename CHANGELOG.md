# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
- Remove lightning account with shortcut

## [4.0.19] - 2023-11-22

### Added
- Scan BCUR animated qr code
- Add watch-only import from Jade
- Add delegated Lightning account for Jade (bip85)

### Changed
- Update Breez SDK to 0.2.7
- Update GDK to 0.69.0

## [4.0.18] - 2023-11-07

### Added
- Lightning support LNURL withdraw
- Lightning Shortcuts

### Changed
- Update GDK to release 0.68.4

### Fixed
- Improve QR Scanner

## [4.0.16] - 2023-10-17

### Fixed
- Fix racy crash when using camera
- Improve parsing of LNURL
- Fix connection to custom electrum server through Tor

### Changed
- Improve error messages

## [4.0.15] - 2023-10-12

### Changed
- Bump BreezSdk to 0.2.5
- Update GDK to Release 0.68.1

## [4.0.14] - 2023-10-05

### Changed
- Improving ble pairing and failure messages
- Bump BreezSdk to 0.2.3

## [4.0.13] - 2023-09-22

### Added
- Enable signing address with HW
- URI schema and deep link support

### Changed
- Update gdk to 0.67.1
- UI improvements on amount selection
- Warning for non-default PIN server 
- Increase QRCode scanner area
- Improve support for host unblinding on Jade
- Improve contact support

## [4.0.11] - 2023-08-11

### Changed
- Update gdk to 0.0.65
- Improve signing on Ledger
- Improve bluetooth scanning

### Added
- Address authentication for singlesig software wallets
- UI improvements to lightning accounts

## [4.0.10] - 2023-07-25

### Changed
- Improve QR code readability 
- Update performance metrics
- Update greenlight library

## [4.0.9] - 2023-06-29

### Changed
- New unified dialog to change denomination and exchange 
- Improve Lightning send

## [4.0.8] - 2023-06-12

### Changed
- Fix for un-initialized Jade wallets

## [4.0.7] - 2023-06-08

### Changed
- Bug fixes

## [4.0.6] - 2023-06-06

### Changed
- Bug fixes

## [4.0.5] - 2023-06-05

### Added
- Lightning support

### Changed
- Update gdk to 0.0.63
- UI improvements for lightning account

## [4.0.4] - 2023-05-04

### Changed
- Improves performance on login
- UI improvements on content loading
- Update gdk to 0.0.62

## [4.0.3] - 2023-04-28

### Added
- Add import of watch-only wallets through xpubs and descriptors from QR codes or files
- Allow import of Coldcard watch-only in generic json and electrum format

### Changed
- UI improvements for smaller screens

### Fixed
- Setup Pgp on multiple multisig networks
- Fix sweep transaction in Watch-Only mode
- Fix send button UI in watch-only mode

## [4.0.2] - 2023-04-20

### Fixed
- Enable emergency restore on invalid pin wallet
- Bug fixes

## [4.0.1] - 2023-04-18

### Changed
- Use swift package dependecies instead cocoapods
- Split workspace in multiple subprojects
- Update to gdk 0.0.61
- Bug fixes

## [4.0.0] - 2023-04-12

### Changed
- UI improvements
- Bug fixes

## [4.0.0-beta5] - 2023-04-05

### Added
- Add animations and improve user interface

### Changed
- Bug fixes

## [4.0.0-beta4] - 2023-03-27

### Changed
- Bug fixes
- Update to gdk 0.0.58 post2

## [4.0.0-beta3] - 2023-03-24

### Changed
- Bug fixes
- New hardware wallet experience with Jade and Ledger

## [4.0.0-beta2] - 2023-03-10

### Changed
- Bug fixes
- Update translations

## [4.0.0-beta1] - 2023-03-01

### Changed
- Network Unification
- Update GDK to 0.0.58
- Update translations

### Fixed
- Change data directory for app data storage

## [3.9.2] - 2023-02-07

### Added
- Customer satisfaction survey

## [3.9.0] - 2022-10-25

### Added
- Emergency recovery phrase restore

### Changed
- Update GDK to 0.0.57

## [3.8.9] - 2022-10-11

### Added
- New "About" section
- Give us your feedback utility

### Changed
- Announcements and alerts, improved navigation
- Improved performance of asset registry usage
- Updates GDK to version 0.0.56
- Improve testing with debug & adhoc release

### Fixed
- Improve tor bootstrapping support

## [3.8.8] - 2022-09-23

### Fixed
- Fix Watch-only connection and login
- Fix reloading transactions and subaccounts
- Fix transaction blockheight 

## [3.8.7] - 2022-09-06

### Added
- Enable OTP feature on Jade starting from version 0.1.37
- Enable Emergency Restore on Jade
- Prompt users for app review

### Changed
- Improved BIP39 wallets support
- Updated accounts naming

### Fixed
- Improved transactions reloading
- Improved error messages for watch-only setup
- Fixes for reconnection

## [3.8.6] - 2022-08-03

### Added
- Display firmware hash during Jade firmware update
- Login with BIP39 Passphrase

### Changed
- Display the receive address in transaction details
- Display the net amount without fees in transaction details

### Fixed
- Handle connection failure during wallet discovery

## [3.8.5] - 2022-07-15

### Added
- Support for login with multiple hardware wallets concurrently
- Support to set up watch-only credentials on Liquid multisig shield wallets
- Watch-only wallets: support to delete credentials
- Improved transaction review dialog for hardware wallets
- Faster Jade firmware upgrades
 
### Changed
- Improved login performance with hardware wallets
- Update GDK to 0.0.55
- Onboarding: automatic wallet naming

### Fixed
- Create 2of3 subaccount with Ledger
- Hardware wallets logout view hierarchy
- Improved error messages

## [3.8.4] - 2022-06-17

### Added
- Add Support ID on settings About for multisig wallet

### Changed
- Drop addresses in transaction list
- Update GDK to 0.0.54.post1
- Update translations

### Fixed

## [3.8.3] - 2022-06-10

### Added
- Help Green improve! If you agree, Green will collect limited usage data to optimize your experience
- SPV for multisig shield wallets

### Changed
- Uses a global Tor sessions

### Fixed
- Updates optional fields for Blockstream Jade over the signing process
- Minor bug fixes 

## [3.8.2] - 2022-05-18

### Added
- Singlesig Bitcoin wallets support for Ledger Nano X hardware devices
- Ad-hoc app distribution for internal testing

### Changed
- Improved CI for internal testing
- Improved receive screen layout
- Updated GDK to version 0.0.54
- Updated logic for liquid assets icons and metadata

### Fixed
- Removed tor unavailability warning
- Added watch-only setting for multisig shield wallets used with hardware devices
 
## [3.8.1] - 2022-04-27

### Added
- Archive accounts you no longer use
- Improve CI process for testing release

### Changed 
- Updates GDK to version 0.0.52
- Improves performance of navigation between accounts

### Fixed
- Fixes autologout for watch-only wallets
- Fixes bug when pasting 2FA codes while sending

## [3.8.0] - 2022-04-15

### Added
- Singlesig wallet support for Blockstream Jade hardware devices
- Tor connection support also for singlesig wallets
- 2of3 account creation on bitcoin multisig shield wallets

### Changed
- Select mnemonic length while restoring wallet
- Recovery phrase in settings can also be shown as QR code, for fast import on other devices
- Access app settings screen from hardware wallet connection screen
- Slide to send a transaction
- Update GDK to version 0.51
- Improved asset details screen

### Fixed
- Session autologout on background after timeout

## [3.7.9] - 2022-02-15

### Added
- Streamlined wallet navigation: switch between your wallets without needing to log out every time
- Romanian localization

### Changed
- Improved swifter Send flow, easier to use, easier to read
- Enabled Liquid testnet for Jade when in test mode
- Restoring an already available wallet is detected, preventing duplicates

## [3.7.8] - 2022-01-20

### Changed
- Update GDK to version 0.0.49
- Improve automatic wallet restore

## [3.7.7] - 2021-12-17

### Added
- Automatic wallet restore, Green will find any wallet associated with your recovery phrase
- Balances on account cards when switching between accounts
- Support for wallet creation with both 12 or 24 words recovery phrases
- Support for Ledger Nano X firmware 2.0.0

### Changed
- Improved transaction details layout
- Updated GDK to 0.0.48

### Fixed
- Assist Jade users with Bluetooth re-pairing after firmware 0.1.31+ upgrade

## [3.7.6] - 2021-11-10
### Added
- Support for send to bech32m P2TR address types, available 144 blocks after Taproot activation
- Support to connect to your personal electrum server, available in app settings for singlesig wallets 
- Support to validate transaction inclusion in a block (SPV), available in app settings for singlesig wallets 

### Changed
- Revamps receive view with new UI and button to verify addresses on hardware wallets
- Supports GDK 0.0.47

### Fixed
- Loading of trasactions in the home view
- URL with unblinding data for Liquid transactions
- Improves BLE scanning and error messages

## [3.7.5] - 2021-10-27

### Added
- Supports creating and restoring Singlesig wallets on Liquid
- Reset two factor authentication
- SPV header validation for transactions validation

### Changed
- Improves wallet restore flow
- Testnet networks must be enabled from App Settings to appear as create/restore options
- Testnet UI clarifies that funds have no value on these wallets
- Prompts to perform Jade OTA firmware upgrades via USB cable
- Shows a warning when operating on a testnet network
- Updates GDK to 0.0.46.post1

### Fixed
- Uses default minimum fees when estimates are not available
- UI on restore for iOS15
- Updates fastlane flags on debug mode

## [3.7.3] - 2021-09-30

### Changed
- Updates GDK to 0.0.45.post1

### Fixed
- Explicitly ignore expired certificate in Jade pinserver request

## [3.7.2] - 2021-09-28

### Added
- Support host unblinding for Blockstream Jade version 0.1.27 and higher

### Changed
- New wallet view with revamped UI
- Improves network reconnection behavior
- Updates and supports GDK version 0.0.45
- Updates translations

### Fixed
- Validation of addresses for 2of3 accounts using Blockstream Jade
- Disconnection at auto-logout timeout
- Amounts displayed when sweeping paper wallets

## [3.7.0] - 2021-09-08

### Added
- Support for creating and restoring Singlesig wallets on Bitcoin
- Support for Fastlane to streamline future beta releases

### Changed
- Improves hardware wallet integration
- Updates localizations
- Updates GDK to version 0.0.44

### Fixed
- Fixes UI settings for smaller screens

## [3.6.6] - 2021-08-17

### Added
- Anti-exfil signing protocol support for Blockstream Jade
- Automated tests for onboarding and transactions

### Changed
- Improves Wallet Settings UI
- Preloads icons of Liquid assets
- Improves support for Blockstream Jade hardware

### Fixed
- Title trimming on low resolution devices

## [3.6.3] - 2021-07-13

### Added
- Generates 12 words recovery phrases by default
- Support for creating and restoring Singlesig wallets on Bitcoin Testnet
- Adds account type label in Account Card
- Enhanced support for Blockstream Jade

### Changed
- Removes limit in maximum number of AMP accounts that can be added
- Updates GDK to 0.0.43

## [3.6.1] - 2021-06-18

### Fixed
- Crash on iOS 12
- Checkbox for system message approval
- Bug showing hardware wallets alert when using a software wallet

## [3.6.0] - 2021-06-07

### Added
- Improved UI for 2FA reset using new alert cards
- Users can now undo a 2FA dispute

### Changed
- Improved Blockstream Jade onboarding
- Improved Liquid asset registry loading, supporting refresh in case of failures
- Auto-advance after typing last digit of 2FA codes
- UI improvements for smaller screens
- Updated GDK

### Fixed
- URLs to view transactions on the explorer
