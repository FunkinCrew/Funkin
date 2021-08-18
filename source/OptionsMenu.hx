package;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import Controls.Control;

using StringTools;

class OptionsMenu extends MusicBeatState {
	var options:Array<String> = ['o'];

	var optionText:FlxText;
	var optionDot:FlxSprite;

	var curSelected:Int = 0;

	public override function create() {
		optionText = new FlxText(0, 0, 0, 'OPTIONS LOLOLO', 32);
		add(optionText);
		optionText.screenCenter();
		optionText.alignment = FlxTextAlign.CENTER;

		optionDot = new FlxSprite(0, 0).makeGraphic(10, 10, FlxColor.RED);
		add(optionDot);

		optionDot.y = optionText.y - 20;

		super.create();
	}

	public override function update(elapsed:Float) {
		options = ['Controls ${!FlxG.save.data.dfjk ? 'WASD' : 'DFJK'}',
		'Practice mode ${!FlxG.save.data.pmode ? 'off' : 'on'}',
		'Ghost Tapping ${!FlxG.save.data.gtapping ? 'on' : 'off'}',
		'Limited ScoreBar ${!FlxG.save.data.sbar ? 'off' : 'on'}'];
		optionText.screenCenter();

		optionDot.x = optionText.x - 20;

		optionText.text = '';
		for (option in options) {
			optionText.text += '\n${option}';
		}

		if (controls.ACCEPT) {
			if (options[curSelected].startsWith('Controls')) {
				FlxG.save.data.dfjk = !FlxG.save.data.dfjk;
			}
			if (options[curSelected].startsWith('Practice mode')) {
				FlxG.save.data.pmode = !FlxG.save.data.pmode;
			}
			if (options[curSelected].startsWith('Ghost Tapping')) {
				FlxG.save.data.gtapping = !FlxG.save.data.gtapping;
			}
			if (options[curSelected].startsWith('Limited ScoreBar')) {
				FlxG.save.data.sbar = !FlxG.save.data.sbar;
			}
		}

		if (controls.BACK) {
			FlxG.switchState(new MainMenuState());
		}

		if (controls.UP_P) {
			curSelected--;
			optionDot.y -= 16 * 2.5;
		}
		if (controls.DOWN_P) {
			curSelected++;
			optionDot.y += 16 * 2.5;
		}

		if (curSelected < 0) {
			curSelected = 0;
			optionDot.y += 16 * 2.5;
		}
		if (curSelected > options.length - 1) {
			curSelected = options.length - 1;
			optionDot.y -= 16 * 2.5;
		}

		super.update(elapsed);
	}
}