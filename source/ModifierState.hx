package;

import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import sys.io.File;
import haxe.Json;
using StringTools;
class ModifierState extends MusicBeatState
{


	public static var modifiers:Array<Dynamic>;
	var grpAlphabet:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;
	var checkmarks:Array<FlxSprite> = [];
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		menuBG.color = 0xFFea71fd;
		grpAlphabet = new FlxTypedGroup<Alphabet>();
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		modifiers = [{name: "Perfect Mode", value: false}, {name:"FC Mode", value: false}, {name: "Practice Mode", value: false}, {name: "Health Gain Up", value: false}, {name: "Health Gain Down", value: false}, {name: "Health Loss Up", value: false}, {name: "Health Loss Down", value: false},{name: "Sup Love", value: false},{name: "Poison EXR", value: false},{name: "Play", value: false}];
		for (modifier in 0...modifiers.length) {
			var swagModifier = new Alphabet(0, 10, "   "+modifiers[modifier].name, true, false, false);
			swagModifier.isMenuItem = true;
			swagModifier.targetY = modifier;
			var coolCheckmark:FlxSprite = new FlxSprite().loadGraphic('assets/images/checkmark.png');
			coolCheckmark.visible = modifiers[modifier].value;
			checkmarks.push(coolCheckmark);
			swagModifier.add(coolCheckmark);
			grpAlphabet.add(swagModifier);
		}
		add(menuBG);
		add(grpAlphabet);
		super.create();
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			FlxG.switchState(new FreeplayState());
		}
		if (controls.UP_P)
		{
			changeSelection(-1);
		}
		if (controls.DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.ACCEPT)
			toggleSelection();
	}
	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = modifiers.length - 1;
		if (curSelected >= modifiers.length)
			curSelected = 0;


		var bullShit:Int = 0;

		for (item in grpAlphabet.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
	function toggleSelection() {
		if (modifiers[curSelected].name != 'Play'){
			checkmarks[curSelected].visible = !checkmarks[curSelected].visible;
			modifiers[curSelected].value = checkmarks[curSelected].visible;
		} else {
			FlxG.switchState(new PlayState());
		}

	}
}
