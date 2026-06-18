#!/bin/bash

set -euo pipefail

# Decompile with Apktool (decode resources + classes)
wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.11.0/apktool_2.11.0.jar -O apktool.jar || { echo "Failed to download apktool"; exit 1; }
java -jar apktool.jar d iceraven.apk -o iceraven-patched  # -s flag removed
rm -rf iceraven-patched/META-INF

# Color patching
sed -i 's/<color name="fx_mobile_surface">.*/<color name="fx_mobile_surface">#ff000000<\/color>/g' iceraven-patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_background">.*/<color name="fx_mobile_background">#ff000000<\/color>/g' iceraven-patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_layer_color_2">.*/<color name="fx_mobile_layer_color_2">@color\/photonDarkGrey90<\/color>/g' iceraven-patched/res/values-night/colors.xml

# Smali patching
sed -i 's/ff2b2a33/ff000000/g' iceraven-patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff42414d/ff15141a/g' iceraven-patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff52525e/ff15141a/g' iceraven-patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali

# Recompile the APK
java -jar apktool.jar b iceraven-patched -o iceraven-patched.apk --use-aapt2

# Check zipalign is available
command -v zipalign >/dev/null 2>&1 || { echo "zipalign not found. Install it with: sudo apt install zipalign"; exit 1; }

# Align and sign the APK
zipalign 4 iceraven-patched.apk iceraven-patched-signed.apk

# Verify APK was created
if [ ! -f iceraven-patched-signed.apk ]; then
    echo "Error: iceraven-patched-signed.apk was not created"
    exit 1
fi
echo "APK verification passed: iceraven-patched-signed.apk exists"

# Clean up
rm -rf iceraven-patched iceraven-patched.apk iceraven-patched-signed.apk iceraven.apk
