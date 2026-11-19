# App Store export compliance (since 1.5.0)

Up to 1.4.x the app used only HTTPS/TLS and Apple's own crypto, so
`ITSAppUsesNonExemptEncryption` was `false` and uploads asked nothing.

From **1.5.0** the app bundles **libsodium** (through `sodium_libs`) to encrypt
marriage applications end to end before upload: X25519 sealed boxes
(`crypto_box_seal`) and XChaCha20-Poly1305, all standard, published
algorithms (code: `lib/core/crypto/marriage_crypto.dart`). That is encryption
for data confidentiality with a library that is **not** Apple's operating
system, so the app no longer counts as exempt:
`ITSAppUsesNonExemptEncryption` is now `true` in `ios/Runner/Info.plist`
(checked by `test/ios/export_compliance_test.dart`).

## What happens on upload

Each uploaded build shows **"Missing Compliance"** in TestFlight until the
questions are answered in App Store Connect (TestFlight → the build →
"Manage" next to the compliance warning). The answers for this app:

1. Does your app use encryption? **Yes.**
2. Algorithm type: **"Standard encryption algorithms instead of, or in
   addition to, using or accessing the encryption within Apple's operating
   system."** Not proprietary: libsodium implements published IETF/standard
   constructions, so no US CCATS is needed.
3. **France:** Apple asks whether the app is available on the App Store in
   France. Apple's table ("Export compliance documentation for encryption")
   says an app using an industry-standard algorithm not provided by the OS
   needs the **French encryption declaration** uploaded in App Store Connect
   **only if it is distributed in France**.
   - If France is in the app's territories (App Store Connect → Pricing and
     Availability): either file the French declaration (ANSSI) and upload the
     approval, or remove France from the territories before 1.5.0 is
     submitted. This is the mosque's decision; the app is aimed at Toronto.
   - If France isn't listed: answer **No**, and nothing is uploaded.

Once the answers are accepted for one build, App Store Connect offers to
reuse them; if Apple issues an export compliance code, it can be added as
`ITSEncryptionExportComplianceCode` in `Info.plist` so later builds don't ask.

This note records the reasoning, not legal advice. If in doubt (e.g. new
territories), check Apple's current App Store Connect help on export
compliance or ask an export-control adviser.
