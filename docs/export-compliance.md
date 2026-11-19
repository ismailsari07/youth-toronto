# App Store export compliance (since 1.5.0)

Up to 1.4.x the app used only HTTPS/TLS and Apple's own crypto, so
`ITSAppUsesNonExemptEncryption` was `false` and uploads asked nothing.

From **1.5.0** the app bundles **libsodium** (through `sodium_libs`) to encrypt
marriage applications end to end before upload: X25519 sealed boxes
(`crypto_box_seal`) and XChaCha20-Poly1305, all standard, published
algorithms (code: `lib/core/crypto/marriage_crypto.dart`). That is encryption
for data confidentiality with a library that is **not** Apple's operating
system, so the app no longer counts as exempt.

## Info.plist: neither key (decided 2026-11-19)

`ios/Runner/Info.plist` has **no** `ITSAppUsesNonExemptEncryption` and **no**
`ITSEncryptionExportComplianceCode` (checked by
`test/ios/export_compliance_test.dart`, which also checks the widget's plist).

- `false` would be untrue while libsodium is bundled.
- `true` tells App Store Connect the app has **approved** export compliance
  documentation, whose code must be in `ITSEncryptionExportComplianceCode`.
  We have none, so 1.5.0 build 30 was refused at upload with **ITMS-90592**
  ("Invalid Export Compliance Code … key value [] … doesn't match … the
  app's export compliance documentation"; `[]` = no code in the plist).
- With no key, the upload goes through and App Store Connect asks the
  questions for each build.

Put `true` back only together with an Apple-issued code
(`ITSEncryptionExportComplianceCode`), i.e. after Apple approves documentation
uploaded in App Store Connect (App Information → App Encryption Documentation).
This app doesn't need that: standard algorithms, not distributed in France.

## What to answer for each build

The build shows **"Missing Compliance"** in TestFlight until answered:
TestFlight → the build → "Manage" next to the warning (or the prompt when the
build is added to a submission). The wording of Apple's dialog changes from time
to time; the substance of the answers:

1. "What type of encryption algorithms does your app implement?" (or "Does your
   app use encryption?" → **Yes**): choose **"Standard encryption algorithms
   instead of, or in addition to, using or accessing the encryption within
   Apple's operating system."** Not "None of the algorithms mentioned above"
   (that is only for apps that use nothing but HTTPS/Apple crypto), and not
   "Proprietary or non-standard" (libsodium implements published
   constructions, so no US CCATS is needed).
2. "Is your app going to be available on the App Store in France?" → **No.**
   Decided by the owner on 2026-11-19: France is removed from the app's
   territories (App Store Connect → Pricing and Availability) before 1.5.0 is
   submitted, so no French declaration is filed. If France is ever added back,
   the declaration (ANSSI) comes first.
3. If Apple then asks to upload documentation: it shouldn't for this
   combination. If it does, stop and check Apple's current help before
   uploading anything; don't invent a code for the plist.

Every new build asks again (the key stays absent). That is the cost of having
no approved compliance code.

This note records the reasoning, not legal advice. If in doubt (e.g. new
territories), check Apple's current App Store Connect help on export
compliance or ask an export-control adviser.
