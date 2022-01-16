package debuggers;

import flixel.ui.FlxButton;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
import ui.FlxUIDropDownMenuCustom;
import states.MusicBeatState;
import states.MainMenuState;
import states.PlayState;
import utilities.CoolUtil;
import game.Character;
import game.Boyfriend;
import flixel.system.FlxSound;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;
/**
	*DEBUG MODE
 */
class AnimationDebug extends MusicBeatState
{
	var char:Character;
	var animText:FlxText;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;
	var _file:FileReference;

	public function new(daAnim:String = 'spooky')
	{
		super();
		this.daAnim = daAnim;
	}

	var characters:Map<String, Array<String>> = [
		"default" => ["bf", "gf"]
	];

	var modListLmao:Array<String> = ["default"];
	var curCharList:Array<String>;

	var offset_Button:FlxButton;
	var charDropDown:FlxUIDropDownMenuCustom;
	var modDropDown:FlxUIDropDownMenuCustom;

	/* CAMERA */
	var gridCam:FlxCamera;
	var charCam:FlxCamera;
	var camHUD:FlxCamera;

	override function create()
	{
		FlxG.mouse.visible = true;

		gridCam = new FlxCamera();
		charCam = new FlxCamera();
		charCam.bgColor.alpha = 0;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset();
		FlxG.cameras.add(gridCam, false);
		FlxG.cameras.add(charCam, true);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(charCam, true);

		FlxG.camera = charCam;

		if(FlxG.sound.music.active)
			FlxG.sound.music.stop();

		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0, 0);
		gridBG.cameras = [gridCam];
		add(gridBG);

		char = new Character(0, 0, daAnim);
		char.debugMode = true;
		add(char);

		animText = new FlxText(2, 2, 0, "BRUH BRUH BRUH: [0,0]", 20);
		animText.scrollFactor.set();
		animText.color = FlxColor.BLUE;
		animText.cameras = [camHUD];
		add(animText);

		var moveText = new FlxText(2, 2, 0, "Use IJKL to move the camera\nE and Q to zoom the camera\nSHIFT for faster moving offset or camera\n", 20);
		moveText.x = FlxG.width - moveText.width;
		moveText.scrollFactor.set();
		moveText.color = FlxColor.BLUE;
		moveText.alignment = RIGHT;
		moveText.cameras = [camHUD];
		add(moveText);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.sound.playMusic(Paths.music('breakfast'));
		
		charCam.follow(camFollow);

		var characterData:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		char.screenCenter();

		for(item in characterData)
		{
			var characterDataVal:Array<String> = item.split(":");

			var charName:String = characterDataVal[0];
			var charMod:String = characterDataVal[1];

			var charsLmao:Array<String> = [];

			if(characters.exists(charMod))
				charsLmao = characters.get(charMod);
			else
				modListLmao.push(charMod);

			charsLmao.push(charName);
			characters.set(charMod, charsLmao);
		}

		curCharList = characters.get("default");

		charDropDown = new FlxUIDropDownMenuCustom(10, 500, FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true), function(character:String)
		{
			remove(char);
			char.kill();
			char.destroy();

			daAnim = curCharList[Std.parseInt(character)];
			char = new Character(0, 0, daAnim);
			char.debugMode = true;
			add(char);
			char.screenCenter();
			animList = [];
			genBoyOffsets(true);
		});

		charDropDown.selectedLabel = daAnim;
		charDropDown.scrollFactor.set();
		charDropDown.cameras = [camHUD];
		add(charDropDown);

		modDropDown = new FlxUIDropDownMenuCustom(charDropDown.x + charDropDown.width + 1, charDropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(modListLmao, true), function(modID:String)
		{
			var mod:String = modListLmao[Std.parseInt(modID)];

			if(characters.exists(mod))
			{
				curCharList = characters.get(mod);
				charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true));
				charDropDown.selectedLabel = curCharList[0];

				remove(char);
				char.kill();
				char.destroy();

				daAnim = curCharList[0];
				char = new Character(0, 0, daAnim);
				char.debugMode = true;
				add(char);
				char.screenCenter();
				animList = [];
				genBoyOffsets(true);
			}
		});

		modDropDown.selectedLabel = "default";
		modDropDown.scrollFactor.set();
		modDropDown.cameras = [camHUD];
		add(modDropDown);

		offset_Button = new FlxButton(charDropDown.x, charDropDown.y - 30, "Save Offsets", function() {
			saveOffsets();
		});
		offset_Button.scrollFactor.set();
		offset_Button.cameras = [camHUD];
		add(offset_Button);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		animText.text = "";

		for (anim => offsets in char.animOffsets)
		{
			if (pushList)
				animList.push(anim);

			animText.text += anim + (anim == animList[curAnim] ? " (current) " : "") + ": " + offsets + "\n";
		}
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.E)
			charCam.zoom += 0.25;
		if (FlxG.keys.justPressed.Q)
			charCam.zoom -= 0.25;

		var shiftThing:Int = FlxG.keys.pressed.SHIFT ? 5 : 1;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90 * shiftThing;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90 * shiftThing;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90 * shiftThing;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90 * shiftThing;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W)
		{
			curAnim -= 1;
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new MainMenuState());

		if (FlxG.keys.justPressed.S)
		{
			curAnim += 1;
		}

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
		{
			char.playAnim(animList[curAnim], true);
			char.screenCenter();

			genBoyOffsets(false);
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		if (upP || rightP || downP || leftP)
		{
			if (upP)
				char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			if (downP)
				char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			if (leftP)
				char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			if (rightP)
				char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;

			genBoyOffsets(false);
			char.playAnim(animList[curAnim], true);
		}

		super.update(elapsed);
	}

	function saveOffsets()
	{
		var offsetsText:String = "";

		for (anim => offsets in char.animOffsets)
		{
			offsetsText += anim + " " + offsets[0] + " " + offsets[1] + "\n";
		}

		if ((offsetsText != "") && (offsetsText.length > 0))
		{
			if (offsetsText.endsWith("\n"))
				offsetsText = offsetsText.substr(0, offsetsText.length - 1);

			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			_file.save(offsetsText, "offsets.txt");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved OFFSETS FILE.");
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
		FlxG.log.error("Problem saving offsets file");
	}
}
