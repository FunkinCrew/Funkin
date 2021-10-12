package debuggers;

import game.Character;
import modding.CharacterConfig;
import ui.FlxUIDropDownMenuCustom;
import lime.tools.AssetType;
#if sys
import modding.ModdingSound;
import sys.FileSystem;
import polymod.fs.PolymodFileSystem;
import polymod.backends.PolymodAssets;
#end
import utilities.Difficulties;
import game.Song;
import states.LoadingState;
import utilities.CoolUtil;
import game.Conductor;
import states.PlayState;
import states.MusicBeatState;
import ui.HealthIcon;
import game.Note;
import game.Conductor.BPMChangeEvent;
import game.Section.SwagSection;
import game.Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

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

	var difficulty:String = 'normal';

	var typingShit:FlxInputText;
	var swagShit:FlxInputText;
	var modchart_Input:FlxInputText;
	var cutscene_Input:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var tempBpm:Float = 0;

	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var characters:Map<String, Array<String>> = new Map<String, Array<String>>();
	var gridBlackLine:FlxSprite;

	var selected_mod:String = "default";

	var stepperSusLength:FlxUINumericStepper;
	var stepperCharLength:FlxUINumericStepper;

	var current_Note_Character:Int = 0;

	override function create()
	{
		// FOR WHEN COMING IN FROM THE TOOLS PAGE LOL
		if (Assets.getLibrary("shared") == null)
			Assets.loadLibrary("shared").onComplete(function (_) { });

		#if sys
		var characterList = CoolUtil.coolTextFilePolymod(Paths.txt('characterList'));
		#else
		var characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

		for(Text in characterList)
		{
			var Properties = Text.split(":");

			var name = Properties[0];
			var mod = Properties[1];

			var base_array;

			if(characters.get(mod) != null)
				base_array = characters.get(mod);
			else
				base_array = [];

			base_array.push(name);
			characters.set(mod, base_array);
		}

		curSection = lastSection;

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		leftIcon.updateHitbox();
		rightIcon.updateHitbox();

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -45);
		rightIcon.setPosition(gridBG.width / 2, -45);

		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadFromJson("test", "test");

		_song.speed = PlayState.previousScrollSpeedLmao;

		FlxG.mouse.visible = true;

		tempBpm = _song.bpm;

		addSection();

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song Options", label: 'Song Options'},
			{name: "Chart Options", label: 'Chart Options'},
			{name: "Art Options", label: 'Art Options'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = 0;
		UI_box.y = 100;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();

		add(curRenderedNotes);
		add(curRenderedSustains);

		updateHeads();
		updateGrid();

		super.create();
	}

	function addSongUI():Void
	{
		//base ui thingy :D
		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song Options";

		// interactive

		// inputs
		var UI_songTitle = new FlxUIInputText(10, 30, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var UI_songDiff = new FlxUIInputText(10, UI_songTitle.y + UI_songTitle.height + 2, 70, PlayState.storyDifficultyStr, 8);
		swagShit = UI_songDiff;

		var check_voices = new FlxUICheckBox(10, UI_songDiff.y + UI_songDiff.height + 1, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;

		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, check_voices.y + check_voices.height + 5, 0.1, 1, 0.1, 999, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + stepperBPM.height, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperKeyCount:FlxUINumericStepper = new FlxUINumericStepper(10, stepperSpeed.y + stepperSpeed.height, 1, 4, 1, 18);
		stepperKeyCount.value = _song.keyCount;
		stepperKeyCount.name = 'song_keycount';

		var check_mute_inst = new FlxUICheckBox(10, stepperKeyCount.y + stepperKeyCount.height + 10, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		modchart_Input = new FlxUIInputText(10, check_mute_inst.y + check_mute_inst.height + 2, 70, _song.modchartPath, 8);

		cutscene_Input = new FlxUIInputText(modchart_Input.x, modchart_Input.y + modchart_Input.height + 2, 70, _song.cutscene, 8);

		var saveButton:FlxButton = new FlxButton(10, 220, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + saveButton.height + 20, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase(), difficulty.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(saveButton.x, saveButton.y + saveButton.height + 20, 'Load Autosave', loadAutosave);

		var restart = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + loadAutosaveBtn.height + 20,"Reset Chart", function()
		{
			for (ii in 0..._song.notes.length)
				{
					for (i in 0..._song.notes[ii].sectionNotes.length)
					{
						_song.notes[ii].sectionNotes = [];
					}
				}
	
				resetSection(true);
		});

		// labels

		var songNameLabel = new FlxText(UI_songTitle.x + UI_songTitle.width + 1, UI_songTitle.y, 0, "Song Name", 9);
		var diffLabel = new FlxText(UI_songDiff.x + UI_songDiff.width + 1, UI_songDiff.y, 0, "Difficulty", 9);

		var bpmLabel = new FlxText(stepperBPM.x + stepperBPM.width + 1, stepperBPM.y, 0, "BPM", 9);
		var speedLabel = new FlxText(stepperSpeed.x + stepperSpeed.width + 1, stepperSpeed.y, 0, "Scroll Speed", 9);
		var keyCountLabel = new FlxText(stepperKeyCount.x + stepperKeyCount.width + 1, stepperKeyCount.y, 0, "Key Count", 9);

		var modChartLabel = new FlxText(modchart_Input.x + modchart_Input.width + 1, modchart_Input.y, 0, "Modchart Path", 9);
		var cutsceneLabel = new FlxText(cutscene_Input.x + cutscene_Input.width + 1, cutscene_Input.y, 0, "Cutscene JSON Name", 9);

		var settingsLabel = new FlxText(10, 10, 0, "Setings", 9);
		var actionsLabel = new FlxText(10, 200, 0, "Actions", 9);

		// adding things
		tab_group_song.add(songNameLabel);
		tab_group_song.add(diffLabel);
		
		tab_group_song.add(bpmLabel);
		tab_group_song.add(speedLabel);
		tab_group_song.add(keyCountLabel);

		tab_group_song.add(modChartLabel);
		tab_group_song.add(cutsceneLabel);

		tab_group_song.add(settingsLabel);
		tab_group_song.add(actionsLabel);

		tab_group_song.add(UI_songTitle);
		tab_group_song.add(UI_songDiff);
		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(modchart_Input);
		tab_group_song.add(cutscene_Input);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(restart);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stepperKeyCount);

		// final addings
		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		// also this, idk what it does but ehhhh who cares \_(:/)_/
		FlxG.camera.follow(strumLine);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var cur_Note_Type:String = "default";

	function addSectionUI():Void
	{
		// SECTION CREATION
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Chart Options';

		// Section Titles
		var sectionText = new FlxText(10, 10, 0, "Section Options", 9);
		var noteText = new FlxText(10, 240, 0, "Note Options", 9);

		// Interactive Stuff

		// Section Section (lol) //

		// numbers
		stepperLength = new FlxUINumericStepper(10, 30, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 100, 0.1, Conductor.bpm, 0, 999, 1);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var copySectionCount:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		// https://www.youtube.com/watch?v=B5O30UmxKLM&t=186
		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last", function()
		{
			copySection(Std.int(copySectionCount.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var clearLeftSectionButton:FlxButton = new FlxButton(clearSectionButton.x + clearSectionButton.width + 2, 150, "Clear Left", function()
		{
			clearSectionSide(0);
		});

		var clearRightSectionButton:FlxButton = new FlxButton(clearSectionButton.x + clearSectionButton.width + 2, 170, "Clear Right", function()
		{
			clearSectionSide(1);
		});

		var swapSectionButton:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				_song.notes[curSection].sectionNotes[i][1] += _song.keyCount;
				_song.notes[curSection].sectionNotes[i][1] %= _song.keyCount * 2;

				updateGrid();
			}
		});

		// checkboxes
		check_mustHitSection = new FlxUICheckBox(10, 50, null, null, "Camera points at P1", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;

		check_altAnim = new FlxUICheckBox(10, 195, null, null, "Enemy Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 80, null, null, 'Change BPM?', 100);
		check_changeBPM.name = 'check_changeBPM';

		// Labels for Interactive Stuff
		var stepperSizeText = new FlxText(stepperLength.x + stepperLength.width + 2, stepperLength.y, 0, "Section size", 9);
		var stepperText:FlxText = new FlxText(110 + copySectionCount.width, 130, 0, "Sections back", 9);
		var bpmText:FlxText = new FlxText(12 + stepperSectionBPM.width, 100, 0, "New BPM", 9);

		// end of section section //

		// NOTE SECTION //

		// numbers
		stepperSusLength = new FlxUINumericStepper(10, 260, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		stepperCharLength = new FlxUINumericStepper(stepperSusLength.x, stepperSusLength.y + stepperSusLength.height + 1, 1, 0, 0, 999);
		stepperCharLength.value = 0;
		stepperCharLength.name = 'note_char';

		// labels
		var susText = new FlxText(stepperSusLength.x + stepperSusLength.width + 1, stepperSusLength.y, 0, "Sustain note length", 9);
		var charText = new FlxText(stepperCharLength.x + stepperCharLength.width + 1, stepperCharLength.y, 0, "Character", 9);

		// Adding everything in

		var setCharacterLeftSide:FlxButton = new FlxButton(stepperCharLength.x, stepperCharLength.y + stepperCharLength.height + 1, "Char To Left", function()
		{
			characterSectionSide(0, Std.int(stepperCharLength.value));
		});

		var setCharacterRightSide:FlxButton = new FlxButton(setCharacterLeftSide.x + setCharacterLeftSide.width + 2, setCharacterLeftSide.y, "Char To Right", function()
		{
			characterSectionSide(1, Std.int(stepperCharLength.value));
		});

		// dropdown lmao
		var arrow_Types = CoolUtil.coolTextFilePolymod(Paths.txt("arrowTypes"));

		var typeDropDown = new FlxUIDropDownMenuCustom(setCharacterLeftSide.x, setCharacterLeftSide.y + setCharacterLeftSide.height, FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrow_Types, true), function(type:String)
		{
			cur_Note_Type = arrow_Types[Std.parseInt(type)];
		});

		typeDropDown.selectedLabel = cur_Note_Type;

		// note stuff
		tab_group_section.add(noteText);

		tab_group_section.add(stepperSusLength);
		tab_group_section.add(susText);

		tab_group_section.add(stepperCharLength);
		tab_group_section.add(charText);

		tab_group_section.add(typeDropDown);

		tab_group_section.add(setCharacterLeftSide);
		tab_group_section.add(setCharacterRightSide);

		// section stuff
		tab_group_section.add(sectionText);

		tab_group_section.add(stepperLength);
		tab_group_section.add(bpmText);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(copySectionCount);
		tab_group_section.add(stepperText);
		tab_group_section.add(stepperSizeText);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(clearLeftSectionButton);
		tab_group_section.add(clearRightSectionButton);
		tab_group_section.add(swapSectionButton);

		// final addition
		UI_box.addGroup(tab_group_section);
	}

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Art Options';

		var arrayCharacters = ["bf","gf",""];
		var tempCharacters = characters.get(selected_mod);

		for(Item in tempCharacters)
		{
			arrayCharacters.push(Item);
		}

		// CHARS
		var player1DropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrayCharacters, true), function(character:String)
		{
			_song.player1 = arrayCharacters[Std.parseInt(character)];
			updateHeads();
		});

		player1DropDown.selectedLabel = _song.player1;

		var gfDropDown = new FlxUIDropDownMenuCustom(10, 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrayCharacters, true), function(character:String)
		{
			_song.gf = arrayCharacters[Std.parseInt(character)];
		});

		gfDropDown.selectedLabel = _song.gf;

		var player2DropDown = new FlxUIDropDownMenuCustom(10, 70, FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrayCharacters, true), function(character:String)
		{
			_song.player2 = arrayCharacters[Std.parseInt(character)];
			updateHeads();
		});
		
		player2DropDown.selectedLabel = _song.player2;

		// OTHER
		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));

		var stageDropDown = new FlxUIDropDownMenuCustom(10, 120, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true), function(stage:String)
		{
			_song.stage = stages[Std.parseInt(stage)];
		});

		stageDropDown.selectedLabel = _song.stage;

		var mods:Array<String> = [];

		var iterator = characters.keys();

		while(iterator.hasNext())
		{
			mods.push(iterator.next());
		}

		var modDropDown = new FlxUIDropDownMenuCustom(10, 140, FlxUIDropDownMenuCustom.makeStrIdLabelArray(mods, true), function(mod:String)
		{
			selected_mod = mods[Std.parseInt(mod)];

			arrayCharacters = ["bf","gf",""];
			tempCharacters = characters.get(selected_mod);
			
			for(Item in tempCharacters)
			{
				arrayCharacters.push(Item);
			}

			var character_Data_List = FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrayCharacters, true);
			
			player1DropDown.setData(character_Data_List);
			gfDropDown.setData(character_Data_List);
			player2DropDown.setData(character_Data_List);

			player1DropDown.selectedLabel = _song.player1;
			gfDropDown.selectedLabel = _song.gf;
			player2DropDown.selectedLabel = _song.player2;
		});

		modDropDown.selectedLabel = selected_mod;

		// LABELS
		var characterLabel = new FlxText(10, 10, 0, "Characters", 9);
		var otherLabel = new FlxText(10, 100, 0, "Other", 9);

		var p1Label = new FlxText(12 + player1DropDown.width, player1DropDown.y, 0, "Player 1", 9);
		var gfLabel = new FlxText(12 + gfDropDown.width, gfDropDown.y, 0, "Girlfriend", 9);
		var p2Label = new FlxText(12 + player2DropDown.width, player2DropDown.y, 0, "Player 2", 9);
		var stageLabel = new FlxText(12 + stageDropDown.width, stageDropDown.y, 0, "Stage", 9);

		var modLabel = new FlxText(12 + modDropDown.width, modDropDown.y, 0, "Current Mod", 9);

		// adding main dropdowns
		tab_group_note.add(modDropDown);
		tab_group_note.add(stageDropDown);
		tab_group_note.add(player2DropDown);
		tab_group_note.add(gfDropDown);
		tab_group_note.add(player1DropDown);

		// adding labels
		tab_group_note.add(characterLabel);
		tab_group_note.add(otherLabel);

		tab_group_note.add(p1Label);
		tab_group_note.add(gfLabel);
		tab_group_note.add(p2Label);
		tab_group_note.add(stageLabel);
		tab_group_note.add(modLabel);

		// final add
		UI_box.addGroup(tab_group_note);
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		#if sys
		if(Assets.exists(Paths.inst(daSong)))
			FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(daSong));
		else
			FlxG.sound.music = new ModdingSound().loadByteArray(PolymodAssets.getBytes(Paths.instSYS(daSong)));

		FlxG.sound.music.persist = true;

		#else
		FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(daSong));
		FlxG.sound.music.persist = true;
		#end
		
		if (_song.needsVoices)
		{
			#if sys
			if(Assets.exists(Paths.voices(daSong)))
				vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
			else
				vocals = new ModdingSound().loadByteArray(PolymodAssets.getBytes(Paths.voicesSYS(daSong)));
			#else
			vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
			#end
		}
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

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
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;

			switch (label)
			{
				case 'Camera points at P1':
					_song.notes[curSection].mustHitSection = check.checked;
					updateHeads();
				case 'Change BPM?':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');

					//if(check.checked == true)
				case "Enemy Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);

			switch(wname)
			{
				case 'section_length':
					_song.notes[curSection].lengthInSteps = Std.int(nums.value);
					updateGrid();
				case 'song_speed':
					_song.speed = nums.value;
				case 'song_keycount':
					_song.keyCount = Std.int(nums.value);
					updateGrid();
				case 'song_bpm':
					tempBpm = nums.value;
					Conductor.mapBPMChanges(_song);
					Conductor.changeBPM(Std.int(nums.value));
				case 'note_susLength':
					curSelectedNote[2] = nums.value;
					updateGrid();
				case 'note_char':
					current_Note_Character = Std.int(nums.value);
				case 'section_bpm':
					_song.notes[curSection].bpm = Std.int(nums.value);
					updateGrid();
			}
		}
	}

	var updatedSection:Bool = false;

	function sectionStartTime():Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;

		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}

			daPos += 4 * (1000 * (60 / daBPM));
		}

		return daPos;
	}

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;
		difficulty = swagShit.text.toLowerCase();
		PlayState.storyDifficultyStr = difficulty.toUpperCase();
		_song.modchartPath = modchart_Input.text;
		_song.cutscene = cutscene_Input.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			trace(curStep);
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed)
		{
			var coolNess = true;

			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note) && Math.floor(FlxG.mouse.x / GRID_SIZE) == note.rawNoteData)
					{
						coolNess = false;

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

			if(coolNess)
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			lastSection = curSection;

			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			vocals.stop();
			LoadingState.loadAndSwitchState(new PlayState());
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

				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
				vocals.time = FlxG.sound.music.time;
			}

			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = 700 * FlxG.elapsed;

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

		bpmTxt.text = (
			"Time: "
			+ Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSection
			+ "\nBPM: "
			+ Conductor.bpm
			+ "\nCurStep: "
			+ curStep
			+ "\nCurBeat: "
			+ curBeat
		);

		leftIcon.x = gridBG.x;
		rightIcon.x = gridBlackLine.x;

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

				// lol so one e press works as a held note lmao
				curSelectedNote[2] = Math.ceil(curSelectedNote[2]);
			}
		}

		updateNoteUI();
		updateGrid();
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

		if (_song.notes[sec] != null)
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

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3], note[4]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
		var healthIconP2:String = loadHealthIconFromCharacter(_song.player2);

		if (_song.notes[curSection].mustHitSection)
		{
			leftIcon.playSwagAnim(healthIconP1);
			rightIcon.playSwagAnim(healthIconP2);
		}
		else
		{
			leftIcon.playSwagAnim(healthIconP2);
			rightIcon.playSwagAnim(healthIconP1);
		}
	}

	function loadHealthIconFromCharacter(char:String) {
		var characterPath:String = 'character data/' + char + '/config';

		#if polymod
		var path:String = Paths.json(characterPath);

		if (!PolymodAssets.exists(path)) {
			path = Paths.json('character data/bf/config');
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.json(characterPath);

		if (!Assets.exists(path))
		#end
		{
			path = Paths.json('character data/bf/config');
		}

		var rawJson = Assets.getText(path).trim();

		var json:CharacterConfig = cast Json.parse(rawJson);

		return (json.healthIcon != null && json.healthIcon != "" ? json.healthIcon : char);
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void
	{
		remove(gridBG);
		gridBG.kill();
		gridBG.destroy();

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * _song.keyCount * 2, GRID_SIZE * _song.notes[curSection].lengthInSteps);
        add(gridBG);

		remove(gridBlackLine);
		gridBlackLine.kill();
		gridBlackLine.destroy();

		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;

			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;

			Conductor.changeBPM(daBPM);
		}

		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];

			var daType = i[4];

			if(daType == null)
				daType = "default";

			var note:Note = new Note(daStrumTime, daNoteInfo % _song.keyCount, null, false, 0, daType, _song);
			note.sustainLength = daSus;

			note.setGraphicSize(0, Std.parseInt(PlayState.instance.arrow_Configs.get(daType)[2]));
			note.updateHitbox();

			note.x = Math.floor(daNoteInfo * GRID_SIZE) + Std.parseFloat(PlayState.instance.arrow_Configs.get(daType)[1]);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps))) + Std.parseFloat(PlayState.instance.arrow_Configs.get(daType)[3]);

			note.rawNoteData = daNoteInfo;

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

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i.strumTime == note.strumTime && i.noteData % _song.keyCount == note.noteData)
			{
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] == note.rawNoteData)
			{
				FlxG.log.add('FOUND EVIL NUMBER');
				_song.notes[curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSectionSide(side:Int = 0):Void
	{
		var removeThese = [];

		for(noteIndex in 0..._song.notes[curSection].sectionNotes.length)
		{
			var i = _song.notes[curSection].sectionNotes[noteIndex];

			if(side == 0)
			{
				if(i[1] < _song.keyCount)
				{
					removeThese.push(i);
				}
			}
			else if(side == 1)
			{
				if(i[1] >= _song.keyCount)
				{
					removeThese.push(i);
				}
			}
		}

		if(removeThese != [])
		{
			for(x in removeThese)
			{
				_song.notes[curSection].sectionNotes.remove(x);
			}

			updateGrid();
		}
	}

	function characterSectionSide(side:Int = 0, character:Int = 0):Void
	{
		var changeThese = [];

		for(noteIndex in 0..._song.notes[curSection].sectionNotes.length)
		{
			var noteData = _song.notes[curSection].sectionNotes[noteIndex][1];

			if(side == 0)
			{
				if(noteData < _song.keyCount)
				{
					changeThese.push(noteIndex);
				}
			}
			else if(side == 1)
			{
				if(noteData >= _song.keyCount)
				{
					changeThese.push(noteIndex);
				}
			}
		}

		if(changeThese != [])
		{
			for(x in changeThese)
			{
				_song.notes[curSection].sectionNotes[x][3] = character;
			}

			updateGrid();
		}
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote():Void
	{
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;

		if(cur_Note_Type != "default")
			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, current_Note_Character, cur_Note_Type]);
		else
			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, current_Note_Character]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			if(cur_Note_Type != "default")
				_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + _song.keyCount) % (_song.keyCount * 2), noteSus, current_Note_Character, cur_Note_Type]);
			else
				_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + _song.keyCount) % (_song.keyCount * 2), noteSus, current_Note_Character]);
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

			for (i in _song.notes)
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
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String, ?diff:String):Void
	{
		var songT:String = song;

		if(diff != 'normal')
			songT = songT + '-' + diff.toLowerCase();

		PlayState.storyDifficulty = Difficulties.stringToNum(diff.toLowerCase());
		PlayState.storyDifficultyStr = diff;
		PlayState.SONG = Song.loadFromJson(songT.toLowerCase(), song.toLowerCase());

		LoadingState.instance.checkLoadSong(LoadingState.getSongPath());

		if (PlayState.SONG.needsVoices)
			LoadingState.instance.checkLoadSong(LoadingState.getVocalPath());

		FlxG.sound.music.stop();
		vocals.stop();

		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			var gamingName = _song.song.toLowerCase();

			if(difficulty.toLowerCase() != 'normal')
				gamingName = gamingName + '-' + difficulty.toLowerCase();

			_file.save(data.trim(), gamingName + ".json");
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
