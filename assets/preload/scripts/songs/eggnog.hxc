import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxBasePoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.Conductor;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinSprite;
import funkin.modding.base.ScriptedFlxAtlasSprite;
import funkin.play.cutscene.CutsceneType;
import funkin.play.cutscene.VideoCutscene;
import funkin.play.GameOverSubState;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.play.stage.StageProp;
import funkin.save.Save;

// We have to use FlxBasePoint in scripts because FlxPoint is inlined and not available in scripts

class EggnogSong extends Song
{
	var hasPlayedCutscene:Bool = false;

  //var santaDead:ScriptedFlxAtlasSprite;

	function new()
	{
		super('eggnog');

		hasPlayedCutscene = false;
	}

	public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);
		trace(PlayState.instance.currentVariation);
	}

	function onSongRetry(event:ScriptEvent)
	{
		super.onSongRetry(event);

	}

	public override function isSongNew(currentDifficulty:String, currentVariation:String):Bool
	{
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

	public override function onSongEnd(event:CountdownScriptEvent):Void {
		super.onSongEnd(event);
   	if (PlayState.instance.currentVariation != 'erect') hasPlayedCutscene = true;
		// only play this on erect..

    if (!hasPlayedCutscene) {
      hasPlayedCutscene = true;

      event.cancel();

			// start the video cutscene and hide it so the other stuff can happen after
      startCutscene();
    } else {
			// Make sure the cutscene can play again next time!
			hasPlayedCutscene = false;
			// DO NOT CANCEL THE EVENT!
		}
	}

	function startCutscene(){

    var normalSanta = PlayState.instance.currentStage.getNamedProp('santa');
    normalSanta.visible = false;

    var santaDead:ScriptedFlxAtlasSprite = ScriptedFlxAtlasSprite.init('SantaDiesSprite', 0, 0);

    santaDead.x = -458;
		santaDead.y = 498;
		santaDead.zIndex = normalSanta.zIndex - 1;

    PlayState.instance.currentStage.add(santaDead);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

    santaDead.scriptCall('playCutscene');

    PlayState.instance.currentStage.getDad().visible = false;
    var parentsShoot:ScriptedFlxAtlasSprite = ScriptedFlxAtlasSprite.init('DadShootsSprite', 0, 0);

    parentsShoot.x = -516;
		parentsShoot.y = 503;
		parentsShoot.zIndex = santaDead.zIndex - 1;

    PlayState.instance.currentStage.add(parentsShoot);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

    parentsShoot.scriptCall('playCutscene');

		//FlxTween.tween(PlayState.instance.camHUD, {alpha: 0}, 1);

		PlayState.instance.isInCutscene = true;
		hasPlayedCutscene = true;

		PlayState.instance.currentStage.getBoyfriend().danceEvery = 0;
		PlayState.instance.currentStage.getDad().danceEvery = 0;

    PlayState.instance.tweenCameraToPosition(santaDead.x + 300, santaDead.y, 2.8, FlxEase.expoOut);
		//PlayState.instance.tweenCameraToPosition(santaDead.x + 300, santaDead.y, 2.8, FlxEase.expoOut);
		PlayState.instance.tweenCameraZoom(0.73, 2, true, FlxEase.quadInOut);

		FunkinSound.playOnce(Paths.sound('santa_emotion'), 1);

		new FlxTimer().start(2.8, function(tmr)
		{
			PlayState.instance.tweenCameraToPosition(santaDead.x + 150, santaDead.y, 9, FlxEase.quartInOut);
			PlayState.instance.tweenCameraZoom(0.79, 9, true, FlxEase.quadInOut);
		});


		new FlxTimer().start(11.3, function(tmr){
			//PlayState.instance.tweenCameraZoom(0.73, 0.8, true, FlxEase.backOut);
			//PlayState.instance.tweenCameraToPosition(santaDead.x + 220, santaDead.y, 0.8, FlxEase.expoOut);
			//PlayState.instance.camGame.shake(0.007, 0.4);
		});
		new FlxTimer().start(11.375, function(tmr)
		{
			FunkinSound.playOnce(Paths.sound('santa_shot_n_falls'), 1);
		});

		new FlxTimer().start(12.83, function(tmr)
		{
			PlayState.instance.camGame.shake(0.005, 0.2);
			PlayState.instance.tweenCameraToPosition(santaDead.x + 160, santaDead.y + 80, 5, FlxEase.expoOut);
		});


		new FlxTimer().start(15, function(tmr)
		{
			PlayState.instance.camHUD.fade(0xFF000000, 1, false, null, true);
		});

		new FlxTimer().start(16, function(tmr)
		{
			PlayState.instance.camHUD.fade(0xFF000000, 0.5, true, null, true);
			PlayState.instance.endSong(true);
		});

	}

	function onUpdate(event:UpdateScriptEvent) {
		super.onUpdate(event);
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
