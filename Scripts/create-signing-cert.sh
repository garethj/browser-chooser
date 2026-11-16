#!/bin/bash
# Creates a self-signed code-signing certificate in the login keychain, which build.sh
# then signs with instead of ad-hoc. A stable signing identity lets macOS keep privacy
# grants (e.g. Full Disk Access) across rebuilds; with ad-hoc signing every build looks
# like a new app and loses them. Safe to re-run: does nothing if the identity exists.
set -euo pipefail

NAME="${1:-BrowserChooser Local Signing}"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -p codesigning "$KEYCHAIN" | grep -qF "\"$NAME\""; then
    echo "==> Signing identity \"$NAME\" already exists"
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Creating self-signed code-signing certificate \"$NAME\"..."
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -subj "/CN=$NAME" \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null

/usr/bin/openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -name "$NAME" -out "$TMP/identity.p12" -passout pass:browserchooser

# -T pre-authorises codesign to use the private key.
security import "$TMP/identity.p12" -k "$KEYCHAIN" -P browserchooser -T /usr/bin/codesign >/dev/null

echo "==> Imported into login keychain. The first signing may ask to allow codesign"
echo "    to use the key: choose \"Always Allow\"."
