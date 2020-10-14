package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITabMenu;
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
import openfl.net.FileReference;

using StringTools;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	var sectionInfo:Array<Dynamic>;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Smash';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;

	var _song:Song;

	var typingShit:FlxInputText;

	override function create()
	{
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		curRenderedNotes = new FlxTypedGroup<Note>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = new Song(curSong, [], Conductor.bpm, 0);
		}

		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);

		bpmTxt = new FlxText(20, 20);
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = true;
		_song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);

		UI_box.addGroup(tab_group_song);

		add(curRenderedNotes);

		super.create();
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.playMusic('assets/music/' + daSong + '.mp3', 0.6);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		};
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
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum(Conductor.songPosition % (Conductor.stepCrochet * 16));

		if (curBeat % 4 == 0)
		{
			if (curStep > (_song.notes[curSection].lengthInSteps * 2) * (curSection + 1))
			{
				if (_song.notes[curSection + 1] == null)
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
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					curRenderedNotes.forEach(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							deleteNote(note);
						}
					});
				}
				else
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			FlxG.switchState(new PlayState());
		}

		if (!typingShit.hasFocus)
		{
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
				if (FlxG.keys.pressed.SHIFT)
					changeSection();
				else
					changeSection(curSection);
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var daTime:Float = 700 * FlxG.elapsed;

				if (FlxG.keys.pressed.W)
				{
					FlxG.sound.music.time -= daTime;
				}
				else
					FlxG.sound.music.time += daTime;
			}
		}

		_song.bpm = Conductor.bpm;

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
		if (_song.notes[sec] != null)
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
					daLength += _song.notes[daNum].lengthInSteps * 2;
					daNum++;
				}

				FlxG.sound.music.time = (daLength - (_song.notes[sec].lengthInSteps * 2)) * Conductor.stepCrochet;
			}
		}
	}

	function updateGrid():Void
	{
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].notes;

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
		_song.notes.push(new Section(lengthInSteps));
	}

	function deleteNote(note:Note):Void
	{
		for (i in _song.notes[curSection].notes)
		{
			if (i[0] == note.strumTime && i[1] == note.noteData)
			{
				FlxG.log.add('FOUND EVIL NUMBER');
				_song.notes[curSection].notes.remove(i);
			}
		}

		updateGrid();
	}

	private function addNote():Void
	{
		_song.notes[curSection].notes.push([
			Math.round(getStrumTime(dummyArrow.y) + (curSection * (Conductor.stepCrochet * 32))),
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

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.notes);
		}

		return noteData;
	}

	private function saveLevel()
	{
		var json = {
			"song": _song.song,
			"bpm": Conductor.bpm,
			"sections": _song.notes.length,
			'notes': _song.notes
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
