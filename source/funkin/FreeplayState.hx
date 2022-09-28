package funkin;

import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.Controls.Control;
import funkin.freeplayStuff.BGScrollingText;
import funkin.freeplayStuff.DJBoyfriend;
import funkin.freeplayStuff.FreeplayScore;
import funkin.freeplayStuff.LetterSort;
import funkin.freeplayStuff.SongMenuItem;
import funkin.play.HealthIcon;
import funkin.play.PlayState;
import funkin.shaderslmfao.AngleMask;
import funkin.shaderslmfao.PureColor;
import funkin.shaderslmfao.StrokeShader;
import lime.app.Future;
import lime.utils.Assets;

using StringTools;

class FreeplayState extends MusicBeatSubstate
{
	var songs:Array<SongMetadata> = [];

	// var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var fp:FreeplayScore;
	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	var grpDifficulties:FlxSpriteGroup;

	var coolColors:Array<Int> = [
		0xff9271fd,
		0xff9271fd,
		0xff223344,
		0xFF941653,
		0xFFfc96d7,
		0xFFa0d1ff,
		0xffff78bf,
		0xfff6b604
	];

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpCapsules:FlxTypedGroup<SongMenuItem>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var typing:FlxInputText;

	override function create()
	{
		FlxTransitionableState.skipNextTransIn = true;

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		addSong('Test', 1, 'bf-pixel');
		addSong('Pyro', 4, 'bf');
		#end

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length)
		{
			songs.push(new SongMetadata(initSonglist[i], 1, 'gf'));
		}

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 1, ['dad']);

		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Spookeez', 'South', 'Monster'], 2, ['spooky', 'spooky', 'monster']);

		if (StoryMenuState.weekUnlocked[3] || isDebug)
			addWeek(['Pico', 'Philly', 'Blammed'], 3, ['pico']);

		if (StoryMenuState.weekUnlocked[4] || isDebug)
			addWeek(['Satin-Panties', 'High', 'Milf'], 4, ['mom']);

		if (StoryMenuState.weekUnlocked[5] || isDebug)
			addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 5, ['parents-christmas', 'parents-christmas', 'monster-christmas']);

		if (StoryMenuState.weekUnlocked[6] || isDebug)
			addWeek(['Senpai', 'Roses', 'Thorns'], 6, ['senpai', 'senpai', 'spirit']);

		if (StoryMenuState.weekUnlocked[7] || isDebug)
			addWeek(['Ugh', 'Guns', 'Stress'], 7, ['tankman']);

		addWeek(["Darnell", "lit-up", "2hot"], 8, ['darnell']);
		addWeek(["bro"], 1, ['gf']);

		// LOAD MUSIC

		// LOAD CHARACTERS

		trace(FlxG.width);
		trace(FlxG.camera.zoom);
		trace(FlxG.camera.initialZoom);
		trace(FlxCamera.defaultZoom);
		trace(FlxG.initialZoom);

		var pinkBack:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/pinkBack'));
		pinkBack.color = 0xFFffd4e9; // sets it to pink!
		pinkBack.x -= pinkBack.width;

		FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
		add(pinkBack);

		var orangeBackShit:FlxSprite = new FlxSprite(84, FlxG.height * 0.68).makeGraphic(Std.int(pinkBack.width), 50, 0xFFffd400);
		add(orangeBackShit);

		var alsoOrangeLOL:FlxSprite = new FlxSprite(0, orangeBackShit.y).makeGraphic(100, Std.int(orangeBackShit.height), 0xFFffd400);
		add(alsoOrangeLOL);

		FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
		orangeBackShit.visible = false;
		alsoOrangeLOL.visible = false;

		var grpTxtScrolls:FlxGroup = new FlxGroup();
		add(grpTxtScrolls);
		grpTxtScrolls.visible = false;

		var moreWays:BGScrollingText = new BGScrollingText(0, 200, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width);
		moreWays.funnyColor = 0xFFfff383;
		moreWays.speed = 4;
		grpTxtScrolls.add(moreWays);

		var funnyScroll:BGScrollingText = new BGScrollingText(0, 250, "BOYFRIEND", FlxG.width / 2);
		funnyScroll.funnyColor = 0xFFff9963;
		funnyScroll.speed = -1;
		grpTxtScrolls.add(funnyScroll);

		var txtNuts:BGScrollingText = new BGScrollingText(0, 300, "PROTECT YO NUTS", FlxG.width / 2);
		grpTxtScrolls.add(txtNuts);

		var funnyScroll2:BGScrollingText = new BGScrollingText(0, 340, "BOYFRIEND", FlxG.width / 2);
		funnyScroll2.funnyColor = 0xFFff9963;
		funnyScroll2.speed = -1.2;
		grpTxtScrolls.add(funnyScroll2);

		var moreWays2:BGScrollingText = new BGScrollingText(0, 400, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width);
		moreWays2.funnyColor = 0xFFfff383;
		moreWays2.speed = 4.4;
		grpTxtScrolls.add(moreWays2);

		var funnyScroll3:BGScrollingText = new BGScrollingText(0, orangeBackShit.y, "BOYFRIEND", FlxG.width / 2);
		funnyScroll3.funnyColor = 0xFFff9963;
		funnyScroll3.speed = -0.8;
		grpTxtScrolls.add(funnyScroll3);

		var dj:DJBoyfriend = new DJBoyfriend(0, -100);
		add(dj);

		var bgDad:FlxSprite = new FlxSprite(pinkBack.width * 0.75, 0).loadGraphic(Paths.image('freeplay/freeplayBGdad'));
		bgDad.setGraphicSize(0, FlxG.height);
		bgDad.updateHitbox();
		bgDad.shader = new AngleMask();
		bgDad.visible = false;

		var blackOverlayBullshitLOLXD:FlxSprite = new FlxSprite(FlxG.width).makeGraphic(Std.int(bgDad.width), Std.int(bgDad.height), FlxColor.BLACK);
		add(blackOverlayBullshitLOLXD); // used to mask the text lol!

		add(bgDad);
		FlxTween.tween(blackOverlayBullshitLOLXD, {x: pinkBack.width * 0.75}, 1, {ease: FlxEase.quintOut});

		blackOverlayBullshitLOLXD.shader = bgDad.shader;

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpCapsules = new FlxTypedGroup<SongMenuItem>();
		add(grpCapsules);

		grpDifficulties = new FlxSpriteGroup(-300, 80);
		add(grpDifficulties);

		grpDifficulties.add(new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayEasy')));
		grpDifficulties.add(new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayNorm')));
		grpDifficulties.add(new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayHard')));

		grpDifficulties.group.forEach(function(spr)
		{
			spr.visible = false;
		});

		grpDifficulties.group.members[curDifficulty].visible = true;

		var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
		overhangStuff.y -= overhangStuff.height;
		add(overhangStuff);
		FlxTween.tween(overhangStuff, {y: 0}, 0.3, {ease: FlxEase.quartOut});

		var fnfFreeplay:FlxText = new FlxText(0, 12, 0, "FREEPLAY", 48);
		fnfFreeplay.font = "VCR OSD Mono";
		fnfFreeplay.visible = false;
		var sillyStroke = new StrokeShader(0xFFFFFFFF, 2, 2);
		fnfFreeplay.shader = sillyStroke;
		add(fnfFreeplay);

		fp = new FreeplayScore(420, 40, 100);
		fp.visible = false;
		add(fp);

		dj.animHITsignal.add(function()
		{
			FlxTween.tween(grpDifficulties, {x: 90}, 0.6, {ease: FlxEase.quartOut});

			add(new DifficultySelector(20, grpDifficulties.y - 10, false, controls));
			add(new DifficultySelector(325, grpDifficulties.y - 10, true, controls));

			var letterSort:LetterSort = new LetterSort(300, 100);
			add(letterSort);

			letterSort.changeSelectionCallback = (str) ->
			{
				switch (str)
				{
					case "fav":
						generateSongList({filterType: FAVORITE}, true);
					case "ALL":
						generateSongList(null, true);
					default:
						generateSongList({filterType: STARTSWITH, filterData: str}, true);
				}
			};

			new FlxTimer().start(1 / 24, function(handShit)
			{
				fnfFreeplay.visible = true;
				fp.visible = true;
				fp.updateScore(FlxG.random.int(0, 1000));

				new FlxTimer().start(1.5 / 24, function(bold)
				{
					sillyStroke.width = 0;
					sillyStroke.height = 0;
				});
			});

			pinkBack.color = 0xFFffd863;
			// fnfFreeplay.visible = true;
			bgDad.visible = true;
			orangeBackShit.visible = true;
			alsoOrangeLOL.visible = true;
			grpTxtScrolls.visible = true;
		});

		generateSongList();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		// selector = new FlxText();

		// selector.size = 40;
		// selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			trace(md);
		 */

		var funnyCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		funnyCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(funnyCam);

		typing = new FlxInputText(100, 100);
		add(typing);

		typing.callback = function(txt, action)
		{
			// generateSongList(new EReg(txt.trim(), "ig"));
			trace(action);
		};

		forEach(function(bs)
		{
			bs.cameras = [funnyCam];
		});

		super.create();
	}

	public function generateSongList(?filterStuff:SongFilter, ?force:Bool = false)
	{
		curSelected = 0;

		grpCapsules.clear();

		// var regexp:EReg = regexp;
		var tempSongs:Array<SongMetadata> = songs;

		if (filterStuff != null)
		{
			switch (filterStuff.filterType)
			{
				case STARTSWITH:
					tempSongs = tempSongs.filter(str ->
					{
						return str.songName.toLowerCase().startsWith(filterStuff.filterData);
					});
				case ALL:
				// no filter!
				case FAVORITE:
					tempSongs = tempSongs.filter(str ->
					{
						return str.isFav;
					});
				default:
					// return all on default
			}
		}

		// if (regexp != null)
		// 	tempSongs = songs.filter(item -> regexp.match(item.songName));

		// tempSongs.sort(function(a, b):Int
		// {
		// 	var tempA = a.songName.toUpperCase();
		// 	var tempB = b.songName.toUpperCase();

		// 	if (tempA < tempB)
		// 		return -1;
		// 	else if (tempA > tempB)
		// 		return 1;
		// 	else
		// 		return 0;
		// });

		for (i in 0...tempSongs.length)
		{
			var funnyMenu:SongMenuItem = new SongMenuItem(FlxG.width, (i * 150) + 160, tempSongs[i].songName);
			funnyMenu.targetPos.x = funnyMenu.x;
			funnyMenu.ID = i;
			funnyMenu.alpha = 0.5;
			funnyMenu.songText.visible = false;
			funnyMenu.favIcon.visible = tempSongs[i].isFav;

			fp.updateScore(0);

			new FlxTimer().start((1 / 24) * i, function(doShit)
			{
				funnyMenu.doJumpIn = true;
			});

			new FlxTimer().start((0.09 * i) + 0.85, function(lerpTmr)
			{
				funnyMenu.doLerp = true;
			});

			if (!force)
			{
				new FlxTimer().start(((0.20 * i) / (1 + i)) + 0.75, function(swagShi)
				{
					funnyMenu.songText.visible = true;
					funnyMenu.alpha = 1;
				});
			}
			else
			{
				funnyMenu.songText.visible = true;
				funnyMenu.alpha = 1;
			}

			grpCapsules.add(funnyMenu);

			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, tempSongs[i].songName, true, false);
			songText.x += 100;
			songText.isMenuItem = true;
			songText.targetY = i;

			// grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(tempSongs[i].songCharacter);
			// icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			// add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		changeSelection();
		changeDiff();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	var touchY:Float = 0;
	var touchX:Float = 0;
	var dxTouch:Float = 0;
	var dyTouch:Float = 0;
	var velTouch:Float = 0;

	var veloctiyLoopShit:Float = 0;
	var touchTimer:Float = 0;

	var initTouchPos:FlxPoint = new FlxPoint();

	var spamTimer:Float = 0;
	var spamming:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F)
		{
			var realShit = curSelected;
			songs[curSelected].isFav = !songs[curSelected].isFav;
			if (songs[curSelected].isFav)
			{
				
				FlxTween.tween(grpCapsules.members[realShit], {angle: 360}, 0.4, {
					ease: FlxEase.elasticOut,
					onComplete: _ ->
					{
						grpCapsules.members[realShit].favIcon.visible = true;
						grpCapsules.members[realShit].favIcon.animation.play("fav");
					}
				});
			}
			else
			{
				grpCapsules.members[realShit].favIcon.animation.play('fav', false, true);
				new FlxTimer().start((1 / 24) * 14, _ ->
				{
					grpCapsules.members[realShit].favIcon.visible = false;
				});
				new FlxTimer().start((1 / 24) * 24, _ ->
				{
					FlxTween.tween(grpCapsules.members[realShit], {angle: 0}, 0.4, {ease: FlxEase.elasticOut});
				});
			}
		}

		if (FlxG.keys.justPressed.T)
			typing.hasFocus = true;

		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * elapsed;
			}
		}

		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.2);

		fp.scoreShit = Std.int(lerpScore);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (FlxG.onMobile)
		{
			for (touch in FlxG.touches.list)
			{
				if (touch.justPressed)
				{
					initTouchPos.set(touch.screenX, touch.screenY);
				}
				if (touch.pressed)
				{
					var dx = initTouchPos.x - touch.screenX;
					var dy = initTouchPos.y - touch.screenY;

					var angle = Math.atan2(dy, dx);
					var length = Math.sqrt(dx * dx + dy * dy);

					FlxG.watch.addQuick("LENGTH", length);
					FlxG.watch.addQuick("ANGLE", Math.round(FlxAngle.asDegrees(angle)));
					trace("ANGLE", Math.round(FlxAngle.asDegrees(angle)));
				}

				/* switch (inputID)
					{
						case FlxObject.UP:
							return
						case FlxObject.DOWN:
					}
				 */
			}

			if (FlxG.touches.getFirst() != null)
			{
				if (touchTimer >= 1.5)
					accepted = true;

				touchTimer += elapsed;
				var touch:FlxTouch = FlxG.touches.getFirst();

				velTouch = Math.abs((touch.screenY - dyTouch)) / 50;

				dyTouch = touch.screenY - touchY;
				dxTouch = touch.screenX - touchX;

				if (touch.justPressed)
				{
					touchY = touch.screenY;
					dyTouch = 0;
					velTouch = 0;

					touchX = touch.screenX;
					dxTouch = 0;
				}

				if (Math.abs(dxTouch) >= 100)
				{
					touchX = touch.screenX;
					if (dxTouch != 0)
						dxTouch < 0 ? changeDiff(1) : changeDiff(-1);
				}

				if (Math.abs(dyTouch) >= 100)
				{
					touchY = touch.screenY;

					if (dyTouch != 0)
						dyTouch < 0 ? changeSelection(1) : changeSelection(-1);
					// changeSelection(1);
				}
			}
			else
			{
				touchTimer = 0;
			}
		}

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				// accepted = true;
			}
		}
		#end

		if (controls.UI_UP || controls.UI_DOWN)
		{
			spamTimer += elapsed;

			if (spamming)
			{
				if (spamTimer >= 0.07)
				{
					spamTimer = 0;

					if (controls.UI_UP)
						changeSelection(-1);
					else
						changeSelection(1);
				}
			}
			else if (spamTimer >= 0.9)
				spamming = true;
		}
		else
		{
			spamming = false;
			spamTimer = 0;
		}

		if (upP)
			changeSelection(-1);
		if (downP)
			changeSelection(1);

		if (FlxG.mouse.wheel != 0)
			changeSelection(-Math.round(FlxG.mouse.wheel / 4));

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK && !typing.hasFocus)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));

			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			// if (Assets.exists())

			var poop:String = songs[curSelected].songName.toLowerCase();

			// does not work properly, always just accidentally sets it to normal anyways!
			/* if (!Assets.exists(Paths.json(songs[curSelected].songName + '/' + poop)))
				{
					// defaults to normal if HARD / EASY doesn't exist
					// does not account if NORMAL doesn't exist!
					FlxG.log.warn("CURRENT DIFFICULTY IS NOT CHARTED, DEFAULTING TO NORMAL!");
					poop = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), 1);
					curDifficulty = 1;
			}*/

			PlayState.currentSong = SongLoad.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			// SongLoad.curDiff = Highscore.formatSong()

			SongLoad.curDiff = switch (curDifficulty)
			{
				case 0:
					'easy';
				case 1:
					'normal';
				case 2:
					'hard';
				default: 'normal';
			};

			PlayState.storyWeek = songs[curSelected].week;
			trace(' CUR WEEK ' + PlayState.storyWeek);
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	override function switchTo(nextState:FlxState):Bool
	{
		clearDaCache(songs[curSelected].songName);
		return super.switchTo(nextState);
	}

	function changeDiff(change:Int = 0)
	{
		touchTimer = 0;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		// intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		PlayState.storyDifficulty = curDifficulty;

		grpDifficulties.group.forEach(function(spr)
		{
			spr.visible = false;
		});

		var curShit:FlxSprite = grpDifficulties.group.members[curDifficulty];

		curShit.visible = true;
		curShit.offset.y += 5;
		curShit.alpha = 0.5;
		new FlxTimer().start(1 / 24, function(swag)
		{
			curShit.alpha = 1;
			curShit.updateHitbox();
		});
	}

	// Clears the cache of songs, frees up memory, they' ll have to be loaded in later tho function clearDaCache(actualSongTho:String)
	function clearDaCache(actualSongTho:String)
	{
		for (song in songs)
		{
			if (song.songName != actualSongTho)
			{
				trace('trying to remove: ' + song.songName);
				// openfl.Assets.cache.clear(Paths.inst(song.songName));
			}
		}
	}

	function changeSelection(change:Int = 0)
	{
		// fp.updateScore(12345);

		NGio.logEvent('Fresh');

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpCapsules.members.length - 1;
		if (curSelected >= grpCapsules.members.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		// intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedScore = FlxG.random.int(0, 1000000);
		// lerpScore = 0;

		#if PRELOAD_ALL
		// FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (index => capsule in grpCapsules.members)
		{
			capsule.selected = false;

			capsule.targetPos.y = ((index - curSelected) * 150) + 160;
			capsule.targetPos.x = 270 + (60 * (Math.sin(index - curSelected)));
			// capsule.targetPos.x = 320 + (40 * (index - curSelected));

			if (index < curSelected)
				capsule.targetPos.y -= 100; // another 100 for good measure
		}

		if (grpCapsules.members.length > 0)
			grpCapsules.members[curSelected].selected = true;
	}
}

