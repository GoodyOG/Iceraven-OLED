#!/bin/bash

set -e

# Download latest Apktool
wget -q https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.11.0.jar -O apktool.jar
wget -q https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
chmod +x apktool*

# Download latest Iceraven APK
wget -q https://download.mozilla.org/?product=fenix-latest&os=android&lang=en-US -O iceraven.apk

# Decompile the APK
./apktool d -s iceraven.apk -o iceraven-patched

# Remove META-INF (if necessary)
rm -rf iceraven-patched/META-INF

# Color patching 
sed -i 's/<color name="fx_mobile_layer_color_1">.*/<color name="fx_mobile_layer_color_1">@color\/photonBlack<\/color>/g' iceraven-patched/res/values*/colors.xml
sed -i 's/<color name="fx_mobile_layer_color_2">.*/<color name="fx_mobile_layer_color_2">@color\/photonDarkGrey90<\/color>/g' iceraven-patched/res/values*/colors.xml

# Decompile the APK using JADX
wget -q https://github.com/skylot/jadx/releases/download/v1.4.7/jadx-1.4.7.zip -O jadx.zip

# Use the -o option with unzip to overwrite files without prompting
unzip -o jadx.zip 

rm jadx.zip

./jadx/bin/jadx -d iceraven-patched iceraven.apk

# Find and patch PhotonColors.smali
photon_path=$(find iceraven-patched -name PhotonColors.smali)

if [ -n "$photon_path" ]; then
  echo "Found PhotonColors.smali at: $photon_path"

  # Smali patching
  sed -i 's/ff2b2a33/ff000000/g' "$photon_path"
  sed -i 's/ff42414d/ff15141a/g' "$photon_path"
  sed -i 's/ff52525e/ff15141a/g' "$photon_path"

else
  echo "Error: PhotonColors.smali not found!"
  exit 1
fi

# Recompile the APK
./apktool b iceraven-patched -o iceraven-patched.apk --use-aapt2

# Align and sign the APK
zipalign 4 iceraven-patched.apk iceraven-patched-signed.apk

# Clean up
rm -rf iceraven-patched iceraven-patched.apk
