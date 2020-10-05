package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

class PlayState extends FlxState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;
	private var vocals:FlxSound;

	private var canHit:Bool = false;

	private var totalBeats:Int = 0;
	private var totalSteps:Int = 0;

	private var canHitText:FlxText;

	private var dad:Dad;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var sectionScores:Array<Dynamic> = [[], []];
	private var sectionLengths:Array<Int> = [];

	private var camFollow:FlxObject;
	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	override public function create()
	{
		var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(AssetPaths.bg__png);
		bg.setGraphicSize(Std.int(bg.width * 2.5));
		bg.updateHitbox();
		bg.antialiasing = true;
		bg.scrollFactor.set(0.9, 0.9);
		add(bg);

		dad = new Dad(100, 100);

		add(dad);

		boyfriend = new Boyfriend(770, 450);
		add(boyfriend);

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		generateSong('fresh');

		canHitText = new FlxText(10, 10, 0, "weed");

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = 1.05;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		super.create();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		generateStaticArrows(0);
		generateStaticArrows(1);

		var songData = Json.parse(Assets.getText('assets/data/' + dataPath + '/' + dataPath + '.json'));
		Conductor.changeBPM(songData.bpm);
		FlxG.sound.playMusic("assets/music/" + songData.song + "_Inst.mp3");

		vocals = new FlxSound().loadEmbedded("assets/music/" + songData.song + "_Voices.mp3");
		FlxG.sound.list.add(vocals);
		vocals.play();

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
						if (notes.members.length > 0)
							oldNote = notes.members[notes.members.length - 1];
						else
							oldNote = null;

						var swagNote:Note = new Note(daStrumTime, songNotes, oldNote);
						swagNote.scrollFactor.set(0, 0);

						swagNote.x += ((FlxG.width / 2) * playerCounter); // general offset

						if (playerCounter == 1) // is the player
						{
							swagNote.mustPress = true;
						}
						else
						{
							sectionScores[0][daBeats] += swagNote.noteScore;
						}

						notes.add(swagNote);
					}

					daStep += 1;
				}

				// only need to do it once
				if (playerCounter == 0)
					sectionLengths.push(Math.round(coolSection / 4));
				totalLength += Math.round(coolSection / 4);
				daBeats += 1;
			}

			playerCounter += 1;
		}
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

		if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting());
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new Charting(true));

		Conductor.songPosition = FlxG.sound.music.time;
		var playerTurn:Int = totalBeats % (sectionLengths[curSection] * 8);

		if (playerTurn == (sectionLengths[curSection] * 8) - 1 && !sectionScored)
		{
			popUpScore();
			sectionScored = true;
		}

		if (playerTurn == 0)
		{
			camFollow.setPosition(dad.getGraphicMidpoint().x + 150, dad.getGraphicMidpoint().y - 100);
			vocals.volume = 1;
		}

		if (playerTurn == Std.int((sectionLengths[curSection] * 8) / 2))
		{
			camFollow.setPosition(boyfriend.getGraphicMidpoint().x - 100, boyfriend.getGraphicMidpoint().y - 100);
		}

		if (playerTurn < 4)
		{
			sectionScored = false;
		}

		FlxG.watch.addQuick("beatShit", playerTurn);

		everyBeat();
		everyStep();

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

			if (daNote.y < -daNote.height)
			{
				if (daNote.tooLate)
					vocals.volume = 0;

				daNote.kill();
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
			}

			daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * 0.45);

			// one time sort
			if (!sortedNotes)
				notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		});

		keyShit();
	}

	private function popUpScore():Void
	{
		boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = sectionScores[1][curSection] + '/' + sectionScores[0][curSection];
		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.75;
		add(coolText);

		FlxTween.tween(coolText, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.kill();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	function keyShit():Void
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
		if ((upP || rightP || downP || leftP) && !boyfriend.stunned)
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
					}
				}
			}
			else
			{
				badNoteCheck();
			}
		}

		if ((up || right || down || left) && boyfriend.stunned)
		{
			var possibleNotes:Array<Note> = [];

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
			trace('badNote');
			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + ".mp3", 0.2);

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
			trace('goodhit');

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
		}
	}

	function everyBeat():Void
	{
		if (Conductor.songPosition > lastBeat + Conductor.crochet - Conductor.safeZoneOffset
			|| Conductor.songPosition < lastBeat + Conductor.safeZoneOffset)
		{
			if (Conductor.songPosition > lastBeat + Conductor.crochet)
			{
				lastBeat += Conductor.crochet;
				canHitText.text += "\nWEED\nWEED";

				totalBeats += 1;

				dad.animation.play('idle');

				if (!boyfriend.animation.curAnim.name.startsWith("sing"))
					boyfriend.playAnim('idle');
			}
		}
	}

	function everyStep()
	{
		if (Conductor.songPosition > lastStep + Conductor.stepCrochet - Conductor.safeZoneOffset
			|| Conductor.songPosition < lastStep + Conductor.safeZoneOffset)
		{
			canHit = true;

			if (Conductor.songPosition > lastStep + Conductor.stepCrochet)
			{
				totalSteps += 1;
				lastStep += Conductor.stepCrochet;
				canHitText.text += "\nWEED\nWEED";
			}
		}
		else
			canHit = false;
	}
}
