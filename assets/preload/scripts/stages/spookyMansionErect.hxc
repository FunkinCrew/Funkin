import flixel.FlxG;
import funkin.audio.FunkinSound;
import funkin.play.PlayState;
import funkin.play.stage.Stage;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.util.FlxTweenUtil;
import flixel.util.FlxTimer;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterDataParser;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;
import funkin.graphics.shaders.RuntimeRainShader;

class SpookyMansionErectStage extends Stage
{
	function new()
	{
		super('spookyMansionErect');
	}

	var rainShaderTarget:FlxSprite;
	var rainShader:RuntimeRainShader = new RuntimeRainShader();

	var lightningStrikeBeat:Int = 0;
	var lightningStrikeOffset:Int = 8;

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);

		trace('Applying rain shader...');

		// adjust this value so that the rain looks nice
		rainShader.scale = FlxG.height / 200 * 2;
		rainShader.intensity = 0.4;
		rainShader.spriteMode = true;

		rainShaderTarget = getNamedProp('bgTrees');
		rainShaderTarget.shader = rainShader;
		rainShaderTarget.animation.callback = onBranchFrame;
	}

	function onBranchFrame(name, frameNum, frameIndex) {
		rainShader.updateFrameInfo(rainShaderTarget.frame);
	}

  override function buildStage()
	{
		super.buildStage();
    getNamedProp('bgLight').alpha = 0;
    getNamedProp('stairsLight').alpha = 0;
	}

  override function onUpdate(event:UpdateScriptEvent)
	{
		super.onUpdate(event);
		rainShader.update(event.elapsed);
	}

	function doLightningStrike(playSound:Bool, beat:Int):Void
	{
		if(getBoyfriend() == null || getGirlfriend() == null || getDad() == null) return;

		if (playSound)
		{
			FunkinSound.playOnce(Paths.soundRandom('thunder_', 1, 2), 1.0);
		}

		//getNamedProp('halloweenBG').animation.play('lightning');
    getNamedProp('bgLight').alpha = 1;
    getNamedProp('stairsLight').alpha = 1;
    PlayState.instance.currentStage.getBoyfriend().alpha = 0;
    PlayState.instance.currentStage.getDad().alpha = 0;
    PlayState.instance.currentStage.getGirlfriend().alpha = 0;

    new FlxTimer().start(0.06, function(_) {
      getNamedProp('bgLight').alpha = 0;
      getNamedProp('stairsLight').alpha = 0;
        PlayState.instance.currentStage.getBoyfriend().alpha = 1;
        PlayState.instance.currentStage.getDad().alpha = 1;
        PlayState.instance.currentStage.getGirlfriend().alpha = 1;
		});

    new FlxTimer().start(0.12, function(_) {
      getNamedProp('bgLight').alpha = 1;
      getNamedProp('stairsLight').alpha = 1;
      PlayState.instance.currentStage.getBoyfriend().alpha = 0;
      PlayState.instance.currentStage.getDad().alpha = 0;
      PlayState.instance.currentStage.getGirlfriend().alpha = 0;
      FlxTween.tween(getNamedProp('bgLight'), {alpha: 0}, 1.5);
      FlxTween.tween(getNamedProp('stairsLight'), {alpha: 0}, 1.5);
      FlxTween.tween(PlayState.instance.currentStage.getBoyfriend(), {alpha: 1}, 1.5);
      FlxTween.tween(PlayState.instance.currentStage.getDad(), {alpha: 1}, 1.5);
      FlxTween.tween(PlayState.instance.currentStage.getGirlfriend(), {alpha: 1}, 1.5);
		});

		lightningStrikeBeat = beat;
		lightningStrikeOffset = FlxG.random.int(8, 24);

		if (getBoyfriend() != null) {
			getBoyfriend().playAnimation('scared', true, true);
		}

		if (getGirlfriend() != null) {
			getGirlfriend().playAnimation('scared', true, true);
		}
	}

	/**
	 * If your stage uses additional assets not specified in the JSON,
	 * make sure to specify them like this, or they won't get cached in the loading screen.
	 */
	function fetchAssetPaths():Array<String>
	{
		var results:Array<String> = super.fetchAssetPaths();
		results.push(Paths.sound('thunder_1'));
		results.push(Paths.sound('thunder_2'));
		return results;
	}

	function onBeatHit(event:SongTimeScriptEvent)
	{
		super.onBeatHit(event);

		// Play lightning on sync at the start of this specific song.
		// TODO: Rework this after chart format redesign.
		if (PlayState.instance.currentSong != null) {
			if (event.beat == 4 && PlayState.instance.currentSong.id == "spookeez")
			{
				doLightningStrike(false, event.beat);
			}
		}

		// Play lightning at random intervals.
		if (FlxG.random.bool(10) && event.beat > (lightningStrikeBeat + lightningStrikeOffset))
		{
			doLightningStrike(true, event.beat);
		}
	}

	function onSongRetry(event:ScriptEvent)
	{
		super.onSongRetry(event);

		// Properly reset lightning when restarting the song.
		lightningStrikeBeat = 0;
		lightningStrikeOffset = 8;
	}
}
