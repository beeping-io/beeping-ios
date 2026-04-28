# 🤝 Contributing to `beeping-ios`

Thanks for your interest! This repo is part of the **Beeping Platform** ecosystem.
The contributing guidelines, commit conventions, branch model, code of conduct,
and PR rules are **shared across the ecosystem** and live in
[`beeping-io/beeping-meta`][meta]. Read those first.

- 📘 [CONVENTIONS.md][conventions] — commits, branches, PRs, Renovate, lint
- 🤝 [CONTRIBUTING.md][contributing] — process, signing, PR template
- 📜 [CODE_OF_CONDUCT.md][coc] — community standards
- 🔒 [SECURITY.md][security] — vulnerability disclosure (also linked from this repo)

---

## ⚡ Repo-specific quick notes

- **Active scope**: Phase 9 of the Beeping Platform Linear project.
  See [`docs/PRODUCTO.md`](docs/PRODUCTO.md) section 6 for the 16 tasks
  (BEE-67..BEE-82, 94 SP).
- **Branch base**: `develop`. `main` is reserved for releases (release-please managed once BEE-82 lands).
- **Stack target**: Swift 6 + strict concurrency, iOS 15+, Xcode 16+, SPM primary + CocoaPods secondary. Currently legacy ObjC.
- **Commit format** (Conventional Commits + Linear ID):

  ```
  feat(api): BEE-70 BeepingClient actor + AsyncStream<BeepingEvent>
  fix(audio): BEE-71 retry on session interruption
  chore(deps): BEE-73 wire swift-openapi-generator plugin
  ```

- **PR template**: required sections include 🧪 Automated tests + 🧑‍🔬 Human QA evidence — see [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md).
- **Definition of done**: lint clean (SwiftLint + swift-format, **0 warnings**), tests passing, strict concurrency clean, coverage gate, CHANGELOG updated, Linear task closed with comment summarizing changes + QA cycles.

---

## 🔧 Local development

See [`README.md`](README.md) — currently building requires Xcode (any recent
version) for the legacy ObjC code. Post-BEE-68, **Xcode 16+** and **Swift 6**
toolchain are required.

[meta]: https://github.com/beeping-io/beeping-meta
[conventions]: https://github.com/beeping-io/beeping-meta/blob/develop/CONVENTIONS.md
[contributing]: https://github.com/beeping-io/beeping-meta/blob/develop/CONTRIBUTING.md
[coc]: https://github.com/beeping-io/beeping-meta/blob/develop/CODE_OF_CONDUCT.md
[security]: https://github.com/beeping-io/beeping-meta/blob/develop/SECURITY.md
