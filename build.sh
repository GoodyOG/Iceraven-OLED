#!/bin/bash
data=$(curl -s https://github.com/fork-maintainers/iceraven-browser/releases/latest | grep -o 'tag/iceraven-[^"]*' | head -n 1 | cut -d/ -f2 | sed 's/iceraven-//')

# Construct the URL for the IceRaven APK
apk="https://github.com/fork-maintainers/iceraven-browser/releases/download/iceraven-$data/iceraven-$data-browser-arm64-v8a-forkRelease.apk"

wget -q $apk -O latest.apk

wget -q https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.8.1.jar -O apktool.jar
wget -q https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
chmod +x apktool*

rm -rf patched patched_signed.apk
./apktool d -s latest.apk -o patched
rm -rf patched/META-INF

sed -i 's/<color name="fx_mobile_layer_color_1">.*/<color name="fx_mobile_layer_color_1">@color\/photonBlack<\/color>/g' patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_layer_color_2">.*/<color name="fx_mobile_layer_color_2">@color\/photonDarkGrey90<\/color>/g' patched/res/values-night/colors.xml

./apktool b patched -o patched.apk --use-aapt2

zipalign 4 patched.apk patched_signed.apk
rm -rf patched patched.apk
