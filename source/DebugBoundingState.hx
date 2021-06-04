package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import lime.utils.Assets as LimeAssets;
import openfl.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import sys.io.File;

using StringTools;
using flixel.util.FlxSpriteUtil;

class DebugBoundingState extends FlxState
{
	/* 
		TODAY'S TO-DO
		- Refactor the animation offset menu to be in this one instead
			- Cleaner UI
			- Easier to access, test, and export data from.
			- Easier movement
			- Onion skinning
			- Mouse controls??
			- Load different characters on the fly

	 */
	var bg:FlxSprite;
	var fileInfo:FlxText;

	var txtGrp:FlxGroup;

	var hudCam:FlxCamera;

	var charInput:FlxUIDropDownMenu;

	var curView:ANIMDEBUGVIEW = SPRITESHEET;

	var spriteSheetView:FlxGroup;
	var animDropDownMenu:FlxUIDropDownMenu;
	var dropDownSetup:Bool = false;

	override function create()
	{
		Paths.setCurrentLevel('week1');

		hudCam = new FlxCamera();
		hudCam.bgColor.alpha = 0;

		FlxG.cameras.add(hudCam, false);

		bg = FlxGridOverlay.create(10, 10);

		bg.scrollFactor.set();
		add(bg);

		initSpritesheetView();

		// charInput = new FlxInputText(300, 10, 150, "bf", 16);
		// charInput.focusCam = hudCam;
		// charInput.cameras = [hudCam];
		// charInput.scrollFactor.set();

		animDropDownMenu = new FlxUIDropDownMenu(370, 20, FlxUIDropDownMenu.makeStrIdLabelArray(['weed'], true));
		animDropDownMenu.cameras = [hudCam];
		add(animDropDownMenu);

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		charInput = new FlxUIDropDownMenu(200, 20, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(str:String)
		{
			loadAnimShit(characters[Std.parseInt(str)]);
			// trace();
		});
		// charInput.
		charInput.cameras = [hudCam];
		add(charInput);

		super.create();
	}

	function initSpritesheetView():Void
	{
		spriteSheetView = new FlxGroup();
		add(spriteSheetView);

		var tex = Paths.getSparrowAtlas('characters/temp');
		// tex.frames[0].uv

		var bf:FlxSprite = new FlxSprite();
		bf.loadGraphic(tex.parent);
		spriteSheetView.add(bf);

		var swagGraphic:FlxSprite = new FlxSprite().makeGraphic(tex.parent.width, tex.parent.height, FlxColor.TRANSPARENT);

		for (i in tex.frames)
		{
			var lineStyle:LineStyle = {color: FlxColor.RED, thickness: 2};

			var uvW:Float = (i.uv.width * i.parent.width) - (i.uv.x * i.parent.width);
			var uvH:Float = (i.uv.height * i.parent.height) - (i.uv.y * i.parent.height);

			// trace(Std.int(i.uv.width * i.parent.width));
			swagGraphic.drawRect(i.uv.x * i.parent.width, i.uv.y * i.parent.height, uvW, uvH, FlxColor.TRANSPARENT, lineStyle);
			// swagGraphic.setPosition(, );
			// trace(uvH);
		}

		txtGrp = new FlxGroup();
		txtGrp.cameras = [hudCam];
		spriteSheetView.add(txtGrp);

		addInfo('boyfriend.xml', "");
		addInfo('Width', bf.width);
		addInfo('Height', bf.height);

		swagGraphic.antialiasing = true;
		spriteSheetView.add(swagGraphic);

		FlxG.stage.window.onDropFile.add(function(path:String)
		{
			trace("DROPPED FILE FROM: " + Std.string(path));
			var newPath = "./" + Paths.image('characters/temp');
			File.copy(path, newPath);

			var swag = Paths.image('characters/temp');

			if (bf != null)
				remove(bf);
			FlxG.bitmap.removeByKey(Paths.image('characters/temp'));
			Assets.cache.clear();

			bf.loadGraphic(Paths.image('characters/temp'));
			add(bf);
		});
	}

	function addInfo(str:String, value:Dynamic)
	{
		var swagText:FlxText = new FlxText(10, 10 + (28 * txtGrp.length));
		swagText.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.scrollFactor.set();
		txtGrp.add(swagText);

		swagText.text = str + ": " + Std.string(value);
	}

