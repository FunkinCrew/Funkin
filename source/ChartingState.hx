package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.geom.Rectangle;
import openfl.net.FileReference;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;
	var sequencer:FlxTypedGroup<DisplayNote>;
	var sectionShit:FlxTypedGroup<DisplayNote>;
	var notes:Array<Dynamic> = [];

	var UI_box:FlxUI9SliceSprite;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var sectionData:Map<Int, DisplayNote>;

	var section:Int = 0;
	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Fresh';
	var amountSteps:Int = 0;
	private var curNoteSelected:DisplayNote;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

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

		UI_box = new FlxUI9SliceSprite(FlxG.width / 2, 20, null, new Rectangle(0, 0, FlxG.width * 0.46, 400));
		add(UI_box);

		super.create();
	}

	var tooltipType:FlxUITooltipStyle = {titleWidth: 120, bodyWidth: 120, bodyOffset: new FlxPoint(5, 5)};

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);

		var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
		loopCheck.checked = curNoteSelected.doesLoop;
		tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
		bullshitUI.add(loopCheck);

		switch (curNoteSelected.type)
		{
			case DisplayNote.SECTION:
				title.text = 'Section note';
			case DisplayNote.PLAY_NOTE:
				title.text = 'Play note';
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Loops':
					curNoteSelected.doesLoop = check.checked;
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

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
