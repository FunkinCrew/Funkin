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

	/**
	 * Array of notes showing when each section STARTS
	 */
	var sectionData:Array<Int> = [0];

	var section:Int = 0;
	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Fresh';
	var amountSteps:Int = 0;

	override function create()
	{
		FlxG.sound.playMusic('assets/music/' + curSong + '.mp3', 0.6);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		};
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

		amountSteps = Math.floor(FlxG.sound.music.length / Conductor.stepCrochet);

		for (r in 0...4)
		{
			notes.push([]);
			for (i in 0...amountSteps)
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
				seqBtn.ID = i + (amountSteps * r);
				sequencer.add(seqBtn);
			}
		}
	}

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.mouse.justPressedMiddle && section > 0)
		{
			var pushSection:Int = Math.round(FlxG.sound.music.time / Conductor.crochet) * 4;

			if (sectionData[section] == null)
			{
				sectionData.push(pushSection);
			}
			else
				sectionData[section] == pushSection;
		}

		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
		{
			FlxG.sound.music.pause();

			if (FlxG.keys.justPressed.RIGHT)
			{
				if (section + 1 <= sectionData.length)
					section += 1;
				else
					section = 0;
			}

			if (FlxG.keys.justPressed.LEFT)
			{
				if (section > 0)
					section -= 1;
				else
					section = sectionData.length;
			}

			if (sectionData[section] != null)
				FlxG.sound.music.time = sectionData[section] * Conductor.stepCrochet;
		}

		if (FlxG.keys.justPressed.R && sectionData[section] != null)
			FlxG.sound.music.time = sectionData[section] * Conductor.stepCrochet;

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

		bpmTxt.text = "BPM: " + Conductor.bpm + "\nSection: " + section;

		sequencer.forEach(function(spr:DisplayNote)
		{
			if (notes[Std.int(spr.ID / amountSteps)][spr.ID % amountSteps] != 0)
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
