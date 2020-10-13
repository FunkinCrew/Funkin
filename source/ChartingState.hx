package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
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

using StringTools;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUI9SliceSprite;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	var sectionInfo:Array<Dynamic>;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Tutorial';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;

	var sections:Array<Section> = [];
	var gridBG:FlxSprite;

	override function create()
	{
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		curRenderedNotes = new FlxTypedGroup<Note>();

		addSection();

		FlxG.sound.playMusic('assets/music/' + curSong + '.mp3', 0.6);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		};
		Conductor.changeBPM(100);

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

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		add(curRenderedNotes);

		super.create();
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
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
					// curNoteSelected.doesLoop = check.checked;
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		strumLine.y = getYfromStrum(Conductor.songPosition % (Conductor.stepCrochet * 16));

		if (curBeat % 4 == 0)
		{
			if (curStep > (sections[curSection].lengthInSteps * 2) * (curSection + 1))
			{
				if (sections[curSection + 1] == null)
				{
					addSection();
				}

				changeSection(curSection + 1, false);
			}
		}

		if (FlxG.mouse.overlaps(gridBG))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;

			if (FlxG.mouse.justPressed)
			{
				addNote();
			}
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			PlayState.SONG = new Song(curSong, getNotes(), Conductor.bpm, sections.length);
			FlxG.switchState(new PlayState());
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

		if (FlxG.keys.justPressed.R)
		{
			changeSection();
		}

		if (FlxG.keys.justPressed.UP)
			Conductor.changeBPM(Conductor.bpm + 1);
		if (FlxG.keys.justPressed.DOWN)
			Conductor.changeBPM(Conductor.bpm - 1);

		if (FlxG.keys.justPressed.RIGHT)
			changeSection(curSection + 1);
		if (FlxG.keys.justPressed.LEFT)
			changeSection(curSection - 1);

		bpmTxt.text = "BPM: " + Conductor.bpm + "\nSection: " + curSection;
		super.update(elapsed);
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (sections[sec] != null)
		{
			curSection = sec;
			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();

				var daNum:Int = 0;
				var daLength:Int = 0;
				while (daNum <= sec)
				{
					daLength += sections[daNum].lengthInSteps * 2;
					daNum++;
				}

				FlxG.sound.music.time = (daLength - (sections[sec].lengthInSteps * 2)) * Conductor.stepCrochet;
			}
		}
	}

	function updateGrid():Void
	{
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = sections[curSection].notes;

		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];

			var note:Note = new Note(i[0], daNoteInfo);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(i[1] * GRID_SIZE);
			note.y = getYfromStrum(note.strumTime) % gridBG.height;

			curRenderedNotes.add(note);
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		sections.push(new Section(lengthInSteps));
	}

	private function addNote():Void
	{
		sections[curSection].notes.push([
			getStrumTime(dummyArrow.y) + (curSection * (Conductor.stepCrochet * 16)),
			Math.floor(FlxG.mouse.x / GRID_SIZE)
		]);

		trace(getStrumTime(dummyArrow.y) + (curSection * (Conductor.stepCrochet * 16)));
		trace(curSection);

		updateGrid();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	private var daSpacing:Float = 0.3;

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in sections)
		{
			noteData.push(i.notes);
		}

		return noteData;
	}

	private function saveLevel()
	{
		var json = {
			"song": curSong,
			"bpm": Conductor.bpm,
			"sections": sections.length,
			'notes': getNotes
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), json.song.toLowerCase() + ".json");
			_file.browse();
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
