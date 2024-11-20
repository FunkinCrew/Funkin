import funkin.play.song.Song;
import funkin.play.PlayState;
import funkin.play.cutscene.VideoCutscene;
import funkin.save.Save;

import funkin.play.PlayStatePlaylist;

class GunsSong extends Song {
  var hasPlayedCutscene:Bool;

	public function new() {
		super('guns');

    hasPlayedCutscene = false;
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

  public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);

    if (!PlayStatePlaylist.isStoryMode) hasPlayedCutscene = true;

    if (!hasPlayedCutscene) {
      trace('Pausing countdown to play a video cutscene (`guns`)');

      hasPlayedCutscene = true;

      event.cancel(); // CANCEL THE COUNTDOWN!

      startVideo();
    }
	}

  function startVideo() {
    VideoCutscene.play(Paths.videos('gunsCutscene'));
  }

  /**
   * Don't replay the cutscene between restarts.
   */
  function onSongRetry(event:ScriptEvent)
  {
    super.onSongRetry(event);

    hasPlayedCutscene = true;
  }

  /**
   * Replay the cutscene after leaving the song.
   */
  function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);

    hasPlayedCutscene = false;
  }
}
