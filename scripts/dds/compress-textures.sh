#!/bin/bash

set -e

if [ -z "$1" ]; then
	echo "Usage: $0 <bc7enc>"
	exit 1
fi

BC7ENC="$1"

chmod +x "$BC7ENC"

rm -rf "dds-textures"

mkdir -p "dds-textures"

EXCLUDES=(
	"assets/ui/options/"
	"assets/ui/cursor/"
	"assets/ui/fonts/"
	"assets/ui/freeplay/"
	"assets/ui/soundtray/"
	"assets/ui/story-mode/levels/"
	"assets/ui/editors/"
	"assets/gameplay/dialogue/"
	"assets/gameplay/notestyles/pixel/"
	"assets/gameplay/characters/bf-pixel/"
	"assets/gameplay/characters/gf/"
	"assets/gameplay/characters/gf-car/"
	"assets/gameplay/characters/gf-christmas/"
	"assets/gameplay/characters/gf-dark/"
	"assets/gameplay/characters/gf-pixel/"
	"assets/gameplay/characters/nene-pixel/"
	"assets/gameplay/characters/pico-pixel/"
	"assets/gameplay/characters/senpai/"
	"assets/gameplay/characters/spirit/"
	"assets/gameplay/stages/mainStage/"
	"assets/gameplay/stages/school/"
	"assets/gameplay/stages/schoolErect/"
	"assets/gameplay/stages/schoolEvil/"
	"assets/gameplay/stages/schoolEvilErect/"
	"assets/ui/results/clear-percent/"
	"assets/ui/results/difficulty/"
	"assets/ui/results/rank-text/"
)

EXCLUDE_FILES=(
	"assets/gameplay/characters/bf/icon-bf.png"
	"assets/gameplay/characters/bf-old/icon-bf-old.png"
	"assets/gameplay/characters/bf-pixel/icon-bf-pixel.png"
	"assets/gameplay/characters/dad/icon-dad.png"
	"assets/gameplay/characters/darnell/icon-darnell.png"
	"assets/gameplay/characters/face/icon-face.png"
	"assets/gameplay/characters/gf/icon-gf.png"
	"assets/gameplay/characters/mom/icon-mom.png"
	"assets/gameplay/characters/monster/icon-monster.png"
	"assets/gameplay/characters/parents-christmas/icon-parents.png"
	"assets/gameplay/characters/parents-christmas/icon-parents-christmas.png"
	"assets/gameplay/characters/pico/icon-pico.png"
	"assets/gameplay/characters/senpai/icon-senpai.png"
	"assets/gameplay/characters/spirit/icon-spirit.png"
	"assets/gameplay/characters/spooky/icon-spooky.png"
	"assets/gameplay/characters/tankman/icon-tankman.png"
	"assets/gameplay/characters/tankman/icon-tankman-bloody.png"
	"assets/gameplay/characters/sserafim-chaewon/icon-sserafim-chaewon.png"
	"assets/gameplay/characters/sserafim-eunchae/icon-sserafim-eunchae.png"
	"assets/gameplay/characters/sserafim-kazuha/icon-sserafim-kazuha.png"
	"assets/gameplay/characters/sserafim-sakura/icon-sserafim-sakura.png"
	"assets/gameplay/characters/sserafim-yunjin/icon-sserafim-yunjin.png"
	"assets/ui/title/title-screen-text/spritemap1.png"
	"assets/ui/title/title-screen-text-mobile/spritemap1.png"
	"assets/gameplay/characters/nene/nene/spritemap1.png"
	"assets/gameplay/characters/pico-holding-nene/pico-holding-nene/spritemap1.png"
	"assets/gameplay/characters/sserafim-eunchae/sserafim-eunchae/spritemap1.png"
	"assets/gameplay/characters/sserafim-kazuha/sserafim-kazuha/spritemap1.png"
	"assets/gameplay/characters/sserafim-akura/sserafim-sakura/spritemap1.png"
	"assets/gameplay/characters/sserafim-gf/sserafim-gf/spritemap1.png"
	"assets/gameplay/characters/sserafim-yunjin/sserafim-yunjin/spritemap1.png"
	"assets/gameplay/general/health-bar.png"
	"assets/gameplay/playable-characters/bf/results/graphics/results-excellent/spritemap1.png"
	"assets/gameplay/playable-characters/bf/results/graphics/results-good/gf.png"
	"assets/gameplay/playable-characters/bf/results/graphics/results-great/gf/spritemap1.png"
	"assets/gameplay/playable-characters/bf/results/graphics/results-shit/spritemap1.png"
	"assets/gameplay/stages/mainStageErect/bright-light.png"
	"assets/gameplay/stages/mainStageErect/light-above.png"
	"assets/gameplay/stages/mainStageErect/light-green.png"
	"assets/gameplay/stages/mainStageErect/light-red.png"
	"assets/gameplay/stages/mainStageErect/light-orange.png"
	"assets/gameplay/stages/spookyMansionErect/stairs-dark.png"
	"assets/gameplay/stages/spookyMansionErect/stairs-light.png"
	"assets/gameplay/stages/tankmanBattlefield/bricks-ground.png"
	"assets/gameplay/stages/tankmanBattlefieldErect/bricks-ground.png"
	"assets/gameplay/stages/sserafim/cutscene/cutscene-main/spritemap1.png"
)

is_excluded()
{
	local file="$1"

	for exclude in "${EXCLUDE_FILES[@]}"; do
		[ "$file" = "$exclude" ] && return 0
	done

	for exclude in "${EXCLUDES[@]}"; do
		[[ "$file" == "$exclude"* ]] && return 0
	done

	return 1
}

find "assets" -type f -name "*.png" | while read -r f; do
	if is_excluded "$f"; then
		continue
	fi

	out="dds-textures/$(dirname "$f")"
	mkdir -p "$out"

	dds="$out/$(basename "${f%.png}.dds")"

	echo "Compressing: $f"

	"$BC7ENC" \
		-3 \
		-g \
		-q \
		"$f" \
		"$dds"
done
