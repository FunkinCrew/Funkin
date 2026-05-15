package funkin.modding.compat;

import openfl.utils.AssetType as OpenFLAssetType;

/**
 * A utility class which evaluates asset paths,
 * checking known previous paths for backwards compatibility.
 */
class Paths
{
  /**
   * A static map of known previous paths for certain assets, or paths older mods may try to access files at.
   * Used for maintaining backwards compatibility by redirecting file queries.
   * Try not to remove any, even if they're super old!
   */
  static final PATHS:Map<String, String> = [
    // ===
    //
    // Pre-Great Sorting asset paths, with library.
    //
    // 'assets/shared/images/characters/BOYFRIEND.png'
    // 'assets/shared/images/characters/BOYFRIEND.xml'
    // 'assets/shared/images/characters/senpai.xml'
    'assets/images/charSelect/barThing/Animation.json' => 'assets/ui/character-select/interface/bar-thing/Animation.json',
    'assets/images/charSelect/barThing/spritemap1.json' => 'assets/ui/character-select/interface/bar-thing/spritemap1.json',
    'assets/images/charSelect/barThing/spritemap1.png' => 'assets/ui/character-select/interface/bar-thing/spritemap1.png',
    'assets/images/charSelect/charSelectSpeakers/Animation.json' => 'assets/ui/character-select/interface/speakers/Animation.json',
    'assets/images/charSelect/charSelectSpeakers/spritemap1.json' => 'assets/ui/character-select/interface/speakers/spritemap1.json',
    'assets/images/charSelect/charSelectSpeakers/spritemap1.png' => 'assets/ui/character-select/interface/speakers/spritemap1.png',
    'assets/images/charSelect/charSelectStage/Animation.json' => 'assets/ui/character-select/interface/char-select-stage/Animation.json',
    'assets/images/charSelect/charSelectStage/spritemap1.json' => 'assets/ui/character-select/interface/char-select-stage/spritemap1.json',
    'assets/images/charSelect/charSelectStage/spritemap1.png' => 'assets/ui/character-select/interface/char-select-stage/spritemap1.png',
    'assets/images/charSelect/crowd/Animation.json' => 'assets/ui/character-select/interface/crowd/Animation.json',
    'assets/images/charSelect/crowd/spritemap1.json' => 'assets/ui/character-select/interface/crowd/spritemap1.json',
    'assets/images/charSelect/crowd/spritemap1.png' => 'assets/ui/character-select/interface/crowd/spritemap1.png',
    'assets/images/charSelect/lock/Animation.json' => 'assets/ui/character-select/interface/lock/Animation.json',
    'assets/images/charSelect/lock/spritemap1.json' => 'assets/ui/character-select/interface/lock/spritemap1.json',
    'assets/images/charSelect/lock/spritemap1.png' => 'assets/ui/character-select/interface/lock/spritemap1.png',
    'assets/images/freeplay/albumRoll/freeplayAlbum/Animation.json' => 'assets/ui/freeplay/interface/freeplay-album/Animation.json',
    'assets/images/freeplay/albumRoll/freeplayAlbum/spritemap1.json' => 'assets/ui/freeplay/interface/freeplay-album/spritemap1.json',
    'assets/images/freeplay/albumRoll/freeplayAlbum/spritemap1.png' => 'assets/ui/freeplay/interface/freeplay-album/spritemap1.png',
    'assets/images/freeplay/backing-text-yeah/Animation.json' => 'assets/ui/freeplay/styles/bf/backing-card/Animation.json',
    'assets/images/freeplay/backing-text-yeah/spritemap1.json' => 'assets/ui/freeplay/styles/bf/backing-card/spritemap1.json',
    'assets/images/freeplay/backing-text-yeah/spritemap1.png' => 'assets/ui/freeplay/styles/bf/backing-card/spritemap1.png',
    'assets/images/freeplay/backingCards/pico/pico-confirm/Animation.json' => 'assets/ui/freeplay/styles/pico/backing-card/pico-confirm/Animation.json',
    'assets/images/freeplay/backingCards/pico/pico-confirm/spritemap1.json' => 'assets/ui/freeplay/styles/pico/backing-card/pico-confirm/spritemap1.json',
    'assets/images/freeplay/backingCards/pico/pico-confirm/spritemap1.png' => 'assets/ui/freeplay/styles/pico/backing-card/pico-confirm/spritemap1.png',
    'assets/images/freeplay/freeplayStars/Animation.json' => 'assets/ui/freeplay/difficulty/freeplay-stars/Animation.json',
    'assets/images/freeplay/freeplayStars/spritemap1.json' => 'assets/ui/freeplay/difficulty/freeplay-stars/spritemap1.json',
    'assets/images/freeplay/freeplayStars/spritemap1.png' => 'assets/ui/freeplay/difficulty/freeplay-stars/spritemap1.png',
    'assets/images/freeplay/sortedLetters/Animation.json' => 'assets/ui/freeplay/interface/sorted-letters/Animation.json',
    'assets/images/freeplay/sortedLetters/spritemap1.json' => 'assets/ui/freeplay/interface/sorted-letters/spritemap1.json',
    'assets/images/freeplay/sortedLetters/spritemap1.png' => 'assets/ui/freeplay/interface/sorted-letters/spritemap1.png',
    'assets/images/title-screen-text-mobile/Animation.json' => 'assets/ui/title/title-screen-text-mobile/Animation.json',
    'assets/images/title-screen-text-mobile/spritemap1.json' => 'assets/ui/title/title-screen-text-mobile/spritemap1.json',
    'assets/images/title-screen-text-mobile/spritemap1.png' => 'assets/ui/title/title-screen-text-mobile/spritemap1.png',
    'assets/images/title-screen-text/Animation.json' => 'assets/ui/title/title-screen-text/Animation.json',
    'assets/images/title-screen-text/spritemap1.json' => 'assets/ui/title/title-screen-text/spritemap1.json',
    'assets/images/title-screen-text/spritemap1.png' => 'assets/ui/title/title-screen-text/spritemap1.png',
    'assets/images/ui/medal/Animation.json' => 'assets/ui/medals/medal-popup/Animation.json',
    'assets/images/ui/medal/spritemap1.json' => 'assets/ui/medals/medal-popup/spritemap1.json',
    'assets/images/ui/medal/spritemap1.png' => 'assets/ui/medals/medal-popup/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsEXCELLENT/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-excellent/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsEXCELLENT/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-excellent/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsEXCELLENT/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-excellent/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsGOOD/bf/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-good/bf/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsGOOD/bf/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-good/bf/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsGOOD/bf/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-good/bf/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsGOOD/resultGirlfriendGOOD.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-good/gf.png',
    'assets/shared/images/resultScreen/results-bf/resultsGOOD/resultGirlfriendGOOD.xml' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-good/gf.xml',
    'assets/shared/images/resultScreen/results-bf/resultsGREAT/bf/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-great/bf/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsGREAT/bf/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-great/bf/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsGREAT/bf/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-great/bf/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsGREAT/gf/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-great/gf/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsGREAT/gf/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-great/gf/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsGREAT/gf/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-great/gf/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/bed/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/bed/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/bed/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/bed/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/bed/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/bed/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/hearts/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/hearts/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/hearts/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/hearts/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/hearts/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/hearts/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/tickleFight/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/tickleFight/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/tickleFight/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/tickleFight/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsPERFECT/tickleFight/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-perfect/tickleFight/spritemap1.png',
    'assets/shared/images/resultScreen/results-bf/resultsSHIT/Animation.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-shit/Animation.json',
    'assets/shared/images/resultScreen/results-bf/resultsSHIT/spritemap1.json' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-shit/spritemap1.json',
    'assets/shared/images/resultScreen/results-bf/resultsSHIT/spritemap1.png' =>
    'assets/gameplay/playable-characters/bf/results/graphics/results-shit/spritemap1.png',
    'assets/shared/images/resultScreen/results-pico/resultsGOOD/Animation.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-good/Animation.json',
    'assets/shared/images/resultScreen/results-pico/resultsGOOD/spritemap1.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-good/spritemap1.json',
    'assets/shared/images/resultScreen/results-pico/resultsGOOD/spritemap1.png' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-good/spritemap1.png',
    'assets/shared/images/resultScreen/results-pico/resultsGREAT/Animation.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-great/Animation.json',
    'assets/shared/images/resultScreen/results-pico/resultsGREAT/spritemap1.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-great/spritemap1.json',
    'assets/shared/images/resultScreen/results-pico/resultsGREAT/spritemap1.png' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-great/spritemap1.png',
    'assets/shared/images/resultScreen/results-pico/resultsPERFECT/Animation.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-perfect/Animation.json',
    'assets/shared/images/resultScreen/results-pico/resultsPERFECT/spritemap1.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-perfect/spritemap1.json',
    'assets/shared/images/resultScreen/results-pico/resultsPERFECT/spritemap1.png' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-perfect/spritemap1.png',
    'assets/shared/images/resultScreen/results-pico/resultsSHIT/Animation.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-shit/Animation.json',
    'assets/shared/images/resultScreen/results-pico/resultsSHIT/spritemap1.json' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-shit/spritemap1.json',
    'assets/shared/images/resultScreen/results-pico/resultsSHIT/spritemap1.png' =>
    'assets/gameplay/playable-characters/pico/results/graphics/results-shit/spritemap1.png',
    'assets/week2/images/halloween_bg/Animation.json' => '',
    'assets/week2/images/halloween_bg/spritemap1.json' => '',
    'assets/week2/images/halloween_bg/spritemap1.png' => '',
    'assets/week3/images/philly/erect/bloodPool/Animation.json' => '',
    'assets/week3/images/philly/erect/bloodPool/spritemap1.json' => '',
    'assets/week3/images/philly/erect/bloodPool/spritemap1.png' => '',
    'assets/week3/images/philly/erect/pico_doppleganger/Animation.json' => '',
    'assets/week3/images/philly/erect/pico_doppleganger/spritemap1.json' => '',
    'assets/week3/images/philly/erect/pico_doppleganger/spritemap1.png' => '',
    'assets/week5/images/christmas/erect/bottomBop/Animation.json' => '',
    'assets/week5/images/christmas/erect/bottomBop/spritemap1.json' => '',
    'assets/week5/images/christmas/erect/bottomBop/spritemap1.png' => '',
    'assets/week5/images/christmas/parents_shoot_assets/Animation.json' => '',
    'assets/week5/images/christmas/parents_shoot_assets/spritemap1.json' => '',
    'assets/week5/images/christmas/parents_shoot_assets/spritemap1.png' => '',
    'assets/week5/images/christmas/santa_speaks_assets/Animation.json' => '',
    'assets/week5/images/christmas/santa_speaks_assets/spritemap1.json' => '',
    'assets/week5/images/christmas/santa_speaks_assets/spritemap1.png' => '',
    'assets/week7/images/erect/cutscene/tankmanEnding/Animation.json' => '',
    'assets/week7/images/erect/cutscene/tankmanEnding/spritemap1.json' => '',
    'assets/week7/images/erect/cutscene/tankmanEnding/spritemap1.png' => '',
    'assets/week7/images/erect/rando/Animation.json' => '',
    'assets/week7/images/erect/rando/spritemap1.json' => '',
    'assets/week7/images/erect/rando/spritemap1.png' => '',
    'assets/week7/images/erect/sniper/Animation.json' => '',
    'assets/week7/images/erect/sniper/spritemap1.json' => '',
    'assets/week7/images/erect/sniper/spritemap1.png' => '',
    'assets/weekend1/images/spraycanAtlas/Animation.json' => '',
    'assets/weekend1/images/spraycanAtlas/spritemap1.json' => '',
    'assets/weekend1/images/spraycanAtlas/spritemap1.png' => '',
    'assets/shared/images/holdCoverBlue.png' => 'assets/gameplay/notestyles/funkin/hold-cover-down.png',
    'assets/shared/images/holdCoverBlue.xml' => 'assets/gameplay/notestyles/funkin/hold-cover-down.xml',
    'assets/shared/images/holdCoverGreen.png' => 'assets/gameplay/notestyles/funkin/hold-cover-up.png',
    'assets/shared/images/holdCoverGreen.xml' => 'assets/gameplay/notestyles/funkin/hold-cover-up.xml',
    'assets/shared/images/holdCoverPurple.png' => 'assets/gameplay/notestyles/funkin/hold-cover-left.png',
    'assets/shared/images/holdCoverPurple.xml' => 'assets/gameplay/notestyles/funkin/hold-cover-left.xml',
    'assets/shared/images/holdCoverRed.png' => 'assets/gameplay/notestyles/funkin/hold-cover-right.png',
    'assets/shared/images/holdCoverRed.xml' => 'assets/gameplay/notestyles/funkin/hold-cover-right.xml',
    'assets/shared/images/noteSplashes.png' => 'assets/gameplay/notestyles/funkin/note-splashes.png',
    'assets/shared/images/noteSplashes.xml' => 'assets/gameplay/notestyles/funkin/note-splashes.xml',
    'assets/shared/images/noteStrumline.png' => 'assets/gameplay/notestyles/funkin/note-strumline.png',
    'assets/shared/images/noteStrumline.xml' => 'assets/gameplay/notestyles/funkin/note-strumline.xml',
    'assets/shared/images/notes.png' => 'assets/gameplay/notestyles/funkin/notes.png',
    'assets/shared/images/notes.xml' => 'assets/gameplay/notestyles/funkin/notes.xml',
    'assets/music/chartEditorLoop/chartEditorLoop-metadata.json' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression-metadata.json',
    'assets/music/chartEditorLoop/chartEditorLoop.ogg' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression.ogg',
    'assets/music/freakyMenu/freakyMenu-metadata.json' => 'assets/ui/main-menu/freaky-menu/freaky-menu-metadata.json',
    'assets/music/freakyMenu/freakyMenu.ogg' => 'assets/ui/main-menu/freaky-menu/freaky-menu.ogg',
    'assets/music/freeplayRandom/freeplayRandom-metadata.json' => 'assets/ui/freeplay/freeplay-random/freeplay-random-metadata.json',
    'assets/music/freeplayRandom/freeplayRandom.ogg' => 'assets/ui/freeplay/freeplay-random/freeplay-random.ogg',
    'assets/music/girlfriendsRingtone/girlfriendsRingtone-metadata.json' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone-metadata.json',
    'assets/music/girlfriendsRingtone/girlfriendsRingtone.ogg' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone.ogg',
    'assets/music/offsetsLoop/drumsLoop.ogg' => 'assets/ui/input-offsets/drums-loop/drums-loop.ogg',
    'assets/music/offsetsLoop/offsetsLoop.ogg' => 'assets/ui/input-offsets/offsets-loop/offsets-loop.ogg',
    'assets/music/stayFunky/stayFunky-intro.ogg' => 'assets/ui/character-select/stay-funky/stay-funky-intro.ogg',
    'assets/music/stayFunky/stayFunky-metadata.json' => 'assets/ui/character-select/stay-funky/stay-funky-metadata.json',
    'assets/music/stayFunky/stayFunky.ogg' => 'assets/ui/character-select/stay-funky/stay-funky.ogg',
    'assets/shared/images/characters/NeneKnifeToss.png' => 'assets/gameplay/characters/nene/nene-knifetoss.png',
    'assets/shared/images/characters/NeneKnifeToss.xml' => 'assets/gameplay/characters/nene/nene-knifetoss.xml',
    'assets/shared/images/characters/SpookyKids.png' => 'assets/gameplay/characters/spooky/spooky-kids.png',
    'assets/shared/images/characters/SpookyKids.xml' => 'assets/gameplay/characters/spooky/spooky-kids.xml',
    'assets/shared/images/characters/abot/abotSystem/Animation.json' => 'assets/gameplay/characters/nene/abot-system/Animation.json',
    'assets/shared/images/characters/abot/abotSystem/spritemap1.json' => 'assets/gameplay/characters/nene/abot-system/spritemap1.json',
    'assets/shared/images/characters/abot/abotSystem/spritemap1.png' => 'assets/gameplay/characters/nene/abot-system/spritemap1.png',
    'assets/shared/images/characters/abot/dark/abotSystem/Animation.json' => 'assets/gameplay/characters/nene-dark/abot-system-dark/Animation.json',
    'assets/shared/images/characters/abot/dark/abotSystem/spritemap1.json' => 'assets/gameplay/characters/nene-dark/abot-system-dark/spritemap1.json',
    'assets/shared/images/characters/abot/dark/abotSystem/spritemap1.png' => 'assets/gameplay/characters/nene-dark/abot-system-dark/spritemap1.png',
    'assets/shared/images/characters/abot/systemEyes/Animation.json' => 'assets/gameplay/characters/nene/abot-eyes/Animation.json',
    'assets/shared/images/characters/abot/systemEyes/spritemap1.json' => 'assets/gameplay/characters/nene/abot-eyes/spritemap1.json',
    'assets/shared/images/characters/abot/systemEyes/spritemap1.png' => 'assets/gameplay/characters/nene/abot-eyes/spritemap1.png',
    'assets/shared/images/characters/bf-car/Animation.json' => 'assets/gameplay/characters/bf-car/bf-car/Animation.json',
    'assets/shared/images/characters/bf-car/spritemap1.json' => 'assets/gameplay/characters/bf-car/bf-car/spritemap1.json',
    'assets/shared/images/characters/bf-car/spritemap1.png' => 'assets/gameplay/characters/bf-car/bf-car/spritemap1.png',
    'assets/shared/images/characters/bf-dark/Animation.json' => 'assets/gameplay/characters/bf-dark/bf-dark/Animation.json',
    'assets/shared/images/characters/bf-dark/spritemap1.json' => 'assets/gameplay/characters/bf-dark/bf-dark/spritemap1.json',
    'assets/shared/images/characters/bf-dark/spritemap1.png' => 'assets/gameplay/characters/bf-dark/bf-dark/spritemap1.png',
    'assets/shared/images/characters/bf-death/Animation.json' => 'assets/gameplay/characters/bf/bf-dead/Animation.json',
    'assets/shared/images/characters/bf-death/spritemap1.json' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.json',
    'assets/shared/images/characters/bf-death/spritemap1.png' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.png',
    'assets/shared/images/characters/bf/Animation.json' => 'assets/gameplay/characters/bf/boyfriend/Animation.json',
    'assets/shared/images/characters/bf/spritemap1.json' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.json',
    'assets/shared/images/characters/bf/spritemap1.png' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.png',
    'assets/shared/images/characters/bfFakeOut/Animation.json' => 'assets/gameplay/characters/bf/bf-fakeout/Animation.json',
    'assets/shared/images/characters/bfFakeOut/spritemap1.json' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.json',
    'assets/shared/images/characters/bfFakeOut/spritemap1.png' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.png',
    'assets/shared/images/characters/dad/Animation.json' => 'assets/gameplay/characters/dad/daddy-dearest/Animation.json',
    'assets/shared/images/characters/dad/spritemap1.json' => 'assets/gameplay/characters/dad/daddy-dearest/spritemap1.json',
    'assets/shared/images/characters/dad/spritemap1.png' => 'assets/gameplay/characters/dad/daddy-dearest/spritemap1.png',
    'assets/shared/images/characters/darnell/Animation.json' => 'assets/gameplay/characters/darnell/darnell/Animation.json',
    'assets/shared/images/characters/darnell/spritemap1.json' => 'assets/gameplay/characters/darnell/darnell/Animation.json',
    'assets/shared/images/characters/darnell/spritemap1.png' => 'assets/gameplay/characters/darnell/darnell/Animation.json',
    'assets/shared/images/characters/darnellBlazin/Animation.json' => 'assets/gameplay/characters/darnell-blazin/darnell-blazin/Animation.json',
    'assets/shared/images/characters/darnellBlazin/spritemap1.json' => 'assets/gameplay/characters/darnell-blazin/darnell-blazin/spritemap1.json',
    'assets/shared/images/characters/darnellBlazin/spritemap1.png' => 'assets/gameplay/characters/darnell-blazin/darnell-blazin/spritemap1.png',
    'assets/shared/images/characters/gf-christmas/Animation.json' => 'assets/gameplay/characters/gf-christmas/gf-christmas/Animation.json',
    'assets/shared/images/characters/gf-christmas/spritemap1.json' => 'assets/gameplay/characters/gf-christmas/gf-christmas/Animation.json',
    'assets/shared/images/characters/gf-christmas/spritemap1.png' => 'assets/gameplay/characters/gf-christmas/gf-christmas/Animation.json',
    'assets/shared/images/characters/gf-dark/Animation.json' => 'assets/gameplay/characters/gf-dark/gf-dark/Animation.json',
    'assets/shared/images/characters/gf-dark/spritemap1.json' => 'assets/gameplay/characters/gf-dark/gf-dark/spritemap1.json',
    'assets/shared/images/characters/gf-dark/spritemap1.png' => 'assets/gameplay/characters/gf-dark/gf-dark/spritemap1.png',
    'assets/shared/images/characters/gf/Animation.json' => 'assets/gameplay/characters/gf/girlfriend/Animation.json',
    'assets/shared/images/characters/gf/spritemap1.json' => 'assets/gameplay/characters/gf/girlfriend/spritemap1.json',
    'assets/shared/images/characters/gf/spritemap1.png' => 'assets/gameplay/characters/gf/girlfriend/spritemap1.png',
    'assets/shared/images/characters/gfCar/Animation.json' => 'assets/gameplay/characters/gf-car/gf-car/Animation.json',
    'assets/shared/images/characters/gfCar/spritemap1.json' => 'assets/gameplay/characters/gf-car/gf-car/spritemap1.json',
    'assets/shared/images/characters/gfCar/spritemap1.png' => 'assets/gameplay/characters/gf-car/gf-car/spritemap1.png',
    'assets/shared/images/characters/momCar/Animation.json' => 'assets/gameplay/characters/mom-car/mom-car/Animation.json',
    'assets/shared/images/characters/momCar/spritemap1.json' => 'assets/gameplay/characters/mom-car/mom-car/spritemap1.json',
    'assets/shared/images/characters/momCar/spritemap1.png' => 'assets/gameplay/characters/mom-car/mom-car/spritemap1.png',
    'assets/shared/images/characters/monster/Animation.json' => 'assets/gameplay/characters/monster/monster/Animation.json',
    'assets/shared/images/characters/monster/spritemap1.json' => 'assets/gameplay/characters/monster/monster/spritemap1.json',
    'assets/shared/images/characters/monster/spritemap1.png' => 'assets/gameplay/characters/monster/monster/spritemap1.png',
    'assets/shared/images/characters/nene-christmas/Animation.json' => 'assets/gameplay/characters/nene-christmas/nene-christmas/Animation.json',
    'assets/shared/images/characters/nene-christmas/spritemap1.json' => 'assets/gameplay/characters/nene-christmas/nene-christmas/spritemap1.json',
    'assets/shared/images/characters/nene-christmas/spritemap1.png' => 'assets/gameplay/characters/nene-christmas/nene-christmas/spritemap1.png',
    'assets/shared/images/characters/nene-dark/Animation.json' => 'assets/gameplay/characters/nene-dark/nene-dark/Animation.json',
    'assets/shared/images/characters/nene-dark/spritemap1.json' => 'assets/gameplay/characters/nene-dark/nene-dark/Animation.json',
    'assets/shared/images/characters/nene-dark/spritemap1.png' => 'assets/gameplay/characters/nene-dark/nene-dark/Animation.json',
    'assets/shared/images/characters/nene/Animation.json' => 'assets/gameplay/characters/nene/nene/Animation.json',
    'assets/shared/images/characters/nene/spritemap1.json' => 'assets/gameplay/characters/nene/nene/spritemap1.json',
    'assets/shared/images/characters/nene/spritemap1.png' => 'assets/gameplay/characters/nene/nene/spritemap1.png',
    'assets/shared/images/characters/neneChristmasKnife.png' => 'assets/gameplay/characters/nene-christmas/nene-christmas-knife.png',
    'assets/shared/images/characters/neneChristmasKnife.xml' => 'assets/gameplay/characters/nene-christmas/nene-christmas-knife.xml',
    'assets/shared/images/characters/otis/Animation.json' => 'assets/gameplay/characters/otis-speaker/otis-speaker/Animation.json',
    'assets/shared/images/characters/otis/spritemap1.json' => 'assets/gameplay/characters/otis-speaker/otis-speaker/spritemap1.json',
    'assets/shared/images/characters/otis/spritemap1.png' => 'assets/gameplay/characters/otis-speaker/otis-speaker/spritemap1.png',
    'assets/shared/images/characters/parents-christmas/Animation.json' => 'assets/gameplay/characters/parents-christmas/parents-christmas/Animation.json',
    'assets/shared/images/characters/parents-christmas/spritemap1.json' => 'assets/gameplay/characters/parents-christmas/parents-christmas/spritemap1.json',
    'assets/shared/images/characters/parents-christmas/spritemap1.png' => 'assets/gameplay/characters/parents-christmas/parents-christmas/spritemap1.png',
    'assets/shared/images/characters/pico-christmas/Animation.json' => 'assets/gameplay/characters/pico-christmas/pico-christmas/Animation.json',
    'assets/shared/images/characters/pico-christmas/spritemap1.json' => 'assets/gameplay/characters/pico-christmas/pico-christmas/spritemap1.json',
    'assets/shared/images/characters/pico-christmas/spritemap1.png' => 'assets/gameplay/characters/pico-christmas/pico-christmas/spritemap1.png',
    'assets/shared/images/characters/pico-dark/Animation.json' => 'assets/gameplay/characters/pico-dark/pico-dark/Animation.json',
    'assets/shared/images/characters/pico-dark/spritemap1.json' => 'assets/gameplay/characters/pico-dark/pico-dark/spritemap1.json',
    'assets/shared/images/characters/pico-dark/spritemap1.png' => 'assets/gameplay/characters/pico-dark/pico-dark/spritemap1.png',
    'assets/shared/images/characters/pico-holding-nene/Animation.json' => 'assets/gameplay/characters/pico-holding-nene/pico-holding-nene/Animation.json',
    'assets/shared/images/characters/pico-holding-nene/picoAndNene-DEAD/Animation.json' =>
    'assets/gameplay/characters/pico-holding-nene/pico-holding-nene-dead/Animation.json',
    'assets/shared/images/characters/pico-holding-nene/picoAndNene-DEAD/spritemap1.json' =>
    'assets/gameplay/characters/pico-holding-nene/pico-holding-nene-dead/spritemap1.json',
    'assets/shared/images/characters/pico-holding-nene/picoAndNene-DEAD/spritemap1.png' =>
    'assets/gameplay/characters/pico-holding-nene/pico-holding-nene-dead/spritemap1.png',
    'assets/shared/images/characters/pico-holding-nene/spritemap1.json' => 'assets/gameplay/characters/pico-holding-nene/pico-holding-nene/spritemap1.json',
    'assets/shared/images/characters/pico-holding-nene/spritemap1.png' => 'assets/gameplay/characters/pico-holding-nene/pico-holding-nene/spritemap1.png',
    'assets/shared/images/characters/pico-speaker/Animation.json' => 'assets/gameplay/characters/pico-speaker/pico-speaker/Animation.json',
    'assets/shared/images/characters/pico-speaker/spritemap1.json' => 'assets/gameplay/characters/pico-speaker/pico-speaker/spritemap1.json',
    'assets/shared/images/characters/pico-speaker/spritemap1.png' => 'assets/gameplay/characters/pico-speaker/pico-speaker/spritemap1.png',
    'assets/shared/images/characters/pico/basic-animations/Animation.json' => 'assets/gameplay/characters/pico/pico-basic-animations/Animation.json',
    'assets/shared/images/characters/pico/basic-animations/spritemap1.json' => 'assets/gameplay/characters/pico/pico-basic-animations/spritemap1.json',
    'assets/shared/images/characters/pico/basic-animations/spritemap1.png' => 'assets/gameplay/characters/pico/pico-basic-animations/spritemap1.png',
    'assets/shared/images/characters/pico/death/Animation.json' => 'assets/gameplay/characters/pico-playable/pico-death/Animation.json',
    'assets/shared/images/characters/pico/death/spritemap1.json' => 'assets/gameplay/characters/pico-playable/pico-death/spritemap1.json',
    'assets/shared/images/characters/pico/death/spritemap1.png' => 'assets/gameplay/characters/pico-playable/pico-death/spritemap1.png',
    'assets/shared/images/characters/pico/explosion-death/Animation.json' => 'assets/gameplay/characters/pico-playable/pico-death-explosion/Animation.json',
    'assets/shared/images/characters/pico/explosion-death/spritemap1.json' => 'assets/gameplay/characters/pico-playable/pico-death-explosion/spritemap1.json',
    'assets/shared/images/characters/pico/explosion-death/spritemap1.png' => 'assets/gameplay/characters/pico-playable/pico-death-explosion/spritemap1.png',
    'assets/shared/images/characters/pico/playable-animations/Animation.json' =>
    'assets/gameplay/characters/pico-playable/pico-playable-animations/Animation.json',
    'assets/shared/images/characters/pico/playable-animations/spritemap1.json' =>
    'assets/gameplay/characters/pico-playable/pico-playable-animations/spritemap1.json',
    'assets/shared/images/characters/pico/playable-animations/spritemap1.png' =>
    'assets/gameplay/characters/pico-playable/pico-playable-animations/spritemap1.png',
    'assets/shared/images/characters/picoBlazin/Animation.json' => 'assets/gameplay/characters/pico-blazin/pico-blazin/Animation.json',
    'assets/shared/images/characters/picoBlazin/spritemap1.json' => 'assets/gameplay/characters/pico-blazin/pico-blazin/spritemap1.json',
    'assets/shared/images/characters/picoBlazin/spritemap1.png' => 'assets/gameplay/characters/pico-blazin/pico-blazin/spritemap1.png',
    'assets/shared/images/characters/picoPixel/picoPixel.png' => 'assets/gameplay/characters/pico-pixel/pico-pixel.png',
    'assets/shared/images/characters/picoPixel/picoPixel.xml' => 'assets/gameplay/characters/pico-pixel/pico-pixel.xml',
    'assets/shared/images/characters/senpai.png' => 'assets/gameplay/characters/senpai/senpai.png',
    'assets/shared/images/characters/spirit.png' => 'assets/gameplay/characters/spirit/spirit.png',
    'assets/shared/images/characters/spirit.txt' => 'assets/gameplay/characters/spirit/spirit.txt',
    'assets/shared/images/characters/spooky_dark.png' => 'assets/gameplay/characters/spooky-dark/spooky-dark.png',
    'assets/shared/images/characters/spooky_dark.xml' => 'assets/gameplay/characters/spooky-dark/spooky-dark.xml',
    'assets/shared/images/characters/sserafim/chaewon/Animation.json' => 'assets/gameplay/characters/sserafim-chaewon/sserafim-chaewon/Animation.json',
    'assets/shared/images/characters/sserafim/chaewon/spritemap1.json' => 'assets/gameplay/characters/sserafim-chaewon/sserafim-chaewon/spritemap1.json',
    'assets/shared/images/characters/sserafim/chaewon/spritemap1.png' => 'assets/gameplay/characters/sserafim-chaewon/sserafim-chaewon/spritemap1.png',
    'assets/shared/images/characters/sserafim/eunchae/Animation.json' => 'assets/gameplay/characters/sserafim-eunchae/sserafim-eunchae/Animation.json',
    'assets/shared/images/characters/sserafim/eunchae/spritemap1.json' => 'assets/gameplay/characters/sserafim-eunchae/sserafim-eunchae/spritemap1.json',
    'assets/shared/images/characters/sserafim/eunchae/spritemap1.png' => 'assets/gameplay/characters/sserafim-eunchae/sserafim-eunchae/spritemap1.png',
    'assets/shared/images/characters/sserafim/kazuha/Animation.json' => 'assets/gameplay/characters/sserafim-kazuha/sserafim-kazuha/Animation.json',
    'assets/shared/images/characters/sserafim/kazuha/spritemap1.json' => 'assets/gameplay/characters/sserafim-kazuha/sserafim-kazuha/spritemap1.json',
    'assets/shared/images/characters/sserafim/kazuha/spritemap1.png' => 'assets/gameplay/characters/sserafim-kazuha/sserafim-kazuha/spritemap1.png',
    'assets/shared/images/characters/sserafim/sakura/Animation.json' => 'assets/gameplay/characters/sserafim-sakura/sserafim-sakura/Animation.json',
    'assets/shared/images/characters/sserafim/sakura/spritemap1.json' => 'assets/gameplay/characters/sserafim-sakura/sserafim-sakura/spritemap1.json',
    'assets/shared/images/characters/sserafim/sakura/spritemap1.png' => 'assets/gameplay/characters/sserafim-sakura/sserafim-sakura/spritemap1.png',
    'assets/shared/images/characters/sserafim/sserafim-gf/Animation.json' => 'assets/gameplay/characters/sserafim-gf/sserafim-gf/gf/Animation.json',
    'assets/shared/images/characters/sserafim/sserafim-gf/spritemap1.json' => 'assets/gameplay/characters/sserafim-gf/sserafim-gf/gf/spritemap1.json',
    'assets/shared/images/characters/sserafim/sserafim-gf/spritemap1.png' => 'assets/gameplay/characters/sserafim-gf/sserafim-gf/gf/spritemap1.png',
    'assets/shared/images/characters/sserafim/yunjin/Animation.json' => 'assets/gameplay/characters/sserafim-yunjin/sserafim-yunjin/Animation.json',
    'assets/shared/images/characters/sserafim/yunjin/spritemap1.json' => 'assets/gameplay/characters/sserafim-yunjin/sserafim-yunjin/spritemap1.json',
    'assets/shared/images/characters/sserafim/yunjin/spritemap1.png' => 'assets/gameplay/characters/sserafim-yunjin/sserafim-yunjin/spritemap1.png',
    'assets/shared/images/characters/tankman/basic/Animation.json' => 'assets/gameplay/characters/tankman/tankman-basic-animations/Animation.json',
    'assets/shared/images/characters/tankman/basic/spritemap1.json' => 'assets/gameplay/characters/tankman/tankman-basic-animations/spritemap1.json',
    'assets/shared/images/characters/tankman/basic/spritemap1.png' => 'assets/gameplay/characters/tankman/tankman-basic-animations/spritemap1.png',
    'assets/shared/images/characters/tankman/bloody/Animation.json' => 'assets/gameplay/characters/tankman-bloody/tankman-bloody/Animation.json',
    'assets/shared/images/characters/tankman/bloody/spritemap1.json' => 'assets/gameplay/characters/tankman-bloody/tankman-bloody/spritemap1.json',
    'assets/shared/images/characters/tankman/bloody/spritemap1.png' => 'assets/gameplay/characters/tankman-bloody/tankman-bloody/spritemap1.png',
    'assets/shared/images/characters/tankman/extra-animations/Animation.json' => 'assets/gameplay/characters/tankman/tankman-extra-animations/Animation.json',
    'assets/shared/images/characters/tankman/extra-animations/spritemap1.json' => 'assets/gameplay/characters/tankman/tankman-extra-animations/spritemap1.json',
    'assets/shared/images/characters/tankman/extra-animations/spritemap1.png' => 'assets/gameplay/characters/tankman/tankman-extra-animations/spritemap1.png',
    'assets/sserafim/images/back-stools.png' => 'gameplay/stages/sserafim/back-stools.png',
    'assets/sserafim/images/back-tables.png' => 'gameplay/stages/sserafim/back-tables.png',
    'assets/sserafim/images/bg.png' => 'gameplay/stages/sserafim/bg.png',
    'assets/sserafim/images/dust/dustBack.png' => 'gameplay/stages/sserafim/dust/dust-back.png',
    'assets/sserafim/images/dust/dustFront.png' => 'gameplay/stages/sserafim/dust/dust-front.png',
    'assets/sserafim/images/dust/dustMid.png' => 'gameplay/stages/sserafim/dust/dust-mid.png',
    'assets/sserafim/images/end/end1.png' => 'gameplay/stages/sserafim/end/end-1.png',
    'assets/sserafim/images/end/end2.png' => 'gameplay/stages/sserafim/end/end-2.png',
    'assets/sserafim/images/floor.png' => 'gameplay/stages/sserafim/floor.png',
    'assets/sserafim/images/front-stool.png' => 'gameplay/stages/sserafim/front-stool.png',
    'assets/sserafim/images/lights/back-light-color.png' => 'gameplay/stages/sserafim/lights/back-light-color.png',
    'assets/sserafim/images/lights/back-light-white.png' => 'gameplay/stages/sserafim/lights/back-light-white.png',
    'assets/sserafim/images/lights/truck-light1.png' => 'gameplay/stages/sserafim/lights/truck-light-1.png',
    'assets/sserafim/images/lights/truck-light2.png' => 'gameplay/stages/sserafim/lights/truck-light-2.png',
    'assets/sserafim/images/truck-door.png' => 'gameplay/stages/sserafim/truck-door.png',
    'assets/sserafim/images/truck-stuff.png' => 'gameplay/stages/sserafim/truck-stuff.png',
    'assets/sserafim/sounds/cutscene/end1.ogg' => 'gameplay/stages/sserafim/sounds/cutscene/end-1.ogg',
    'assets/sserafim/sounds/cutscene/end2.ogg' => 'gameplay/stages/sserafim/sounds/cutscene/end-2.ogg',
    'assets/sserafim/sounds/cutscene/startCutscene.ogg' => 'gameplay/stages/sserafim/sounds/cutscene/start-cutscene.ogg',
    'assets/sserafim/sounds/doorKick1.ogg' => 'gameplay/stages/sserafim/sounds/door-kick-1.ogg',
    'assets/sserafim/sounds/doorKick2.ogg' => 'gameplay/stages/sserafim/sounds/door-kick-2.ogg',
    'assets/sserafim/images/cutscene/burger-cutscene.png' => 'gameplay/stages/sserafim/cutscene/burger-cutscene.png',
    'assets/sserafim/images/cutscene/counter-stretch.png' => 'gameplay/stages/sserafim/cutscene/counter-stretch.png',
    'assets/sserafim/images/cutscene/floor-cutscene.png' => 'gameplay/stages/sserafim/cutscene/floor-cutscene.png',
    'assets/sserafim/images/cutscene/cutsceneMain/Animation.json' => 'gameplay/stages/sserafim/cutscene/cutscene-main/Animation.json',
    'assets/sserafim/images/cutscene/cutsceneMain/spritemap1.json' => 'gameplay/stages/sserafim/cutscene/cutscene-main/spritemap1.json',
    'assets/sserafim/images/cutscene/cutsceneMain/spritemap1.png' => 'gameplay/stages/sserafim/cutscene/cutscene-main/spritemap1.png',
    'assets/sserafim/images/cutscene/bfGetUp/Animation.json' => 'gameplay/stages/sserafim/cutscene/bf-get-up/Animation.json',
    'assets/sserafim/images/cutscene/bfGetUp/spritemap1.json' => 'gameplay/stages/sserafim/cutscene/bf-get-up/spritemap1.json',
    'assets/sserafim/images/cutscene/bfGetUp/spritemap1.png' => 'gameplay/stages/sserafim/cutscene/bf-get-up/spritemap1.png',
    'assets/sserafim/images/cutscene/gfGetUp/Animation.json' => 'gameplay/stages/sserafim/cutscene/gf-get-up/Animation.json',
    'assets/sserafim/images/cutscene/gfGetUp/spritemap1.json' => 'gameplay/stages/sserafim/cutscene/gf-get-up/spritemap1.json',
    'assets/sserafim/images/cutscene/gfGetUp/spritemap1.png' => 'gameplay/stages/sserafim/cutscene/gf-get-up/spritemap1.png',
    'assets/sserafim/images/sserafim-lipsync-yunjin/Animation.json' => 'gameplay/stages/sserafim/sserafim-lipsync-yunjin/Animation.json'
    'assets/sserafim/images/sserafim-lipsync-yunjin/spritemap1.json' => 'gameplay/stages/sserafim/sserafim-lipsync-yunjin/spritemap1.json'
    'assets/sserafim/images/sserafim-lipsync-yunjin/spritemap1.png' => 'gameplay/stages/sserafim/sserafim-lipsync-yunjin/spritemap1.png'
    'assets/sserafim/images/sserafim-lipsync/Animation.json' => 'gameplay/stages/sserafim/sserafim-lipsync/Animation.json'
    'assets/sserafim/images/sserafim-lipsync/spritemap1.json' => 'gameplay/stages/sserafim/sserafim-lipsync/spritemap1.json'
    'assets/sserafim/images/sserafim-lipsync/spritemap1.png' => 'gameplay/stages/sserafim/sserafim-lipsync/spritemap1.png'
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-1.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-1.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-2.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-2.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-3.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-3.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-4.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-4.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-5.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-5.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-6.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-6.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-7.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-7.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-8.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-8.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-9.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-9.ogg',
    'assets/week7/sounds/jeffGameover-pico/jeffGameover-10.ogg' => 'assets/gameplay/characters/pico-holding-nene/sounds/jeff-gameover-10.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-1.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-1.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-2.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-2.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-3.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-3.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-4.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-4.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-5.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-5.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-6.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-6.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-7.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-7.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-8.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-8.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-9.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-9.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-10.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-10.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-11.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-11.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-12.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-12.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-13.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-13.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-14.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-14.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-15.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-15.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-16.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-16.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-17.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-17.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-18.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-18.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-19.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-19.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-20.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-20.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-21.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-21.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-22.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-22.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-23.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-23.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-24.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-24.ogg',
    'assets/week7/sounds/jeffGameover/jeffGameover-25.ogg' => 'assets/gameplay/characters/bf-holding-gf/sounds/jeff-gameover-25.ogg',
    'assets/week1/images/erect/bg.png' => 'gameplay/stages/mainStageErect/bg.png',
    'assets/week1/images/erect/brightLightSmall.png' => 'gameplay/stages/mainStageErect/bright-light.png',
    'assets/week1/images/erect/crowd.png' => 'gameplay/stages/mainStageErect/crowd.png',
    'assets/week1/images/erect/crowd.xml' => 'gameplay/stages/mainStageErect/crowd.xml',
    'assets/week1/images/erect/lightAbove.png' => 'gameplay/stages/mainStageErect/light-above.png',
    'assets/week1/images/erect/lightgreen.png' => 'gameplay/stages/mainStageErect/light-green.png',
    'assets/week1/images/erect/lightred.png' => 'gameplay/stages/mainStageErect/light-red.png',
    'assets/week1/images/erect/lights.png' => 'gameplay/stages/mainStageErect/lights.png',
    'assets/week1/images/erect/orangeLight.png' => 'gameplay/stages/mainStageErect/light-orange.png',
    'assets/week1/images/erect/server.png' => 'gameplay/stages/mainStageErect/server.png',
    'assets/week1/hall-of-fame-tweet.png' => 'assets/gameplay/stages/mainStage/hall-of-fame-tweet.png',
    'assets/week1/lol.png' => 'assets/gameplay/stages/mainStage/lol.png',
    'assets/week1/opensauceforever.png' => 'assets/gameplay/stages/mainStage/open-sauce-forever.png',
    'assets/week1/screencapTierImage.png' => 'assets/gameplay/stages/mainStage/screencap-tier-image.png',
    'assets/week1/week-12-leak.jpg' => 'assets/gameplay/stages/mainStage/week-12-leak.jpg',
    'assets/week1/week54prototype.png' => 'assets/gameplay/stages/mainStage/week-54-prototype.png',
    'assets/week1/zzzzzzzz.png' => 'assets/gameplay/stages/mainStage/zzzzzzzz.png',
    'assets/week2/images/erect/bgDark.png'
    'assets/week2/images/erect/bgLight.png'
    'assets/week2/images/erect/bgtrees.png'
    'assets/week2/images/erect/bgtrees.xml'
    'assets/week2/images/erect/stairsDark.png'
    'assets/week2/images/erect/stairsLight.png'
    'assets/week2/sounds/thunder_1.ogg'
    'assets/week2/sounds/thunder_2.ogg'
    'assets/week3/images/philly/behindTrain.png'
    'assets/week3/images/philly/city.png'
    'assets/week3/images/philly/erect/behindTrain.png'
    'assets/week3/images/philly/erect/cigarette.png'
    'assets/week3/images/philly/erect/cigarette.xml'
    'assets/week3/images/philly/erect/city.png'
    'assets/week3/images/philly/erect/sky.png'
    'assets/week3/images/philly/erect/street.png'
    'assets/week3/images/philly/sky.png'
    'assets/week3/images/philly/street.png'
    'assets/week3/images/philly/train.png'
    'assets/week3/images/philly/win.png'
    'assets/week3/music/cutscene/cutscene-metadata.json'
    'assets/week3/music/cutscene/cutscene.ogg'
    'assets/week3/music/cutscene/cutscene2.ogg'
    'assets/week3/sounds/cutscene/picoCigarette.ogg'
    'assets/week3/sounds/cutscene/picoCigarette2.ogg'
    'assets/week3/sounds/cutscene/picoExplode.ogg'
    'assets/week3/sounds/cutscene/picoGasp.ogg'
    'assets/week3/sounds/cutscene/picoShoot.ogg'
    'assets/week3/sounds/cutscene/picoSpin.ogg'
    'assets/week3/sounds/train_passes.ogg'
    'assets/week4/images/limo/bgLimo.png'
    'assets/week4/images/limo/bgLimo.xml'
    'assets/week4/images/limo/erect/bgLimo.png'
    'assets/week4/images/limo/erect/bgLimo.xml'
    'assets/week4/images/limo/erect/limoDrive.png'
    'assets/week4/images/limo/erect/limoDrive.xml'
    'assets/week4/images/limo/erect/limoSunset.png'
    'assets/week4/images/limo/erect/mistBack.png'
    'assets/week4/images/limo/erect/mistFront.png'
    'assets/week4/images/limo/erect/mistMid.png'
    'assets/week4/images/limo/erect/shooting star.png'
    'assets/week4/images/limo/erect/shooting star.xml'
    'assets/week4/images/limo/fastCarLol.png'
    'assets/week4/images/limo/henchmen.png'
    'assets/week4/images/limo/henchmen.xml'
    'assets/week4/images/limo/limoDancer.png'
    'assets/week4/images/limo/limoDancer.xml'
    'assets/week4/images/limo/limoDrive.png'
    'assets/week4/images/limo/limoDrive.xml'
    'assets/week4/images/limo/limoOverlay.png'
    'assets/week4/images/limo/limoSunset.png'
    'assets/week4/sounds/carPass0.ogg'
    'assets/week4/sounds/carPass1.ogg'
    'assets/week5/images/christmas/bgEscalator.png'
    'assets/week5/images/christmas/bgWalls.png'
    'assets/week5/images/christmas/bottomBop.png'
    'assets/week5/images/christmas/bottomBop.xml'
    'assets/week5/images/christmas/christmasTree.png'
    'assets/week5/images/christmas/christmasWall.png'
    'assets/week5/images/christmas/erect/bgEscalator.png'
    'assets/week5/images/christmas/erect/bgWalls.png'
    'assets/week5/images/christmas/erect/christmasTree.png'
    'assets/week5/images/christmas/erect/snowflakes.png'
    'assets/week5/images/christmas/erect/snowflakes.xml'
    'assets/week5/images/christmas/erect/upperBop.png'
    'assets/week5/images/christmas/erect/upperBop.xml'
    'assets/week5/images/christmas/erect/white.png'
    'assets/week5/images/christmas/evilBG.png'
    'assets/week5/images/christmas/evilSnow.png'
    'assets/week5/images/christmas/evilTree.png'
    'assets/week5/images/christmas/fgSnow.png'
    'assets/week5/images/christmas/santa.png'
    'assets/week5/images/christmas/santa.xml'
    'assets/week5/images/christmas/upperBop.png'
    'assets/week5/images/christmas/upperBop.xml'
    'assets/week5/sounds/Lights_Shut_off.ogg'
    'assets/week5/sounds/Lights_Turn_On.ogg'
    'assets/week5/sounds/santa_emotion.ogg'
    'assets/week5/sounds/santa_shot_n_falls.ogg'
    'assets/week6/images/pixelNoteHoldCover.png'
    'assets/week6/images/pixelNoteHoldCover.xml'
    'assets/week6/images/pixelNoteSplash.png'
    'assets/week6/images/pixelNoteSplash.xml'
    'assets/week6/images/weeb/animatedEvilSchool.png'
    'assets/week6/images/weeb/animatedEvilSchool.xml'
    'assets/week6/images/weeb/bgFreaks.png'
    'assets/week6/images/weeb/bgFreaks.xml'
    'assets/week6/images/weeb/erect/evil/backSpike.png'
    'assets/week6/images/weeb/erect/evil/weebBackSpikes.png'
    'assets/week6/images/weeb/erect/evil/weebSchool.png'
    'assets/week6/images/weeb/erect/evil/weebStreet.png'
    'assets/week6/images/weeb/erect/masks/aBotPixelSpeaker_mask.png'
    'assets/week6/images/weeb/erect/masks/bfPixel_mask.png'
    'assets/week6/images/weeb/erect/masks/gfPixel_mask.png'
    'assets/week6/images/weeb/erect/masks/nenePixel_mask.png'
    'assets/week6/images/weeb/erect/masks/picoPixel_mask.png'
    'assets/week6/images/weeb/erect/masks/senpai_mask.png'
    'assets/week6/images/weeb/erect/petals.png'
    'assets/week6/images/weeb/erect/petals.xml'
    'assets/week6/images/weeb/erect/weebBackTrees.png'
    'assets/week6/images/weeb/erect/weebSchool.png'
    'assets/week6/images/weeb/erect/weebSky.png'
    'assets/week6/images/weeb/erect/weebStreet.png'
    'assets/week6/images/weeb/erect/weebTrees.png'
    'assets/week6/images/weeb/erect/weebTrees.txt'
    'assets/week6/images/weeb/erect/weebTreesBack.png'
    'assets/week6/images/weeb/evil/weebBackTrees.png'
    'assets/week6/images/weeb/evil/weebSchool.png'
    'assets/week6/images/weeb/evil/weebStreet.png'
    'assets/week6/images/weeb/evil/weebTrees.png'
    'assets/week6/images/weeb/petals.png'
    'assets/week6/images/weeb/petals.xml'
    'assets/week6/images/weeb/pixelUI/arrowEndsNew.png'
    'assets/week6/images/weeb/pixelUI/arrows-pixels.png'
    'assets/week6/images/weeb/pixelUI/arrows-pixels.xml'
    'assets/week6/images/weeb/pixelUI/dialogueBox-evil.png'
    'assets/week6/images/weeb/pixelUI/dialogueBox-evil.xml'
    'assets/week6/images/weeb/pixelUI/dialogueBox-evilNew.png'
    'assets/week6/images/weeb/pixelUI/dialogueBox-evilNew.xml'
    'assets/week6/images/weeb/pixelUI/dialogueBox-new.png'
    'assets/week6/images/weeb/pixelUI/dialogueBox-new.xml'
    'assets/week6/images/weeb/pixelUI/dialogueBox-pixel.png'
    'assets/week6/images/weeb/pixelUI/dialogueBox-pixel.xml'
    'assets/week6/images/weeb/pixelUI/dialogueBox-senpaiMad.png'
    'assets/week6/images/weeb/pixelUI/dialogueBox-senpaiMad.xml'
    'assets/week6/images/weeb/pixelUI/hand_textbox.png'
    'assets/week6/images/weeb/portrait-boyfriend.png'
    'assets/week6/images/weeb/portrait-boyfriend.xml'
    'assets/week6/images/weeb/portrait-nene-peeved.png'
    'assets/week6/images/weeb/portrait-nene-peeved.xml'
    'assets/week6/images/weeb/portrait-nene.png'
    'assets/week6/images/weeb/portrait-nene.xml'
    'assets/week6/images/weeb/portrait-pico-peeved.png'
    'assets/week6/images/weeb/portrait-pico-peeved.xml'
    'assets/week6/images/weeb/portrait-pico.png'
    'assets/week6/images/weeb/portrait-pico.xml'
    'assets/week6/images/weeb/portrait-senpai-angry.png'
    'assets/week6/images/weeb/portrait-senpai-angry.xml'
    'assets/week6/images/weeb/portrait-senpai-bwuh.png'
    'assets/week6/images/weeb/portrait-senpai-bwuh.xml'
    'assets/week6/images/weeb/portrait-senpai.png'
    'assets/week6/images/weeb/portrait-senpai.xml'
    'assets/week6/images/weeb/senpaiAngryPortrait.xml'
    'assets/week6/images/weeb/senpaiCrazy.png'
    'assets/week6/images/weeb/senpaiCrazy.xml'
    'assets/week6/images/weeb/spiritFaceForward.png'
    'assets/week6/images/weeb/spiritFaceForward.xml'
    'assets/week6/images/weeb/weebBackTrees.png'
    'assets/week6/images/weeb/weebSchool.png'
    'assets/week6/images/weeb/weebSky.png'
    'assets/week6/images/weeb/weebStreet.png'
    'assets/week6/images/weeb/weebTrees.png'
    'assets/week6/images/weeb/weebTrees.txt'
    'assets/week6/images/weeb/weebTreesBack.png'
    'assets/week6/music/Lunchbox.ogg'
    'assets/week6/music/LunchboxScary.ogg'
    'assets/week6/music/breakfast-pixel.ogg'
    'assets/week6/music/breakfast-pixel/breakfast-pixel.ogg'
    'assets/week6/sounds/Senpai_Dies.ogg'
    'assets/week6/sounds/pixelText.ogg'
    'assets/week6/sounds/textboxClick.ogg'
    'assets/week7/images/bricksGround.png'
    'assets/week7/images/cityruins2.png'
    'assets/week7/images/erect/bg.png'
    'assets/week7/images/erect/bricksGround.png'
    'assets/week7/images/erect/masks/gfTankmen_mask.png'
    'assets/week7/images/erect/masks/neneTankmen_mask.png'
    'assets/week7/images/erect/masks/tankmanCaptainBloody_mask.png'
    'assets/week7/images/mountains2.png'
    'assets/week7/images/smokeLeft.png'
    'assets/week7/images/smokeLeft.xml'
    'assets/week7/images/smokeRight.png'
    'assets/week7/images/smokeRight.xml'
    'assets/week7/images/tank0.png'
    'assets/week7/images/tank0.xml'
    'assets/week7/images/tank1.png'
    'assets/week7/images/tank1.xml'
    'assets/week7/images/tank2.png'
    'assets/week7/images/tank2.xml'
    'assets/week7/images/tank3.png'
    'assets/week7/images/tank3.xml'
    'assets/week7/images/tank4.png'
    'assets/week7/images/tank4.xml'
    'assets/week7/images/tank5.png'
    'assets/week7/images/tank5.xml'
    'assets/week7/images/tankBuildings.png'
    'assets/week7/images/tankClouds.png'
    'assets/week7/images/tankGround.png'
    'assets/week7/images/tankMountains.png'
    'assets/week7/images/tankRolling.png'
    'assets/week7/images/tankRolling.xml'
    'assets/week7/images/tankRuins.png'
    'assets/week7/images/tankSky.png'
    'assets/week7/images/tankWatchtower.png'
    'assets/week7/images/tankWatchtower.xml'
    'assets/week7/images/tankmanKilled1.png'
    'assets/week7/images/tankmanKilled1.xml'
    'assets/week7/music/DISTORTO.ogg'
    'assets/week7/sounds/bfBeep.ogg'
    'assets/week7/sounds/erect/endCutscene.ogg'
    'assets/week7/sounds/gameplay/gameover/fnf_loss_sfx-pico-and-nene.ogg'
    'assets/week7/sounds/killYou.ogg'
    'assets/week7/sounds/song3censor.ogg'
    'assets/week7/sounds/stressCutscene.ogg'
    'assets/week7/sounds/tankSong2.ogg'
    'assets/week7/sounds/wellWellWell.ogg'
    'assets/weekend1/images/CanImpactParticle.png'
    'assets/weekend1/images/CanImpactParticle.xml'
    'assets/weekend1/images/PicoBullet.png'
    'assets/weekend1/images/PicoBullet.xml'
    'assets/weekend1/images/SpraycanPile.png'
    'assets/weekend1/images/SpraypaintExplosion.png'
    'assets/weekend1/images/SpraypaintExplosion.xml'
    'assets/weekend1/images/bgConcept.png'
    'assets/weekend1/images/fightDarnell.png'
    'assets/weekend1/images/fightDarnell.xml'
    'assets/weekend1/images/fightPico.png'
    'assets/weekend1/images/fightPico.xml'
    'assets/weekend1/images/phillyBlazin/lightning.png'
    'assets/weekend1/images/phillyBlazin/lightning.xml'
    'assets/weekend1/images/phillyBlazin/skyBlur.png'
    'assets/weekend1/images/phillyBlazin/streetBlur.png'
    'assets/weekend1/images/phillyStreets/erect/greyGradient.png'
    'assets/weekend1/images/phillyStreets/erect/mistBack.png'
    'assets/weekend1/images/phillyStreets/erect/mistFront.png'
    'assets/weekend1/images/phillyStreets/erect/mistMid.png'
    'assets/weekend1/images/phillyStreets/erect/paper.png'
    'assets/weekend1/images/phillyStreets/erect/paper.xml'
    'assets/weekend1/images/phillyStreets/erect/phillyCars.png'
    'assets/weekend1/images/phillyStreets/erect/phillyCars.xml'
    'assets/weekend1/images/phillyStreets/erect/phillyConstruction.png'
    'assets/weekend1/images/phillyStreets/erect/phillyForeground.png'
    'assets/weekend1/images/phillyStreets/erect/phillyForegroundCity.png'
    'assets/weekend1/images/phillyStreets/erect/phillyHighway.png'
    'assets/weekend1/images/phillyStreets/erect/phillyHighwayLights.png'
    'assets/weekend1/images/phillyStreets/erect/phillySkybox.png'
    'assets/weekend1/images/phillyStreets/erect/phillySkyline.png'
    'assets/weekend1/images/phillyStreets/erect/phillyTraffic.png'
    'assets/weekend1/images/phillyStreets/erect/phillyTraffic.xml'
    'assets/weekend1/images/phillyStreets/erect/phillyTraffic_lightmap.png'
    'assets/weekend1/images/phillyStreets/phillyCars.png'
    'assets/weekend1/images/phillyStreets/phillyCars.xml'
    'assets/weekend1/images/phillyStreets/phillyConstruction.png'
    'assets/weekend1/images/phillyStreets/phillyForeground.png'
    'assets/weekend1/images/phillyStreets/phillyForegroundCity.png'
    'assets/weekend1/images/phillyStreets/phillyHighway.png'
    'assets/weekend1/images/phillyStreets/phillyHighwayLights.png'
    'assets/weekend1/images/phillyStreets/phillyHighwayLights_lightmap.png'
    'assets/weekend1/images/phillyStreets/phillySkybox.png'
    'assets/weekend1/images/phillyStreets/phillySkyline.png'
    'assets/weekend1/images/phillyStreets/phillySmog.png'
    'assets/weekend1/images/phillyStreets/phillyTraffic.png'
    'assets/weekend1/images/phillyStreets/phillyTraffic.xml'
    'assets/weekend1/images/phillyStreets/phillyTraffic_lightmap.png'
    'assets/weekend1/images/phillyStreets/puddle.png'
    'assets/weekend1/images/picoBlazinDeathConfirm.png'
    'assets/weekend1/images/picoBlazinDeathConfirm.xml'
    'assets/weekend1/images/spraypaintExplosionEZ.png'
    'assets/weekend1/images/spraypaintExplosionEZ.xml'
    'assets/weekend1/images/wked1_cutscene_1_can.png'
    'assets/weekend1/images/wked1_cutscene_1_can.xml'
    'assets/weekend1/music/darnellCanCutscene/darnellCanCutscene-metadata.json'
    'assets/weekend1/music/darnellCanCutscene/darnellCanCutscene.ogg'
    'assets/weekend1/music/gameplay/gameover/gameOverStart-pico-explode.ogg'
    'assets/weekend1/sounds/Darnell_Lighter.ogg'
    'assets/weekend1/sounds/Gun_Prep.ogg'
    'assets/weekend1/sounds/Kick_Can_FORWARD.ogg'
    'assets/weekend1/sounds/Kick_Can_UP.ogg'
    'assets/weekend1/sounds/Lightning1.ogg'
    'assets/weekend1/sounds/Lightning2.ogg'
    'assets/weekend1/sounds/Lightning3.ogg'
    'assets/weekend1/sounds/Pico_Bonk.ogg'
    'assets/weekend1/sounds/Shoot_1.ogg'
    'assets/weekend1/sounds/carAmbience.ogg'
    'assets/weekend1/sounds/cutscene/darnell_laugh.ogg'
    'assets/weekend1/sounds/cutscene/nene_laugh.ogg'
    'assets/weekend1/sounds/fuse_burning.ogg'
    'assets/weekend1/sounds/gameplay/gameover/fnf_loss_sfx-pico-explode.ogg'
    'assets/weekend1/sounds/gameplay/gameover/fnf_loss_sfx-pico-gutpunch.ogg'
    'assets/weekend1/sounds/rainAmbience.ogg'
    'assets/weekend1/sounds/shot1.ogg'
    'assets/weekend1/sounds/shot2.ogg'
    'assets/weekend1/sounds/shot3.ogg'
    'assets/weekend1/sounds/shot4.ogg'
    'assets/weekend1/sounds/singed_loop.ogg' => '',
    //
    // Pre-Great Sorting asset paths, without library.
    //
    'assets/images/menuBG.png' => 'assets/ui/main-menu/menu-bg.png',
    'assets/images/menuBGMagenta.png' => 'assets/ui/main-menu/menu-bg-magenta.png',
    'assets/images/menuDesat.png' => 'assets/ui/main-menu/menu-desat.png',
    'assets/images/freeplay/albumRoll/expansion1-text.png' => 'assets/ui/freeplay/albums/expansion1-text.png',
    'assets/images/freeplay/albumRoll/expansion1-text.xml' => 'assets/ui/freeplay/albums/expansion1-text.xml',
    'assets/images/freeplay/albumRoll/expansion1.png' => 'assets/ui/freeplay/albums/expansion1.png',
    'assets/images/freeplay/albumRoll/expansion2-text.png' => 'assets/ui/freeplay/albums/expansion2-text.png',
    'assets/images/freeplay/albumRoll/expansion2-text.xml' => 'assets/ui/freeplay/albums/expansion2-text.xml',
    'assets/images/freeplay/albumRoll/expansion2.png' => 'assets/ui/freeplay/albums/expansion2.png',
    'assets/images/freeplay/albumRoll/spaghetti-text.png' => 'assets/ui/freeplay/albums/spaghetti-text.png',
    'assets/images/freeplay/albumRoll/spaghetti-text.xml' => 'assets/ui/freeplay/albums/spaghetti-text.xml',
    'assets/images/freeplay/albumRoll/spaghetti.png' => 'assets/ui/freeplay/albums/spaghetti.png',
    'assets/images/freeplay/albumRoll/volume1-text.png' => 'assets/ui/freeplay/albums/volume1-text.png',
    'assets/images/freeplay/albumRoll/volume1-text.xml' => 'assets/ui/freeplay/albums/volume1-text.xml',
    'assets/images/freeplay/albumRoll/volume1.png' => 'assets/ui/freeplay/albums/volume1.png',
    'assets/images/freeplay/albumRoll/volume2-text.png' => 'assets/ui/freeplay/albums/volume2-text.png',
    'assets/images/freeplay/albumRoll/volume2-text.xml' => 'assets/ui/freeplay/albums/volume2-text.xml',
    'assets/images/freeplay/albumRoll/volume2.png' => 'assets/ui/freeplay/albums/volume2.png',
    'assets/images/freeplay/albumRoll/volume3-text.png' => 'assets/ui/freeplay/albums/volume3-text.png',
    'assets/images/freeplay/albumRoll/volume3-text.xml' => 'assets/ui/freeplay/albums/volume3-text.xml',
    'assets/images/freeplay/albumRoll/volume3.png' => 'assets/ui/freeplay/albums/volume3.png',
    'assets/images/freeplay/albumRoll/volume4-text.png' => 'assets/ui/freeplay/albums/volume4-text.png',
    'assets/images/freeplay/albumRoll/volume4-text.xml' => 'assets/ui/freeplay/albums/volume4-text.xml',
    'assets/images/freeplay/albumRoll/volume4.png' => 'assets/ui/freeplay/albums/volume4.png',
    'assets/images/funkay.png' => 'assets/ui/loading/funkay.png',
    'assets/images/gfDanceTitle.png' => 'assets/ui/title/gf-dance-title.png',
    'assets/images/gfDanceTitle.xml' => 'assets/ui/title/gf-dance-title.xml',
    'assets/images/logoBumpin.png' => 'assets/ui/title/logo-bumpin.png',
    'assets/images/logoBumpin.xml' => 'assets/ui/title/logo-bumpin.xml',
    'assets/images/ui/popup/funkin/bad.png' => 'assets/gameplay/notestyles/funkin/popup/bad.png',
    'assets/images/ui/popup/funkin/good.png' => 'assets/gameplay/notestyles/funkin/popup/good.png',
    'assets/images/ui/popup/funkin/num0.png' => 'assets/gameplay/notestyles/funkin/popup/digit-0.png',
    'assets/images/ui/popup/funkin/num1.png' => 'assets/gameplay/notestyles/funkin/popup/digit-1.png',
    'assets/images/ui/popup/funkin/num2.png' => 'assets/gameplay/notestyles/funkin/popup/digit-2.png',
    'assets/images/ui/popup/funkin/num3.png' => 'assets/gameplay/notestyles/funkin/popup/digit-3.png',
    'assets/images/ui/popup/funkin/num4.png' => 'assets/gameplay/notestyles/funkin/popup/digit-4.png',
    'assets/images/ui/popup/funkin/num5.png' => 'assets/gameplay/notestyles/funkin/popup/digit-5.png',
    'assets/images/ui/popup/funkin/num6.png' => 'assets/gameplay/notestyles/funkin/popup/digit-6.png',
    'assets/images/ui/popup/funkin/num7.png' => 'assets/gameplay/notestyles/funkin/popup/digit-7.png',
    'assets/images/ui/popup/funkin/num8.png' => 'assets/gameplay/notestyles/funkin/popup/digit-8.png',
    'assets/images/ui/popup/funkin/num9.png' => 'assets/gameplay/notestyles/funkin/popup/digit-9.png',
    'assets/images/ui/popup/funkin/shit.png' => 'assets/gameplay/notestyles/funkin/popup/shit.png',
    'assets/images/ui/popup/funkin/sick.png' => 'assets/gameplay/notestyles/funkin/popup/sick.png',
    'assets/images/ui/popup/pixel/bad.png' => 'assets/gameplay/notestyles/pixel/popup/bad.png',
    'assets/images/ui/popup/pixel/good.png' => 'assets/gameplay/notestyles/pixel/popup/good.png',
    'assets/images/ui/popup/pixel/num0.png' => 'assets/gameplay/notestyles/pixel/popup/digit-0.png',
    'assets/images/ui/popup/pixel/num1.png' => 'assets/gameplay/notestyles/pixel/popup/digit-1.png',
    'assets/images/ui/popup/pixel/num2.png' => 'assets/gameplay/notestyles/pixel/popup/digit-2.png',
    'assets/images/ui/popup/pixel/num3.png' => 'assets/gameplay/notestyles/pixel/popup/digit-3.png',
    'assets/images/ui/popup/pixel/num4.png' => 'assets/gameplay/notestyles/pixel/popup/digit-4.png',
    'assets/images/ui/popup/pixel/num5.png' => 'assets/gameplay/notestyles/pixel/popup/digit-5.png',
    'assets/images/ui/popup/pixel/num6.png' => 'assets/gameplay/notestyles/pixel/popup/digit-6.png',
    'assets/images/ui/popup/pixel/num7.png' => 'assets/gameplay/notestyles/pixel/popup/digit-7.png',
    'assets/images/ui/popup/pixel/num8.png' => 'assets/gameplay/notestyles/pixel/popup/digit-8.png',
    'assets/images/ui/popup/pixel/num9.png' => 'assets/gameplay/notestyles/pixel/popup/digit-9.png',
    'assets/images/ui/popup/pixel/shit.png' => 'assets/gameplay/notestyles/pixel/popup/shit.png',
    'assets/images/ui/popup/pixel/sick.png' => 'assets/gameplay/notestyles/pixel/popup/sick.png',
    'assets/data/introText.txt' => 'assets/ui/title/intro-text.txt',
    'assets/fonts/vcr-bmp.fnt' => 'assets/ui/fonts/vcr-bmp.fnt',
    'assets/fonts/vcr-bmp.png' => 'assets/ui/fonts/vcr-bmp.png',
    'assets/fonts/5by7.ttf' => 'assets/ui/fonts/5by7.ttf',
    'assets/fonts/5by7_b.ttf' => 'assets/ui/fonts/5by7-bold.ttf',
    'assets/fonts/Consolas.ttf' => 'assets/ui/fonts/Inconsolata Regular.ttf',
    'assets/fonts/DS-DIGI.TTF' => 'assets/ui/fonts/LCDMono2 Normal.ttf',
    'assets/fonts/DS-DIGIB.TTF' => 'assets/ui/fonts/LCDMono2 Bold.ttf',
    'assets/fonts/DS-DIGII.TTF' => 'assets/ui/fonts/LCDMono2 Light.ttf',
    'assets/fonts/DS-DIGIT.TTF' => 'assets/ui/fonts/LCDMono2 Ultra.ttf',
    'assets/fonts/vcr-bold.ttf' => 'assets/ui/fonts/VCR OSD Mono Bold.ttf',
    'assets/fonts/vcr-bolditalic.ttf' => 'assets/ui/fonts/VCR OSD Mono Bold Italic.ttf',
    'assets/fonts/vcr-italic.ttf' => 'assets/ui/fonts/VCR OSD Mono Italic.ttf',
    'assets/fonts/vcr.ttf' => 'assets/ui/fonts/VCR OSD Mono.ttf',
    'assets/shaders/adjustColor.frag' => 'assets/ui/shaders/adjust-color.frag',
    'assets/shaders/building.frag' => 'assets/ui/shaders/building.frag',
    'assets/shaders/customBlend.frag' => 'assets/ui/shaders/custom-blend.frag',
    'assets/shaders/gaussianBlur.frag' => 'assets/ui/shaders/gaussian-blur.frag',
    'assets/shaders/grayscale.frag' => 'assets/ui/shaders/grayscale.frag',
    'assets/shaders/hsv.frag' => 'assets/ui/shaders/hsv.frag',
    'assets/shaders/InverseDots.frag' => 'assets/ui/shaders/inverse-dots.frag',
    'assets/shaders/mosaic.frag' => 'assets/ui/shaders/mosaic.frag',
    'assets/shaders/pixel.frag' => 'assets/ui/shaders/pixel.frag',
    'assets/shaders/puddle.frag' => 'assets/ui/shaders/puddle.frag',
    'assets/shaders/rain.frag' => 'assets/ui/shaders/rain.frag',
    'assets/shaders/wiggle.frag' => 'assets/ui/shaders/wiggle.frag',
    'assets/sounds/cartoons/191815.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/191815.ogg',
    'assets/sounds/cartoons/376197.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/376197.ogg',
    'assets/sounds/cartoons/402450.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/402450.ogg',
    'assets/sounds/cartoons/420994.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/420994.ogg',
    'assets/sounds/cartoons/436786.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/436786.ogg',
    'assets/sounds/cartoons/445123.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/445123.ogg',
    'assets/sounds/cartoons/455919.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/455919.ogg',
    'assets/sounds/cartoons/460535.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/460535.ogg',
    'assets/sounds/cartoons/527474.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/527474.ogg',
    'assets/sounds/cartoons/530334.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/530334.ogg',
    'assets/sounds/cartoons/544919.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/544919.ogg',
    'assets/sounds/cartoons/604642.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/604642.ogg',
    'assets/sounds/cartoons/614710.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/614710.ogg',
    'assets/sounds/cartoons/665671.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/665671.ogg',
    'assets/sounds/cartoons/673103.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/673103.ogg',
    'assets/sounds/cartoons/674980.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/674980.ogg',
    'assets/sounds/cartoons/681102.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/681102.ogg',
    'assets/sounds/cartoons/694697.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/694697.ogg',
    'assets/sounds/cartoons/717986.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/717986.ogg',
    'assets/sounds/cartoons/719366.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/719366.ogg',
    'assets/sounds/cartoons/758136.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/758136.ogg',
    'assets/sounds/cartoons/760595.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/760595.ogg',
    'assets/sounds/cartoons/776249.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/776249.ogg',
    'assets/sounds/cartoons/790104.ogg' => 'assets/ui/freeplay/dj/bf/cartoons/790104.ogg',
    'assets/images/cursor/cursor-cell.png' => 'assets/ui/cursor/desktop/cursor-cell.png',
    'assets/images/cursor/cursor-cross.png' => 'assets/ui/cursor/desktop/cursor-cross.png',
    'assets/images/cursor/cursor-crosshair.png' => 'assets/ui/cursor/desktop/cursor-crosshair.png',
    'assets/images/cursor/cursor-default.png' => 'assets/ui/cursor/desktop/cursor-default.png',
    'assets/images/cursor/cursor-eraser.png' => 'assets/ui/cursor/desktop/cursor-eraser.png',
    'assets/images/cursor/cursor-grabbing.png' => 'assets/ui/cursor/desktop/cursor-grabbing.png',
    'assets/images/cursor/cursor-hourglass.png' => 'assets/ui/cursor/desktop/cursor-hourglass.png',
    'assets/images/cursor/cursor-pointer.png' => 'assets/ui/cursor/desktop/cursor-pointer.png',
    'assets/images/cursor/cursor-scroll.png' => 'assets/ui/cursor/desktop/cursor-scroll.png',
    'assets/images/cursor/cursor-text-vertical.png' => 'assets/ui/cursor/desktop/cursor-text-vertical',
    'assets/images/cursor/cursor-text.png' => 'assets/ui/cursor/desktop/cursor-text.png',
    'assets/images/cursor/cursor-zoom-in.png' => 'assets/ui/cursor/desktop/cursor-zoom-in',
    'assets/images/cursor/cursor-zoom-out.png' => 'assets/ui/cursor/desktop/cursor-zoom-out',
    'assets/images/cursor/kevin.png' => 'assets/images/cursor/mobile/kevin.png',
    'assets/images/cursor/michael.png' => 'assets/images/cursor/mobile/michael.png',
    'assets/images/freeplay/freeplayeasy.png' => 'assets/ui/freeplay/difficulty/easy.png',
    'assets/images/freeplay/freeplayerect.png' => 'assets/ui/freeplay/difficulty/erect.png',
    'assets/images/freeplay/freeplayhard.png' => 'assets/ui/freeplay/difficulty/hard.png',
    'assets/images/freeplay/freeplaynightmare.png' => 'assets/ui/freeplay/difficulty/nightmare.png',
    'assets/images/freeplay/freeplaynightmare.xml' => 'assets/ui/freeplay/difficulty/nightmare.xml',
    'assets/images/freeplay/freeplaynormal.png' => 'assets/ui/freeplay/difficulty/normal.png',
    'assets/images/freeplay/freeplay-boyfriend/Animation.json' => 'assets/ui/freeplay/dj/bf/freeplay-boyfriend/Animation.json',
    'assets/images/freeplay/freeplay-boyfriend/spritemap1.json' => 'assets/ui/freeplay/dj/bf/freeplay-boyfriend/spritemap1.json',
    'assets/images/freeplay/freeplay-boyfriend/spritemap1.png' => 'assets/ui/freeplay/dj/bf/freeplay-boyfriend/spritemap1.png',
    'assets/images/freeplay/freeplay-pico/Animation.json' => 'assets/ui/freeplay/dj/pico/freeplay-pico/Animation.json',
    'assets/images/freeplay/freeplay-pico/spritemap1.json' => 'assets/ui/freeplay/dj/pico/freeplay-pico/spritemap1.json',
    'assets/images/freeplay/freeplay-pico/spritemap1.png' => 'assets/ui/freeplay/dj/pico/freeplay-pico/spritemap1.png',
    'assets/images/charSelect/boyfriendNametag.png' => 'assets/ui/character-select/characters/nametag-bf.png',
    'assets/images/storymenu/difficulties/easy.png' => 'assets/ui/story-mode/difficulties/easy.png',
    'assets/images/storymenu/difficulties/erect.png' => 'assets/ui/story-mode/difficulties/erect.png',
    'assets/images/storymenu/difficulties/hard.png' => 'assets/ui/story-mode/difficulties/hard.png',
    'assets/images/storymenu/difficulties/nightmare.png' => 'assets/ui/story-mode/difficulties/nightmare.png',
    'assets/images/storymenu/difficulties/nightmare.xml' => 'assets/ui/story-mode/difficulties/nightmare.xml',
    'assets/images/storymenu/difficulties/normal.png' => 'assets/ui/story-mode/difficulties/normal.png',
    'assets/images/storymenu/titles/sserafim.png' => 'assets/ui/story-mode/levels/sserafim.png',
    'assets/images/storymenu/titles/tutorial.png' => 'assets/ui/story-mode/levels/tutorial.png',
    'assets/images/storymenu/titles/week1.png' => 'assets/ui/story-mode/levels/week1.png',
    'assets/images/storymenu/titles/week2.png' => 'assets/ui/story-mode/levels/week2.png',
    'assets/images/storymenu/titles/week3.png' => 'assets/ui/story-mode/levels/week3.png',
    'assets/images/storymenu/titles/week4.png' => 'assets/ui/story-mode/levels/week4.png',
    'assets/images/storymenu/titles/week5.png' => 'assets/ui/story-mode/levels/week5.png',
    'assets/images/storymenu/titles/week6.png' => 'assets/ui/story-mode/levels/week6.png',
    'assets/images/storymenu/titles/week7.png' => 'assets/ui/story-mode/levels/week7.png',
    'assets/images/storymenu/titles/weekend1.png' => 'assets/ui/story-mode/levels/weekend1.png',
    'assets/images/storymenu/ui/arrows.png' => 'assets/ui/story-mode/arrows.png',
    'assets/images/storymenu/ui/arrows.xml' => 'assets/ui/story-mode/arrows.xml',
    'assets/images/storymenu/ui/lock.png' => 'assets/ui/story-mode/lock.png',
    'assets/images/storymenu/props/bf.png' => 'assets/ui/story-mode/props/bf.png',
    'assets/images/storymenu/props/bf.xml' => 'assets/ui/story-mode/props/bf.xml',
    'assets/images/storymenu/props/dad.png' => 'assets/ui/story-mode/props/dad.png',
    'assets/images/storymenu/props/dad.xml' => 'assets/ui/story-mode/props/dad.xml',
    'assets/images/storymenu/props/darnell.png' => 'assets/ui/story-mode/props/darnell.png',
    'assets/images/storymenu/props/darnell.xml' => 'assets/ui/story-mode/props/darnell.xml',
    'assets/images/storymenu/props/gf.png' => 'assets/ui/story-mode/props/gf.png',
    'assets/images/storymenu/props/gf.xml' => 'assets/ui/story-mode/props/gf.xml',
    'assets/images/storymenu/props/mom.png' => 'assets/ui/story-mode/props/mom.png',
    'assets/images/storymenu/props/mom.xml' => 'assets/ui/story-mode/props/mom.xml',
    'assets/images/storymenu/props/nene.png' => 'assets/ui/story-mode/props/nene.png',
    'assets/images/storymenu/props/nene.xml' => 'assets/ui/story-mode/props/nene.xml',
    'assets/images/storymenu/props/parents-xmas.png' => 'assets/ui/story-mode/props/parents-xmas.png',
    'assets/images/storymenu/props/parents-xmas.xml' => 'assets/ui/story-mode/props/parents-xmas.xml',
    'assets/images/storymenu/props/pico-player.png' => 'assets/ui/story-mode/props/pico-player.png',
    'assets/images/storymenu/props/pico-player.xml' => 'assets/ui/story-mode/props/pico-player.xml',
    'assets/images/storymenu/props/pico.png' => 'assets/ui/story-mode/props/pico.png',
    'assets/images/storymenu/props/pico.xml' => 'assets/ui/story-mode/props/pico.xml',
    'assets/images/storymenu/props/senpai.png' => 'assets/ui/story-mode/props/senpai.png',
    'assets/images/storymenu/props/senpai.xml' => 'assets/ui/story-mode/props/senpai.xml',
    'assets/images/storymenu/props/spaghetti.png' => 'assets/ui/story-mode/props/spaghetti.png',
    'assets/images/storymenu/props/spaghetti.xml' => 'assets/ui/story-mode/props/spaghetti.xml',
    'assets/images/storymenu/props/spooky.png' => 'assets/ui/story-mode/props/spooky.png',
    'assets/images/storymenu/props/spooky.xml' => 'assets/ui/story-mode/props/spooky.xml',
    'assets/images/storymenu/props/tankman.png' => 'assets/ui/story-mode/props/tankman.png',
    'assets/images/storymenu/props/tankman.xml' => 'assets/ui/story-mode/props/tankman.xml',
    'assets/images/characters/bf/Animation.json' => 'assets/gameplay/characters/bf/boyfriend/Animation.json',
    'assets/images/characters/bf/spritemap1.json' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.json',
    'assets/images/characters/bf/spritemap1.png' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.png',
    'assets/images/characters/bf-death/Animation.json' => 'assets/gameplay/characters/bf/bf-dead/Animation.json',
    'assets/images/characters/bf-death/spritemap1.json' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.json',
    'assets/images/characters/bf-death/spritemap1.png' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.png',
    'assets/images/characters/bfFakeOut/Animation.json' => 'assets/gameplay/characters/bf/bf-fakeout/Animation.json',
    'assets/images/characters/bfFakeOut/spritemap1.json' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.json',
    'assets/images/characters/bfFakeOut/spritemap1.png' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.png',
    //
    // The output of a call to `funkin.Paths`, which no longer uses prefixes.
    //
    'assets/chartEditorLoop/chartEditorLoop.ogg' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression.ogg',
    'assets/chartEditorLoop/chartEditorLoop-metadata.json' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression-metadata.json',
    'assets/freakyMenu/freakyMenu.ogg' => 'assets/ui/main-menu/freaky-menu/freaky-menu.ogg',
    'assets/freakyMenu/freakyMenu-metadata.json' => 'assets/ui/main-menu/freaky-menu/freaky-menu-metadata.json',
    'assets/freeplayRandom/freeplayRandom.ogg' => 'assets/ui/freeplay/freeplay-random/freeplay-random.ogg',
    'assets/freeplayRandom/freeplayRandom-metadata.json' => 'assets/ui/freeplay/freeplay-random/freeplay-random-metadata.json',
    'assets/girlfriendsRingtone/girlfriendsRingtone.ogg' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone.ogg',
    'assets/girlfriendsRingtone/girlfriendsRingtone-metadata.json' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone-metadata.json',
    'assets/offsetsLoop/drumsLoop.ogg' => 'assets/ui/input-offsets/drums-loop/drums-loop.ogg',
    'assets/offsetsLoop/offsetsLoop.ogg' => 'assets/ui/input-offsets/offsets-loop/offsets-loop.ogg',
    'assets/stayFunky/stayFunky.ogg' => 'assets/ui/character-select/stay-funky/stay-funky.ogg',
    'assets/stayFunky/stayFunky-intro.ogg' => 'assets/ui/character-select/stay-funky/stay-funky-intro.ogg',
    'assets/stayFunky/stayFunky-metadata.json' => 'assets/ui/character-select/stay-funky/stay-funky-metadata.json',
    'assets/storymenu/props/bf.png' => 'assets/ui/story-mode/props/bf.png',
    'assets/storymenu/props/bf.xml' => 'assets/ui/story-mode/props/bf.xml',
    'assets/storymenu/props/dad.png' => 'assets/ui/story-mode/props/dad.png',
    'assets/storymenu/props/dad.xml' => 'assets/ui/story-mode/props/dad.xml',
    'assets/storymenu/props/darnell.png' => 'assets/ui/story-mode/props/darnell.png',
    'assets/storymenu/props/darnell.xml' => 'assets/ui/story-mode/props/darnell.xml',
    'assets/storymenu/props/gf.png' => 'assets/ui/story-mode/props/gf.png',
    'assets/storymenu/props/gf.xml' => 'assets/ui/story-mode/props/gf.xml',
    'assets/storymenu/props/mom.png' => 'assets/ui/story-mode/props/mom.png',
    'assets/storymenu/props/mom.xml' => 'assets/ui/story-mode/props/mom.xml',
    'assets/storymenu/props/nene.png' => 'assets/ui/story-mode/props/nene.png',
    'assets/storymenu/props/nene.xml' => 'assets/ui/story-mode/props/nene.xml',
    'assets/storymenu/props/parents-xmas.png' => 'assets/ui/story-mode/props/parents-xmas.png',
    'assets/storymenu/props/parents-xmas.xml' => 'assets/ui/story-mode/props/parents-xmas.xml',
    'assets/storymenu/props/pico-player.png' => 'assets/ui/story-mode/props/pico-player.png',
    'assets/storymenu/props/pico-player.xml' => 'assets/ui/story-mode/props/pico-player.xml',
    'assets/storymenu/props/pico.png' => 'assets/ui/story-mode/props/pico.png',
    'assets/storymenu/props/pico.xml' => 'assets/ui/story-mode/props/pico.xml',
    'assets/storymenu/props/senpai.png' => 'assets/ui/story-mode/props/senpai.png',
    'assets/storymenu/props/senpai.xml' => 'assets/ui/story-mode/props/senpai.xml',
    'assets/storymenu/props/spaghetti.png' => 'assets/ui/story-mode/props/spaghetti.png',
    'assets/storymenu/props/spaghetti.xml' => 'assets/ui/story-mode/props/spaghetti.xml',
    'assets/storymenu/props/spooky.png' => 'assets/ui/story-mode/props/spooky.png',
    'assets/storymenu/props/spooky.xml' => 'assets/ui/story-mode/props/spooky.xml',
    'assets/storymenu/props/tankman.png' => 'assets/ui/story-mode/props/tankman.png',
    'assets/storymenu/props/tankman.xml' => 'assets/ui/story-mode/props/tankman.xml',
    'assets/shared/characters/bf/Animation.json' => 'assets/gameplay/characters/bf/boyfriend/Animation.json',
    'assets/shared/characters/bf/spritemap1.json' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.json',
    'assets/shared/characters/bf/spritemap1.png' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.png',
    'assets/shared/characters/bf-death/Animation.json' => 'assets/gameplay/characters/bf/bf-dead/Animation.json',
    'assets/shared/characters/bf-death/spritemap1.json' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.json',
    'assets/shared/characters/bf-death/spritemap1.png' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.png',
    'assets/shared/characters/bfFakeOut/Animation.json' => 'assets/gameplay/characters/bf/bf-fakeout/Animation.json',
    'assets/shared/characters/bfFakeOut/spritemap1.json' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.json',
    'assets/shared/characters/bfFakeOut/spritemap1.png' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.png',
  ];

