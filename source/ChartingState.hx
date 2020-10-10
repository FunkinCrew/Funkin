package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;
	var sequencer:FlxTypedGroup<DisplayNote>;
	var notes:Array<Dynamic> = [];
	var bpmTxt:FlxText;

	var strumLine:FlxSprite;

	override function create()
	{
		FlxG.sound.playMusic('assets/music/Fresh.mp3', 0.6);
		FlxG.sound.music.pause();
		Conductor.changeBPM(120);

		var saveButton:FlxButton = new FlxButton(0, 0, "Save", function()
		{
			saveLevel();
		});
		saveButton.screenCenter();
		add(saveButton);

		bpmTxt = new FlxText(20, 20);
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		createStepChart();

		super.create();
	}

	function createStepChart()
	{
		sequencer = new FlxTypedGroup<DisplayNote>();
		add(sequencer);

		for (r in 0...4)
		{
			notes.push([]);
			for (i in 0...16)
			{
				notes[r].push(false);
				var seqBtn:DisplayNote = new DisplayNote((35 * r) + 10, (35 * i) + 50, null, function()
				{
					if (notes[r][i] == 0)
						notes[r][i] = 1;
					else
						notes[r][i] = 0;
				});

				seqBtn.strumTime = Conductor.stepCrochet * i;
				seqBtn.makeGraphic(30, 30, FlxColor.WHITE);
				seqBtn.ID = i + (16 * r);
				sequencer.add(seqBtn);
			}
		}
	}

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.playing)
		{
		}
		else
		{
			if (FlxG.keys.pressed.W)
				FlxG.sound.music.time -= 900 * FlxG.elapsed;
			if (FlxG.keys.pressed.S)
				FlxG.sound.music.time += 900 * FlxG.elapsed;
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
			}
			else
				FlxG.sound.music.play();
		}

		if (FlxG.keys.justPressed.UP)
			Conductor.changeBPM(Conductor.bpm + 1);
		if (FlxG.keys.justPressed.DOWN)
			Conductor.changeBPM(Conductor.bpm - 1);

		bpmTxt.text = "BPM: " + Conductor.bpm;

		sequencer.forEach(function(spr:DisplayNote)
		{
			if (notes[Std.int(spr.ID / 16)][spr.ID % 16] != 0)
				spr.alpha = 1;
			else
				spr.alpha = 0.5;

			spr.y = (strumLine.y - (Conductor.songPosition - spr.strumTime) * daSpacing);
		});

		super.update(elapsed);
	}

	private var daSpacing:Float = 0.3;

	private function saveLevel()
	{
		var json = {
			"song": "Bopeebo",
			"bpm": 100,
			"sections": 15
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, json.song + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
