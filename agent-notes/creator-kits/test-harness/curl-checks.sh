#!/usr/bin/env bash
# Auth + Range checks for the kit routes (run ON node-2 via devhost run). Never committed.
set -u
B=http://127.0.0.1:${PORT:-4515}
T=_kit-test/tokens.json
npx tsx _kit-test/seed.ts >/dev/null
tok() { node -e "console.log(require('./$T').tokens['$1'])"; }
C="${NXEON_COOKIE_NAME:-nxeon_session}"
ZERO=$(tok zero); AIX=$(tok aix); NONE=$(tok none); CUST=$(tok cust); ADMIN=$(tok admin)
ZV=nxeon-promo_ZEROSTER_en_16x9.mp4
req() { # label expected cookie path [extra curl args...]
  local label=$1 exp=$2 ck=$3 path=$4; shift 4
  local args=(-s -o /dev/null -w '%{http_code} %{size_download} %{content_type} | %header{content-range} | %header{content-disposition}' "$@")
  [ -n "$ck" ] && args+=(-H "Cookie: $C=$ck")
  local out; out=$(curl "${args[@]}" "$B$path")
  local code=${out%% *}
  if [ "$code" = "$exp" ]; then echo "PASS  $label -> $out"; else echo "FAIL  $label (want $exp) -> $out"; fi
}
# warm the routes (dev compiles on first hit)
curl -s -o /dev/null "$B/api/creator-partner/kits/ZEROSTER/$ZV" ; curl -s -o /dev/null "$B/api/creator-partner/kits/ZEROSTER"
echo "--- signed out"
req "signed-out file"            401 ""      "/api/creator-partner/kits/ZEROSTER/$ZV"
req "signed-out zip"             401 ""      "/api/creator-partner/kits/ZEROSTER"
req "signed-out generic"         401 ""      "/api/creator-partner/kits/_generic/nxeon-promo_GENERIC_en_16x9.mp4"
echo "--- own files"
req "ZEROSTER own video"         200 "$ZERO" "/api/creator-partner/kits/ZEROSTER/$ZV"
req "ZEROSTER own endframe"      200 "$ZERO" "/api/creator-partner/kits/ZEROSTER/nxeon-promo_ZEROSTER_en_16x9_endframe.png"
req "ZEROSTER guide download"    200 "$ZERO" "/api/creator-partner/kits/ZEROSTER/HOW-TO-USE.txt?download=1"
req "ZEROSTER generic"           200 "$ZERO" "/api/creator-partner/kits/_generic/nxeon-promo_GENERIC_en_16x9.mp4"
req "ZEROSTER own zip"           200 "$ZERO" "/api/creator-partner/kits/ZEROSTER"
echo "--- range"
req "range 0-1023"               206 "$ZERO" "/api/creator-partner/kits/ZEROSTER/$ZV" -H "Range: bytes=0-1023"
req "range open-ended 1000000-"  206 "$ZERO" "/api/creator-partner/kits/ZEROSTER/$ZV" -H "Range: bytes=1000000-"
req "range suffix -500"          206 "$ZERO" "/api/creator-partner/kits/ZEROSTER/$ZV" -H "Range: bytes=-500"
req "range past end"             416 "$ZERO" "/api/creator-partner/kits/ZEROSTER/$ZV" -H "Range: bytes=999999999-"
req "HEAD"                       200 "$ZERO" "/api/creator-partner/kits/ZEROSTER/$ZV" -I
echo "--- other partners' files"
req "ZEROSTER -> AIXLL50 video"  404 "$ZERO" "/api/creator-partner/kits/AIXLL50/nxeon-promo_AIXLL50_en_16x9.mp4"
req "ZEROSTER -> AIXLL50 zip"    404 "$ZERO" "/api/creator-partner/kits/AIXLL50"
req "NOKIT9 -> ZEROSTER video"   404 "$NONE" "/api/creator-partner/kits/ZEROSTER/$ZV"
req "NOKIT9 generic"             200 "$NONE" "/api/creator-partner/kits/_generic/HOW-TO-USE.txt"
req "NOKIT9 own (none) zip"      404 "$NONE" "/api/creator-partner/kits/NOKIT9"
req "customer (no partner)"      404 "$CUST" "/api/creator-partner/kits/_generic/HOW-TO-USE.txt"
echo "--- traversal / validation"
req "lowercase code"             404 "$ZERO" "/api/creator-partner/kits/zeroster/$ZV"
req "dotdot encoded"             404 "$ZERO" "/api/creator-partner/kits/ZEROSTER/..%2F..%2Fkits%2FAIXLL50%2FHOW-TO-USE.txt"
req "dotdot code"                404 "$ZERO" "/api/creator-partner/kits/..%2FAIXLL50/HOW-TO-USE.txt"
req "unlisted file"              404 "$ZERO" "/api/creator-partner/kits/ZEROSTER/secret.txt"
req "admin as staff -> AIXLL50"  200 "$ADMIN" "/api/creator-partner/kits/AIXLL50/nxeon-promo_AIXLL50_tr_16x9_endframe.png"
echo "--- zip integrity"
curl -s -H "Cookie: $C=$ZERO" -o /tmp/kit-zeroster.zip "$B/api/creator-partner/kits/ZEROSTER"
python3 -c "
import zipfile,sys
z=zipfile.ZipFile('/tmp/kit-zeroster.zip'); bad=z.testzip()
print('zip entries:', [(i.filename,i.file_size) for i in z.infolist()]); print('testzip (CRC check):', 'OK' if bad is None else 'BAD '+bad)"
rm -f /tmp/kit-zeroster.zip
