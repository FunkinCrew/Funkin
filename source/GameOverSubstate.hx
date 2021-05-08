package;

import FreeplayState.SongMetadata;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var bksp:FlxSprite;

	var stageSuffix:String = "";

	public function new(x:Float, y:Float)
	{
		var daStage = PlayState.curStage;
		var daBf:String = '';
		switch (daStage)
		{
			case 'school':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			case 'schoolEvil':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			default:
				daBf = 'bf';
		}

		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bksp = new FlxSprite(32, FlxG.height - 128);
		bksp.frames = Paths.getSparrowAtlas('st_ui_assets');
		bksp.animation.addByPrefix('indicator', 'backspace' + stageSuffix + ' indicator', 24, false);
		bksp.antialiasing = true;
		bksp.animation.play('indicator');
		bksp.alpha = 0;
		bksp.updateHitbox();
		add(bksp);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		bksp.cameras = [camHUD];

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			if (!isEnding) {
				isEnding = true;

				FlxG.sound.music.stop();
				FlxG.sound.play(Paths.music('gameOverConfirmEnd'));

				FlxTween.tween(bksp.scale, {x: 1.15, y: 1.15}, 0.125, {
					ease: FlxEase.quartInOut,
					onComplete: function(tween:FlxTween)
					{
						FlxTween.tween(bksp.scale, {x: 1, y: 1}, 0.125, {ease: FlxEase.quartInOut});
					}
				});

				new FlxTimer().start(0.7, function(tmr:FlxTimer)
				{
					FlxTween.tween(bksp, {alpha: 0}, 2, {
						ease: FlxEase.quartInOut
					});
						
					FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
					{
						if (PlayState.isStoryMode == true) {
							LoadingState.loadAndSwitchState(new StoryMenuState());
						} else {
							LoadingState.loadAndSwitchState(new FreeplayState());
						}
					});
				});

				/*
				if (PlayState.isStoryMode)
					FlxG.switchState(new StoryMenuState());
				else
					FlxG.switchState(new FreeplayState());
				*/
			}
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));

			FlxTween.tween(bksp, {alpha: 1}, 0.75, {
				ease: FlxEase.quartInOut
			});
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxTween.tween(bksp.scale, {x: 1.05, y: 1.05}, 0.125, {
            ease: FlxEase.quartInOut,
            onComplete: function(tween:FlxTween)
            {
                FlxTween.tween(bksp.scale, {x: 1, y: 1}, 0.125, {ease: FlxEase.quartInOut});
            }
        });

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxTween.tween(bksp, {alpha: 0}, 2, {
					ease: FlxEase.quartInOut
				});
				
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
