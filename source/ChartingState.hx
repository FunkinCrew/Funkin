package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUICheckBox;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
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
	var sectionData:Map<Int, Int>;

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

		sectionShit = new FlxTypedGroup<DisplayNote>();

		createStepChart();
		sectionData = new Map<Int, Int>();
		sectionData.set(0, 0);
		updateSectionColors();

		highlight = new FlxSprite().makeGraphic(10, 10, FlxColor.BLUE);
		add(highlight);

		UI_box = new FlxUI9SliceSprite(FlxG.width / 2, 20, null, new Rectangle(0, 0, FlxG.width * 0.46, 400));
		add(UI_box);

		bullshitUI = new FlxGroup();
		add(bullshitUI);

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

		var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
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
					trace(curNoteSelected.doesLoop);
			}
			FlxG.log.add(label);
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	function updateSectionColors():Void
	{
		sectionShit.forEach(function(note:DisplayNote)
		{
			sequencer.remove(note, true);
			sectionShit.remove(note, true);
			note.destroy();
		});

		for (i in sectionData.keys())
		{
			var sec:FlxText = new FlxText(strumLine.width, 0, 0, "Section " + i);
			var sectionTex:DisplayNote = createDisplayNote(5, i - 1, sec);
			sectionTex.type = DisplayNote.SECTION;

			sectionTex.onDown.callback = function()
			{
				curNoteSelected = sectionTex;
				generateUI();
			};

			sectionTex.strumTime = sectionData.get(i) * Conductor.stepCrochet;
			sequencer.add(sectionTex);
			sectionShit.add(sectionTex);
			trace(i);
		}
	}

	function createDisplayNote(row:Float, column:Float, ?spr:FlxSprite, ?func:Void->Void):DisplayNote
	{
		return new DisplayNote((35 * row) + 10, (35 * column) + 50, spr, func);
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
				var seqBtn:DisplayNote = createDisplayNote(r, i, null);

				/* seqBtn.onUp.callback = function()
					{
						if (seqBtn == curNoteSelected)
						{
							if (notes[r][i] == 0)
								notes[r][i] = 1;
							else
								notes[r][i] = 0;
						}
						else
							curNoteSelected = seqBtn;
					}
				 */

				seqBtn.onDown.callback = function()
				{
					if (FlxG.keys.pressed.SHIFT)
					{
						curNoteSelected = seqBtn;
						generateUI();
					}
					else
					{
						if (notes[r][i] == 0)
							notes[r][i] = 1;
						else
							notes[r][i] = 0;
					}
				};

				seqBtn.type = DisplayNote.PLAY_NOTE;
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

		if (curNoteSelected != null)
			highlight.setPosition(curNoteSelected.getGraphicMidpoint().x, curNoteSelected.getGraphicMidpoint().y);

		if (FlxG.mouse.justPressedMiddle && section > 0)
		{
			var pushSection:Int = Math.round(Conductor.songPosition / Conductor.crochet) * 4;

			sectionData.set(section, pushSection);

			updateSectionColors();
		}

		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
		{
			FlxG.sound.music.pause();

			if (FlxG.keys.justPressed.RIGHT)
			{
				if (section + 1 <= Lambda.count(sectionData))
					section += 1;
				else
					section = 0;
			}

			if (FlxG.keys.justPressed.LEFT)
			{
				if (section > 0)
					section -= 1;
				else
					section = Lambda.count(sectionData);
			}

			if (sectionData.exists(section))
				FlxG.sound.music.time = sectionData.get(section) * Conductor.stepCrochet;
		}

		if (FlxG.keys.justPressed.R && sectionData.exists(section))
			FlxG.sound.music.time = sectionData.get(section) * Conductor.stepCrochet;

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
