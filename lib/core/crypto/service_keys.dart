/// The marriage service's public keys, PINNED IN CODE (base64, by key_id).
///
/// The same list as pape-admin `src/lib/crypto/service-keys.ts`. The app
/// encrypts an application only to a key that is both active in the
/// database (`marriage_service_keys`, not retired) and listed here, so a key
/// swapped in the database is never used.
///
/// Empty until the key ceremony (pape-admin docs/marriage-key-ceremony.md).
/// While it is empty the new form says the service isn't open yet and
/// nothing can be sent. A change to this file needs the independent
/// reviewer (CODEOWNERS), and a new app build.
const Map<int, String> kPinnedServiceKeys = {};
