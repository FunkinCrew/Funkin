package funkin.play;

import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxSprite;

/**
 * Static methods for playing cutscenes in the PlayState.
 * TODO: Un-hardcode this shit!!!!!1!
 */
class VanillaCutscenes
{
	public static function playUghCutscene():Void
	{
		playVideoCutscene('music/ughCutscene.mp4');
	}

	public static function playGunsCutscene():Void
	{
		playVideoCutscene('music/gunsCutscene.mp4');
	}

	public static function playStressCutscene():Void
	{
		playVideoCutscene('music/stressCutscene.mp4');
	}

	static var blackScreen:FlxSprite;

	/**
	 * Plays a cutscene from a video file, then starts the countdown once the video is done.
	 * TODO: Cutscene is currently skipped on native platforms.
	 */
	static function playVideoCutscene(path:String):Void
	{
		PlayState.isInCutscene = true;
		PlayState.instance.camHUD.visible = false;

		blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackScreen.scrollFactor.set(0, 0);
		PlayState.instance.add(blackScreen);

		#if html5
		vid:FlxVideo = new FlxVideo(path);
		vid.finishCallback = finishVideoCutscene();
		#else
		finishVideoCutscene();
		#end
	}

	/**
	 * Does the cleanup to start the countdown after the video is done.
	 * Gets called immediately if the video can't be played.
	 */
	static function finishVideoCutscene():Void
	{
		PlayState.instance.remove(blackScreen);
		blackScreen = null;

		FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCameraZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
		@:privateAccess
		PlayState.instance.startCountdown();
		@:privateAccess
		PlayState.instance.controlCamera();
	}

	public static function playHorrorStartCutscene()
	{
		PlayState.isInCutscene = true;
		PlayState.instance.camHUD.visible = false;

		blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackScreen.scrollFactor.set(0, 0);
		PlayState.instance.add(blackScreen);

		new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			PlayState.instance.remove(blackScreen);
			FlxG.sound.play(Paths.sound('Lights_Turn_On'));
			PlayState.instance.cameraFollowPoint.y = -2050;
			PlayState.instance.cameraFollowPoint.x += 200;
			FlxG.camera.focusOn(PlayState.instance.cameraFollowPoint.getPosition());
			FlxG.camera.zoom = 1.5;

			new FlxTimer().start(0.8, function(tmr:FlxTimer)
			{
				PlayState.instance.camHUD.visible = true;
				PlayState.instance.remove(blackScreen);
				blackScreen = null;
				FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCameraZoom}, 2.5, {
					ease: FlxEase.quadInOut,
					onComplete: function(twn:FlxTween)
					{
						Countdown.performCountdown(false);
					}
				});
			});
		});
	}
}