  /**
   * @param id The base path of the asset, including the extension.
   * @param type The type of asset.
   * @param library The asset library to use
   * @param verbose Whether to print warnings/errors if the path doesn't exist.
   * @return String
   */
  public static function getPath(id:String, type:OpenFLAssetType, library:String = 'default', verbose:Bool = true):String
  {
    // Don't use library:path since new Funkin' doesn't use asset libraries.
    var filePath:String = (library == 'default') ? 'assets/$id' : 'assets/$library/$id';

    // If the path just exists, return it. This is the most common case.
    if (funkin.assets.Assets.exists(filePath, type))
    {
      return filePath;
    }

    // If the path doesn't exist, it might be a mod backwards compatibility issue.

    // Check the list of known paths.
    if (PATHS.exists(filePath))
    {
      // trace(' WARNING '.warning() + ' Converting legacy asset path $filePath to ${PATHS[filePath]}')
      return PATHS[filePath];
    }

    // Try to guess some other paths.
    var result:Null<String> = tryGuessPath(id, filePath, type);
    if (result != null) return result;

    // I guess just use the filePath and suffer whatever errors result.
    if (verbose) trace(' ERROR '.error() + ' Could not convert legacy asset path '$filePath ' ($type), expect lots of errors!');
    return filePath;
  }

