package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class OptionsSubState extends MusicBeatSubstate
{
	var textMenuItems:Array<String> = ['Controls', 'Downscroll', 'Song Position', 'Ghost Tapping'];

	var selector:FlxSprite;
	var curSelected:Int = 0;

	var grpOptionsTexts:FlxTypedGroup<FlxText>;

	public function new()
	{
		super();

		grpOptionsTexts = new FlxTypedGroup<FlxText>();
		add(grpOptionsTexts);

		for (i in 0...textMenuItems.length)
		{
			var optionText:FlxText = new FlxText(20, 20 + (i * 50), 0, textMenuItems[i], 35);
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
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case "Song Position":
					FlxG.save.data.songPosition = !FlxG.save.data.songPosition;
					if(FlxG.save.data.songPosition)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case "Ghost Tapping":
					FlxG.save.data.ghost = !FlxG.save.data.ghost;
					if(FlxG.save.data.ghost)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
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