class DifficultySelector extends FlxSprite
{
	var controls:Controls;
	var whiteShader:PureColor;

	public function new(x:Float, y:Float, flipped:Bool, controls:Controls)
	{
		super(x, y);

		this.controls = controls;

		frames = Paths.getSparrowAtlas('freeplay/freeplaySelector');
		animation.addByPrefix('shine', "arrow pointer loop", 24);
		animation.play('shine');

		whiteShader = new PureColor(FlxColor.WHITE);

		shader = whiteShader;

		flipX = flipped;
	}

	override function update(elapsed:Float)
	{
		if (flipX && controls.UI_RIGHT_P)
			moveShitDown();
		if (!flipX && controls.UI_LEFT_P)
			moveShitDown();

		super.update(elapsed);
	}

	function moveShitDown()
	{
		offset.y -= 5;

		whiteShader.colorSet = true;

		new FlxTimer().start(2 / 24, function(tmr)
		{
			whiteShader.colorSet = false;
			updateHitbox();
		});
	}
}

typedef SongFilter =
{
	var filterType:FilterType;
	var ?filterData:Dynamic;
}

enum abstract FilterType(String)
{
	var STARTSWITH;
	var FAVORITE;
	var ALL;
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var isFav:Bool = false;

	public function new(song:String, week:Int, songCharacter:String, ?isFav:Bool = false)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.isFav = isFav;
	}
}
