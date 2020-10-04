package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
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

	private var dad:FlxSprite;
	private var boyfriend:FlxSprite;

	private var notes:FlxTypedGroup<Note>;

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var sectionScores:Array<Dynamic> = [[], []];

	private var camFollow:FlxObject;

	override public function create()
	{
		dad = new FlxSprite(100, 100).loadGraphic(AssetPaths.DADDY_DEAREST__png);
		var dadTex = FlxAtlasFrames.fromSparrow(AssetPaths.DADDY_DEAREST__png, AssetPaths.DADDY_DEAREST__xml);
		dad.frames = dadTex;
		dad.animation.addByPrefix('idle', 'Dad idle dance', 24);
		dad.animation.addByPrefix('singUP', 'Dad Sing note UP', 24);
		dad.animation.addByPrefix('singRIGHT', 'Dad Sing note UP', 24);
		dad.animation.addByPrefix('singDOWN', 'Dad Sing Note DOWN', 24);
		dad.animation.addByPrefix('singLEFT', 'dad sing note right', 24);
		dad.animation.play('idle');
		add(dad);

		boyfriend = new FlxSprite(770, 450);
		var tex = FlxAtlasFrames.fromSparrow(AssetPaths.BOYFRIEND__png, AssetPaths.BOYFRIEND__xml);
		boyfriend.frames = tex;
		boyfriend.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		boyfriend.animation.addByPrefix('singUP', 'BF NOTE UP', 24, false);
		boyfriend.animation.addByPrefix('singLEFT', 'BF NOTE LEFT', 24, false);
		boyfriend.animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT', 24, false);
		boyfriend.animation.addByPrefix('singDOWN', 'BF NOTE DOWN', 24, false);
		boyfriend.animation.addByPrefix('hey', 'BF HEY', 24, false);
		boyfriend.animation.play('idle');
		add(boyfriend);

		generateSong('assets/data/bopeebo/bopeebo.json');

		canHitText = new FlxText(10, 10, 0, "weed");

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = 1.05;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		super.create();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = Json.parse(Assets.getText(dataPath));
		FlxG.sound.playMusic("assets/music/" + songData.song + "_Inst.mp3");

		vocals = new FlxSound().loadEmbedded("assets/music/" + songData.song + "_Voices.mp3");
		FlxG.sound.list.add(vocals);
		vocals.play();

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<Dynamic> = [];

		for (i in 1...songData.sections + 1)
		{
			trace(i);
			noteData.push(ChartParser.parse(songData.song.toLowerCase(), i));
		}

		var playerCounter:Int = 0;

		while (playerCounter < 2)
		{
			var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
			for (section in noteData)
			{
				var dumbassSection:Array<Dynamic> = section;

				var daStep:Int = 0;

				for (songNotes in dumbassSection)
				{
					sectionScores[0].push(0);
					sectionScores[1].push(0);

					if (songNotes != 0)
					{
						var daStrumTime:Float = (((daStep * Conductor.stepCrochet) + (Conductor.crochet * 8 * daBeats))
							+ ((Conductor.crochet * 4) * playerCounter));

						var swagNote:Note = new Note(daStrumTime, songNotes);
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

						if (notes.members.length > 0)
							swagNote.prevNote = notes.members[notes.members.length - 1];
						else
							swagNote.prevNote = swagNote;

						notes.add(swagNote);
					}

					daStep += 1;
				}

				daBeats += 1;
			}

			playerCounter += 1;
		}
	}

	var sectionScored:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting());

		Conductor.songPosition = FlxG.sound.music.time;
		var playerTurn:Int = totalBeats % 8;

		if (playerTurn == 7 && !sectionScored)
		{
			popUpScore();
			sectionScored = true;
		}

		if (playerTurn == 0)
		{
			camFollow.setPosition(dad.getGraphicMidpoint().x + 150, dad.getGraphicMidpoint().y - 100);
			vocals.volume = 1;
		}

		if (playerTurn == 4)
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
						dad.animation.play('singUP');
					case 2:
						dad.animation.play('singRIGHT');
					case 3:
						dad.animation.play('singDOWN');
					case 4:
						dad.animation.play('singLEFT');
				}

				daNote.kill();
			}

			daNote.y = (strumLine.y + 5 - (daNote.height / 2)) - ((Conductor.songPosition - daNote.strumTime) * 0.4);
		});

		keyShit();
	}

	private function popUpScore():Void
	{
		boyfriend.animation.play('hey');
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

		if (up || right || down || left)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.canBeHit)
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
						case 1: // NOTES YOU JUST PRESSED
							if (upP)
								goodNoteHit(daNote);
						case 2:
							if (rightP)
								goodNoteHit(daNote);
						case 3:
							if (downP)
								goodNoteHit(daNote);
						case 4:
							if (leftP)
								goodNoteHit(daNote);
					}

					if (daNote.wasGoodHit)
					{
						daNote.kill();
					}
				}
			});
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			switch (Math.abs(note.noteData))
			{
				case 1:
					boyfriend.animation.play('singUP');
				case 2:
					boyfriend.animation.play('singRIGHT');
				case 3:
					boyfriend.animation.play('singDOWN');
				case 4:
					boyfriend.animation.play('singLEFT');
			}

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
					boyfriend.animation.play('idle');
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
