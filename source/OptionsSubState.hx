package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import PlayState.*;

class OptionsSubState extends MusicBeatSubstate
{
	var textMenuItems:Array<String> = ['Master Volume', 'Sound Volume', 'Controls', 'Deuteranopia', 'Protanopia', 'Tritanopia', 'No filter'];

	var selector:FlxSprite;
	var curSelected:Int = 0;

	var grpOptionsTexts:FlxTypedGroup<FlxText>;
	
	public static var Deuteranopiabool:Bool = false;
	public static var Protanopiabool:Bool = false;
	public static var Tritanopiabool:Bool = false;
	
	public function new()
	{
		super();

		grpOptionsTexts = new FlxTypedGroup<FlxText>();
		add(grpOptionsTexts);

		selector = new FlxSprite().makeGraphic(5, 5, FlxColor.RED);
		add(selector);

		for (i in 0...textMenuItems.length)
		{
			var optionText:FlxText = new FlxText(20, 20 + (i * 50), 0, textMenuItems[i], 32);
			optionText.ID = i;
			grpOptionsTexts.add(optionText);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UP_P)
			curSelected -= 1;

		if (controls.DOWN_P)
			curSelected += 1;

		if (curSelected < 0)
			curSelected = textMenuItems.length - 1;

		if (curSelected >= textMenuItems.length)
			curSelected = 0;
		
		if (controls.BACK)
			{
				FlxG.switchState(new MainMenuState());
			}

		grpOptionsTexts.forEach(function(txt:FlxText)
		{
			txt.color = FlxColor.WHITE;

			if (txt.ID == curSelected)
				txt.color = FlxColor.YELLOW;
		});

		if (controls.ACCEPT)
		{
			switch (textMenuItems[curSelected])
			{
				case "Controls":
					FlxG.state.closeSubState();
					FlxG.state.openSubState(new ControlsSubState());
				case "Deuteranopia":
					OptionsSubState.Deuteranopiabool = true;
					OptionsSubState.Protanopiabool = false;
					OptionsSubState.Tritanopiabool = false;
					trace("Deuteranopia");
				case "Protanopia":
					OptionsSubState.Protanopiabool = true;
					OptionsSubState.Deuteranopiabool = false;
					OptionsSubState.Tritanopiabool = false;
					trace("Protanopia");
				case "Tritanopia":
					OptionsSubState.Tritanopiabool = true;
					OptionsSubState.Protanopiabool = false;
					OptionsSubState.Deuteranopiabool = false;
					trace("Tritanopia");
				case "No filter":
					OptionsSubState.Tritanopiabool = false;
					OptionsSubState.Protanopiabool = false;
					OptionsSubState.Deuteranopiabool = false;
					trace("No Filter");
			}
		}
	}
}
