package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import DifficultyIcons;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxUITabMenu;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import sys.FileSystem;
import flash.media.Sound;

#end
import lime.ui.FileDialog;
import lime.app.Event;
import haxe.Json;
import tjson.TJSON;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.ui.FileDialogType;
import haxe.io.Path;
using StringTools;

class NewStageState extends MusicBeatState
{
	var addCharUi:FlxUI;
	var nameText:FlxUIInputText;
	var mainPngButton:FlxButton;
	var mainXmlButton:FlxButton;
	var deadPngButton:FlxButton;
	var deadXmlButton:FlxButton;
	var crazyPngButton:FlxButton;
	var crazyXmlButton:FlxButton;
	var likeText:FlxUIInputText;
	var iconAlive:FlxUINumericStepper;
	var iconDead:FlxUINumericStepper;
	var iconPoison:FlxUINumericStepper;
	var finishButton:FlxButton;
	var coolFile:FileReference;
	var coolData:ByteArray;
	var epicFiles:Array<String>;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	override function create()
	{
		addCharUi = new FlxUI();
		FlxG.mouse.visible = true;
		epicFiles = [];
		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);
		mainPngButton = new FlxButton(10,10,"Stage Files",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN_MULTIPLE);
			coolDialog.onSelectMultiple.add(function (paths:Array<String>):Void {
				epicFiles = paths;
			});
		});
		nameText = new FlxUIInputText(100,50,70,"template");
		likeText = new FlxUIInputText(100, 10, 70,"stage");
		add(mainPngButton);
		finishButton = new FlxButton(FlxG.width - 170, FlxG.height - 50, "Finish", function():Void {
			writeCharacters();
			LoadingState.loadAndSwitchState(new SaveDataState());
		});
		var cancelButton = new FlxButton(FlxG.width - 300, FlxG.height - 50, "Cancel", function():Void
		{
			// go back
			LoadingState.loadAndSwitchState(new SaveDataState());
		});
		add(cancelButton);
		add(finishButton);
		add(nameText);
		add(likeText);
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

	}
	function writeCharacters() {
		// check to see if directory exists
		#if sys
		if (!FileSystem.exists('assets/images/custom_stages/'+nameText.text)) {
			FileSystem.createDirectory('assets/images/custom_stages/'+nameText.text);
		}

		for (epicFile in epicFiles) {
			var coolPath:Path = new Path(epicFile);
			coolPath.dir = 'assets/custom_stages/'+nameText.text;
			var pathString:String = coolPath.dir + '/' + coolPath.file + '.' + coolPath.ext;
			File.copy(epicFile,pathString);
		}

		var epicStageFile:Dynamic =CoolUtil.parseJson(Assets.getText('assets/images/custom_stages/custom_stages.json'));
		trace("parsed");
		Reflect.setField(epicStageFile,nameText.text,likeText.text);

		File.saveContent('assets/images/custom_stages/custom_stages.json', CoolUtil.stringifyJson(epicStageFile));
		trace("cool stuff");
		#end
	}
}
