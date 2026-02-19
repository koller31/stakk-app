# Privacy Policy

**Effective Date: February 16, 2026**
**Last Updated: February 16, 2026**

## Summary

Stakk stores all your data locally on your device. We do not collect, transmit, or store any personal information on external servers. Your IDs never leave your phone.

## 1. Introduction

Stakk ("the App") is a digital ID wallet that allows you to scan, store, and present identification cards on your mobile device. This Privacy Policy explains how your information is handled when you use the App.

## 2. Information We Collect

**We do not collect any personal information.** All data created within the App is stored exclusively on your device.

The App processes the following types of data locally:

- **Card images**: Photos of your identification cards, captured via your device camera or imported from your gallery. These images are encrypted with AES-256 and stored only on your device.
- **Card metadata**: Names, nicknames, and notes you enter about your cards. Stored in an encrypted local database.
- **OCR text**: Text automatically extracted from card images using on-device optical character recognition. This processing happens entirely on your device.
- **Authentication data**: Your PIN is stored as a salted cryptographic hash. Biometric data is processed by your device's secure hardware and is never accessible to the App.
- **App preferences**: Theme selection, auto-lock timeout, and category display settings.

## 3. Business Connections (Optional Feature)

If you choose to connect to a business identity provider using the optional Business Connections feature:

- You will be redirected to the business's OAuth authorization page. The App does not see or store your login credentials for that service.
- An access token is stored locally on your device to retrieve your business badge.
- Badge profile data (name, photo, employee ID) is fetched from the business's API and stored locally.
- You can remove any business connection at any time, which deletes all associated data from your device.

## 4. Camera and NFC Access

- **Camera**: Used solely to capture images of your identification cards. Photos are encrypted immediately after capture. The App does not access your camera for any other purpose.
- **NFC (Near Field Communication)**: Used solely for the optional badge emulation feature, allowing you to present a digital business badge to NFC readers. NFC data is stored locally and transmitted only when you actively hold your device to a reader.
- **Biometric sensors**: Used solely for app authentication as an alternative to PIN entry. Biometric data never leaves your device's secure hardware.

## 5. Data Security

Stakk employs multiple layers of security to protect your data:

- All card images are encrypted using AES-256-GCM encryption
- The local database is encrypted with AES-256
- Encryption keys are stored in your device's secure hardware (Android Keystore)
- Your PIN is stored as a salted SHA-256 hash with constant-time comparison
- Screenshots and screen recording are blocked within the App
- The App automatically locks after a configurable inactivity timeout
- When you delete a card, its image files are securely overwritten before deletion

## 6. Data Sharing

**We do not share your data with anyone.** Specifically:

- No data is sent to our servers (we do not operate any servers)
- No analytics or tracking services are integrated
- No advertising networks receive your data
- No third parties have access to your data

## 7. Data Retention and Deletion

All data remains on your device until you choose to delete it. You can:

- Delete individual cards (images are securely wiped)
- Clear all extracted text data from Settings
- Reset the entire app from Settings, which permanently deletes all cards and data
- Uninstall the App, which removes all stored data from your device

## 8. Children's Privacy

Stakk is not directed at children under 13. We do not knowingly collect information from children. The App is intended for adults who wish to digitize their personal identification documents.

## 9. Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be reflected by updating the "Last Updated" date at the top of this page. Continued use of the App after changes constitutes acceptance of the updated policy.

## 10. Contact

If you have questions about this Privacy Policy or the App's data practices, please contact us at:

**Email**: joek331@gmail.com

---

*Copyright 2026 Stakk. All rights reserved.*
