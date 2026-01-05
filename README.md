# mihomo for iOS

**mihomo for iOS** is a native iOS client built directly on top of the official **mihomo** codebase. It aims to bring the full mihomo experience to iOS while keeping **complete behavioral and configuration consistency** with the upstream project.

This project does **not** reimplement proxy logic or introduce private extensions. Instead, it focuses on adapting the official mihomo core to the iOS platform in a clean, maintainable, and upstream-friendly way.

---

## ✨ Key Features

### Fully Based on Official mihomo Core
- Uses the official mihomo source code
- No protocol changes, no behavior rewrites
- Runtime behavior matches upstream mihomo

### 100% Configuration Compatibility
- All configuration fields follow the official mihomo specification
- Supports the same YAML structure and semantics
- Existing mihomo / Clash Meta configurations work without modification

> If a configuration works on official mihomo, it will work on mihomo for iOS.

---

## 📦 Supported Capabilities

- TUN mode (via iOS Network Extension)
- HTTP / SOCKS5 / Mixed proxy ports
- DNS hijacking and Fake-IP
- Rule / Rule-Set / GEOIP / GEOSITE
- Proxy Groups (select / auto / fallback / load-balance)
- Remote configuration subscriptions
- Hot-reload of configurations
- Runtime logging and status reporting

Feature support strictly follows the upstream mihomo release and is not artificially limited.

---

## 📱 iOS Platform Integration

mihomo for iOS includes platform-specific adaptations while preserving upstream logic:

- Built on Apple Network Extension APIs
- Designed for iOS background execution constraints
- Optimized lifecycle and resource management
- Compatible with iOS system networking behavior

The goal is long-term stability and predictability on real iOS devices.

---

## 🔄 Relationship with Upstream mihomo

| Aspect | Description |
|------|-------------|
| Core Logic | Official mihomo |
| Config Format | Fully compatible |
| Runtime Behavior | Identical |
| Update Strategy | Track upstream |
| iOS Adaptation | This project |

mihomo for iOS acts as a **native container** for mihomo on iOS, not a forked ecosystem.

---

## 🧑‍💻 Intended Audience

- Users already familiar with mihomo or Clash Meta
- Advanced users who require consistent proxy behavior across platforms
- Developers who value transparency and upstream compatibility
- Users who prefer full control over their own configurations

---

## ⚠️ Important Notes

- This project only provides the proxy client
- No built-in nodes, subscriptions, or third-party services
- Users are responsible for complying with local laws and regulations
- The project does not endorse or manage any external configuration content

---

## 📜 License

This project follows the same open-source license as the official mihomo project.
Please refer to the LICENSE file in this repository for details.

---

## 📌 Project Philosophy

- Upstream-first
- No private configuration formats
- No protocol fragmentation
- Long-term maintainability

mihomo for iOS exists to deliver a **trustworthy, predictable, and upstream-aligned** mihomo experience on Apple platforms.


