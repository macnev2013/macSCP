# Mac App Store Submission Guide

## Prerequisites

- Apple Developer account with App Store Connect access
- Xcode with "Apple Distribution" signing certificate installed
- Mac App Store provisioning profile for `com.macscp.macSCP`

## Build Configuration

### MAS Build Flag

This project uses a `MAS_BUILD` Swift compiler flag to conditionally exclude Sparkle (third-party update framework), which Apple does not allow on the App Store.

To build for the Mac App Store:

1. In Xcode, go to **Build Settings** → **Swift Compiler - Custom Flags** → **Active Compilation Conditions**
2. Add `MAS_BUILD` to the Release configuration
3. Alternatively, pass it via xcodebuild:

```bash
xcodebuild archive \
  -project macSCP.xcodeproj \
  -scheme macSCP \
  -archivePath build/macSCP-MAS.xcarchive \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) MAS_BUILD' \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  CODE_SIGN_STYLE=Manual \
  PROVISIONING_PROFILE_SPECIFIER="macSCP App Store"
```

### MAS Entitlements

Use `macSCP/macSCP_MAS.entitlements` for the App Store build. This file mirrors the standard entitlements but is suitable for MAS distribution.

When exporting the archive:

```bash
xcodebuild -exportArchive \
  -archivePath build/macSCP-MAS.xcarchive \
  -exportPath build/MAS \
  -exportOptionsPlist ExportOptions-MAS.plist
```

### ExportOptions-MAS.plist (create this)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>NW7K6UFA6P</string>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.macscp.macSCP</key>
        <string>macSCP App Store</string>
    </dict>
</dict>
</plist>
```

## App Store Connect Setup

1. **Create the app** in App Store Connect with bundle ID `com.macscp.macSCP`
2. **App Information**:
   - Name: macSCP
   - Subtitle: SFTP, S3 & SSH for Mac
   - Category: Developer Tools
   - Secondary Category: Utilities
3. **Description**:
   > macSCP is a native macOS client for managing remote servers via SFTP, Amazon S3, and SSH terminal — all in one app built with SwiftUI.
   >
   > Features:
   > • SFTP file browser with drag-and-drop transfers
   > • Amazon S3 bucket management
   > • Built-in SSH terminal
   > • Secure credential storage in Keychain
   > • Multiple simultaneous connections
   > • Dark mode support
4. **Keywords**: sftp, s3, ssh, terminal, file transfer, remote, server, ftp, macos, developer
5. **Screenshots**: Required sizes — 1280x800 and 1440x900 (or retina equivalents)
6. **Privacy Policy URL**: Required — add to macscp.co
7. **Support URL**: https://github.com/macnev2013/macSCP/issues
8. **Marketing URL**: https://www.macscp.co

## Upload & Submit

1. Archive in Xcode (Product → Archive) with MAS build settings
2. Upload via Xcode Organizer or `xcrun altool --upload-app`
3. In App Store Connect, select the build and submit for review

## Review Notes

> macSCP requires network access (outgoing and incoming) to connect to SFTP servers, Amazon S3 buckets, and SSH terminals. The app stores connection credentials securely in the macOS Keychain.
>
> To test: Add an SFTP connection using any publicly accessible SFTP server, or configure an S3 bucket with valid AWS credentials.

## Timeline

- App Store review typically takes 1-3 days
- Submit by March 22 to be live for launch week (March 25+)
