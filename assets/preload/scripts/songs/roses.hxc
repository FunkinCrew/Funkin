import funkin.play.song.Song;
import funkin.play.PlayState;
import funkin.Preferences;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import flixel.FlxG;
import funkin.play.PlayStatePlaylist;
import funkin.audio.FunkinSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.ui.options.PreferencesMenu;

class RosesSong extends Song {
  var hasPlayedCutscene:Bool;

	public function new() {
		super('roses');
	}

  public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);
    trace('Started countdown for Roses...');

    if (!PlayStatePlaylist.isStoryMode) hasPlayedCutscene = true;

    if (!hasPlayedCutscene) {
      trace('Pausing countdown to play cutscene.');

      hasPlayedCutscene = true;

      event.cancel(); // CANCEL THE COUNTDOWN!

      // Play a SFX
      FunkinSound.playOnce(Paths.sound('ANGRY'), 1.0);

      PlayState.instance.currentStage.pause();

      startDialogue();
    }
	}

  function startDialogue() {
    if (Preferences.naughtyness) {
      trace('Playing uncensored dialogue...');
      PlayState.instance.startConversation('roses');
    } else {
      trace('Playing censored dialogue...');
      PlayState.instance.startConversation('roses-censored');
    }
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

	function onBeatHit(event:SongTimeScriptEvent)
  {
    // When overriding onBeatHit, make sure to call super.onBeatHit,
    // otherwise boppers will not work.
    super.onBeatHit(event);

    if (event.beat == 180 && PlayStatePlaylist.isStoryMode) {
      trace('Hit end of song! Starting outro.');

      PlayState.instance.camCutscene.visible = true;

      var red = new FunkinSprite(-20, -20).makeSolidColor(FlxG.width * 1.5, FlxG.height * 1.5, 0xFFFF1B31);
      red.cameras = [PlayState.instance.camCutscene];

      red.alpha = 0.0;
      FlxTween.tween(PlayState.instance.camHUD, {alpha: 0.0}, 1.5, {ease: FlxEase.linear});
      FlxTween.tween(red, {alpha: 1.0}, 2.0, {ease: FlxEase.linear});
      PlayState.instance.add(red);
    }
  }

  public override function onDialogueEnd() {
    // We may need to wait for the outro to play.
    Countdown.performCountdown();
  }
}
