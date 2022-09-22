package funkin.play;

import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import funkin.audiovis.PolygonSpectogram;
import funkin.noteStuff.NoteBasic.NoteData;

class PicoFight extends MusicBeatState
{
	var picoHealth:Float = 1;
	var darnellHealth:Float = 1;

	var pico:Fighter;
	var darnell:Fighter;
	var darnellGhost:Fighter;

	var nextHitTmr:FlxSprite;

	var funnyWave:PolygonSpectogram;

	var noteQueue:Array<NoteData> = [];
	var noteSpawner:FlxTypedGroup<FlxSprite>;

	override function create()
	{
		Paths.setCurrentLevel("weekend1");

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height);
		bg.scrollFactor.set();
		add(bg);

		FlxG.sound.playMusic(Paths.inst("blazin"));

		SongLoad.loadFromJson('blazin', "blazin");
		Conductor.forceBPM(SongLoad.songData.bpm);

		for (dumbassSection in SongLoad.songData.noteMap['hard'])
		{
			for (noteStuf in dumbassSection.sectionNotes)
			{
				noteQueue.push(noteStuf);
				trace(noteStuf);
			}
		}

		funnyWave = new PolygonSpectogram(FlxG.sound.music, FlxColor.RED, FlxG.height);
		funnyWave.x = (FlxG.width / 2);
		funnyWave.realtimeVisLenght = 0.6;
		add(funnyWave);

		noteSpawner = new FlxTypedGroup<FlxSprite>();
		add(noteSpawner);

		makeNotes();

		nextHitTmr = new FlxSprite((FlxG.width / 2) - 5).makeGraphic(10, FlxG.height, FlxColor.BLACK);
		add(nextHitTmr);

		var trailShit:FlxTrail = new FlxTrail(nextHitTmr);
		add(trailShit);

		pico = new Fighter(0, 300, "pico-fighter");
		add(pico);

		darnell = new Fighter(0, 300, "darnell-fighter");
		add(darnell);

		darnellGhost = new Fighter(0, 300, "darnell-fighter");
		darnellGhost.alpha = 0.5;
		add(darnellGhost);

		mid = (FlxG.width / 2) - (pico.width / 2);
		resetPositions();

		// fuk u, hardcoded bullshit bitch

		super.create();
	}

	function makeNotes()
	{
		for (notes in noteQueue)
		{
			if (notes.strumTime < Conductor.songPosition + (Conductor.crochet * 4))
			{
				spawnNote(notes);
				spawnNote(notes, FlxDirectionFlags.RIGHT);
			}
		}
	}

	function spawnNote(note:NoteData, facing:Int = FlxDirectionFlags.LEFT)
	{
		var spr:FlxSprite = new FlxSprite(0, (FlxG.height / 2) - 60).makeGraphic(10, 120, Note.codeColors[note.noteData]);
		spr.ID = Std.int(note.strumTime); // using ID as strum, lol!
		spr.facing = facing;
		noteSpawner.add(spr);
	}

	var mid:Float = (FlxG.width * 0.5) - 200;

	function resetPositions()
	{
		resetPicoPos();
		resetDarnell();
	}

	function resetPicoPos()
	{
		pico.x = mid + pico.width;
	}

	function resetDarnell()
	{
		darnell.x = mid - darnell.width;
	}

	var prevNoteHit:Float = 0;

	override function update(elapsed:Float)
	{
		darnellGhost.x = darnell.x;

		Conductor.songPosition = FlxG.sound.music.time;

		funnyWave.thickness = CoolUtil.coolLerp(funnyWave.thickness, 2, 0.5);
		funnyWave.waveAmplitude = Std.int(CoolUtil.coolLerp(funnyWave.waveAmplitude, 100, 0.1));
		funnyWave.realtimeVisLenght = CoolUtil.coolLerp(funnyWave.realtimeVisLenght, 0.6, 0.1);

		noteSpawner.forEachAlive((nt:FlxSprite) ->
		{
			// i forget how to make rhythm games
			nt.x = (nt.ID - Conductor.songPosition) * (nt.ID / (Conductor.songPosition * 0.8));

			if (nt.facing == FlxDirectionFlags.RIGHT)
			{
				nt.x = FlxMath.remapToRange(nt.x, 0, FlxG.width, FlxG.width, 0);
				nt.x -= FlxG.width / 2;
			}
			else
			{
				nt.x += FlxG.width / 2;
			}

			nt.scale.x = FlxMath.remapToRange(nt.ID - Conductor.songPosition, 0, Conductor.crochet * 3, 0.2, 2);
			nt.scale.y = FlxMath.remapToRange((nt.ID - Conductor.songPosition), 0, Conductor.crochet * 2, 6, 0.2);

			if (nt.ID < Conductor.songPosition)
				nt.kill();
		});

		if (noteQueue.length > 0)
		{
			nextHitTmr.scale.y = FlxMath.remapToRange(Conductor.songPosition, prevNoteHit, noteQueue[0].strumTime, 1, 0);

			darnellGhost.scale.x = darnellGhost.scale.y = FlxMath.remapToRange(Conductor.songPosition, prevNoteHit, noteQueue[0].strumTime, 2, 1);
			darnellGhost.alpha = FlxMath.remapToRange(Conductor.songPosition, prevNoteHit, noteQueue[0].strumTime, 0.3, 0.1);

			if (Conductor.songPosition >= noteQueue[0].strumTime)
			{
				prevNoteHit = noteQueue[0].strumTime;

				noteQueue.shift();

				darnell.doSomething(darnellGhost.curAction);

				darnellGhost.doSomething();
				darnellGhost.animation.curAnim.frameRate = 12;
			}
		}

		if (controls.NOTE_LEFT_P)
		{
			pico.punch();
		}
		if (controls.NOTE_LEFT_R)
			pico.playAnimation('idle');

		super.update(elapsed);
	}

	override function stepHit():Bool
	{
		return super.stepHit();
	}

	override function beatHit():Bool
	{
		// super.beatHit() returns false if a module cancelled the event.
		if (!super.beatHit())
			return false;

		funnyWave.thickness = 10;
		funnyWave.waveAmplitude = 300;
		funnyWave.realtimeVisLenght = 0.1;

		picoHealth += 1;

		makeNotes();
		return true;
	}
}
