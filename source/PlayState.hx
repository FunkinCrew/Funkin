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
	private var safeFrames:Int = 5;
	private var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds
	private var canHit:Bool = false;

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

		safeZoneOffset = (safeFrames / 60) * 1000;

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
						var daStrumTime:Float = (daStep * Conductor.stepCrochet) + ((Conductor.crochet * 4) * playerCounter);

						var swagNote:Note = new Note(daStrumTime, songNotes);

						var swagWidth:Float = 40;

						swagNote.x += (swagWidth * (Math.abs(songNotes))) + ((FlxG.width / 2) * playerCounter);

						if (playerCounter == 2) // is the player
						{
							swagNote.mustPress = true;
						}

						notes.add(swagNote);
					}

					daStep += 1;
				}

				daBeats += 1;
			}

			playerCounter += 1;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;

		if (dad.scale.x > 1)
		{
			dad.setGraphicSize(Std.int(dad.width - (FlxG.elapsed * 2)));
		}

		canHitText.visible = canHit;
		canHitText.text = 'WWEED' + debugNum;

		if (canHit)
		{
			debugNum += 1;
		}
		else
			debugNum = 0;

		everyBeat();
		everyStep();

		notes.forEach(function(daNote:Note)
		{
			daNote.y = (strumLine.y + 5 - (daNote.height / 2)) - ((Conductor.songPosition - daNote.strumTime) * 0.4);
		});
	}

	function everyBeat():Void
	{
		if (Conductor.songPosition > lastBeat + Conductor.crochet - safeZoneOffset || Conductor.songPosition < lastBeat + safeZoneOffset)
		{
			if (Conductor.songPosition > lastBeat + Conductor.crochet)
			{
				lastBeat += Conductor.crochet;
				canHitText.text += "\nWEED\nWEED";

				dad.setGraphicSize(Std.int(dad.width * 1.1));
			}
		}
	}

	function everyStep()
	{
		if (Conductor.songPosition > lastStep + Conductor.stepCrochet - safeZoneOffset
			|| Conductor.songPosition < lastStep + safeZoneOffset)
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
