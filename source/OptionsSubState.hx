package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class OptionsSubState extends MusicBeatSubstate
{
	var textMenuItems:Array<String> = ['Controls', 'Downscroll', 'Song Position', 'Ghost Tapping', 'Note Splashes', 'Light CPU Strums'];

	var selector:FlxSprite;
	var curSelected:Int = 0;

	var grpOptionsTexts:FlxTypedGroup<Alphabet>;

	public function new()
	{
		super();

		grpOptionsTexts = new FlxTypedGroup<Alphabet>();
		add(grpOptionsTexts);

		for (i in 0...textMenuItems.length)
		{
			var optionText:Alphabet = new Alphabet(0, (85 * i) + 30, textMenuItems[i], true);
			optionText.ID = i;
			grpOptionsTexts.add(optionText);
			optionText.screenCenter(X);
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

		grpOptionsTexts.forEach(function(txt:Alphabet)
		{
			txt.color = FlxColor.WHITE;
			txt.alpha = 0.6;

			if (txt.ID == curSelected)
				txt.alpha = 1;
		});

		if (controls.ACCEPT)
		{
			switch (textMenuItems[curSelected])
			{
				case "Controls":
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
				case "Note Splashes":
					FlxG.save.data.sploosh = !FlxG.save.data.sploosh;
					if(FlxG.save.data.sploosh)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case "Light CPU Strums":
					FlxG.save.data.cpuStrums = !FlxG.save.data.cpuStrums;
					if(FlxG.save.data.cpuStrums)
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