  /**
   * @param id The base ID of the asset, including the extension.
   * @param filePath The original guess at the file path, used for caching the result later if we find the true path.
   * @param type The type of asset.
   * @param library The library. Start with the `default` library, then iterate through others if we can't find it.
   * @return `String`, or `null` if a valid path couldn't be found.
   */
  static function tryGuessPath(id:String, filePath:String, type:OpenFLAssetType, library:String = 'default'):Null<String>
  {
    var result:Null<String> = null;

    var usePathIfExists = (path:String) ->
    {
      // Skip asset check if we already found a valid path.
      if (result != null) return;
      // Check if the path is valid, and if so, save it.
      if (funkin.assets.Assets.exists(path, type)) result = path;
    }

    // Try to guess where the path would be, pre-Great Sorting.
    // If we figure it out, add it to the list of known paths.
    var extension:String = haxe.io.Path.extension(filePath);
    var fileName:String = haxe.io.Path.withoutDirectory(filePath);
    var dirName:String = haxe.io.Path.directory(filePath);
    switch (extension)
    {
      case 'png': // Images
        var typeFilePath = (library == 'default') ? 'assets/images/$id' : 'assets/$library/images/$id';
        // Specific redirect for health icons
        var iconFilePath = (library == 'default') ? 'assets/images/icons/$fileName' : 'assets/$library/images/icons/$fileName';
        // Specific redirect for freeplay icon paths
        var freeplayIconFilePath = filePath.replace('ui/freeplay/characters/', 'images/freeplay/icons/').replace('.png', 'pixel.png');
        // Specific redirect for char select nametags
        var nametagFilePath = filePath.replace('ui/character-select/characters/nametag-', 'images/charSelect/').replace('.png', 'Nametag.png');
        // Specific redirect for char select animate atlases
        var charSelectFilePath = dirName.replace('ui/character-select/characters/', 'images/charSelect/') + 'Chill/$fileName';

        usePathIfExists(typeFilePath);
        usePathIfExists(iconFilePath);
        usePathIfExists(freeplayIconFilePath);
        usePathIfExists(nametagFilePath);
        usePathIfExists(charSelectFilePath);

      case 'frag' | 'vert': // Shader text
        var typeFilePath = (library == 'default') ? 'assets/shaders/$id' : 'assets/$library/shaders/$id';

        usePathIfExists(typeFilePath);
      case 'txt': // Data text
        var typeFilePath = (library == 'default') ? 'assets/data/$id' : 'assets/$library/data/$id';

        usePathIfExists(typeFilePath);
      case 'xml': // Data or image text
        var dataFilePath = (library == 'default') ? 'assets/data/$id' : 'assets/$library/data/$id';
        var imageFilePath = (library == 'default') ? 'assets/images/$id' : 'assets/$library/images/$id';
        // Specific redirect for freeplay icon paths
        var freeplayIconFilePath = filePath.replace('ui/freeplay/characters/', 'images/freeplay/icons/').replace('.xml', 'pixel.xml');

        usePathIfExists(dataFilePath);
        usePathIfExists(imageFilePath);
        usePathIfExists(freeplayIconFilePath);

      case 'json': // Data or image text
        var dataFilePath = (library == 'default') ? 'assets/data/$id' : 'assets/$library/data/$id';
        // Redirect for Animate atlas data
        var imageFilePath = (library == 'default') ? 'assets/images/$id' : 'assets/$library/images/$id';
        // Specific redirect for song data
        var songFilePath:String = filePath.replace('gameplay/songs/', 'songs/');
        var songDataFilePath:String = dataFilePath.replace('gameplay/songs/', 'songs/');
        // Specific redirect for char select animate atlases
        var charSelectFilePath = dirName.replace('ui/character-select/characters/', 'images/charSelect/') + 'Chill/$fileName';

        usePathIfExists(dataFilePath);
        usePathIfExists(imageFilePath);
        usePathIfExists(songDataFilePath);
        usePathIfExists(songFilePath);
        usePathIfExists(charSelectFilePath);

      case 'ogg': // Music or sound
        // Redirect for music files
        var musicFilePath:String = (library == 'default') ? 'assets/music/$id' : 'assets/$library/music/$id';
        // Redirect for sound effect files
        var soundFilePath:String = (library == 'default') ? 'assets/sound/$id' : 'assets/$library/sound/$id';
        // Specific redirect for song audio
        var songFilePath:String = filePath.replace('gameplay/songs/', 'songs/');

        usePathIfExists(musicFilePath);
        usePathIfExists(soundFilePath);
        usePathIfExists(songFilePath);

      case 'mp4' | 'mkv': // videos, without or with subtitles
        var videoFilePath:String = (library == 'default') ? 'assets/videos/$id' : 'assets/$library/videos/$id';

        usePathIfExists(videoFilePath);

      default:
        // No idea, sorry.
    }

    if (result != null)
    {
      // trace(' WARNING '.warning() + ' Converting legacy asset path $filePath to $result')

      // Successfully found a redirect that exists
      PATHS[filePath] = result;
      return result;
    }

    // Try some other asset libraries?
    if (library == 'default')
    {
      for (libraryToTry in ['shared', 'songs', 'videos'])
      {
        result = tryGuessPath(id, filePath, type, libraryToTry);
        if (result != null) return result;
      }
    }

    // No idea, sorry.
    return null;
  }
}
