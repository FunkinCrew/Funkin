package funkin;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.audiovis.PolygonSpectogram;

class LatencyState extends MusicBeatSubstate
{
	var offsetText:FlxText;
	var noteGrp:FlxTypedGroup<Note>;
	var strumLine:FlxSprite;

	var blocks:FlxGroup;

	var songPosVis:FlxSprite;

	var beatTrail:FlxSprite;

	override function create()
	{
		FlxG.sound.playMusic(Paths.sound('soundTest'));
		Conductor.bpm = 120;

		noteGrp = new FlxTypedGroup<Note>();
		add(noteGrp);

		// var musSpec:PolygonSpectogram = new PolygonSpectogram(FlxG.sound.music, FlxColor.RED, FlxG.height, Math.floor(FlxG.height / 2));
		// musSpec.x += 170;
		// musSpec.scrollFactor.set();
		// musSpec.waveAmplitude = 100;
		// musSpec.realtimeVisLenght = 0.45;
		// // musSpec.visType = FREQUENCIES;
		// add(musSpec);

		for (beat in 0...Math.floor(FlxG.sound.music.length / Conductor.crochet))
		{
			var beatTick:FlxSprite = new FlxSprite(songPosToX(beat * Conductor.crochet), FlxG.height - 15);
			beatTick.makeGraphic(2, 15);
			beatTick.alpha = 0.3;
			add(beatTick);
		}

		songPosVis = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.RED);
		add(songPosVis);

		beatTrail = new FlxSprite(0, songPosVis.y).makeGraphic(2, 20, FlxColor.PURPLE);
		beatTrail.alpha = 0.7;
		add(beatTrail);

		blocks = new FlxGroup();
		add(blocks);

		for (i in 0...8)
		{
			var block = new FlxSprite(2, 50 * i).makeGraphic(48, 48);
			block.visible = false;
			blocks.add(block);
		}

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

		super.create();
	}

	override function beatHit()
	{
		beatTrail.x = songPosVis.x;

		if (curBeat % 8 == 0)
			blocks.forEach(blok ->
			{
				blok.visible = false;
			});

		blocks.members[curBeat % 8].visible = true;
		// block.visible = !block.visible;

		super.beatHit();
	}

	override function update(elapsed:Float)
	{
		songPosVis.x = songPosToX(Conductor.songPosition);

		offsetText.text = "Offset: " + Conductor.visualOffset + "ms";
		offsetText.text += "\ncurStep: " + curStep;
		offsetText.text += "\ncurBeat: " + curBeat;

		Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;

		var multiply:Float = 10;

		if (FlxG.keys.pressed.SHIFT)
			multiply = 1;

		if (FlxG.keys.justPressed.RIGHT)
		{
			Conductor.visualOffset += 1 * multiply;
		}

		if (FlxG.keys.justPressed.LEFT)
		{
			Conductor.visualOffset -= 1 * multiply;
		}

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

	function songPosToX(pos:Float):Float
	{
		return FlxMath.remapToRange(pos, 0, FlxG.sound.music.length, 0, FlxG.width);
	}
}
