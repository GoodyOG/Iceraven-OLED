#!/bin/bash
set -e

# Decompile with Apktool (decode resources + classes)
wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.11.0/apktool_2.11.0.jar -O apktool.jar
java -jar apktool.jar d iceraven.apk -o iceraven-patched
rm -rf iceraven-patched/META-INF

# ---- Color patching ----

# Legacy XML views (toolbar/webview chrome)
COLORS=iceraven-patched/res/values-night/colors.xml
if [ -f "$COLORS" ]; then
  sed -i 's/<color name="fx_mobile_surface">.*/<color name="fx_mobile_surface">#ff000000<\/color>/g' "$COLORS"
  sed -i 's/<color name="fx_mobile_background">.*/<color name="fx_mobile_background">#ff000000<\/color>/g' "$COLORS"
  sed -i 's/<color name="fx_mobile_layer_color_2">.*/<color name="fx_mobile_layer_color_2">@color\/photonDarkGrey90<\/color>/g' "$COLORS"
  echo "[OLED] values-night/colors.xml patched"
fi

# PhotonColors.smali: DarkGrey90 #15141A -> black
PH=$(find iceraven-patched -path '*/mozilla/components/ui/colors/PhotonColors.smali' | head -n1)
if [ -n "$PH" ]; then
  sed -i 's/ff15141a/ff000000/g' "$PH"
  echo "[OLED] PhotonColors patched: $PH"
fi

# NovaColors.smali: new dark surfaces (Gray65/70/75/80/85) -> black
NC=$(find iceraven-patched -path '*/mozilla/components/ui/colors/NovaColors.smali' | head -n1)
if [ -n "$NC" ]; then
  sed -i 's/ff312f33/ff000000/g; s/ff252428/ff000000/g; s/ff1d1b1f/ff000000/g; s/ff171519/ff000000/g; s/ff131215/ff000000/g' "$NC"
  echo "[OLED] NovaColors dark surfaces -> black"
fi

# ============================================================
# PRIVATE / INCOGNITO OLED 
# ============================================================

# 1) fx_mobile_private_surface -> black
#    Private window background + status bar (the huge solid
#    #180E30 region) via HomepageEdgeToEdgeFeature.
for C in iceraven-patched/res/values/colors.xml iceraven-patched/res/values-night/colors.xml; do
  if [ -f "$C" ]; then
    sed -i 's/<color name="fx_mobile_private_surface">.*/<color name="fx_mobile_private_surface">#ff000000<\/color>/g' "$C"
    echo "[OLED] $C: fx_mobile_private_surface -> black"
  fi
done

# 2) NovaColors dark-violet family -> black
#    Private scheme surfaces: toolbar #281D44=VioletDesaturated80,
#    home #180E30=VioletDesaturated90, all fields NUCLEAR blackens.
if [ -n "$NC" ]; then
  sed -i 's/ff180e30/ff000000/g; s/ff281d44/ff000000/g; s/ff3e315f/ff000000/g; s/ff584a7d/ff000000/g; s/ff3e2976/ff000000/g; s/ff5939a8/ff000000/g; s/80180e30/ff000000/g; s/b2180e30/ff000000/g; s/80711d08/ff000000/g' "$NC"
  echo "[OLED] NovaColors violet family -> black"
fi

# 3) AcornColorsKt private palette + private scheme inline colors -> black
#    #11042B = private layerGradientStart + surfaceContainer color,
#    #20163A / #0D0321 = private scheme surfaces.
AC=$(find iceraven-patched -path '*/mozilla/components/compose/base/theme/AcornColorsKt.smali' | head -n1)
if [ -n "$AC" ]; then
  sed -i 's/0xff11042b/0xff000000/g; s/0xff20163a/0xff000000/g; s/0xff0d0321/0xff000000/g' "$AC"
  echo "[OLED] AcornColorsKt private colors -> black"
fi

# ============================================================
# END private / incognito OLED
# ============================================================

# M3 dark defaults: Background/Surface/SurfaceDim (PaletteTokens.Neutral6) -> black
CDT=$(find iceraven-patched -path '*/androidx/compose/material3/tokens/ColorDarkTokens.smali' | head -n1)
if [ -n "$CDT" ]; then
  sed -i 's#sget-wide v0, Landroidx/compose/material3/tokens/PaletteTokens;->Neutral6:J#const-wide v0, 0xff000000L#' "$CDT"
  echo "[OLED] ColorDarkTokens patched (M3 background/surface)"
fi

# GeckoView loading/cover background (#2A2A2E -> black)
find iceraven-patched -path '*/org/mozilla/geckoview/GeckoView.smali' -exec sed -i 's/-0xd5d5d2/-0x1000000/g' {} +
find iceraven-patched -path '*/mozilla/components/browser/engine/gecko/GeckoEngineView.smali' -exec sed -i 's/-0xd5d5d2/-0x1000000/g' {} +
echo "[OLED] GeckoView loading background -> black"

# ============================================================
# TAB BAR (tab strip) + STATUS BAR OLED
# ============================================================
AGS=$(find iceraven-patched -path '*/mozilla/components/compose/base/theme/AcornGradientSchemeKt.smali' | head -n1)
if [ -n "$AGS" ]; then
  sed -i -E 's#sget-wide ([vp][0-9]+), Lmozilla/components/ui/colors/NovaColors;->(VioletDesaturated90A40|Orange70A50|VioletDesaturated80|Violet10A50|Orange10A50):J#const-wide \1, 0xff000000L#' "$AGS"
  if grep -q 'NovaColors;->\(VioletDesaturated90A40\|Orange70A50\|VioletDesaturated80\|Violet10A50\|Orange10A50\):J' "$AGS"; then
    echo "[OLED] WARN: accentSubtle colors not fully patched: $AGS"
  else
    echo "[OLED] tab bar + status bar (accentSubtle) -> black"
  fi
fi
# ============================================================

# Recompile the APK
java -jar apktool.jar b iceraven-patched -o iceraven-patched.apk --use-aapt2

# Align the APK (signing happens in the workflow with the release keystore)
zipalign -f 4 iceraven-patched.apk iceraven-patched-signed.apk

# Clean up
rm -rf iceraven-patched iceraven-patched.apk apktool.jar
