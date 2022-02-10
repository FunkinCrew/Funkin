package charting;

import Conductor.BPMChangeEvent;
import Note.NoteData;
import Section.SwagSection;
import SongLoad.SwagSong;
import audiovis.ABotVis;
import audiovis.SpectogramSprite;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import rendering.MeshRender;

using Lambda;
using StringTools;
using flixel.util.FlxSpriteUtil; // add in "compiler save" that saves the JSON directly to the debug json using File.write() stuff on windows / sys

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;
	var sidePreview:FlxSprite;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var gridBG:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:NoteData;

	var tempBpm:Float = 0;

	var vocals:VoicesGroup;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var audioBuf:AudioBuffer = new AudioBuffer();

	var playheadTest:FlxSprite;

	var staticSpecGrp:FlxTypedGroup<SpectogramSprite>;

	override function create()
	{
		curSection = lastSection;

		// sys.io.File.saveContent('./bitShit.txt', "swag");

		// trace(audioBuf.sampleRate);

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		trace("GRD BG: " + gridBG.height);
		add(gridBG);

		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
		{
			_song = SongLoad.songData = PlayState.SONG;
			trace("LOADED A PLAYSTATE SONGFILE");
		}
		else
		{
			_song = SongLoad.songData = SongLoad.getDefaultSwagSong();
		}

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = SongLoad.getSong();

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 8), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFCC2288);
		dummyArrow.alpha = 0.3;
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = (FlxG.width / 4) * 3;
		UI_box.y = 120;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();

		add(curRenderedNotes);
		add(curRenderedSustains);

		changeSection();
		super.create();
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var saveCompiler:FlxButton = new FlxButton(110, 30, "Save compile", function()
		{
			saveLevel(true);
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 2);
		stepperSpeed.value = SongLoad.getSpeed();
		// stepperSpeed.value = _song.speed[SongLoad.curDiff];
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 100, 1, 999, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;

		var difficultyDropDown = new FlxUIDropDownMenu(10, 230, FlxUIDropDownMenu.makeStrIdLabelArray(_song.difficulties, true), function(diff:String)
		{
			SongLoad.curDiff = _song.difficulties[Std.parseInt(diff)];
			SongLoad.checkAndCreateNotemap(SongLoad.curDiff);

			while (SongLoad.getSong()[curSection] == null)
				addSection();

			updateGrid();
		});
		difficultyDropDown.selectedLabel = SongLoad.curDiff;

		var difficultyAdder = new FlxUIInputText(130, 230, 100, "", 12);

		var addDiff:FlxButton = new FlxButton(130, 250, "Add Difficulty", function()
		{
			difficultyAdder.text = "";
			// something to regenerate difficulties
		});

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveCompiler);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);
		tab_group_song.add(difficultyDropDown);
		tab_group_song.add(difficultyAdder);
		tab_group_song.add(addDiff);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.focusOn(gridBG.getGraphicMidpoint());
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = SongLoad.getSong()[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 1, 999, 3);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0...SongLoad.getSong()[curSection].sectionNotes.length)
			{
				var note:Note = new Note(0, 0);
				note.data = SongLoad.getSong()[curSection].sectionNotes[i];
				note.data.noteData = (note.data.noteData + 4) % 8;
				SongLoad.getSong()[curSection].sectionNotes[i] = note.data;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var stepperPerNoteSpeed:FlxUINumericStepper;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		stepperPerNoteSpeed = new FlxUINumericStepper(10, 40, 0.1, 1, 0.01, 100, 2);
		stepperPerNoteSpeed.value = 1;
		stepperPerNoteSpeed.name = "note_PerNoteSpeed";

		var noteSpeedName:FlxText = new FlxText(40, stepperPerNoteSpeed.y, 0, "Note Speed Multiplier");

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(stepperPerNoteSpeed);
		tab_group_note.add(noteSpeedName);
		tab_group_note.add(applyLength);

		UI_box.addGroup(tab_group_note);
	}

	// var spec:SpectogramSprite;

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		var pathShit = Paths.inst(daSong);

		if (!openfl.utils.Assets.cache.hasSound(pathShit))
		{
			var library = Assets.getLibrary("songs");
			var symbolPath = pathShit.split(":").pop();
			// @:privateAccess
			// library.types.set(symbolPath, SOUND);
			// @:privateAccess
			// library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
			// var callback = callbacks.add("song:" + pathShit);
			openfl.utils.Assets.loadSound(pathShit).onComplete(function(_)
			{
				// callback();
			});
		}

		FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		var musSpec:SpectogramSprite = new SpectogramSprite(FlxG.sound.music, FlxColor.RED, FlxG.height / 2, Math.floor(FlxG.height / 2));
		musSpec.x += 70;
		musSpec.scrollFactor.set();
		// musSpec.visType = FREQUENCIES;
		add(musSpec);

		sidePreview = new FlxSprite(0, 0).makeGraphic(40, FlxG.height, FlxColor.GRAY);
		sidePreview.scrollFactor.set();
		add(sidePreview);

		// trace(audioBuf.data.length);
		playheadTest = new FlxSprite(0, 0).makeGraphic(30, 2, FlxColor.RED);
		playheadTest.scrollFactor.set();
		playheadTest.alpha = 0.5;
		add(playheadTest);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new VoicesGroup(daSong, _song.voiceList);
		// vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		// FlxG.sound.list.add(vocals);

		staticSpecGrp = new FlxTypedGroup<SpectogramSprite>();
		add(staticSpecGrp);

		var aBoy:ABotVis = new ABotVis(FlxG.sound.music);
		// add(aBoy);

		for (index => voc in vocals.members)
		{
			var vocalSpec:SpectogramSprite = new SpectogramSprite(voc, FlxG.random.color(0xFFAAAAAA, FlxColor.WHITE, 100), musSpec.daHeight,
				Math.floor(FlxG.height / 2));
			vocalSpec.x = 70 - (50 * index);
			// vocalSpec.visType = FREQUENCIES;
			vocalSpec.daHeight = musSpec.daHeight;
			vocalSpec.y = vocalSpec.daHeight;
			vocalSpec.scrollFactor.set();
			add(vocalSpec);

			var staticVocal:SpectogramSprite = new SpectogramSprite(voc, FlxG.random.color(0xFFAAAAAA, FlxColor.WHITE, 100), GRID_SIZE * 16, GRID_SIZE * 8);
			if (index == 0)
				staticVocal.x -= 150;

			if (index == 1)
				staticVocal.x = gridBG.width;

			staticVocal.visType = STATIC;
			staticSpecGrp.add(staticVocal);
		}

		FlxG.sound.music.pause();

		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
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
			loopCheck.checked = notes[0]elected.doesLoop;
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
				case 'Must hit section':
					SongLoad.getSong()[curSection].mustHitSection = check.checked;

					updateHeads();

				case 'Change BPM':
					SongLoad.getSong()[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					SongLoad.getSong()[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				SongLoad.getSong()[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				// _song.speed[SongLoad.curDiff] = nums.value;
				_song.speed.normal = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(nums.value);
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote.sustainLength = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				SongLoad.getSong()[curSection].bpm = nums.value;
				updateGrid();
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (SongLoad.getSong()[curSection].changeBPM)
				return SongLoad.getSong()[curSection].lengthInSteps * (SongLoad.getSong()[curSection].bpm / _song.bpm);
			else
				return SongLoad.getSong()[curSection].lengthInSteps;
	}*/
	/**
	 * Gets the start time of section, defaults to the curSection
	 * @param section 
	 * @return position of the song in... either seconds or milliseconds.... woops
	 */
	function sectionStartTime(?funnySection:Int):Float
	{
		if (funnySection == null)
			funnySection = curSection;

		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...funnySection)
		{
			if (SongLoad.getSong()[i].changeBPM)
			{
				daBPM = SongLoad.getSong()[i].bpm;
			}
			daPos += 4 * sectionCalc(daBPM);
		}
		return daPos;
	}

	function measureStartTime():Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = sectionStartTime();

		daPos = Math.floor(FlxG.sound.music.time / sectionCalc(daBPM)) * sectionCalc(daBPM);
		return daPos;
	}

	function sectionCalc(bpm:Float)
	{
		return (1000 * 60 / bpm);
	}

	var p1Muted:Bool = false;
	var p2Muted:Bool = false;

	override function update(elapsed:Float)
	{
		// FlxG.camera.followLerp = CoolUtil.camLerpShit(0.05);

		FlxG.sound.music.pan = FlxMath.remapToRange(FlxG.mouse.screenX, 0, FlxG.width, -1, 1) * 10;

		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		playheadTest.y = CoolUtil.coolLerp(playheadTest.y, FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music.length, 0, FlxG.height), 0.5);

		var strumLinePos:Float = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * SongLoad.getSong()[curSection].lengthInSteps));

		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.playing)
				strumLine.y = strumLinePos;
			else
				strumLine.y = CoolUtil.coolLerp(strumLine.y, strumLinePos, 0.5);
		}

		/* if (FlxG.sound.music.playing)
			{
				var normalizedShitIDK:Int = Std.int(FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music.length, 0, audioBuf.data.length));
				FlxG.watch.addQuick('WEIRD AUDIO SHIT LOL', audioBuf.data[normalizedShitIDK]);
				// leftIcon.scale.x = FlxMath.remapToRange(audioBuf.data[normalizedShitIDK], 0, 255, 1, 2);
		}*/

		if (FlxG.keys.justPressed.X)
			toggleAltAnimNote();

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			trace(curStep);
			trace((SongLoad.getSong()[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (SongLoad.getSong()[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.pressedMiddle && FlxG.mouse.overlaps(gridBG))
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			FlxG.sound.music.time = CoolUtil.coolLerp(FlxG.sound.music.time, getStrumTime(FlxG.mouse.y) + sectionStartTime(), 0.5);
			vocals.time = FlxG.sound.music.time;
		}

		if (FlxG.mouse.pressed)
		{
			if (FlxG.keys.pressed.ALT && FlxG.mouse.overlaps(gridBG)) // same shit as middle click / hold on grid
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					vocals.pause();
				}

				FlxG.sound.music.time = getStrumTime(FlxG.mouse.y) + sectionStartTime();
				vocals.time = FlxG.sound.music.time;
			}
			else
			{
				if (FlxG.mouse.screenX <= 30 && FlxMath.inBounds(FlxG.mouse.screenY, 0, FlxG.height))
				{
					if (FlxG.sound.music.playing)
					{
						FlxG.sound.music.pause();
						vocals.pause();
					}

					FlxG.sound.music.time = CoolUtil.coolLerp(FlxG.sound.music.time,
						FlxMath.remapToRange(FlxG.mouse.screenY, 0, FlxG.height, 0, FlxG.sound.music.length), 0.5);
					vocals.time = FlxG.sound.music.time;
				}
				if (FlxG.mouse.justPressed)
				{
					if (FlxG.mouse.overlaps(leftIcon))
					{
						if (leftIcon.char == _song.player1)
						{
							p1Muted = !p1Muted;
							leftIcon.animation.curAnim.curFrame = p1Muted ? 1 : 0;
						}
						else
						{
							p2Muted = !p2Muted;

							leftIcon.animation.curAnim.curFrame = p2Muted ? 1 : 0;
						}

						vocals.members[0].volume = p1Muted ? 0 : 1;

						// null check jus in case using old shit?
						if (vocals.members[1] != null)
							vocals.members[1].volume = p2Muted ? 0 : 1;
					}

					// sloppy copypaste lol deal with it!
					if (FlxG.mouse.overlaps(rightIcon))
					{
						if (rightIcon.char == _song.player1)
						{
							p1Muted = !p1Muted;
							rightIcon.animation.curAnim.curFrame = p1Muted ? 1 : 0;
						}
						else
						{
							rightIcon.animation.curAnim.curFrame = p2Muted ? 1 : 0;
							p2Muted = !p2Muted;
						}

						vocals.members[0].volume = p1Muted ? 0 : 1;

						// null check jus in case using old shit?
						if (vocals.members[1] != null)
							vocals.members[1].volume = p2Muted ? 0 : 1;
					}

					if (FlxG.mouse.overlaps(curRenderedNotes))
					{
						curRenderedNotes.forEach(function(note:Note)
						{
							if (FlxG.mouse.overlaps(note))
							{
								selectNote(note);
							}
						});
					}
					else
					{
						if (FlxG.mouse.overlaps(gridBG))
						{
							FlxG.log.add('added note');
							addNote();
						}
					}
				}
			}
		}

		if (FlxG.mouse.pressedRight)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						trace('tryin to delete note...');
						deleteNote(note);
					}
				});
			}
		}

		if (FlxG.mouse.justReleased)
			justPlacedNote = false;

		if (FlxG.mouse.overlaps(gridBG))
		{
			if (justPlacedNote && FlxG.mouse.pressed && FlxG.mouse.y > getYfromStrum(curSelectedNote.strumTime))
			{
				var minusStuff:Float = FlxG.mouse.y - getYfromStrum(curSelectedNote.strumTime);
				minusStuff -= GRID_SIZE;
				minusStuff = Math.floor(minusStuff / GRID_SIZE) * GRID_SIZE;
				minusStuff = FlxMath.remapToRange(minusStuff, 0, 40, 0, Conductor.stepCrochet);

				curSelectedNote.sustainLength = minusStuff;

				updateNoteUI();
				updateGrid();
			}

			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			autosaveSong();

			lastSection = curSection;

			PlayState.SONG = _song;

			// JUST FOR DEBUG DARNELL STUFF, GENERALIZE THIS FOR BETTER LOADING ELSEWHERE TOO!
			PlayState.storyWeek = 8;

			FlxG.sound.music.stop();
			vocals.stop();
			LoadingState.loadAndSwitchState(new PlayState());
			// FlxG.switchState(new PlayState());
		}

		if (FlxG.keys.justPressed.E)
		{
			changeNoteSustain(Conductor.stepCrochet);
		}
		if (FlxG.keys.justPressed.Q)
		{
			changeNoteSustain(-Conductor.stepCrochet);
		}

		if (FlxG.keys.justPressed.TAB)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			}
			else
			{
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}

		if (!typingShit.hasFocus)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					vocals.pause();
				}
				else
				{
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.CONTROL)
					resetSection(BEGINNING);
				else if (FlxG.keys.pressed.SHIFT)
					resetSection(MEASURE);
				else
					resetSection(SECTION);
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				var ctrlMod:Float = FlxG.keys.pressed.CONTROL ? 0.1 : 1;
				var shiftMod:Float = FlxG.keys.pressed.SHIFT ? 2 : 1;

				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4 * ctrlMod * shiftMod);
				vocals.time = FlxG.sound.music.time;
			}

			if (FlxG.keys.justReleased.S)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				#if HAS_PITCH
				FlxG.sound.music.pitch = 1;
				vocals.pitch = 1;
				#end
			}

			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.CONTROL)
						daTime *= 0.2;

					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.pause();
						vocals.pause();
						FlxG.sound.music.time -= daTime;
						vocals.time = FlxG.sound.music.time;
					}
					else
					{
						if (FlxG.keys.justPressed.S)
						{
							FlxG.sound.music.play();
							vocals.play();

							#if HAS_PITCH
							FlxG.sound.music.pitch = 0.5;
							vocals.pitch = 0.5;
							#end
						}
					}
					// FlxG.sound.music.time += daTime;

					// vocals.time = FlxG.sound.music.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					var daTime:Float = Conductor.stepCrochet * 2;

					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.pause();
						vocals.pause();

						FlxG.sound.music.time -= daTime;
						vocals.time = FlxG.sound.music.time;
					}
					else
					{
						if (FlxG.keys.justPressed.S)
						{
							// FlxG.sound.music.time += daTime;

							FlxG.sound.music.play();
							vocals.play();

							#if HAS_PITCH
							FlxG.sound.music.pitch = 0.2;
							vocals.pitch = 0.2;
							#end
						}
					}
				}
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;
		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
			changeSection(curSection + shiftThing);
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
			changeSection(curSection - shiftThing);

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 3))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 3))
			+ "\nSection: "
			+ curSection;
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			curSelectedNote.sustainLength += value;
			curSelectedNote.sustainLength = Math.max(curSelectedNote.sustainLength, 0);
		}

		updateNoteUI();
		updateGrid();
	}

	function toggleAltAnimNote():Void
	{
		if (curSelectedNote != null)
		{
			trace('ALT NOTE SHIT');
			curSelectedNote.altNote = !curSelectedNote.altNote;
			trace(curSelectedNote.altNote);
		}
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:SongResetType = SECTION):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		switch (songBeginning)
		{
			case SECTION:
				// Basically old shit from changeSection???
				FlxG.sound.music.time = sectionStartTime();
			case BEGINNING:
				FlxG.sound.music.time = 0;
				curSection = 0;
			case MEASURE:
				FlxG.sound.music.time = measureStartTime(); // Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE
			default:
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section' + sec);

		if (SongLoad.getSong()[sec] != null)
		{
			curSection = sec;

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
		}
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (noteShit in SongLoad.getSong()[daSec - sectionNum].sectionNotes)
		{
			var strum = noteShit.strumTime + Conductor.stepCrochet * (SongLoad.getSong()[daSec].lengthInSteps * sectionNum);

			var copiedNote:Note = new Note(strum, noteShit.noteData);
			copiedNote.data.sustainLength = noteShit.sustainLength;
			SongLoad.getSong()[daSec].sectionNotes.push(copiedNote.data);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = SongLoad.getSong()[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		if (check_mustHitSection.checked)
		{
			leftIcon.changeIcon(_song.player1);
			rightIcon.changeIcon(_song.player2);

			leftIcon.animation.curAnim.curFrame = p1Muted ? 1 : 0;
			rightIcon.animation.curAnim.curFrame = p2Muted ? 1 : 0;
		}
		else
		{
			leftIcon.changeIcon(_song.player2);
			rightIcon.changeIcon(_song.player1);

			leftIcon.animation.curAnim.curFrame = p2Muted ? 1 : 0;
			rightIcon.animation.curAnim.curFrame = p1Muted ? 1 : 0;
		}
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		leftIcon.height *= 0.6;
		rightIcon.height *= 0.6;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote.sustainLength;
	}

	function updateGrid():Void
	{
		// null if checks jus cuz i put updateGrid() in some weird places!
		if (staticSpecGrp != null)
		{
			staticSpecGrp.forEach(function(spec)
			{
				if (spec != null)
					spec.generateSection(sectionStartTime(), (Conductor.stepCrochet * 32) / 1000);
			});
		}

		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		// generates the cool sidebar shit
		if (sidePreview != null && sidePreview.active)
		{
			sidePreview.drawRect(0, 0, 40, FlxG.height, 0xFF444444);

			/* 
				var sectionsNeeded:Int = Std.int(FlxG.sound.music.length / (sectionCalc(_song.bpm) * 4));

					while (sectionsNeeded > 0)
					{
						sidePreview.drawRect(0, sectionsNeeded * (FlxG.height / sectionsNeeded), 40, FlxG.height / sectionsNeeded,
							(sectionsNeeded % 2 == 0 ? 0xFF000000 : 0xFFFFFFFF));

						sectionsNeeded--;
					}
			 */

			for (secIndex => sideSection in SongLoad.getSong())
			{
				for (notes in sideSection.sectionNotes)
				{
					var col:Int = switch (notes.noteData % 4)
					{
						case 0:
							0xFFFF22AA;
						case 1:
							0xFF00EEFF;
						case 2:
							0xFF00CC00;
						case 3:
							0xFFCC1111;
						default:
							0xFFFF0000;
					}

					var noteFlip:Int = (sideSection.mustHitSection ? 1 : -1);
					var noteX:Float = 5 * (((notes.noteData - 4) * noteFlip) + 4);

					sidePreview.drawRect(noteX, FlxMath.remapToRange(notes.strumTime, 0, FlxG.sound.music.length, 0, FlxG.height), 5, 1, col);
				}
			}
		}

		var sectionInfo:Array<NoteData> = SongLoad.getSong()[curSection].sectionNotes;

		if (SongLoad.getSong()[curSection].changeBPM && SongLoad.getSong()[curSection].bpm > 0)
		{
			Conductor.changeBPM(SongLoad.getSong()[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (SongLoad.getSong()[i].changeBPM)
					daBPM = SongLoad.getSong()[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0...SongLoad.getSong().length)
			{
				for (notesse in 0...SongLoad.getSong()[sec].sectionNotes.length)
				{
					if (SongLoad.getSong()[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						SongLoad.getSong()[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		for (i in sectionInfo)
		{
			var daNoteInfo = i.noteData;
			var daStrumTime = i.strumTime;
			var daSus = i.sustainLength;

			var note:Note = new Note(daStrumTime, daNoteInfo % 4);
			note.data.sustainLength = daSus;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(daNoteInfo * GRID_SIZE);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * SongLoad.getSong()[curSection].lengthInSteps)));

			curRenderedNotes.add(note);

			if (daSus > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
					note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height)));
				curRenderedSustains.add(sustainVis);
			}
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		SongLoad.getSong().push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in SongLoad.getSong()[curSection].sectionNotes)
		{
			if (i.strumTime == note.data.strumTime && i.noteData % 4 == note.data.noteData)
			{
				curSelectedNote = SongLoad.getSong()[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		for (i in SongLoad.getSong()[curSection].sectionNotes)
		{
			if (i.strumTime == note.data.strumTime && i.noteData % 4 == note.data.noteData)
			{
				var placeIDK:Int = Std.int(((Math.floor(dummyArrow.y / GRID_SIZE) * GRID_SIZE)) / 40);

				placeIDK = Std.int(Math.min(placeIDK, 15));
				placeIDK = Std.int(Math.max(placeIDK, 1));

				trace(placeIDK);
				FlxG.sound.play(Paths.sound('funnyNoise/funnyNoise-0' + placeIDK));

				FlxG.log.add('FOUND EVIL NUMBER');
				SongLoad.getSong()[curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void
	{
		SongLoad.getSong()[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0...SongLoad.getSong().length)
		{
			SongLoad.getSong()[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	/**
	 * Is true if clicked and placed a note, set reset to false when releasing mouse button!
	 */
	var justPlacedNote:Bool = false;

	private function addNote():Void
	{
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;
		var noteAlt = false;

		justPlacedNote = true;

		// FlxG.sound.play(Paths.sound('pianoStuff/piano-00' + FlxG.random.int(1, 9)), FlxG.random.float(0.01, 0.3));

		function makeAndPlayChord(soundsToPlay:Array<String>)
		{
			var bullshit:Int = Std.int((Math.floor(dummyArrow.y / GRID_SIZE) * GRID_SIZE) / 40);
			soundsToPlay.push('00' + Std.string((bullshit % 8) + 1));

			for (key in soundsToPlay)
			{
				var snd:FlxSound = FlxG.sound.list.recycle(FlxSound).loadEmbedded(FlxG.sound.cache(Paths.sound("pianoStuff/piano-" + key)));
				snd.autoDestroy = true;
				FlxG.sound.list.add(snd);
				snd.volume = FlxG.random.float(0.05, 0.7);
				snd.pan = noteData - 2; // .... idk why tf panning doesnt work? (as of 2022/01/25) busted ass bullshit. I only went thru this fuss of creating FlxSound just for the panning!

				// snd.proximity(FlxG.mouse.x, FlxG.mouse.y, gridBG, gridBG.width / 2);

				snd.play();
			}
		}

		switch (noteData)
		{
			case 0:
				makeAndPlayChord(["015", "013", "009"]);
			case 1:
				makeAndPlayChord(["015", "012", "009"]);
			case 2:
				makeAndPlayChord(["015", "011", "009"]);
			case 3:
				makeAndPlayChord(["014", "011", "010"]);
		}

		// trace('bullshit $bullshit'); // trace(Math.floor(dummyArrow.y / GRID_SIZE) * GRID_SIZE);

		var daNewNote:Note = new Note(noteStrum, noteData);
		daNewNote.data.sustainLength = noteSus;
		daNewNote.data.altNote = noteAlt;
		SongLoad.getSong()[curSection].sectionNotes.push(daNewNote.data);

		curSelectedNote = SongLoad.getSong()[curSection].sectionNotes[SongLoad.getSong()[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			// SongLoad.getSong()[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteAlt]);
		}

		trace(noteStrum);
		trace(curSection);

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in SongLoad.getSong())
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
					trace('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(SongLoad.getSong());
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in SongLoad.getSong())
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = SongLoad.loadFromJson(song.toLowerCase(), song.toLowerCase());
		LoadingState.loadAndSwitchState(new ChartingState());
	}

	function loadAutosave():Void
	{
		PlayState.SONG = FlxG.save.data.autosave;
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = _song;
		// trace(FlxG.save.data.autosave);
		FlxG.save.flush();
	}

	private function saveLevel(?debugSavepath:Bool = false)
	{
		// Right now the note data is saved as a Note.NoteData typedef / object or whatev
		// we want to format it to an ARRAY. We turn it back into the typedef / object at the end of this function hehe

		for (key in _song.noteMap.keys())
			SongLoad.castNoteDataToArray(_song.noteMap[key]);

		// SongLoad.castNoteDataToArray(_song.notes.easy);
		// SongLoad.castNoteDataToArray(_song.notes.normal);
		// SongLoad.castNoteDataToArray(_song.notes.hard);

		var json = {"song": _song};
		var data:String = Json.stringify(json, null, "\t");

		#if sys
		// quick workaround, since it easier to load into hashlink, thus quicker/nicer to test?
		// should get this auto-saved into a file or somethin
		var filename = _song.song.toLowerCase();

		if (debugSavepath)
		{
			// file path to assumingly your assets folder in your SOURCE CODE assets folder!!!
			// update this later so the save button ONLY appears when you compile in debug mode!
			sys.io.File.saveContent('../../../../assets/preload/data/$filename/$filename.json', data);
		}
		else
			sys.io.File.saveContent('./$filename.json', data);
		#else
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
		#end

		for (key in _song.noteMap.keys())
			SongLoad.castArrayToNoteData(_song.noteMap[key]);

		// turn the array data back to Note.NoteData typedef
		// SongLoad.castArrayToNoteData(_song.notes.easy);
		// SongLoad.castArrayToNoteData(_song.notes.normal);
		// SongLoad.castArrayToNoteData(_song.notes.hard);
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

enum SongResetType
{
	BEGINNING;
	MEASURE; // not sure if measure is 1/4 of a "SECTION" which is definitely a... bar.. right? its nerd shit whatever
	SECTION;
}
