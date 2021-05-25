package;

import haxe.ds.Option;
import OptionsHandler.TOptions;
import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import lime.utils.Assets;
import Controls.KeyboardScheme;
// visual studio code gets pissy when you don't use conditionals
#if sys
import sys.io.File;
#end
import haxe.Json;
import tjson.TJSON;

using StringTools;
typedef TOption = {
	var name:String;
	var intName:String;
	var value:Bool;
	var desc:String;
	var ?ignore:Bool;
}
class SaveDataState extends MusicBeatState
{

	var saves:FlxTypedSpriteGroup<SaveFile>;
	var options:FlxTypedSpriteGroup<Alphabet>;
	var optionMenu:FlxTypedSpriteGroup<FlxSprite>;
	// this will need to be initialized in title state!!!
	public static var optionList:Array<TOption>;
	var curSelected:Int = 0;
	var mappedOptions:Dynamic = {};
	var inOptionsMenu:Bool = false;
	var optionsSelected:Int = 0;
	var checkmarks:FlxTypedSpriteGroup<FlxSprite>;
	var preferredSave:Int = 0;
	var description:FlxText;
	override function create()
	{
		FlxG.sound.music.stop();
		var goodSound = FNFAssets.getSound('assets/music/custom_menu_music/'
			+ CoolUtil.parseJson(FNFAssets.getText("assets/music/custom_menu_music/custom_menu_music.json")).Options
			+ '/options'
			+ TitleState.soundExt);
		FlxG.sound.playMusic(goodSound);
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		optionList = [
						{name: "Always Show Cutscenes", intName: "alwaysDoCutscenes", value: false, desc: "Force show cutscenes, even in freeplay"}, 
						{name: "Skip Modifier Menu", value: false, intName: "skipModifierMenu", desc: "Skip the modifier menu"}, 
						{name: "Skip Victory Screen", value: false, intName : "skipVictoryScreen", desc: "Skip the victory screen at the end of songs."},
						{name: "Downscroll", value: false, intName: "downscroll", desc: "Put da arrows on the bottom and have em scroll down"},
						{name: "Use New input", value: false, intName: "useCustomInput", desc: "Whether to allow spamming"},
						{name: "Ignore Bad Timing", value: false, intName:"ignoreShittyTiming", desc: "Even with new input on, if you hit a note really poorly, it counts as a miss. This disables that."},
						{name: "DJFK Keys", value: false, intName: "DJFKKeys", desc: "Whether to use dfjk keys."},
						{name: "Show Song Position", value: false, intName: "showSongPos", desc: "Whether to show the song bar."},
						{name: "Style", value: false, intName: "style", desc: "Whether to use fancy style or default to base game."},
						
						{name: "Funny Songs", value: false, intName: "stressTankmen", desc: "funny songs"},
						{name: "Credits", value: false, intName:'credits', desc: "Show the credits!", ignore: true},
						{name: "Sound Test...", value: false, intName: 'soundtest', desc: "Listen to the soundtrack", ignore: true},
						#if sys
						{name:"New Character...", value: false, intName:'newchar', desc: "Make a new character!", ignore: true},
						{name:"New Stage...", value:false, intName:'newstage', desc: "Make a new stage!", ignore: true},
						{name: "New Song...", value: false, intName:'newsong', desc: "Make a new song!", ignore: true},
						{name: "New Week...", value: false, intName: 'newweek', desc: "Make a new week!", ignore: true},
						{name: "Sort...", value: false, intName: 'sort', desc: "Sort some of your current songs/weeks!", ignore : true}
						#end
					];
		// amount of things that aren't options
		var uselessShit:Int = 7;
		#if !sys
		uselessShit = 2;
		#end
		var curOptions:TOptions = OptionsHandler.options;
		for (i in 0...optionList.length) {
			if (optionList[i].ignore)
				continue;
			Reflect.setField(mappedOptions, optionList[i].intName, optionList[i]);
			optionList[i].value = Reflect.field(curOptions, optionList[i].intName);
		}
		// we use a var because if we don't it will read the file each time
		// although it isn't as laggy thanks to assets
		
		preferredSave = curOptions.preferredSave;
		/*
		optionList[0].value = curOptions.alwaysDoCutscenes;
		optionList[1].value = curOptions.skipModifierMenu;
		optionList[2].value = curOptions.skipVictoryScreen;
		optionList[3].value = curOptions.downscroll;
		optionList[4].value = curOptions.useCustomInput;
		optionList[5].value = curOptions.DJFKKeys;
		optionList[6].value = curOptions.showSongPos;
		*/
		saves = new FlxTypedSpriteGroup<SaveFile>();
		menuBG.color = 0xFF7194fc;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		trace("before");
		for (i in 0...10) {
			var saveFile = new SaveFile(420, 0, i);

			saves.add(saveFile);
		}
		trace("x3");
		checkmarks = new FlxTypedSpriteGroup<FlxSprite>();
		options = new FlxTypedSpriteGroup<Alphabet>();
		optionMenu = new FlxTypedSpriteGroup<FlxSprite>();
		optionMenu.add(options);
		trace("hmmm");
		for (j in 0...optionList.length) {
			trace("l53");
			var swagOption = new Alphabet(0,0,optionList[j].name,true,false, false);
			swagOption.isMenuItem = true;
			swagOption.targetY = j;
			trace("l57");
			var coolCheckmark = new FlxSprite().loadGraphic('assets/images/checkmark.png');

			coolCheckmark.visible = optionList[j].value;
			checkmarks.add(coolCheckmark);
			swagOption.add(coolCheckmark);
			options.add(swagOption);
		}
		add(menuBG);
		add(saves);
		add(optionMenu);
		trace("hewwo");
		options.x = 10;
		optionMenu.x = FlxG.width;
		options.y = 10;
		description = new FlxText(750, 150, 350, "", 90);
		description.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		description.text = "Amongus???";
		description.scrollFactor.set();
		optionMenu.add(description);
		changeSelection();
		if (curOptions.allowEditOptions)
			swapMenus();
		super.create();
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			if (!saves.members[curSelected].beingSelected) {
				// our current save saves this
				// we are gonna have to do some shenanagins to save our preffered save

				saveOptions();
				saveOptions();
				FlxG.sound.music.stop();
				LoadingState.loadAndSwitchState(new MainMenuState());
			} else {
				if (saves.members[curSelected].askingToConfirm)
					saves.members[curSelected].askToConfirm(false);
				else
					saves.members[curSelected].beSelected(false);
			}
		}
		if (inOptionsMenu || !saves.members[curSelected].askingToConfirm) {
			if (controls.UP_P)
			{
				if (inOptionsMenu||!saves.members[curSelected].beingSelected)
					changeSelection(-1);
			}
			if (controls.DOWN_P)
			{
				if (inOptionsMenu||!saves.members[curSelected].beingSelected)
					changeSelection(1);
			}
			if (controls.RIGHT_P || controls.LEFT_P) {
				if (saves.members[curSelected].beingSelected)
					saves.members[curSelected].changeSelection();
				else {
					if (OptionsHandler.options.allowEditOptions)
						swapMenus();

				}
			}
		}
		if (controls.ACCEPT) {
			if (saves.members[curSelected].beingSelected) {
				if (!saves.members[curSelected].askingToConfirm) {
					if (saves.members[curSelected].selectingLoad) {
						var saveName = "save" + curSelected;
						FlxG.save.close();
						preferredSave = curSelected;
						FlxG.save.bind(saveName, "bulbyVR");
						FlxG.sound.play('assets/sounds/custom_menu_sounds/'
							+ CoolUtil.parseJson(FNFAssets.getText("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuConfirm+'/confirmMenu.ogg');
						// don't edit the djkf
						if (FlxG.save.data.songScores == null) {
							FlxG.save.data.songScores = ["tutorial" => 0];
						}
						Highscore.load();
					} else {
						saves.members[curSelected].askToConfirm(true);
					}

				} else {
					// this means the user confirmed!
					var oldSave = FlxG.save.name;
					var saveName = "save" + curSelected;
					FlxG.save.bind(saveName, "bulbyVR");
					FlxG.save.erase();
					saves.members[curSelected].askToConfirm(false);
					// sounds like someone farted into the mic. perfect for a delete sfx
					FlxG.sound.play('assets/sounds/freshIntro.ogg');
					FlxG.save.data.songScores = ["tutorial" => 0];
					FlxG.save.bind(oldSave, "bulbyVR");
					Highscore.load();
				}
			} else if (!inOptionsMenu) {
				FlxG.sound.play('assets/sounds/custom_menu_sounds/'
					+ CoolUtil.parseJson(FNFAssets.getText("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuScroll+'/scrollMenu' + TitleState.soundExt);
				saves.members[curSelected].beSelected(true);
			} else {
				switch (optionList[optionsSelected].name) {
					case "New Character...":
						// our current save saves this
						// we are gonna have to do some shenanagins to save our preffered save

						saveOptions();
						LoadingState.loadAndSwitchState(new NewCharacterState());
					case "New Stage...":
						// our current save saves this
						// we are gonna have to do some shenanagins to save our preffered save

						saveOptions();

						LoadingState.loadAndSwitchState(new NewStageState());
					case "New Song...":
						saveOptions();

						LoadingState.loadAndSwitchState(new NewSongState());
					case "New Week...":
						saveOptions();
						NewWeekState.sorted = false;
						LoadingState.loadAndSwitchState(new NewWeekState());
					case "Sort...":
						saveOptions();

						LoadingState.loadAndSwitchState(new SelectSortState());
					case "Sound Test...":
						saveOptions();
						FreeplayState.soundTest = true;
						CategoryState.choosingFor = "freeplay";
						LoadingState.loadAndSwitchState(new CategoryState());
					case "Credits": 
						saveOptions();
						LoadingState.loadAndSwitchState(new CreditsState());
					default:
						if (OptionsHandler.options.allowEditOptions){
							checkmarks.members[optionsSelected].visible = !checkmarks.members[optionsSelected].visible;
							optionList[optionsSelected].value = checkmarks.members[optionsSelected].visible;
						}
						
				}

				FlxG.sound.play('assets/sounds/custom_menu_sounds/'
					+ CoolUtil.parseJson(FNFAssets.getText("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuScroll+'/scrollMenu' + TitleState.soundExt);
			}
		}

	}
	function changeSelection(change:Int = 0)
	{
		if (!inOptionsMenu) {
			FlxG.sound.play('assets/sounds/custom_menu_sounds/'
				+ CoolUtil.parseJson(FNFAssets.getText("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuScroll+'/scrollMenu' + TitleState.soundExt, 0.4);

			curSelected += change;

			if (curSelected < 0)
				curSelected = saves.members.length - 1;
			if (curSelected >= saves.members.length)
				curSelected = 0;


			var bullShit:Int = 0;

			for (item in saves.members)
			{
				item.targetY = bullShit - curSelected;
				bullShit++;

				item.color = 0xFF828282;
				// item.setGraphicSize(Std.int(item.width * 0.8));

				if (item.targetY == 0)
				{
					item.color = 0xFFFFFFFF;
					// item.setGraphicSize(Std.int(item.width));
				}
			}
		} else {
			FlxG.sound.play('assets/sounds/custom_menu_sounds/'
				+ CoolUtil.parseJson(FNFAssets.getText("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuScroll+'/scrollMenu' + TitleState.soundExt, 0.4);

			optionsSelected += change;

			if (optionsSelected < 0)
				optionsSelected = options.members.length - 1;
			if (optionsSelected >= options.members.length)
				optionsSelected = 0;


			var bullShit:Int = 0;

			for (item in options.members)
			{
				item.targetY = bullShit - optionsSelected;
				bullShit++;

				item.alpha = 0.6;
				// item.setGraphicSize(Std.int(item.width * 0.8));

				if (item.targetY == 0)
				{
					item.alpha = 1;
					// item.setGraphicSize(Std.int(item.width));
				}
			}
			description.text = optionList[optionsSelected].desc;
		}

	}
	function swapMenus() {
		if (inOptionsMenu) {
			FlxTween.tween(optionMenu, {x: FlxG.width}, 0.2, {type: FlxTweenType.ONESHOT, ease: FlxEase.backInOut});
			FlxTween.tween(saves, {x: 0}, 0.2, {type: FlxTweenType.ONESHOT, ease: FlxEase.backInOut});
			inOptionsMenu = false;
		} else {
			FlxTween.tween(optionMenu, {x: 0}, 0.2, {type: FlxTweenType.ONESHOT, ease: FlxEase.backInOut});
			FlxTween.tween(saves, {x: -FlxG.width }, 0.2, {type: FlxTweenType.ONESHOT, ease: FlxEase.backInOut});
			inOptionsMenu = true;
		}
	}
	function saveOptions() {
		var noneditableoptions:Dynamic = {
			"allowEditOptions": OptionsHandler.options.allowEditOptions,
			"preferredSave": preferredSave,
			"useSaveDataMenu": true
		};
		for (field in Reflect.fields(mappedOptions)) {
			Reflect.setField(noneditableoptions, field, Reflect.field(mappedOptions, field).value);
		}
		OptionsHandler.options = noneditableoptions;
	}
}
