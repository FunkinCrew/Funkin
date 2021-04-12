package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.util.FlxTimer;

class CharacterSelectState extends MusicBeatState
{
	var Playables:Array<Dynamic> = [
		['boyfriend', 'bloops', 'pico', 'milne', 'dylan'],
		['boyfriend'],
		['boyfriend', 'bloops', 'pico', 'dylan'],
		['boyfriend']
	];
	static var curSelected:Int = 0;
	var grpOptionsTexts:FlxTypedGroup<Alphabet>;
	var CharSuffix:String = '';
	var Player:FlxSprite;
	var Selected:Bool = false;
	var icons:Array<Dynamic> = [];
	
	function GetSuffix()
	{
		switch (CharacterMenuState.curSelected)
		{
			case 1:
				CharSuffix = '-pixel';
			case 2:
				CharSuffix = '-bsides';
			case 3:
				CharSuffix = '-pixel-bsides';
			default:
				CharSuffix = '';
		}
	}
	
	
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFff9cff;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		super.create();
		GetSuffix();
		makePlayerText();
		changeSelection(0);
		Player = new FlxSprite(770, 300);
		Player.frames = Paths.getSparrowAtlas('CharSelect'); //this is gonna get ugly
		
		Player.animation.addByPrefix('boyfriend', "BOYFRIEND", 24);
		Player.animation.addByPrefix('boyfriendSelect', "HEY_BOYFRIEND", 24, false);
		Player.animation.addByPrefix('bloops', "BLOOPS", 24);
		Player.animation.addByPrefix('bloopsSelect', "HEY_BLOOPS", 24, false);
		Player.animation.addByPrefix('pico', "PICO", 24);
		Player.animation.addByPrefix('picoSelect', "HEY_PICO", 24, false);
		Player.animation.addByPrefix('dylan', "DYLAN", 24);
		Player.animation.addByPrefix('dylanSelect', "HEY_DYLAN", 24, false);
		Player.animation.addByPrefix('milne', "MILNE", 24);
		Player.animation.addByPrefix('milneSelect', "HEY_MILNE", 24, false);
		
		//B-SIDES
		Player.animation.addByPrefix('boyfriend-bsides', "B-BOYFRIEND", 24);
		Player.animation.addByPrefix('boyfriend-bsidesSelect', "HEY_B-BOYFRIEND", 24, false);
		Player.animation.addByPrefix('bloops-bsides', "B-BLOOPS", 24);
		Player.animation.addByPrefix('bloops-bsidesSelect', "HEY_B-BLOOPS", 24, false);
		Player.animation.addByPrefix('pico-bsides', "B-PICO", 24);
		Player.animation.addByPrefix('pico-bsidesSelect', "HEY_B-PICO", 24, false);
		Player.animation.addByPrefix('dylan-bsides', "B-DYLAN", 24);
		Player.animation.addByPrefix('Dylan-bsidesSelect', "HEY_B-DYLAN", 24, false);
		Player.animation.addByPrefix('milne-bsides', "B-MILNE", 24);
		Player.animation.addByPrefix('milne-bsidesSelect', "HEY_B-MILNE", 24, false);
		
		//PIXEL
		Player.animation.addByPrefix('boyfriend-pixel', "PIXEL BOYFRIEND", 24);
		Player.animation.addByPrefix('boyfriend-pixelSelect', "PIXEL BOYFRIEND", 24, false);
		Player.animation.addByPrefix('boyfriend-pixel-bsides', "B-PIXEL BOYFRIEND", 24);
		Player.animation.addByPrefix('boyfriend-pixel-bsidesSelect', "B-PIXEL BOYFRIEND", 24, false);
		
		Player.antialiasing = true;
		
		add(Player);
		Player.animation.play(Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix, false);
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!Selected)
		{
			Player.animation.play(Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix, false);
			if (controls.BACK)
			{
				FlxG.switchState(new CharacterMenuState());
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
			{
				CharacterMenuState.CurPlayable[CharacterMenuState.curSelected] = curSelected;
				Selected = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				Player.animation.play(Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix + 'Select', false);
				for (i in 1...icons.length)
				{
					remove(icons[i]);
					var isselected:Int = 1;
					if ((i-1) == curSelected)
					{
						isselected = 2;
					}
					icons[i] = new HealthIcon(CharacterMenuState.IconPlayables[CharacterMenuState.curSelected][i-1], false, isselected);
					icons[i].x = grpOptionsTexts.members[i-1].width + (10*i);
					icons[i].y = 10+(100*(i-1));
					add(icons[i]);
				}
				
			}
		}
		else
		{	
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				FlxG.switchState(new CharacterMenuState());
			});
		}
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

		for (i in 0...Playables[CharacterMenuState.curSelected].length)
		{
			var optionText:Alphabet = new Alphabet(0, 50 + (100 * i), Playables[CharacterMenuState.curSelected][i], true, false);
			optionText.ID = i;
			optionText.x += 10*(i+1);
			grpOptionsTexts.add(optionText);
			icons[i+1] = new HealthIcon(CharacterMenuState.IconPlayables[CharacterMenuState.curSelected][i], false);
			icons[i+1].x = optionText.width + (10*(i+1));
			icons[i+1].y = 10+(100*i);
			add(icons[i+1]);
		}
	}
}
