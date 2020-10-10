package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
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
	var sequencer:FlxTypedGroup<FlxSpriteButton>;
	var notes:Array<Dynamic> = [];

	override function create()
	{
		var saveButton:FlxButton = new FlxButton(0, 0, "Save", function()
		{
			saveLevel();
		});
		saveButton.screenCenter();
		add(saveButton);

		createStepChart();

		super.create();
	}

	function createStepChart()
	{
		sequencer = new FlxTypedGroup<FlxSpriteButton>();
		add(sequencer);

		for (r in 0...2)
		{
			notes.push([]);
			for (i in 0...16)
			{
				notes[r].push(false);
				var seqBtn:FlxSpriteButton = new FlxSpriteButton((35 * r) + 10, (35 * i) + 50, null, function()
				{
					notes[r][i] = !notes[r][i];
				});

				seqBtn.makeGraphic(30, 30, FlxColor.WHITE);
				seqBtn.ID = i + (16 * r);
				sequencer.add(seqBtn);
			}
		}
	}

	override function update(elapsed:Float)
	{
		sequencer.forEach(function(spr:FlxSpriteButton)
		{
			if (notes[Std.int(spr.ID / 16)][spr.ID % 16])
				spr.alpha = 1;
			else
				spr.alpha = 0.5;
		});

		super.update(elapsed);
	}

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
