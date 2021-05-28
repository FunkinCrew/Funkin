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
using StringTools;

class NewCharacterState extends MusicBeatState
{
	var addCharUi:FlxUI;
	var nameText:FlxUIInputText;
	var mainPngButton:FlxButton;
	var mainXmlButton:FlxButton;
	var deadPngButton:FlxButton;
	var deadXmlButton:FlxButton;
	var crazyPngButton:FlxButton;
	var crazyXmlButton:FlxButton;
	var iconButton:FlxButton;
	var likeText:FlxUIInputText;
	var iconAlive:FlxUINumericStepper;
	var iconDead:FlxUINumericStepper;
	var iconPoison:FlxUINumericStepper;
	var finishButton:FlxButton;
	var coolFile:FileReference;
	var coolData:ByteArray;
	var epicFiles:Dynamic;
	var colorsText:FlxUIInputText;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	override function create()
	{
		addCharUi = new FlxUI();
		FlxG.mouse.visible = true;
		epicFiles = {
			"charpng": null,
			"charxml":null,
			"deadpng":null,
			"deadxml":null,
			"crazyxml":null,
			"crazypng":null,
			"icons": null
		};
		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);
		mainPngButton = new FlxButton(10,10,"char.png",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles.charpng = path;
			});
		});
		iconButton = new FlxButton(10,300,"icons",function():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function(path:String):Void
			{
				epicFiles.icons = path;
			});
		});
		likeText = new FlxUIInputText(100, 10, 70,"bf");
		nameText = new FlxUIInputText(100,50,70,"template");
		var aliveText = new FlxText(100,70,"Alive Icon");
		iconAlive = new FlxUINumericStepper(100, 90,1,0,0,49);
		var deadText = new FlxText(100,120,"Dead Icon");
		iconDead = new FlxUINumericStepper(100, 140,1,1,0,49);
		var poisonText = new FlxText(100,170,"Poison Icon");
		iconPoison = new FlxUINumericStepper(100, 190,1,24,0,49);
		colorsText = new FlxUIInputText(100, 240, 70, "#FFFFFF,#FFFFFF");
		add(nameText);
		add(likeText);
		add(iconAlive);
		add(iconDead);
		add(iconPoison);
		add(poisonText);
		add(deadText);
		add(aliveText);
		add(mainPngButton);
		add(iconButton);
		add(colorsText);
		mainXmlButton = new FlxButton(10,60,"char.xml/txt",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles.charxml = path;
			});
		});
		add(mainXmlButton);
		deadPngButton = new FlxButton(10,110,"dead.png",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles.deadpng = path;
			});
		});
		crazyPngButton = new FlxButton(10,170,"crazy.png",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles.crazypng = path;
			});
		});
		deadXmlButton = new FlxButton(10,220,"dead.xml",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles.deadxml = path;
			});
		});
		crazyXmlButton = new FlxButton(10,260,"crazy.xml",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles.crazyxml = path;
			});
		});
		finishButton = new FlxButton(FlxG.width - 170, FlxG.height - 50, "Finish", function():Void {
			writeCharacters();
			LoadingState.loadAndSwitchState(new SaveDataState());
		});
		var cancelButton = new FlxButton(FlxG.width - 300, FlxG.height - 50, "Cancel", function():Void
		{
			// go back
			LoadingState.loadAndSwitchState(new SaveDataState());
		});
		add(crazyXmlButton);
		add(deadXmlButton);
		add(deadPngButton);
		add(finishButton);
		add(cancelButton);
		add(crazyPngButton);
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

	}
	function writeCharacters() {
		// check to see if directory exists
		#if sys
		if (!FileSystem.exists('assets/images/custom_chars/'+nameText.text)) {
			FileSystem.createDirectory('assets/images/custom_chars/'+nameText.text);
		}
		trace(epicFiles.charpng);
		trace("hello");
		File.copy(epicFiles.charpng,'assets/images/custom_chars/'+nameText.text+'/char.png');
		// if it was an xml file save it as one
		// otherwise save it as txt
		if (StringTools.endsWith(epicFiles.charxml,"xml"))
			File.copy(epicFiles.charxml,'assets/images/custom_chars/'+nameText.text+'/char.xml');
		else
			File.copy(epicFiles.charxml,'assets/images/custom_chars/'+nameText.text+'/char.txt');
		if (epicFiles.deadpng != null) {
			File.copy(epicFiles.deadpng,'assets/images/custom_chars/'+nameText.text+'/dead.png');
			File.copy(epicFiles.deadxml,'assets/images/custom_chars/'+nameText.text+'/dead.xml');
		}
		if (epicFiles.crazypng != null) {
			File.copy(epicFiles.crazypng,'assets/images/custom_chars/'+nameText.text+'/crazy.png');
			File.copy(epicFiles.crazyxml,'assets/images/custom_chars/'+nameText.text+'/crazy.xml');
		}
		if (epicFiles.icons != null ) {
			File.copy(epicFiles.icons, "assets/images/custom_chars/"+nameText.text+'/icons.png');
		}
		trace("hello");
		var epicCharFile:Dynamic =CoolUtil.parseJson(Assets.getText('assets/images/custom_chars/custom_chars.jsonc'));
		trace("parsed");
		var commaSeperatedColors = colorsText.text.split(",");
		Reflect.setField(epicCharFile,nameText.text,{like:likeText.text,icons: [Std.int(iconAlive.value),Std.int(iconDead.value),Std.int(iconPoison.value)], colors: commaSeperatedColors});

		File.saveContent('assets/images/custom_chars/custom_chars.jsonc', CoolUtil.stringifyJson(epicCharFile));
		trace("cool stuff");
		#end
	}
}
