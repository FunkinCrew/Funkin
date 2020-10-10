package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.ui.FlxButton;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	override function create()
	{
		var saveButton:FlxButton = new FlxButton(0, 0, "Save", function()
		{
			// bullshit

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
		});
		saveButton.screenCenter();
		add(saveButton);

		super.create();
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
