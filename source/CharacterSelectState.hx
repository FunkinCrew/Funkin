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

using StringTools;

class CharacterSelectState extends MusicBeatState
{
	var BloopsisDebugging:Bool = false;
	var Shittext:FlxText;
	var Shittext2:FlxText;
	var Looking:Bool = false;
	var Offshit:Int = 1;
	
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
	var NotUpdated:Bool = true;
	var OffSearch:Int = 0;
	var Offsets:Array<Dynamic> = [ //PAIN
	['boyfriend', 40, -15],
	['boyfriendSelect', 40, -20],
	['bloops', 119, -64],
	['bloopsSelect', 119, -69],
	['pico', 40, -65],
	['picoSelect', 97, -417],
	['milne', 10, -110],
	['milneSelect', 40, -140],
	['dylan', 50, -15],
	['dylanSelect', 30, -20],
	
	['boyfriend-bsides', 40, -15],
	['boyfriend-bsidesSelect', 40, -20],
	['bloops-bsides', 119, -64],
	['bloops-bsidesSelect', 119, -69],
	['pico-bsides', 40, -65],
	['pico-bsidesSelect', 97, -417],
	['milne-bsides', 10, -110],
	['milne-bsidesSelect', 40, -140],
	['dylan-bsides', 50, -15],
	['dylan-bsidesSelect', 30, -20],
	
	['boyfriend-pixel', 0, -130],
	['boyfriend-pixelSelect', 0, -130],
	['boyfriend-pixel-bsides', -70, -100],
	['boyfriend-pixel-bsidesSelect', -70, -100]
	
	];
	
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
		var tex:FlxAtlasFrames;
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
		Player.animation.addByPrefix('dylan-bsidesSelect', "HEY_B-DYLAN", 24, false);
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
		if (BloopsisDebugging)
		{
			Shittext = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
			Shittext.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.RED, RIGHT);
			add(Shittext);
			Shittext2 = new FlxText(FlxG.width * 0.7, 40, 0, "", 32);
			Shittext2.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.RED, RIGHT);
			add(Shittext2);
		}
		if (CharSuffix.startsWith('-pixel'))
		{
			Player.setGraphicSize(Std.int(Player.width * 2));
			Player.updateHitbox();
			Player.antialiasing = false;
		}
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!Selected)
		{
			if (!Looking)
				Player.animation.play(Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix, false);
			if (NotUpdated)
			{
				for (i in 0...Offsets.length)
				{
					if(Offsets[i][0] == (Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix))
					{
						OffSearch = i;
						trace("AAAAA");
						break;
					}
				}
				Player.x = 770;
				Player.y = 300;
				Player.x += Offsets[OffSearch][1];
				Player.y += Offsets[OffSearch][2];
				NotUpdated = false;
			}
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
				for (i in 0...Offsets.length)
				{
					if(Offsets[i][0] == (Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix + 'Select'))
					{
						OffSearch = i;
						trace("AAAAA");
						break;
					}
				}
				Player.x = 770;
				Player.y = 300;
				Player.x += Offsets[OffSearch][1];
				Player.y += Offsets[OffSearch][2];
				
			}
		}
		else
		{	
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				FlxG.switchState(new CharacterMenuState());
			});
		}
		if (BloopsisDebugging)
		{
		
			Player.x = 770;
			Player.y = 300;
			Player.x += Offsets[OffSearch][1];
			Player.y += Offsets[OffSearch][2];
			
			Shittext.text = 'fuck :' + Offsets[OffSearch][1];
			Shittext2.text = 'shit :' +Offsets[OffSearch][2];
			if (FlxG.keys.pressed.SHIFT)
			{
				Offshit = 10;
			}
			else
			{
				Offshit = 1;
			}
			
			if (FlxG.keys.justPressed.G)
				Offsets[OffSearch][1] -= Offshit;
			if (FlxG.keys.justPressed.B)
				Offsets[OffSearch][1] += Offshit;
			if (FlxG.keys.justPressed.H)
				Offsets[OffSearch][2] -= Offshit;
			if (FlxG.keys.justPressed.N)
				Offsets[OffSearch][2] += Offshit;
			if (FlxG.keys.justPressed.T)
			{
				Looking = !Looking;
				if (Looking)
				{
					Player.animation.play(Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix + 'Select', false);
					OffSearch += 1;
				}
				else
				{
					Player.animation.play(Playables[CharacterMenuState.curSelected][curSelected] + CharSuffix, false);
					OffSearch -= 1;
				}
			}
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
		NotUpdated = true;
		Looking = false;
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
