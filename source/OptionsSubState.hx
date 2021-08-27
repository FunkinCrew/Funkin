package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionsSubState extends MusicBeatSubstate
{
	var textMenuItems:Array<String> = ['Controls', 'Downscroll', 'Song Position'];

	var selector:FlxSprite;
	var curSelected:Int = 0;

	var grpOptionsTexts:FlxTypedGroup<FlxText>;

	public function new()
	{
		super();

		grpOptionsTexts = new FlxTypedGroup<FlxText>();
		add(grpOptionsTexts);

		selector = new FlxSprite().makeGraphic(5, 5, FlxColor.RED);
		add(selector);

		for (i in 0...textMenuItems.length)
		{
			var optionText:FlxText = new FlxText(20, 20 + (i * 50), 0, textMenuItems[i], 56);
			optionText.ID = i;
			optionText.setFormat(Paths.font("vcr.ttf"), 56, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
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
					FlxG.state.openSubState(new KeyBindMenu());
				case "Downscroll":
					FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
					if(FlxG.save.data.downscroll)
						FlxG.sound.play(Paths.sound('confirmMenu'));
				case "Song Position":
					FlxG.save.data.songPosition = !FlxG.save.data.songPosition;
					if(FlxG.save.data.songPosition)
						FlxG.sound.play(Paths.sound('confirmMenu'));
			}
		}
		if(controls.BACK)
		{
			FlxG.state.closeSubState();
			FlxG.switchState(new MainMenuState());
			FlxG.save.bind('funkin', 'ninjamuffin99');
		}
	}
}
