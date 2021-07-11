package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;

import flixel.util.FlxSave;

class OptionsMenu extends MusicBeatState
{
	var selector:FlxText;
	var curSelected:Int = 0;

	private var grpControls:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['preferences', 'controls', 'about', 'discord', 'special thanks', 'exit'];

	var notice:FlxText;

	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		//controlsStrings = CoolUtil.coolTextFile('assets/data/controls.txt');
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...menuItems.length)
		{ 
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			controlLabel.screenCenter();
			controlLabel.y = (100 * i) + 70;
			//controlLabel.isMenuItem = true;
			//controlLabel.targetY = i;
			grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}

		#if mobileC
		addVirtualPad(UP_DOWN, A_B);
		#end

		changeSelection();
		
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.ACCEPT)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "preferences":
					FlxG.switchState(new options.PreferencesState());
				case "controls":
					FlxG.switchState(new options.CustomControlsState());
				case "about":
					FlxG.switchState(new options.AboutState());
				case "exit":
					FlxG.switchState(new MainMenuState());
				case "discord":
					FlxG.openURL('https://discord.gg/eGwJnUvZ9H');
				case "special thanks":
					FlxG.switchState(new options.CreditState());
					//FlxG.openURL('https://youtu.be/2IdJzGZ70r4');
			}
		}

		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end) {
			FlxG.switchState(new MainMenuState());
		}

		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);

	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpControls.members)
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

	override function closeSubState()
		{
			super.closeSubState();
		}	
}
