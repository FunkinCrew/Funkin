package funkin;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.audiovis.PolygonSpectogram;

class LatencyState extends MusicBeatSubstate
{
	var offsetText:FlxText;
	var noteGrp:FlxTypedGroup<Note>;
	var strumLine:FlxSprite;

	var block:FlxSprite;

	override function create()
	{
		FlxG.sound.playMusic(Paths.sound('soundTest'));

		noteGrp = new FlxTypedGroup<Note>();
		add(noteGrp);

		var musSpec:PolygonSpectogram = new PolygonSpectogram(FlxG.sound.music, FlxColor.RED, FlxG.height, Math.floor(FlxG.height / 2));
		musSpec.x += 170;
		musSpec.scrollFactor.set();
		musSpec.waveAmplitude = 100;
		musSpec.realtimeVisLenght = 0.45;
		// musSpec.visType = FREQUENCIES;
		add(musSpec);

		block = new FlxSprite().makeGraphic(100, 100);
		add(block);

		for (i in 0...32)
		{
			var note:Note = new Note(Conductor.crochet * i, 1);
			noteGrp.add(note);
		}

		offsetText = new FlxText();
		offsetText.screenCenter();
		add(offsetText);

		strumLine = new FlxSprite(FlxG.width / 2, 100).makeGraphic(FlxG.width, 5);
		add(strumLine);

		Conductor.bpm = 120;

		super.create();
	}

	override function beatHit()
	{
		block.visible = !block.visible;

		super.beatHit();
	}

	override function update(elapsed:Float)
	{
		offsetText.text = "Offset: " + Conductor.offset + "ms";

		Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;

		var multiply:Float = 1;

		if (FlxG.keys.pressed.SHIFT)
			multiply = 10;

		if (FlxG.keys.justPressed.RIGHT)
			Conductor.offset += 1 * multiply;
		if (FlxG.keys.justPressed.LEFT)
			Conductor.offset -= 1 * multiply;

		if (FlxG.keys.justPressed.SPACE)
		{
			FlxG.sound.music.stop();

			FlxG.resetState();
		}

		noteGrp.forEach(function(daNote:Note)
		{
			daNote.y = (strumLine.y - (Conductor.songPosition - daNote.data.strumTime) * 0.45);
			daNote.x = strumLine.x + 30;

			if (daNote.y < strumLine.y)
				daNote.alpha = 0.5;

			if (daNote.y < 0 - daNote.height)
			{
				daNote.alpha = 1;
				// daNote.data.strumTime += Conductor.crochet * 8;
			}
		});

		super.update(elapsed);
	}
}
