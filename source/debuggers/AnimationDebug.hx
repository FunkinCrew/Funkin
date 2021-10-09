package debuggers;

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
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
	*DEBUG MODE
 */
class AnimationDebug extends MusicBeatState
{
	var bf:Boyfriend;
	var dad:Character;
	var char:Character;
	var animText:FlxText;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var isDad:Bool = true;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;

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

	var charDropDown:FlxUIDropDownMenuCustom;
	var modDropDown:FlxUIDropDownMenuCustom;

	override function create()
	{
		FlxG.mouse.visible = true;

		if(FlxG.sound.music.active)
			FlxG.sound.music.stop();

		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0, 0);
		add(gridBG);

		if (daAnim == 'bf')
			isDad = false;

		if (isDad)
		{
			dad = new Character(0, 0, daAnim);
			dad.debugMode = true;
			add(dad);

			char = dad;
			dad.flipX = false;
		}
		else
		{
			bf = new Boyfriend(0, 0);
			bf.debugMode = true;
			add(bf);

			char = bf;
			bf.flipX = false;
		}

		animText = new FlxText(2, 2, 0, "BRUH BRUH BRUH: [0,0]", 20);
		animText.scrollFactor.set();
		animText.color = FlxColor.BLUE;
		add(animText);

		var moveText = new FlxText(2, 2, 0, "Use IJKL to move the camera", 20);
		moveText.x = FlxG.width - moveText.width;
		moveText.scrollFactor.set();
		moveText.color = FlxColor.BLUE;
		add(moveText);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.sound.playMusic(Paths.music('breakfast'));
		
		FlxG.camera.follow(camFollow);

		#if sys
		var characterData:Array<String> = CoolUtil.coolTextFilePolymod(Paths.txt('characterList'));
		#else
		var characterData:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

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
		add(modDropDown);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		animText.text = "";

		var daLoop:Int = 0;

		for (anim => offsets in char.animOffsets)
		{
			animText.text += anim + (anim == animList[curAnim] ? " (current) " : "") + ": " + offsets + "\n";

			if (pushList)
				animList.push(anim);

			daLoop++;
		}
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom += 0.25;
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom -= 0.25;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90;
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
			char.playAnim(animList[curAnim]);
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
			char.playAnim(animList[curAnim]);
		}

		super.update(elapsed);
	}
}
