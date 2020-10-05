package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

class PlayState extends FlxTransitionableState
{
	public static var curLevel:String = 'Bopeebo';

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;
	private var vocals:FlxSound;

	private var totalBeats:Int = 0;
	private var totalSteps:Int = 0;

	private var dad:Dad;
	private var gf:Girlfriend;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var sectionScores:Array<Dynamic> = [[], []];
	private var sectionLengths:Array<Int> = [];

	private var camFollow:FlxObject;
	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var countingDown:Bool = false;

	private var healthHeads:FlxSprite;

	override public function create()
	{
		persistentUpdate = true;
		persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(AssetPaths.stageback__png);
		// bg.setGraphicSize(Std.int(bg.width * 2.5));
		// bg.updateHitbox();
		bg.antialiasing = true;
		bg.scrollFactor.set(0.9, 0.9);
		bg.active = false;
		add(bg);

		var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(AssetPaths.stagefront__png);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = true;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		add(stageFront);

		var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(AssetPaths.stagecurtains__png);
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.antialiasing = true;
		stageCurtains.scrollFactor.set(1.3, 1.3);
		stageCurtains.active = false;

		gf = new Girlfriend(400, 130);
		gf.scrollFactor.set(0.95, 0.95);
		gf.antialiasing = true;
		add(gf);

		dad = new Dad(100, 100);
		add(dad);

		boyfriend = new Boyfriend(770, 450);
		add(boyfriend);

		add(stageCurtains);

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		var swagCounter:Int = 0;

		generateSong(curLevel.toLowerCase());
		countingDown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play('assets/sounds/intro3.mp3', 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic('assets/images/ready.png');
					ready.scrollFactor.set();
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro2.mp3', 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic('assets/images/set.png');
					set.scrollFactor.set();
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro1.mp3', 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic('assets/images/go.png');
					go.scrollFactor.set();
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/introGo.mp3', 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = 1.05;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(AssetPaths.healthBar__png);
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		healthHeads = new FlxSprite();
		var headTex = FlxAtlasFrames.fromSparrow(AssetPaths.healthHeads__png, AssetPaths.healthHeads__xml);
		healthHeads.frames = headTex;
		healthHeads.animation.add('healthy', [0]);
		healthHeads.animation.add('unhealthy', [1]);
		healthHeads.y = healthBar.y - (healthHeads.height / 2);
		healthHeads.scrollFactor.set();
		add(healthHeads);

		super.create();
	}

	function startSong():Void
	{
		countingDown = false;
		FlxG.sound.playMusic("assets/music/" + curLevel + "_Inst.mp3");
		vocals.play();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		generatedMusic = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		var songData = Json.parse(Assets.getText('assets/data/' + dataPath + '/' + dataPath + '.json'));
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		vocals = new FlxSound().loadEmbedded("assets/music/" + curSong + "_Voices.mp3");
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<Dynamic> = [];

		for (i in 1...songData.sections + 1)
		{
			noteData.push(ChartParser.parse(songData.song.toLowerCase(), i));
		}

		var playerCounter:Int = 0;

		while (playerCounter < 2)
		{
			var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
			var totalLength:Int = 0; // Total length of the song, in beats;
			for (section in noteData)
			{
				var dumbassSection:Array<Dynamic> = section;

				var daStep:Int = 0;
				var coolSection:Int = Std.int(section.length / 4);

				if (coolSection <= 4) // FIX SINCE MOST THE SHIT I MADE WERE ONLY 3 HTINGS LONG LOl
					coolSection = 4;
				else if (coolSection <= 8)
					coolSection = 8;

				for (songNotes in dumbassSection)
				{
					sectionScores[0].push(0);
					sectionScores[1].push(0);

					if (songNotes != 0)
					{
						var daStrumTime:Float = ((daStep * Conductor.stepCrochet) + (Conductor.crochet * 8 * totalLength))
							+ ((Conductor.crochet * coolSection) * playerCounter);

						var oldNote:Note;
						if (unspawnNotes.length > 0)
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						else
							oldNote = null;

						var swagNote:Note = new Note(daStrumTime, songNotes, oldNote);
						swagNote.scrollFactor.set(0, 0);

						unspawnNotes.push(swagNote);

						swagNote.x += ((FlxG.width / 2) * playerCounter); // general offset

						if (playerCounter == 1) // is the player
						{
							swagNote.mustPress = true;
						}
						else
						{
							sectionScores[0][daBeats] += swagNote.noteScore;
						}
					}

					daStep += 1;
				}

				// only need to do it once
				if (playerCounter == 0)
					sectionLengths.push(Math.round(coolSection / 4));
				totalLength += Math.round(coolSection / 4);
				daBeats += 1;
			}

			trace(unspawnNotes.length);
			playerCounter += 1;
		}

		unspawnNotes.sort(sortByShit);
		trace('FIRST NOTE ' + unspawnNotes[0]);
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	var sortedNotes:Bool = false;

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var arrTex = FlxAtlasFrames.fromSparrow(AssetPaths.NOTE_assets__png, AssetPaths.NOTE_assets__xml);
			babyArrow.frames = arrTex;
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.scrollFactor.set();
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
			babyArrow.updateHitbox();
			babyArrow.antialiasing = true;

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i + 1;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}

			switch (Math.abs(i + 1))
			{
				case 1:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 4:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	var sectionScored:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		healthHeads.setGraphicSize(Std.int(FlxMath.lerp(100, healthHeads.width, 0.98)));
		healthHeads.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (healthHeads.width / 2);

		if (healthBar.percent < 10)
			healthHeads.animation.play('unhealthy');
		else
			healthHeads.animation.play('healthy');
		/* 
			if (FlxG.keys.justPressed.NINE)
				FlxG.switchState(new Charting());
			if (FlxG.keys.justPressed.EIGHT)
				FlxG.switchState(new Charting(true));
		 */

		if (countingDown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (Conductor.songPosition >= 0)
				startSong();
		}
		else
			Conductor.songPosition = FlxG.sound.music.time;
		var playerTurn:Int = totalBeats % (sectionLengths[curSection] * 8);

		if (playerTurn == (sectionLengths[curSection] * 8) - 1 && !sectionScored)
		{
			popUpScore();
			sectionScored = true;
		}

		if (playerTurn == 0 && generatedMusic)
		{
			if (camFollow.x != dad.getGraphicMidpoint().x + 150)
				camFollow.setPosition(dad.getGraphicMidpoint().x + 150, dad.getGraphicMidpoint().y - 100);
			vocals.volume = 1;
		}

		if (playerTurn == Std.int((sectionLengths[curSection] * 8) / 2) && camFollow.x != boyfriend.getGraphicMidpoint().x - 100)
		{
			camFollow.setPosition(boyfriend.getGraphicMidpoint().x - 100, boyfriend.getGraphicMidpoint().y - 100);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(1.05, FlxG.camera.zoom, 0.96);
		}

		if (playerTurn < 4)
		{
			sectionScored = false;
		}

		FlxG.watch.addQuick("beatShit", totalBeats);

		if (curSong == 'Fresh')
		{
			switch (totalBeats)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					FlxG.sound.music.stop();
					curLevel = 'Bopeebo';
					FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (totalBeats)
			{
				case 127:
					FlxG.sound.music.stop();
					curLevel = 'Fresh';
					FlxG.switchState(new PlayState());
			}
		}
		everyBeat();
		everyStep();
		// better streaming of shit

		if (health <= 0)
		{
			boyfriend.stunned = true;
			FlxG.switchState(new GameOverState());
		}

		if (unspawnNotes[0] != null)
		{
			FlxG.watch.addQuick('spsa', unspawnNotes[0].strumTime);
			FlxG.watch.addQuick('weed', Conductor.songPosition);

			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					switch (Math.abs(daNote.noteData))
					{
						case 1:
							dad.playAnim('singUP');
						case 2:
							dad.playAnim('singRIGHT');
						case 3:
							dad.playAnim('singDOWN');
						case 4:
							dad.playAnim('singLEFT');
					}

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * 0.45);

				if (daNote.y < -daNote.height)
				{
					if (daNote.tooLate)
					{
						health -= 0.05;
						vocals.volume = 0;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// one time sort
				if (!sortedNotes)
					notes.sort(FlxSort.byY, FlxSort.DESCENDING);
			});
		}

		keyShit();
	}

