import funkin.graphics.shaders.GaussianBlurShader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.RuntimeRainShader;
import funkin.play.PlayState;
import funkin.play.stage.Stage;
import openfl.filters.ShaderFilter;
import flixel.tweens.FlxTween;
import funkin.play.stage.StageProp;
import flixel.addons.display.FlxTiledSprite;
import funkin.util.MathUtil;

/**
 * This stage includes a partial version of the Philly Streets stage with shaders applied.
 */
class PhillyBlazinStage extends Stage
{
	function new()
	{
		super('phillyBlazin');
	}

	var rainShader:RuntimeRainShader = new RuntimeRainShader();
	var scrollingSky:FlxTiledSprite;
	// var rainShaderFilter:ShaderFilter;

	override function onCreate(event:ScriptEvent) {
		super.onCreate(event);
		cameraInitialized = false;
		cameraDarkened = false;
		lightningActive = true;

		rainShader.scale = FlxG.height / 200; // adjust this value so that the rain looks nice
		rainShader.intensity = 0.5;

		rainShaderFilter = new ShaderFilter(rainShader);
		FlxG.camera.filters = [rainShaderFilter];
	}

	override function onGameOver(event:ScriptEvent):Void {
		super.onGameOver(event);
		// Make it so the rain shader doesn't show over the game over screen
		FlxG.camera.filters = [];
	}

	override function onSongRetry(event:ScriptEvent):Void {
		super.onSongRetry(event);
		// Make it so the rain shader doesn't show over the game over screen
		FlxG.camera.filters = [rainShaderFilter];
		lightningActive = true;
	}

	override function buildStage()
	{
		super.buildStage();

		var skyAdditive = PlayState.instance.currentStage.getNamedProp('skyAdditive');
		skyAdditive.blend = 0; // ADD
		skyAdditive.visible = false;

		var lightning = PlayState.instance.currentStage.getNamedProp('lightning');
		lightning.visible = false;

		var foregroundMultiply = PlayState.instance.currentStage.getNamedProp('foregroundMultiply');
		foregroundMultiply.blend = 9; // MULTIPLY
		foregroundMultiply.visible = false;

		var additionalLighten = PlayState.instance.currentStage.getNamedProp('additionalLighten');
		additionalLighten.blend = 0; // ADD
		additionalLighten.visible = false;

		scrollingSky = new FlxTiledSprite(Paths.image('phillyBlazin/skyBlur'), 2000, 359, true, false);
		scrollingSky.setPosition(-500, -120);
		scrollingSky.scrollFactor.set(0, 0);
		scrollingSky.zIndex = 10;

		PlayState.instance.currentStage.add(scrollingSky);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		//scrollingSky.velocity.x = -20;
	}

	var cameraInitialized:Bool = false;
	var cameraDarkened:Bool = false;

	var lightningTimer:Float = 3.0;
	var lightningActive:Bool = true;

	var rainTimeScale:Float = 1.0;

	override function onUpdate(event:ScriptEvent)
	{
		super.onUpdate(event);

		rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
		rainShader.update(event.elapsed * rainTimeScale);
		rainTimeScale = MathUtil.coolLerp(rainTimeScale, 0.02, 0.05);

		if(scrollingSky != null) scrollingSky.scrollX -= FlxG.elapsed * 35;

		// Manually focus the camera before the song starts.
		if (!cameraInitialized && PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint != null)
		{
			cameraInitialized = true;
			initializeCamera();

			PlayState.instance.currentStage.getBoyfriend().color = 0xFFDEDEDE;
			PlayState.instance.currentStage.getDad().color = 0xFFDEDEDE;
			PlayState.instance.currentStage.getGirlfriend().color = 0xFF888888;
			PlayState.instance.currentStage.getGirlfriend().scriptGet('abot').color = 0xFF888888;
		}

		if (lightningActive) {
			lightningTimer -= FlxG.elapsed;
		} else {
			lightningTimer = 1;
		}

		if (lightningTimer <= 0) {
			applyLightning();
			lightningTimer = FlxG.random.float(7, 15);
		}
	}

	public function onNoteHit(event:HitNoteScriptEvent) {
		super.onNoteHit(event);
		rainTimeScale += 0.7;
	}


	function applyLightning():Void {
		var lightning = PlayState.instance.currentStage.getNamedProp('lightning');
		var skyAdditive = PlayState.instance.currentStage.getNamedProp('skyAdditive');
		var foregroundMultiply = PlayState.instance.currentStage.getNamedProp('foregroundMultiply');
		var additionalLighten = PlayState.instance.currentStage.getNamedProp('additionalLighten');

		var LIGHTNING_FULL_DURATION = 1.5;
		var LIGHTNING_FADE_DURATION = 0.3;

		skyAdditive.visible = true;
		skyAdditive.alpha = 0.7;
		FlxTween.tween(skyAdditive, {alpha: 0.0}, LIGHTNING_FULL_DURATION, {
			onComplete: cleanupLightning, // Make sure to call this only once!
		});

		foregroundMultiply.visible = true;
		foregroundMultiply.alpha = 0.64;
		FlxTween.tween(foregroundMultiply, {alpha: 0.0}, LIGHTNING_FULL_DURATION);

		additionalLighten.visible = true;
		additionalLighten.alpha = 0.3;
		FlxTween.tween(additionalLighten, {alpha: 0.0}, LIGHTNING_FADE_DURATION);

		lightning.visible = true;
		lightning.animation.play('strike');

		if(FlxG.random.bool(65)){
			lightning.x = FlxG.random.int(-250, 280);
		}else{
			lightning.x = FlxG.random.int(780, 900);
		}


		// Darken characters
		var boyfriend = PlayState.instance.currentStage.getBoyfriend();
		FlxTween.color(boyfriend, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
		var dad = PlayState.instance.currentStage.getDad();
		FlxTween.color(dad, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
		var girlfriend = PlayState.instance.currentStage.getGirlfriend();
		FlxTween.color(girlfriend, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);

		// Sound
		FunkinSound.playOnce(Paths.soundRandom('Lightning', 1, 3), 1.0);
	}

	public override function onSongEnd(event:CountdownScriptEvent):Void {
		super.onSongEnd(event);
		// Disable lightning during ending cutscene.
		lightningActive = false;
	}

	function cleanupLightning(tween:FlxTween):Void {
		var skyAdditive = PlayState.instance.currentStage.getNamedProp('skyAdditive');
		var foregroundMultiply = PlayState.instance.currentStage.getNamedProp('foregroundMultiply');
		var additionalLighten = PlayState.instance.currentStage.getNamedProp('additionalLighten');
		var lightning = PlayState.instance.currentStage.getNamedProp('lightning');
		skyAdditive.visible = false;
		foregroundMultiply.visible = false;
		additionalLighten.visible = false;
		lightning.visible = false;
	}

	function initializeCamera():Void {
		var xTarget:Float = PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.x;
    var yTarget:Float = PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.y;
		// yTarget += 200;
		xTarget += 50;
		yTarget -= 90;
    PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
		PlayState.instance.resetCamera();

		PlayState.instance.comboPopUps.offsets = [480, -50];

		PlayState.instance.camGame.fade(0xFF000000, 1.5, true, null, true);
	}
}
