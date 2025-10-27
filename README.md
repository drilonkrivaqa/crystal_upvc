# crystal_upvc

UPvc windows/doors manufacturing app

## Getting Started

This project is a starting point for a Flutter application.

## Android release builds & upgrades

Updating an existing installation of the Android application requires the
same package identifier and signing key that were used for older releases.
Failing to match both will cause the system to block the install with the
message `App not installed as package conflicts with an existing package`, and
the device would treat the update as a completely different application which
also wipes the on-device Hive database.

### Package / application ID

The application identifier is managed via the Gradle properties
`crystalUpvc.namespace` and `crystalUpvc.applicationId` (see
[`android/gradle.properties`](android/gradle.properties)). The defaults still
use the Flutter template value (`com.example.crystal_upvc`), but you should set
both properties to the identifier that was used in your previous builds (for
example `com.tonialpvc.crystalupvc`). Keeping the same ID ensures the updated
build has access to the existing application sandbox and Hive boxes.

### Release signing

To reuse the signing key from earlier builds:

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Update the property values so that they point to the keystore file and
   credentials that were used for the earlier production/release APKs.
3. Make sure the referenced keystore is available locally (for example in
   `android/keystore/crystal_upvc.jks`).

When `android/key.properties` is present, the Gradle build now signs release
artifacts using that keystore. This allows the APK or app bundle to be
installed as an update over the existing application without losing data. If
the file is missing the build still falls back to the default debug keystore so
that local development keeps working.