	function checkLibrary(library:String)
	{
		trace(Assets.hasLibrary(library));
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;

			// var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function(_)
			{
				trace('LOADED... awesomeness...');
				// callback();
			});
		}
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ONE)
			curView = SPRITESHEET;
		if (FlxG.keys.justReleased.TWO)
			curView = OFFSETSHIT;

		switch (curView)
		{
			case SPRITESHEET:
				spriteSheetView.visible = true;
			case OFFSETSHIT:
				spriteSheetView.visible = false;
				offsetControls();
		}

		/* if (charInput.hasFocus && FlxG.keys.justPressed.ENTER)
			{
				loadAnimShit();
		}*/

		CoolUtil.mouseCamDrag();
		CoolUtil.mouseWheelZoom();

		// bg.scale.x = FlxG.camera.zoom;
		// bg.scale.y = FlxG.camera.zoom;

		bg.setGraphicSize(Std.int(bg.width / FlxG.camera.zoom));

		super.update(elapsed);
	}

	function offsetControls():Void
	{
		if (FlxG.keys.justPressed.RBRACKET)
		{
			if (Std.parseInt(animDropDownMenu.selectedId) + 1 < animDropDownMenu.length)
				animDropDownMenu.selectedId = Std.string(Std.parseInt(animDropDownMenu.selectedId) + 1);
			animDropDownMenu.callback(animDropDownMenu.selectedId);
		}
		if (FlxG.keys.justPressed.LBRACKET)
		{
			if (Std.parseInt(animDropDownMenu.selectedId) - 1 >= 0)
				animDropDownMenu.selectedId = Std.string(Std.parseInt(animDropDownMenu.selectedId) - 1);
			animDropDownMenu.callback(animDropDownMenu.selectedId);
		}

		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
		{
			var animName = animDropDownMenu.selectedLabel;
			var coolValues:Array<Dynamic> = swagChar.animOffsets.get(animName);

			var multiplier:Float = 5;

			if (FlxG.keys.pressed.CONTROL)
				multiplier = 1;

			if (FlxG.keys.pressed.SHIFT)
				multiplier = 10;

			if (FlxG.keys.justPressed.RIGHT)
				coolValues[0] -= 1 * multiplier;
			else if (FlxG.keys.justPressed.LEFT)
				coolValues[0] += 1 * multiplier;
			else if (FlxG.keys.justPressed.UP)
				coolValues[1] += 1 * multiplier;
			else if (FlxG.keys.justPressed.DOWN)
				coolValues[1] -= 1 * multiplier;

			swagChar.animOffsets.set(animDropDownMenu.selectedLabel, coolValues);
			swagChar.playAnim(animName);
			trace(animName);
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			var outputString:String = "";

			for (i in swagChar.animOffsets.keys())
			{
				outputString += i + " " + swagChar.animOffsets.get(i)[0] + " " + swagChar.animOffsets.get(i)[1] + "\n";
			}

			outputString.trim();
			saveOffsets(outputString);
		}
	}

	var swagChar:Character;

	function loadAnimShit(char:String)
	{
		if (swagChar != null)
		{
			remove(swagChar);
			swagChar.destroy();
		}

		swagChar = new Character(100, 100, char);
		swagChar.debugMode = true;
		add(swagChar);

		var animThing:Array<String> = [];

		for (i in swagChar.animOffsets.keys())
		{
			animThing.push(i);
			trace(i);
			trace(swagChar.animOffsets[i]);
		}

		animDropDownMenu.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animThing, true));
		animDropDownMenu.callback = function(str:String)
		{
			var animName = animThing[Std.parseInt(str)];

			swagChar.playAnim(animName); // trace();
			trace(swagChar.animOffsets.get(animName));
		};
		dropDownSetup = true;
	}

	var _file:FileReference;

	private function saveOffsets(saveString:String)
	{
		if ((saveString != null) && (saveString.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(saveString, swagChar.curCharacter + "Offsets.txt");
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

enum ANIMDEBUGVIEW
{
	SPRITESHEET;
	OFFSETSHIT;
}
