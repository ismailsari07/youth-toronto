# Supabase auth email templates (app 1.4.0)

Final. Configured in Supabase on 2026-11-06 (templates, subjects, Redirect URL, codes); "Confirm email" stays **off**
until 1.4.0 is on the App Store (`docs/RELEASE.md` §8).

Paste each file into Supabase → Authentication → Emails → Templates. TR/EN/FR are stacked in one email; the 6-digit
code (`{{ .Token }}`) is the main content and is typed into the app. The link is only a small fallback. There are no
images except the logo, no tracking and no external CSS. Supabase sends the HTML only, so every sentence is plain
text that still reads well with styles stripped.

| Template | File | Subject |
|---|---|---|
| Confirm signup | `confirm-signup.html` | `Pape Mosque · Onay kodu · Confirmation code · Code de confirmation` |
| Reset password | `reset-password.html` | `Pape Mosque · Şifre sıfırlama · Password reset · Réinitialisation` |
| Change email address | `change-email.html` | `Pape Mosque · E-posta değişikliği · Email change · Changement de courriel` |

Magic link, Invite user and Reauthentication stay as they are: neither the app nor the panel sends them.

The logo is `https://papemosque.ca/email/logo.png`, kept stable on the website for email.

## How Reset password serves both the app and the panel

The app always passes `redirectTo: https://papemosque.ca/hesap/onaylandi` (`kAuthEmailRedirect` in
`lib/core/email_auth.dart`). The template checks it:

```
{{ if eq .RedirectTo "https://papemosque.ca/hesap/onaylandi" }}  → app: the code, no link
{{ else }}                                                        → panel: the link button (its /auth/callback)
```

`RedirectTo` only carries that value if the URL is on the Redirect URLs list. Without it, Supabase falls back to the
Site URL and app members get the panel's link email. Keep the two in step: the constant, this README and the template.

## Settings to set in the dashboard (nothing has been changed yet)

Authentication → Sign In / Providers → Email:
- **Email OTP Length: 6.** The app's code field takes exactly 6 digits (`kEmailCodeLength`).
- **Email OTP Expiration: 3600** seconds. The emails say "1 hour".
- **Minimum password length:** at most 6, because the app checks for 6.
- **Secure email change:** leave on. The app has no email change.
- **Confirm email: turn on LAST**, once 1.4.0 is on the App Store and the fallback page is live (see the order below).

Authentication → Rate Limits:
- **Minimum interval between emails per user: 60 seconds.** The app's "Kodu tekrar gönder" waits 60 s (`kResendCooldown`).
  In `config.toml` this setting is `max_frequency`.
- **Emails sent per hour:** at least 30, Resend's default once custom SMTP is on. Raise it if sign-ups come in bursts.

Authentication → URL Configuration:
- **Site URL:** unchanged (the panel). It is the fallback for anything not on the list.
- **Redirect URLs:** add exactly `https://papemosque.ca/hesap/onaylandi`, and keep the panel's `https://<panel>.vercel.app/**`.

Website: `https://papemosque.ca/hesap/onaylandi` is live (since 2026-11-06). It is a static page with
no script: "E-postanız onaylandı. Pape Mosque uygulamasına dönüp giriş yapabilirsiniz." in TR/EN/FR. Supabase confirms
the address before redirecting, so the page needs no code and can ignore the `?code=` it receives.

Apple Developer → Certificates, IDs & Profiles → Services → Sign in with Apple for Email Communication: register
`papemosque.ca` and `noreply@papemosque.ca`. Mail to `…@privaterelay.appleid.com` is dropped otherwise. Apple
requires SPF to pass for the domain, which the Resend domain setup provides.

## Order

1. ~~Publish the website page.~~ Done (2026-11-06, with `/email/logo.png`).
2. Add the Redirect URL. Set the OTP length and expiry, the 60 s interval and the three templates. All of this is safe
   with "Confirm email" still off: only "Şifremi unuttum" uses it, and that is new in 1.4.0.
3. Ship 1.4.0. On TestFlight, check "Şifremi unuttum" on a test account (it works without "Confirm email").
4. Turn on "Confirm email". On the 1.4.0 build, check a sign-up with a new address and a sign-in on an unconfirmed
   account. Before that, an older app closes the sign-up screen with no message.
