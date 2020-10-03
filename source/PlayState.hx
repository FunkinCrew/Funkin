package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import haxe.Json;
import lime.utils.Assets;

class PlayState extends FlxState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var canHit:Bool = false;

	private var totalBeats:Int = 0;

	private var canHitText:FlxText;

	private var dad:FlxSprite;
	private var boyfriend:FlxSprite;

	private var notes:FlxTypedGroup<Note>;

	private var strumLine:FlxSprite;

	override public function create()
	{
		dad = new FlxSprite(100, 100).loadGraphic(AssetPaths.DADDY_DEAREST__png);
		add(dad);

		boyfriend = new FlxSprite(470, 100).loadGraphic(AssetPaths.BOYFRIEND__png);
		add(boyfriend);

		generateSong('assets/data/bopeebo.json');

		canHitText = new FlxText(10, 10, 0, "weed");

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		add(strumLine);

		super.create();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		var songData = Json.parse(Assets.getText(dataPath));
		FlxG.sound.playMusic("assets/music/" + songData.song + ".mp3");

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<Dynamic> = songData.data;

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
					if (songNotes != 0)
					{
						var daStrumTime:Float = (((daStep * Conductor.stepCrochet) + (Conductor.crochet * 8 * daBeats))
							+ ((Conductor.crochet * 4) * playerCounter));

						var swagNote:Note = new Note(daStrumTime, songNotes);

						swagNote.x += ((FlxG.width / 2) * playerCounter); // general offset

						if (playerCounter == 1) // is the player
						{
							swagNote.mustPress = true;
						}

						if (notes.members.length > 0)
							swagNote.prevNote = notes.members[notes.members.length - 1];
						else
							swagNote.prevNote = swagNote;

						trace(notes.members.length - 1);

						notes.add(swagNote);
					}

					daStep += 1;
				}

				daBeats += 1;
			}

			playerCounter += 1;
		}
	}

	var bouncingSprite:FlxSprite;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;
		var playerTurn:Int = totalBeats % 8;

		if (playerTurn < 4)
			bouncingSprite = dad;
		else
			bouncingSprite = boyfriend;

		if (bouncingSprite.scale.x < 1)
		{
			bouncingSprite.setGraphicSize(Std.int(bouncingSprite.width + (FlxG.elapsed * 2)));
		}

		canHitText.visible = canHit;
		canHitText.text = 'WWEED' + debugNum;

		FlxG.watch.addQuick("beatShit", playerTurn);

		everyBeat();
		everyStep();

		notes.forEach(function(daNote:Note)
		{
			daNote.y = (strumLine.y + 5 - (daNote.height / 2)) - ((Conductor.songPosition - daNote.strumTime) * 0.4);
		});

		keyShit();
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
							trace(daNote.prevNote.wasGoodHit);
							if (up && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case -2:
							trace(daNote.prevNote.wasGoodHit);
							if (right && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case -3:
							trace(daNote.prevNote.wasGoodHit);
							if (down && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case -4:
							trace(daNote.prevNote.wasGoodHit);
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
		note.wasGoodHit = true;
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

				bouncingSprite.setGraphicSize(Std.int(bouncingSprite.width * 0.9));
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
				lastStep += Conductor.stepCrochet;
				canHitText.text += "\nWEED\nWEED";
			}
		}
		else
			canHit = false;
	}
}
