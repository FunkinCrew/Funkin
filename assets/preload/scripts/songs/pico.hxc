import flixel.tweens.FlxEase;
import funkin.graphics.FunkinSprite;
import flixel.tweens.FlxTween;
import funkin.play.cutscene.dialogue.DialogueBox;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.save.Save;

import funkin.effects.RetroCameraFade;

class PhillyNiceSong extends Song {
  var hasPlayedCutscene:Bool;

	public function new() {
		super('pico');
	}

	public override function isSongNew(currentDifficulty:String, currentVariation:String):Bool{
		if(currentVariation == 'pico')
		  return !Save.instance.hasBeatenSong(this.id, null, 'pico');

    return false;
	}

  public override function listAltInstrumentalIds(difficultyId:String, variationId:String):Array<String> {
    if (difficultyId == 'easy' || difficultyId == 'normal' || difficultyId == 'hard') {
      var hasBeatenPicoMix = Save.instance.hasBeatenSong(this.id, null, 'pico');

      switch (variationId) {
        case 'pico':
          // return hasBeatenPicoMix ? [''] : [];
          // No Pico mix on BF instrumental, sorry!
          return [];
        default:
          return hasBeatenPicoMix ? ['pico'] : [];
      }
    }
  }
}
