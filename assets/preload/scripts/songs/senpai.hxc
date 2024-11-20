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

import funkin.effects.RetroCameraFade;

class SenpaiSong extends Song {
  var hasPlayedCutscene:Bool;

	public function new() {
		super('senpai');
	}

  public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);

    if (!PlayStatePlaylist.isStoryMode) hasPlayedCutscene = true;

    if (!hasPlayedCutscene) {
      trace('Pausing countdown to play cutscene.');

      hasPlayedCutscene = true;

      event.cancel(); // CANCEL THE COUNTDOWN!

      PlayState.instance.currentStage.pause();

      transitionToDialogue();
    }
	}

  function transitionToDialogue() {
    trace('Transitioning to dialogue.');

    PlayState.instance.camCutscene.visible = true;

    var black:FlxSprite = new FunkinSprite(-20, -20).makeSolidColor(FlxG.width * 1.5, FlxG.height * 1.5, 0xFF000000);
    black.cameras = [PlayState.instance.camCutscene];
    black.zIndex = 1000000;
    PlayState.instance.add(black);

    black.alpha = 1.0;

    var tweenFunction = function(x) {
      var xSnapped = Math.floor(x * 8) / 8;
      // black.alpha = 1.0 - xSnapped;
    };

    new FlxTimer().start(0.25, _ -> {
      PlayState.instance.remove(black);
      RetroCameraFade.fadeBlack(PlayState.instance.camGame, 12, 2);
    });

    FlxTween.num(0.0, 1.0, 2.0, {
      ease: FlxEase.linear,
      startDelay: 0.25,
      onComplete: function (input) {

        // black.visible = false;
        startDialogue();
      }
    }, tweenFunction);
  }

  function startDialogue() {
    PlayState.instance.startConversation('senpai');
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

  public override function onDialogueEnd() {
    // We may need to wait for the outro to play.
    PlayState.instance.currentStage.resume();
    Countdown.performCountdown();
  }
}
