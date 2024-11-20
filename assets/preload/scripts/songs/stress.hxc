import funkin.play.song.Song;
import funkin.play.PlayState;

import funkin.play.PlayStatePlaylist;
import funkin.modding.base.ScriptedFlxSpriteGroup;
import funkin.play.cutscene.VideoCutscene;

class StressSong extends Song {
  var hasPlayedCutscene:Bool;
	var tankmanGroup:TankmanSpriteGroup;

	public function new() {
		super('stress');

    hasPlayedCutscene = false;
	}

  public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);

    if (!PlayStatePlaylist.isStoryMode) hasPlayedCutscene = true;

    if (!hasPlayedCutscene) {
      trace('Pausing countdown to play a video cutscene (`stress`)');

      hasPlayedCutscene = true;

      event.cancel(); // CANCEL THE COUNTDOWN!

      startVideo();
    }

    trace('Initializing tankman group...');
    tankmanGroup = ScriptedFlxSpriteGroup.init('TankmanSpriteGroup');

    if (tankmanGroup != null) {
      // resets the tankmen!
      tankmanGroup.scriptCall('reset');

      tankmanGroup.zIndex = 30;
      PlayState.instance.currentStage.add(tankmanGroup);
      PlayState.instance.currentStage.refresh();
    } else {
      trace('Failed to initialize tankman group!');
    }
	}

  var tankmanGroup = null;

  function onSongStart(event:ScriptEvent):Void
  {
    super.onSongStart(event);

  }

  function startVideo() {
    VideoCutscene.play(Paths.videos('stressCutscene'));
  }

  /**
   * Don't replay the cutscene between restarts.
   */
  function onSongRetry(event:ScriptEvent)
  {
    super.onSongRetry(event);

    hasPlayedCutscene = true;

		// resets the tankmen!
		if (tankmanGroup != null) {
			tankmanGroup.scriptCall('reset');
		}
    if(PlayState.instance.currentStage.getGirlfriend() != null){
        PlayState.instance.currentStage.getGirlfriend().scriptCall('reset');
        trace('reset pico!');
    }
  }

  /**
   * Replay the cutscene after leaving the song.
   */
  function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);

    hasPlayedCutscene = false;
  }

  function kill():Void {
		if (tankmanGroup != null) {
      PlayState.instance.currentStage.remove(tankmanGroup);
      tankmanGroup.destroy();
      tankmanGroup = null;
    }
  }
}
