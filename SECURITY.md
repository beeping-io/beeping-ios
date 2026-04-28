# 🔒 Security Policy — `beeping-ios`

This repository follows the Beeping Platform security policy defined in
[`beeping-io/beeping-meta`][meta-security]. **Read it first.**

---

## 🚨 Reporting a vulnerability

**Do NOT open a public GitHub issue** for security vulnerabilities. Follow the
disclosure process documented in
[beeping-meta SECURITY.md][meta-security] (private email + GPG-encrypted reports).

Expected response window: **72 hours** to first acknowledgement.

---

## 🎯 Scope of this SDK

Security-relevant surfaces of `beeping-ios`:

- 🎙️ **Microphone audio capture** (`NSMicrophoneUsageDescription` in consumer's
  Info.plist). The SDK requests permission lazily on first `listen()` call.
  Audio is **never persisted** — frames flow through the decoder and are discarded.
- 🌐 **Optional HTTP communication** with `beepbox-server` in Cloud mode
  (`.cloud(apiKey:endpoint:)`). API key auth, TLS 1.2+ required.
- 🔌 **ObjC++ bridge** to native `libbeepingcore` (XCFramework). Native libs are
  consumed from signed releases of [`beeping-io/beeping-core`][core-releases]
  (post-BEE-79); current legacy state has them vendored as
  `libBeepingCoreUniversal.a` in the repo.
- 🔐 **`PrivacyInfo.xcprivacy`** with declared API reasons (post-BEE-69, Apple mandate).
- 🔐 **No PII in logs**. Telemetry is opt-out by default and audited for
  privacy in BEE-75.

### Out of scope

- Server-side validation, rate limiting, infrastructure → tracked in
  [`beepbox`](https://github.com/beeping-io/beepbox) and
  [`beeping-meta` terraform](https://github.com/beeping-io/beeping-meta/tree/develop/terraform).
- Client-side cryptography of payloads (none today; payloads are clear-text
  short identifiers — applications layering crypto on top must do so themselves).

---

## 🛡️ Supported versions

| Version | Supported |
|---------|-----------|
| `0.x` (any) | ✅ best-effort, no SLA (early development) |

A formal security SLA starts at `1.0.0` (post-Phase 21).

---

## 📎 References

- [Beeping Platform security policy][meta-security]
- [`beeping-core` releases][core-releases] — source of native binaries (XCFramework)

[meta-security]: https://github.com/beeping-io/beeping-meta/blob/develop/SECURITY.md
[core-releases]: https://github.com/beeping-io/beeping-core/releases
