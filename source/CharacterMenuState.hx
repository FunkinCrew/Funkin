package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;


class CharacterMenuState extends MusicBeatState
{
	public static var Playables:Array<Dynamic> = [
		['bf', 'bf-bloops', 'bf-pico', 'bf-milne', 'bf-dylan'],
		['bf'],
		['bf', 'bf-bloops', 'bf-pico', 'bf-dylan'],
		['bf']
	];
	
	public static var IconPlayables:Array<Dynamic> = [
		['bf', 'bf-bloops', 'bf-pico', 'bf-milne', 'bf-dylan'],
		['bf-pixel'],
		['bf-bsides', 'bf-bloops-bsides', 'bf-pico-bsides', 'bf-dylan-bsides'],
		['bf-pixel-bsides']
	];
	public static var CurPlayable:Array<Int> = [0, 0, 0, 0];
	public static var curSelected:Int = 0;
	
	var textMenuItems:Array<String> = ['DEFAULT', 'RETRO', 'BSIDES', 'BSIDES RETRO'];
	var grpOptionsTexts:FlxTypedGroup<Alphabet>;
	
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFF83beec;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		super.create();
		
		makePlayerText();
		changeSelection(0);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.BACK)
			FlxG.switchState(new OptionsMenu());
		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
		if (controls.ACCEPT)
			FlxG.switchState(new CharacterSelectState());
	}
	
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpOptionsTexts.length - 1;
		if (curSelected >= grpOptionsTexts.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (item in grpOptionsTexts.members)
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
	
	function makePlayerText()
	{
		grpOptionsTexts = new FlxTypedGroup<Alphabet>();
		add(grpOptionsTexts);

		for (i in 0...textMenuItems.length)
		{
			var optionText:Alphabet = new Alphabet(0, 50 + (100 * i), textMenuItems[i], true, false);
			optionText.ID = i;
			optionText.x += 10*(i+1);
			grpOptionsTexts.add(optionText);
			var icon = new HealthIcon(IconPlayables[i][CurPlayable[i]], false);
			icon.x = optionText.width + (10*(i+1));
			icon.y = 10+(100*i);
			add(icon);
		}
	}
}
