#!/bin/bash
# Rebuilds the gallery: the characters from their seeds (avatar-tools build-character), then gallery.json, the
# signed .avatarpack files and the thumbnails (avatar-tools gallery). Run from this folder:
#
#   AVATAR_TOOLS=../AvatarReminder/Tools/AvatarTools/.build/release/avatar-tools KEY=~/avatar-gallery-key ./build.sh
#
# The signing key never goes in this repo.
set -euo pipefail
TOOLS="${AVATAR_TOOLS:-../AvatarReminder/Tools/AvatarTools/.build/release/avatar-tools}"
KEY="${KEY:-$HOME/avatar-gallery-key}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# id, name, seed, version: each design is the builder's random design for that seed. Raise a character's
# version when you change it, so installed copies offer an update.
CHARACTERS=(
  "toast|Toast|6|1.0.0"
  "poppy|Poppy|11|1.0.0"
  "frost|Frost|20|1.0.0"
  "honey|Honey|23|1.0.0"
  "marina|Marina|34|1.0.0"
  "moon|Moon|40|1.0.0"
  "kiwi|Kiwi|42|1.0.0"
  "disco|Disco|43|1.0.0"
)
for entry in "${CHARACTERS[@]}"; do
  IFS='|' read -r id name seed version <<<"$entry"
  "$TOOLS" build-character --seed "$seed" --id "$id" --name "$name" --author "Avatar Reminder" -o "$WORK/packs"
  /usr/bin/python3 - "$WORK/packs/$id.character/manifest.json" "$version" <<'PY'
import json, sys
path, version = sys.argv[1], sys.argv[2]
manifest = json.load(open(path))
manifest["version"] = version
json.dump(manifest, open(path, "w"), indent=2, sort_keys=True)
PY
done

"$TOOLS" gallery "$WORK/packs" -o "$WORK/site" --key "$KEY" --title "Avatar Reminder Gallery" \
  --summary "toast=A toasty little box who never misses a beat" \
  --summary "poppy=A spotty pink bear in round glasses" \
  --summary "frost=Cool as ice, in shades and a beanie" \
  --summary "honey=A sweet striped bunny with a mug" \
  --summary "marina=Sea-green royalty with a golden crown" \
  --summary "moon=A calm little moon with an antenna" \
  --summary "kiwi=A cheerful green frog-bear in specs" \
  --summary "disco=Always dressed for a party"

rm -rf gallery.json packs thumbnails
cp -R "$WORK/site/." .
echo "Built $(ls packs | wc -l | tr -d ' ') characters."