	private function popUpScore():Void
	{
		boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);
		// var placement:String = sectionScores[1][curSection] + '/' + sectionScores[0][curSection];

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.75;
		//

		var rating:FlxSprite = new FlxSprite();

		var daRating:String = "shit";

		if (combo > 60)
			daRating = 'sick';
		else if (combo > 12)
			daRating = 'good'
		else if (combo > 4)
			daRating = 'bad';
		rating.loadGraphic('assets/images/' + daRating + ".png");
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		rating.antialiasing = true;
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.combo__png);
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.antialiasing = true;
		comboSpr.velocity.y -= 150;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.updateHitbox();
		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(comboSpr);
		add(rating);

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic('assets/images/num' + Std.int(i) + '.png');
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.antialiasing = true;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}

		trace(combo);
		trace(seperatedScore);

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var up = FlxG.keys.anyPressed([W, UP]);
		var right = FlxG.keys.anyPressed([D, RIGHT]);
		var down = FlxG.keys.anyPressed([S, DOWN]);
		var left = FlxG.keys.anyPressed([A, LEFT]);

		var upP = FlxG.keys.anyJustPressed([W, UP]);
		var rightP = FlxG.keys.anyJustPressed([D, RIGHT]);
		var downP = FlxG.keys.anyJustPressed([S, DOWN]);
		var leftP = FlxG.keys.anyJustPressed([A, LEFT]);

		var upR = FlxG.keys.anyJustReleased([W, UP]);
		var rightR = FlxG.keys.anyJustReleased([D, RIGHT]);
		var downR = FlxG.keys.anyJustReleased([S, DOWN]);
		var leftR = FlxG.keys.anyJustReleased([A, LEFT]);

		FlxG.watch.addQuick('asdfa', upP);
		if ((upP || rightP || downP || leftP) && !boyfriend.stunned && generatedMusic)
		{
			var possibleNotes:Array<Note> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
				{
					possibleNotes.push(daNote);
					trace('NOTE-' + daNote.strumTime + ' ADDED');
				}
			});

			if (possibleNotes.length > 0)
			{
				for (daNote in possibleNotes)
				{
					switch (daNote.noteData)
					{
						case 1: // NOTES YOU JUST PRESSED
							if (upP || rightP || downP || leftP)
								noteCheck(upP, daNote);
						case 2:
							if (upP || rightP || downP || leftP)
								noteCheck(rightP, daNote);
						case 3:
							if (upP || rightP || downP || leftP)
								noteCheck(downP, daNote);
						case 4:
							if (upP || rightP || downP || leftP)
								noteCheck(leftP, daNote);
					}

					if (daNote.wasGoodHit)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
			}
			else
			{
				badNoteCheck();
			}
		}

		if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case -1:
							if (up && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case -2:
							if (right && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case -3:
							if (down && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case -4:
							if (left && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
					}
				}
			});
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			switch (spr.ID)
			{
				case 1:
					if (upP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (upR)
						spr.animation.play('static');
				case 2:
					if (rightP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (rightR)
						spr.animation.play('static');
				case 3:
					if (downP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (downR)
						spr.animation.play('static');
				case 4:
					if (leftP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (leftR)
						spr.animation.play('static');
			}

			if (spr.animation.curAnim.name == 'confirm')
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.08;
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			combo = 0;

			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + ".mp3", FlxG.random.float(0.05, 0.2));

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (direction)
			{
				case 1:
					boyfriend.playAnim('singUPmiss', true);
				case 2:
					boyfriend.playAnim('singRIGHTmiss', true);
				case 3:
					boyfriend.playAnim('singDOWNmiss', true);
				case 4:
					boyfriend.playAnim('singLEFTmiss', true);
			}
		}
	}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		var upP = FlxG.keys.anyJustPressed([W, UP]);
		var rightP = FlxG.keys.anyJustPressed([D, RIGHT]);
		var downP = FlxG.keys.anyJustPressed([S, DOWN]);
		var leftP = FlxG.keys.anyJustPressed([A, LEFT]);

		if (leftP)
			noteMiss(4);
		if (upP)
			noteMiss(1);
		if (rightP)
			noteMiss(2);
		if (downP)
			noteMiss(3);
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		trace(note.noteData + ' note check here ' + keyP);
		if (keyP)
			goodNoteHit(note);
		else
			badNoteCheck();
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			combo += 1;

			if (note.noteData > 0)
				health += 0.03;
			else
				health += 0.007;

			switch (Math.abs(note.noteData))
			{
				case 1:
					boyfriend.playAnim('singUP');
				case 2:
					boyfriend.playAnim('singRIGHT');
				case 3:
					boyfriend.playAnim('singDOWN');
				case 4:
					boyfriend.playAnim('singLEFT');
			}

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			sectionScores[1][curSection] += note.noteScore;
			note.wasGoodHit = true;
			vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	private function everyBeat():Void
	{
		if (Conductor.songPosition > lastBeat + Conductor.crochet - Conductor.safeZoneOffset
			|| Conductor.songPosition < lastBeat + Conductor.safeZoneOffset)
		{
			if (Conductor.songPosition > lastBeat + Conductor.crochet)
			{
				lastBeat += Conductor.crochet;

				if (camZooming && FlxG.camera.zoom < 1.35 && totalBeats % 4 == 0)
					FlxG.camera.zoom += 0.025;

				totalBeats += 1;

				dad.playAnim('idle');
				healthHeads.setGraphicSize(Std.int(healthHeads.width + 20));

				if (totalBeats % gfSpeed == 0)
					gf.dance();

				if (!boyfriend.animation.curAnim.name.startsWith("sing"))
					boyfriend.playAnim('idle');
			}
		}
	}

	private function everyStep():Void
	{
		if (Conductor.songPosition > lastStep + Conductor.stepCrochet - Conductor.safeZoneOffset
			|| Conductor.songPosition < lastStep + Conductor.safeZoneOffset)
		{
			if (Conductor.songPosition > lastStep + Conductor.stepCrochet)
			{
				totalSteps += 1;
				lastStep += Conductor.stepCrochet;
			}
		}
	}
}
