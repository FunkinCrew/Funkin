package funkin;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.android.FlxAndroidKey;
import flixel.input.android.FlxAndroidKeys;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.id.SwitchJoyconLeftID;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.audiovis.SpectogramSprite;
import funkin.shaderslmfao.BuildingShaders;
import funkin.shaderslmfao.ColorSwap;
import funkin.shaderslmfao.TitleOutline;
import funkin.ui.PreferencesMenu;
import lime.app.Application;
import lime.graphics.Image;
import lime.media.AudioContext;
import lime.ui.Window;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.events.AsyncErrorEvent;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;

using StringTools;

#if desktop
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;
#end

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];
	var lastBeat:Int = 0;
	var swagShader:ColorSwap;
	var alphaShader:BuildingShaders;

	var video:Video;
	var netStream:NetStream;
	private var overlay:Sprite;

	override public function create():Void
	{
		swagShader = new ColorSwap();
		alphaShader = new BuildingShaders();

		curWacky = FlxG.random.getObject(getIntroTextShit());
		FlxG.sound.cache(Paths.music('freakyMenu'));

		// DEBUG BULLSHIT

		super.create();

		/* 
			#elseif web


			if (!initialized)
			{

				video = new Video();
				FlxG.stage.addChild(video);

				var netConnection = new NetConnection();
				netConnection.connect(null);

				netStream = new NetStream(netConnection);
				netStream.client = {onMetaData: client_onMetaData};
				netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netStream_onAsyncError);
				netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnection_onNetStatus);
				// netStream.addEventListener(NetStatusEvent.NET_STATUS) // netStream.play(Paths.file('music/kickstarterTrailer.mp4'));

				overlay = new Sprite();
				overlay.graphics.beginFill(0, 0.5);
				overlay.graphics.drawRect(0, 0, 1280, 720);
				overlay.addEventListener(MouseEvent.MOUSE_DOWN, overlay_onMouseDown);

				overlay.buttonMode = true;
				// FlxG.stage.addChild(overlay);

			}
		 */

		// netConnection.addEventListener(MouseEvent.MOUSE_DOWN, overlay_onMouseDown);
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});
	}

	private function client_onMetaData(metaData:Dynamic)
	{
		video.attachNetStream(netStream);

		video.width = video.videoWidth;
		video.height = video.videoHeight;
		// video.
	}

	private function netStream_onAsyncError(event:AsyncErrorEvent):Void
	{
		trace("Error loading video");
	}

	private function netConnection_onNetStatus(event:NetStatusEvent):Void
	{
		if (event.info.code == 'NetStream.Play.Complete')
		{
			// netStream.dispose();
			// FlxG.stage.removeChild(video);

			startIntro();
		}

		trace(event.toString());
	}

	private function overlay_onMouseDown(event:MouseEvent):Void
	{
		netStream.soundTransform.volume = 0.2;
		netStream.soundTransform.pan = -1;
		// netStream.play(Paths.file('music/kickstarterTrailer.mp4'));

		FlxG.stage.removeChild(overlay);
	}

	var logoBl:FlxSprite;
	var outlineShaderShit:TitleOutline;

	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		Conductor.changeBPM(102);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');

		logoBl.updateHitbox();

		outlineShaderShit = new TitleOutline();
		// logoBl.shader = swagShader.shader;
		// logoBl.shader = outlineShaderShit;

		// trace();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;
		add(gfDance);

		trace('MACRO TEST: ${gfDance.zIndex}');

		// alphaShader.shader.funnyShit.input = gfDance.pixels; // old shit

		logoBl.shader = alphaShader.shader;

		// trace(alphaShader.shader.glFragmentSource)

		// gfDance.shader = swagShader.shader;

		// gfDance.shader = new TitleOutline();

		add(logoBl);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);

		textGroup = new FlxGroup();

		blackScreen = bg.clone();
		credGroup.add(blackScreen);

		// var atlasBullShit:FlxSprite = new FlxSprite();
		// atlasBullShit.frames = CoolUtil.fromAnimate(Paths.image('money'), Paths.file('images/money.json'));
		// credGroup.add(atlasBullShit);

		ngSpr = new FlxSprite(0, FlxG.height * 0.52);

		if (FlxG.random.bool(1))
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo_classic'));
		}
		else if (FlxG.random.bool(30))
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo_animated'), true, 600);
			ngSpr.animation.add('idle', [0, 1], 4);
			ngSpr.animation.play('idle');
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.55));
		}
		else
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo'));
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		}

		add(ngSpr);
		ngSpr.visible = false;

		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxG.mouse.visible = false;

		if (initialized)
			skipIntro();
		else
			initialized = true;

		if (FlxG.sound.music != null)
			FlxG.sound.music.onComplete = function() FlxG.switchState(new VideoState());
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		#if HAS_PITCH
		if (FlxG.keys.pressed.UP)
			FlxG.sound.music.pitch += 0.5 * elapsed;

		if (FlxG.keys.pressed.DOWN)
			FlxG.sound.music.pitch -= 0.5 * elapsed;
		#end

		/* if (FlxG.onMobile)
			{
				if (gfDance != null)
				{
					gfDance.x = (FlxG.width / 2) + (FlxG.accelerometer.x * (FlxG.width / 2));
					// gfDance.y = (FlxG.height / 2) + (FlxG.accelerometer.y * (FlxG.height / 2));
				}
			}
		 */
		if (FlxG.keys.justPressed.I)
		{
			FlxTween.tween(outlineShaderShit, {funnyX: 50, funnyY: 50}, 0.6, {ease: FlxEase.quartOut});
		}
		if (FlxG.keys.pressed.D)
			outlineShaderShit.funnyX += 1;
		// outlineShaderShit.xPos.value[0] += 1;

		if (FlxG.keys.justPressed.Y)
		{
			FlxTween.tween(FlxG.stage.window, {x: FlxG.stage.window.x + 300}, 1.4, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.35});
			FlxTween.tween(FlxG.stage.window, {y: FlxG.stage.window.y + 100}, 0.7, {ease: FlxEase.quadInOut, type: PINGPONG});
		}

		/* 
			FlxG.watch.addQuick('cur display', FlxG.stage.window.display.id);
			if (FlxG.keys.justPressed.Y)
			{
				// trace(FlxG.stage.window.display.name);

				if (FlxG.gamepads.firstActive != null)
				{
					trace(FlxG.gamepads.firstActive.model);
					FlxG.gamepads.firstActive.id
				}
				else
					trace('gamepad null');

				// FlxG.stage.window.title = Std.string(FlxG.random.int(0, 20000));
				// FlxG.stage.window.setIcon(Image.fromFile('assets/images/icon16.png'));
				// FlxG.stage.window.readPixels;

				if (FlxG.stage.window.width == Std.int(FlxG.stage.window.display.bounds.width))
				{
					FlxG.stage.window.width = 1280;
					FlxG.stage.window.height = 720;
					FlxG.stage.window.y = 30;
				}
				else
				{
					FlxG.stage.window.width = Std.int(FlxG.stage.window.display.bounds.width);
					FlxG.stage.window.height = Std.int(FlxG.stage.window.display.bounds.height);
					FlxG.stage.window.x = Std.int(FlxG.stage.window.display.bounds.x);
					FlxG.stage.window.y = Std.int(FlxG.stage.window.display.bounds.y);
				}
			}
		 */

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new CutsceneAnimTestState());
		#end

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;

		// do controls.PAUSE | controls.ACCEPT instead?
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		if (FlxG.onMobile)
		{
			for (touch in FlxG.touches.list)
			{
				if (touch.justPressed)
				{
					FlxG.switchState(new FreeplayState());
					pressedEnter = true;
				}
			}
		}

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		// a faster intro thing lol!
		if (pressedEnter && transitioning && skippedIntro)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.onComplete = null;
			// netStream.play(Paths.file('music/kickstarterTrailer.mp4'));
			NGio.unlockMedal(60960);
			// If it's Friday according to da clock
			if (Date.now().getDay() == 5)
				NGio.unlockMedal(61034);
			titleText.animation.play('press');
			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			transitioning = true;

			var targetState:FlxState = new MainMenuState();

			#if newgrounds
			if (!OutdatedSubState.leftState)
			{
				NGio.checkVersion(function(version)
				{
					// Check if version is outdated
					var localVersion:String = "v" + Application.current.meta.get('version');
					var onlineVersion = version.split(" ")[0].trim();
					if (version.trim() != onlineVersion)
					{
						trace('OLD VERSION!');
						// targetState = new OutdatedSubState();
					}
					else
					{
						// targetState = new MainMenuState();
					}
					// REDO FOR ITCH/FINAL SHIT
				});
			}
			#end
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				// These assets are very unlikely to be used for the rest of gameplay, so it unloads them from cache/memory
				// Saves about 50mb of RAM or so???
				Assets.cache.clear(Paths.image('gfDanceTitle'));
				Assets.cache.clear(Paths.image('logoBumpin'));
				Assets.cache.clear(Paths.image('titleEnter'));
				// ngSpr??
			});
			// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
		}
		if (pressedEnter && !skippedIntro && initialized)
			skipIntro();
		/* 
			#if web
			if (!initialized && controls.ACCEPT)
			{
				// netStream.dispose();
				// FlxG.stage.removeChild(video);

				startIntro();
				skipIntro();
			}
			#end
		 */

		if (controls.UI_LEFT)
			swagShader.update(-elapsed * 0.1);
		if (controls.UI_RIGHT)
			swagShader.update(elapsed * 0.1);
		if (!cheatActive && skippedIntro)
			cheatCodeShit();
		super.update(elapsed);
	}

	var cheatArray:Array<Int> = [0x0001, 0x0010, 0x0001, 0x0010, 0x0100, 0x1000, 0x0100, 0x1000];
	var curCheatPos:Int = 0;
	var cheatActive:Bool = false;

	function cheatCodeShit():Void
	{
		if (FlxG.keys.justPressed.ANY)
		{
			if (controls.NOTE_DOWN_P || controls.UI_DOWN_P)
				codePress(FlxObject.DOWN);
			if (controls.NOTE_UP_P || controls.UI_UP_P)
				codePress(FlxObject.UP);
			if (controls.NOTE_LEFT_P || controls.UI_LEFT_P)
				codePress(FlxObject.LEFT);
			if (controls.NOTE_RIGHT_P || controls.UI_RIGHT_P)
				codePress(FlxObject.RIGHT);
		}
	}

	function codePress(input:Int)
	{
		if (input == cheatArray[curCheatPos])
		{
			curCheatPos += 1;
			if (curCheatPos >= cheatArray.length)
				startCheat();
		}
		else
			curCheatPos = 0;

		trace(input);
	}

	function startCheat():Void
	{
		cheatActive = true;

		FlxG.sound.playMusic(Paths.music('tutorialTitle'), 1);

		var spec:SpectogramSprite = new SpectogramSprite(FlxG.sound.music);
		add(spec);

		Conductor.changeBPM(190);
		FlxG.camera.flash(FlxColor.WHITE, 1);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String)
	{
		lime.ui.Haptic.vibrate(100, 100);

		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	var isRainbow:Bool = false;
	var skippedIntro:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (!skippedIntro)
		{
			FlxG.log.add(curBeat);
			// if the user is draggin the window some beats will
			// be missed so this is just to compensate
			if (curBeat > lastBeat)
			{
				for (i in lastBeat...curBeat)
				{
					switch (i + 1)
					{
						case 1:
							createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
						case 3:
							addMoreText('present');
						case 4:
							deleteCoolText();
						case 5:
							createCoolText(['In association', 'with']);
						case 7:
							addMoreText('newgrounds');
							ngSpr.visible = true;
						case 8:
							deleteCoolText();
							ngSpr.visible = false;
						case 9:
							createCoolText([curWacky[0]]);
						case 11:
							addMoreText(curWacky[1]);
						case 12:
							deleteCoolText();
						case 13:
							addMoreText('Friday');
						case 14:
							addMoreText('Night');
						case 15:
							addMoreText('Funkin');
						case 16:
							skipIntro();
					}
				}
			}
			lastBeat = curBeat;
		}
		if (skippedIntro)
		{
			if (cheatActive && curBeat % 2 == 0)
				swagShader.update(0.125);

			logoBl.animation.play('bump', true);

			danceLeft = !danceLeft;

			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}
	}

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
