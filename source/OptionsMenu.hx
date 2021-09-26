package;

import flixel.FlxBasic;
import flixel.math.FlxMath;
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
	var camFollow:FlxSprite;

	var topText:FlxText;

	var curSelected:Int = 0;

	var background:FlxSprite;

	public override function create() {
		background = new FlxSprite(0, 0, Paths.image('menuBGBlue'));

		background.scrollFactor.x = 0;
		background.scrollFactor.y = 0.18;
		background.setGraphicSize(Std.int(background.width * 1.1));
		background.updateHitbox();
		background.screenCenter();
		background.antialiasing = true;

		add(background);

		optionText = new FlxText(0, 0, 0, 'OPTIONS LOLOLO', 32);
		add(optionText);
		optionText.screenCenter();
		optionText.alignment = FlxTextAlign.CENTER;

		optionDot = new FlxSprite(0, 0).makeGraphic(10, 10, FlxColor.RED);
		add(optionDot);

		camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(optionText.width), Std.int(optionText.height), 0xAAFF0000);

		optionDot.y = optionText.y - 185; // red dot offset, adjust when adding new setting!

		topText = new FlxText(0, optionDot.y - 360, 0, "OPTIONS", 32);
		topText.screenCenter(X);
		// add(topText);

		FlxG.camera.follow(camFollow, null, 0.06);

		super.create();
	}

	public override function update(elapsed:Float) {
		options = ['Controls ${!FlxG.save.data.dfjk ? 'WASD' : 'DFJK'}',
		'Practice mode ${!FlxG.save.data.pmode ? 'off' : 'on'}',
		'Ghost Tapping ${!FlxG.save.data.gtapping ? 'on' : 'off'}',
		'Limited ScoreBar ${!FlxG.save.data.sbar ? 'off' : 'on'}',
		'Light up CPU Strums ${!FlxG.save.data.cpuStrums ? 'off' : 'on'}',
		'Allow using R to reset ${!FlxG.save.data.ron ? 'off' : 'on'}',
		'Hitsounds ${!FlxG.save.data.hsounds ? 'off' : 'on'}',
		'Offset: ${FlxG.save.data.offset}ms',
		'Constant scrollspeed: ${FlxG.save.data.sspeed == 0 ? 'off' : FlxG.save.data.sspeed}',
		'Enable Near Death Tint ${!FlxG.save.data.redTint ? 'on' : 'off'}',
		'Middle Scroll ${!FlxG.save.data.mscroll ? 'off' : 'on'}',
		'RESET SETTINGS'];
		optionText.screenCenter();

		optionDot.x = optionText.x - 20;

		camFollow.screenCenter();
		camFollow.y = optionDot.y - camFollow.height / 2;

		topText.y = optionDot.y - 360;

		// OLD! -- FlxG.camera.y = -FlxMath.lerp(-FlxG.height * 2, optionDot.y, 0.8); // camera following the red dot

		background.screenCenter();

		optionText.text = '';
		for (option in options) {
			optionText.text += '\n${option}';
		}

		if (FlxG.save.data.offset == null) FlxG.save.data.offset = 0;

		if (FlxG.save.data.offset < 0.1 && FlxG.save.data.offset > -10) {
			FlxG.save.data.offset = 0;
		}

		if (FlxG.save.data.sspeed == null) FlxG.save.data.sspeed = 0;

		if (FlxG.save.data.sspeed < 0.1) {
			FlxG.save.data.sspeed = 0;
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
			if (options[curSelected].startsWith('Light up CPU Strums')) {
				FlxG.save.data.cpuStrums = !FlxG.save.data.cpuStrums;
			}
			if (options[curSelected].startsWith('Allow using R to reset')) {
				FlxG.save.data.ron = !FlxG.save.data.ron;
			}
			if (options[curSelected].startsWith('Hitsounds')) {
				FlxG.save.data.hsounds = !FlxG.save.data.hsounds;
			}
			if (options[curSelected].startsWith('Enable Near Death Tint')) {
				FlxG.save.data.redTint = !FlxG.save.data.redTint;
			}
			if (options[curSelected].startsWith('Middle Scroll')) {
				FlxG.save.data.mscroll = !FlxG.save.data.mscroll;
			}
			if (options[curSelected].startsWith('RESET SETTINGS')) {
				FlxG.save.data.offset = null;
				FlxG.save.data.dfjk = null;
				FlxG.save.data.pmode = null;
				FlxG.save.data.gtapping = null;
				FlxG.save.data.sbar = null;
				FlxG.save.data.cpuStrums = null;
				FlxG.save.data.ron = null;
				FlxG.save.data.hsounds = null;
				FlxG.save.data.redTint = null;
				FlxG.save.data.sspeed = null;
				FlxG.save.data.mscroll = null;
			}
		}
		if (controls.LEFT_P) {
			if (options[curSelected].startsWith('Offset: ')) {
				FlxG.save.data.offset -= 10;
			}
			if (options[curSelected].startsWith('Constant scrollspeed:')) {
				FlxG.save.data.sspeed -= 0.1;
			}
		}
		if (controls.RIGHT_P) {
			if (options[curSelected].startsWith('Offset: ')) {
				FlxG.save.data.offset += 10;
			}
			if (options[curSelected].startsWith('Constant scrollspeed:')) {
				FlxG.save.data.sspeed += 0.1;
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