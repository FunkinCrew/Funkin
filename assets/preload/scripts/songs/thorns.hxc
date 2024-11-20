import funkin.audio.FunkinSound;
import flixel.FlxG;
import funkin.graphics.FunkinSprite;
import flixel.FlxSprite;
import funkin.play.song.Song;
import funkin.play.PlayState;
import funkin.util.Constants;
import funkin.play.PlayStatePlaylist;
import flixel.util.FlxTimer;
import funkin.effects.RetroCameraFade;


class ThornsSong extends Song {
  var hasPlayedCutscene:Bool;

	public function new() {
		super('thorns');
	}

  public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);

    if (!PlayStatePlaylist.isStoryMode) hasPlayedCutscene = true;

    if (!hasPlayedCutscene) {
      trace('Pausing countdown to play cutscene.');


      hasPlayedCutscene = true;

      startCutscene();
      event.cancel(); // CANCEL THE COUNTDOWN!
    }
	}

  function startCutscene() {
    trace('Hit start of song! Starting cutscene.');

    PlayState.instance.disableKeys = true;

    PlayState.instance.camHUD.visible = false;
    PlayState.instance.camCutscene.visible = true;

    var red = new FunkinSprite(-20, -20).makeSolidColor(FlxG.width * 1.5, FlxG.height * 1.5, 0xFFFFFFFF);
    red.color = 0xFFFF1B31;
    red.cameras = [PlayState.instance.camCutscene];
    red.alpha = 1.0;
    PlayState.instance.add(red);

    var senpaiCrazy = FunkinSprite.createSparrow(0, 0, 'weeb/senpaiCrazy');
    senpaiCrazy.cameras = [PlayState.instance.camCutscene];
    senpaiCrazy.animation.addByPrefix('idle', 'Senpai Pre Explosion instance 1', 24, false);
		senpaiCrazy.setGraphicSize(Std.int(senpaiCrazy.width * Constants.PIXEL_ART_SCALE));
    senpaiCrazy.antialiasing = false;
    senpaiCrazy.pixelPerfectRender = true;
    senpaiCrazy.pixelPerfectPosition = true;

    senpaiCrazy.scrollFactor.set();
		senpaiCrazy.updateHitbox();
		senpaiCrazy.screenCenter();
		senpaiCrazy.x += senpaiCrazy.width / 5;

    senpaiCrazy.alpha = 0;

    PlayState.instance.add(senpaiCrazy);

    // Senpai fades in stepwise rather than linear.
    new FlxTimer().start(0.3, function(timer:FlxTimer) {
      senpaiCrazy.alpha += 0.15;

      if (senpaiCrazy.alpha < 1) {
        timer.reset();
      } else {
        senpaiCrazy.alpha = 1;

        // Play the actual animation.
        senpaiCrazy.animation.play('idle');

        // Play the SFX alongside it.
        trace('Playing senpai death SFX.');
        FunkinSound.playOnce(Paths.sound('Senpai_Dies'), 1.0, function () {
          trace('Senpai death SFX done.');
          // Called when the sound completes. Clean up the cutscene here.
          // Hard cut to the cutscene.
          PlayState.instance.remove(red);

          RetroCameraFade.fadeBlack(PlayState.instance.camCutscene, 6, 1.4);
          RetroCameraFade.fadeBlack(PlayState.instance.camGame, 6, 1.4);
          new FlxTimer().start(1.6, _ -> {

            startDialogue();

          });
          // PlayState.instance.camCutscene.fade(0xFFEEEEEE, 0.8, true);
        });

        // Fade to white 3.2 seconds into the cutscene.
        new FlxTimer().start(3.2, function(deadTime:FlxTimer)
        {
          RetroCameraFade.fadeWhite(PlayState.instance.camCutscene, 8, 1.4);
          new FlxTimer().start(1.4, function(timer:FlxTimer) {
            red.color = 0xFFFFFFFF;
            PlayState.instance.remove(senpaiCrazy);

            PlayState.instance.camCutscene.filters = [];
            RetroCameraFade.fadeToBlack(PlayState.instance.camCutscene, 8, 0.8);
          });

          // PlayState.instance.camCutscene.fade(0xFFEEEEEE, 1.6, false);
        });
      }
    });
  }

  function startDialogue() {
    PlayState.instance.disableKeys = false;
    PlayState.instance.startConversation('thorns');
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
    Countdown.performCountdown();


  }
}
