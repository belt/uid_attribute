# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities **privately** through one of:

1. [GitHub Security Advisories](https://github.com/belt/uid_attribute/security/advisories/new)
   (preferred — encrypted, ties to the repo)
2. Email the maintainer at `paul.belt@users.noreply.github.com`
   with subject prefix `[security] uid_attribute:`

Do not open a public issue for vulnerabilities. Public disclosure
before a fix is shipped puts every consumer at risk.

## Response Targets

| Step                    | Target          |
| ----------------------- | --------------- |
| Initial acknowledgment  | within 72 hours |
| Triage and severity     | within 7 days   |
| Fix on supported branch | within 30 days  |

Critical vulnerabilities (RCE, auth bypass, ID collision at scale)
target a same-week patch and a coordinated CVE filing.

## Supported Versions

Only the latest minor receives security fixes. Older minors are
end-of-life on the next minor release.

| Version | Status              |
| ------- | ------------------- |
| 1.0.x   | Supported           |
| < 1.0   | End of life         |

## Threat Model

`uid_attribute` is a small attribute-decoration gem. The threat
surface is intentionally narrow.

### In Scope

- **UUID quality** — generated identifiers must be unpredictable
  for v4 and time-monotonic for v7. Compromised entropy or biased
  output is a vulnerability.
- **Attribute confusion** — installing the mixin must not silently
  expose unintended attributes or override host class accessors
  in ways that bypass validation.
- **Validation bypass** — the `:uuid_string` ActiveModel type must
  reject malformed input. A path that lets a non-UUID land in a
  validated column is a vulnerability.
- **Logging hygiene** — the gem must not emit UUIDs to stdout or
  Rails logs as a side effect of mixin installation.

### Out of Scope

- Database column types or storage choices (the host application
  selects the column type).
- Cross-record uniqueness when uniqueness validation is disabled
  (`validate: false`) — that is an opt-in.
- Adversarial denial of service via UUID generation (rate limiting
  belongs at the application layer).
- Privacy properties of UUID v7 (timestamp leakage is documented
  trade-off, not a flaw — use v4 if leakage is unacceptable).

## Architectural Defenses

| Property                                    | Prevents                            |
| ------------------------------------------- | ----------------------------------- |
| `SecureRandom` for v4 + v7                  | Predictable identifiers             |
| `Generator.valid?` strict regex             | Out-of-band hex / wrong layout      |
| Version nibble allow-list (1..7)            | v0 and v8+ injection                |
| Variant nibble allow-list (8/9/a/b)         | Non-RFC layouts                     |
| `frozen_string_literal: true` everywhere    | String mutation surprises           |
| `before_validation(on: :create)` callback   | Overwriting persisted UIDs          |
| Refinements not global monkey-patches       | Cross-gem method collision          |
| `cast` lowercases and re-validates          | Mixed-case duplicates / homoglyphs  |
| `MissingAccessorError` raised eagerly       | Silent attribute mismatch           |
| `bundler-audit` in CI                       | Known vulnerable transitive deps    |
| GitHub Actions pinned to full SHA           | Tag-rewrite supply-chain attacks    |

## Cryptographic Primitives

- UUID v4 → `SecureRandom.uuid` (CSPRNG, 122 bits of entropy)
- UUID v7 → `SecureRandom.uuid_v7` (Ruby 3.3+, ms timestamp +
  74 random bits, RFC 9562 §5.7)

The gem never seeds, derives, or post-processes random material
itself. All entropy comes from the platform CSPRNG (`/dev/urandom`
or `getrandom(2)` on Linux, `arc4random` on BSD/macOS).

## Disclosure

After a fix ships, the advisory is published on the repository's
[Security Advisories](https://github.com/belt/uid_attribute/security/advisories)
page and referenced in `CHANGELOG.md` under a `### Security`
heading per Keep a Changelog conventions.

## References

- [RFC 9562](https://www.rfc-editor.org/rfc/rfc9562.html)
  — Universally Unique IDentifiers (UUIDs)
- [Ruby SecureRandom](https://docs.ruby-lang.org/en/3.4/SecureRandom.html)
- [GitHub Security Advisories docs](https://docs.github.com/en/code-security/security-advisories)
