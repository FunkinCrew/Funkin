package;

import Conductor.BPMChangeEvent;
import Section.SwagSection;
import SongLoad.SwagSong;
import dsp.FFT;
import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.CallStack.StackItem;
import haxe.Json;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import lime.utils.Int16Array;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using Lambda;
using StringTools;
using flixel.util.FlxSpriteUtil;

// add in "compiler save" that saves the JSON directly to the debug json using File.write() stuff on windows / sys
class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

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
	var curSelectedNote:Array<Dynamic>;

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
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [[]],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				speed: [1],
				validScore: false,
				voiceList: ["BF", "BF-pixel"]
			};
		}

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes[SongLoad.curDiff];

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 8), 4);
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
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 2);
		stepperSpeed.value = _song.speed[SongLoad.curDiff];
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
		stepperLength.value = _song.notes[SongLoad.curDiff][curSection].lengthInSteps;
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
			for (i in 0..._song.notes[SongLoad.curDiff][curSection].sectionNotes.length)
			{
				var note = _song.notes[SongLoad.curDiff][curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[SongLoad.curDiff][curSection].sectionNotes[i] = note;
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

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
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

		var musSpec:SpectogramSprite = new SpectogramSprite(FlxG.sound.music, FlxColor.RED);
		musSpec.x += 70;
		musSpec.daHeight = FlxG.height / 2;
		musSpec.scrollFactor.set();
		musSpec.visType = FREQUENCIES;
		add(musSpec);

		// trace(audioBuf.data.length);
		playheadTest = new FlxSprite(0, 0).makeGraphic(2, 255, FlxColor.RED);
		playheadTest.scrollFactor.set();
		add(playheadTest);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new VoicesGroup(daSong, _song.voiceList);
		// vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		// FlxG.sound.list.add(vocals);

		staticSpecGrp = new FlxTypedGroup<SpectogramSprite>();
		add(staticSpecGrp);

		var aBoy:ABotVis = new ABotVis(FlxG.sound.music);
		add(aBoy);

		for (index => voc in vocals.members)
		{
			var vocalSpec:SpectogramSprite = new SpectogramSprite(voc, FlxG.random.color(0xFFAAAAAA, FlxColor.WHITE, 100));
			vocalSpec.x = 70 - (50 * index);
			vocalSpec.visType = FREQUENCIES;
			vocalSpec.daHeight = musSpec.daHeight;
			vocalSpec.y = vocalSpec.daHeight;
			vocalSpec.scrollFactor.set();
			add(vocalSpec);

			var staticVocal:SpectogramSprite = new SpectogramSprite(voc, FlxG.random.color(0xFFAAAAAA, FlxColor.WHITE, 100));
			if (index == 0)
				staticVocal.x -= 150;

			if (index == 1)
				staticVocal.x = gridBG.width;

			staticVocal.daHeight = GRID_SIZE * 16;
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
					_song.notes[SongLoad.curDiff][curSection].mustHitSection = check.checked;

					updateHeads();

				case 'Change BPM':
					_song.notes[SongLoad.curDiff][curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[SongLoad.curDiff][curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[SongLoad.curDiff][curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				_song.speed[SongLoad.curDiff] = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(nums.value);
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[SongLoad.curDiff][curSection].bpm = nums.value;
				updateGrid();
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[SongLoad.curDiff][curSection].changeBPM)
				return _song.notes[SongLoad.curDiff][curSection].lengthInSteps * (_song.notes[SongLoad.curDiff][curSection].bpm / _song.bpm);
			else
				return _song.notes[SongLoad.curDiff][curSection].lengthInSteps;
	}*/
	function sectionStartTime():Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[SongLoad.curDiff][i].changeBPM)
			{
				daBPM = _song.notes[SongLoad.curDiff][i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var p1Muted:Bool = false;
	var p2Muted:Bool = false;

	override function update(elapsed:Float)
	{
		// FlxG.camera.followLerp = CoolUtil.camLerpShit(0.05);

		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		playheadTest.x = FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music.length, 0, FlxG.width);

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[SongLoad.curDiff][curSection].lengthInSteps));

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
			trace((_song.notes[SongLoad.curDiff][curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[SongLoad.curDiff][curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.pressedMiddle)
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			FlxG.sound.music.time = getStrumTime(FlxG.mouse.y) + sectionStartTime();
			vocals.time = FlxG.sound.music.time;
		}

		if (FlxG.mouse.pressed)
		{
			if (FlxG.keys.pressed.ALT)
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
								if (FlxG.keys.pressed.CONTROL)
								{
									selectNote(note);
								}
								else
								{
									trace('tryin to delete note...');
									deleteNote(note);
								}
							}
						});
					}
					else
					{
						if (FlxG.mouse.x > gridBG.x
							&& FlxG.mouse.x < gridBG.x + gridBG.width
							&& FlxG.mouse.y > gridBG.y
							&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[SongLoad.curDiff][curSection].lengthInSteps))
						{
							FlxG.log.add('added note');
							addNote();
						}
					}
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[SongLoad.curDiff][curSection].lengthInSteps))
		{
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
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
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

			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.CONTROL)
						daTime *= 0.2;

					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = Conductor.stepCrochet * 2;

					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
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
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function toggleAltAnimNote():Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[3] != null)
			{
				trace('ALT NOTE SHIT');
				curSelectedNote[3] = !curSelectedNote[3];
				trace(curSelectedNote[3]);
			}
			else
				curSelectedNote[3] = true;
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

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section' + sec);

		if (_song.notes[SongLoad.curDiff][sec] != null)
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

		for (note in _song.notes[SongLoad.curDiff][daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[SongLoad.curDiff][daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[SongLoad.curDiff][daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[SongLoad.curDiff][curSection];

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
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
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

		var sectionInfo:Array<Dynamic> = _song.notes[SongLoad.curDiff][curSection].sectionNotes;

		if (_song.notes[SongLoad.curDiff][curSection].changeBPM && _song.notes[SongLoad.curDiff][curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[SongLoad.curDiff][curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[SongLoad.curDiff][i].changeBPM)
					daBPM = _song.notes[SongLoad.curDiff][i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes[SongLoad.curDiff].length)
			{
				for (notesse in 0..._song.notes[SongLoad.curDiff][sec].sectionNotes.length)
				{
					if (_song.notes[SongLoad.curDiff][sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[SongLoad.curDiff][sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];

			var note:Note = new Note(daStrumTime, daNoteInfo % 4);
			note.sustainLength = daSus;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(daNoteInfo * GRID_SIZE);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[SongLoad.curDiff][curSection].lengthInSteps)));

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

		_song.notes[SongLoad.curDiff].push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[SongLoad.curDiff][curSection].sectionNotes)
		{
			if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
			{
				curSelectedNote = _song.notes[SongLoad.curDiff][curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		for (i in _song.notes[SongLoad.curDiff][curSection].sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
			{
				var placeIDK:Int = Std.int(((Math.floor(dummyArrow.y / GRID_SIZE) * GRID_SIZE)) / 40);

				placeIDK = Std.int(Math.min(placeIDK, 15));
				placeIDK = Std.int(Math.max(placeIDK, 1));

				trace(placeIDK);

				FlxG.sound.play(Paths.sound('funnyNoise/funnyNoise-0' + placeIDK));

				FlxG.log.add('FOUND EVIL NUMBER');
				_song.notes[SongLoad.curDiff][curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void
	{
		_song.notes[SongLoad.curDiff][curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes[SongLoad.curDiff].length)
		{
			_song.notes[SongLoad.curDiff][daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote():Void
	{
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;
		var noteAlt = false;

		// FlxG.sound.play(Paths.sound('pianoStuff/piano-00' + FlxG.random.int(1, 9)), FlxG.random.float(0.01, 0.3));

		switch (noteData)
		{
			case 0:
				FlxG.sound.play(Paths.sound('pianoStuff/piano-015'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-013'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-009'), FlxG.random.float(0.1, 0.3));
			case 1:
				FlxG.sound.play(Paths.sound('pianoStuff/piano-015'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-012'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-009'), FlxG.random.float(0.1, 0.3));
			case 2:
				FlxG.sound.play(Paths.sound('pianoStuff/piano-015'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-011'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-009'), FlxG.random.float(0.1, 0.3));
			case 3:
				FlxG.sound.play(Paths.sound('pianoStuff/piano-014'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-011'), FlxG.random.float(0.1, 0.3));
				FlxG.sound.play(Paths.sound('pianoStuff/piano-010'), FlxG.random.float(0.1, 0.3));
		}

		var bullshit:Int = Std.int((Math.floor(dummyArrow.y / GRID_SIZE) * GRID_SIZE) / 40);

		FlxG.sound.play(Paths.sound('pianoStuff/piano-00' + Std.string((bullshit % 8) + 1)), FlxG.random.float(0.3, 0.6));
		// trace('bullshit $bullshit'); // trace(Math.floor(dummyArrow.y / GRID_SIZE) * GRID_SIZE);

		_song.notes[SongLoad.curDiff][curSection].sectionNotes.push([noteStrum, noteData, noteSus, noteAlt]);

		curSelectedNote = _song.notes[SongLoad.curDiff][curSection].sectionNotes[_song.notes[SongLoad.curDiff][curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			_song.notes[SongLoad.curDiff][curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteAlt]);
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

			for (i in _song.notes[SongLoad.curDiff])
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
		trace(_song.notes[SongLoad.curDiff]);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes[SongLoad.curDiff])
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
		PlayState.SONG = SongLoad.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel(?debugSavepath:Bool = false)
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

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
