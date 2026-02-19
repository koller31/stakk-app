# Security Policy

## How Stakk Protects Your Data

Stakk is designed with security as a core principle. Every card image, every piece of metadata, and every user credential is protected using industry-standard cryptographic techniques.

### Encryption

- **Card images** are encrypted with AES-256-GCM before being written to disk. They are never stored in plaintext.
- **Card metadata** (names, notes, extracted text) is stored in an AES-256 encrypted local database (Hive).
- **Encryption keys** are generated and stored in the Android Keystore, which uses hardware-backed security on supported devices. Keys never leave the secure hardware.

### Authentication

- **PIN protection**: Your PIN is stored as a salted SHA-256 hash. Comparison uses constant-time algorithms to prevent timing attacks.
- **Biometric authentication**: Fingerprint and face recognition are handled entirely by your device's secure hardware. The app never has access to your biometric data.
- **Auto-lock**: The app automatically locks after a configurable period of inactivity (30 seconds to 15 minutes).

### Screen Protection

- **FLAG_SECURE** is enabled on all screens, which prevents screenshots, screen recording, and the app from appearing in the recent apps thumbnail.

### Data Deletion

- When you delete a card, its image files are **overwritten with random bytes followed by zeros** before the file is removed from the filesystem.
- Clearing all data from Settings permanently removes all cards, metadata, and extracted text.
- Uninstalling the app removes all stored data from your device.

### Device Integrity

- Stakk checks for **root/jailbreak status** on launch and warns users if their device has been compromised, as rooted devices may allow other apps to bypass the encryption protections.

### Network Security

- Stakk does not operate any servers. No data is transmitted over the network during normal use.
- The only network activity occurs during optional OAuth business badge connections, which use PKCE-protected OAuth 2.0 flows.

## Reporting a Vulnerability

If you discover a security vulnerability in Stakk, please report it responsibly:

- **Email**: joek331@gmail.com
- **Subject line**: `[SECURITY] Stakk Vulnerability Report`

Please include:
1. A description of the vulnerability
2. Steps to reproduce
3. The potential impact

We take all security reports seriously and will respond within 48 hours.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |
