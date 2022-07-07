package funkin;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.audiovis.PolygonSpectogram;
import openfl.events.KeyboardEvent;

class LatencyState extends MusicBeatSubstate
{
	var offsetText:FlxText;
	var noteGrp:FlxTypedGroup<Note>;
	var strumLine:FlxSprite;

	var blocks:FlxGroup;

	var songPosVis:FlxSprite;
	var songVisFollowVideo:FlxSprite;
	var songVisFollowAudio:FlxSprite;

	var beatTrail:FlxSprite;
	var diffGrp:FlxTypedGroup<FlxText>;

	override function create()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, key ->
		{
			trace("EVENT PRESS: " + FlxG.sound.music.time + " " + Sys.time());
			// trace("EVENT LISTENER: " + key);
		});

		FlxG.sound.playMusic(Paths.sound('soundTest'));
		Conductor.bpm = 60;

		noteGrp = new FlxTypedGroup<Note>();
		add(noteGrp);

		diffGrp = new FlxTypedGroup<FlxText>();
		add(diffGrp);

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

			var offsetTxt:FlxText = new FlxText(songPosToX(beat * Conductor.crochet), FlxG.height - 26, 0, "swag");
			offsetTxt.alpha = 0.5;
			diffGrp.add(offsetTxt);
		}

		songVisFollowAudio = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.YELLOW);
		add(songVisFollowAudio);

		songVisFollowVideo = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.BLUE);
		add(songVisFollowVideo);

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
		if (FlxG.keys.justPressed.S)
		{
			trace("UPDATE PRESS: " + FlxG.sound.music.time + " " + Sys.time());
		}

		if (FlxG.keys.justPressed.X)
		{
			var closestBeat:Int = Math.round(Conductor.songPosition / Conductor.crochet);
			var getDiff:Float = Conductor.songPosition - (closestBeat * Conductor.crochet);
			getDiff -= Conductor.visualOffset;

			trace("\tDISTANCE TO CLOSEST BEAT: " + getDiff + "ms");
			trace("\tCLOSEST BEAT: " + closestBeat);
			beatTrail.x = songPosVis.x;
			if (closestBeat < FlxG.sound.music.length / Conductor.crochet)
				diffGrp.members[closestBeat].text = getDiff + "ms";
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music.playing)
				FlxG.sound.music.pause();
			else
				FlxG.sound.music.resume();
		}

		if (FlxG.keys.pressed.D)
			FlxG.sound.music.time += 1000 * FlxG.elapsed;

		Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;

		songPosVis.x = songPosToX(Conductor.songPosition);
		songVisFollowAudio.x = songPosToX(Conductor.songPosition - Conductor.audioOffset);
		songVisFollowVideo.x = songPosToX(Conductor.songPosition - Conductor.visualOffset);

		offsetText.text = "AUDIO Offset: " + Conductor.audioOffset + "ms";
		offsetText.text += "\nVIDOE Offset: " + Conductor.visualOffset + "ms";
		offsetText.text += "\ncurStep: " + curStep;
		offsetText.text += "\ncurBeat: " + curBeat;

		var multiply:Float = 10;

		if (FlxG.keys.pressed.SHIFT)
			multiply = 1;

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.RIGHT)
			{
				Conductor.audioOffset += 1 * multiply;
			}

			if (FlxG.keys.justPressed.LEFT)
			{
				Conductor.audioOffset -= 1 * multiply;
			}
		}
		else
		{
			if (FlxG.keys.justPressed.RIGHT)
			{
				Conductor.visualOffset += 1 * multiply;
			}

			if (FlxG.keys.justPressed.LEFT)
			{
				Conductor.visualOffset -= 1 * multiply;
			}
		}

		/* if (FlxG.keys.justPressed.SPACE)
			{
				FlxG.sound.music.stop();

				FlxG.resetState();
		}*/

		noteGrp.forEach(function(daNote:Note)
		{
			daNote.y = (strumLine.y - ((Conductor.songPosition - Conductor.audioOffset) - daNote.data.strumTime) * 0.45);
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
