package optionshit;

import flixel.addons.transition.FlxTransitionableState;
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
	var options:Array<String> = ['Controls ${!FlxG.save.data.dfjk ? 'WASD' : 'DFJK'}',
	'Epilepsy Mode ${FlxG.save.data.epilepsyMode ? 'ON' : 'OFF'}',
	'Ghost Tapping ${FlxG.save.data.gtapping ? 'ON' : 'OFF'}',
	'Disable Distractions ${FlxG.save.data.noDistractions ? 'ON' : 'OFF'}',
	'RESET SETTINGS'];

	var optionText:FlxText;
	var optionDot:FlxSprite;
	var camFollow:FlxSprite;

	var topText:FlxText;

	var curSelected:Int = 0;

	var background:FlxSprite;

	public override function create() {
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

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
		optionText.alignment = FlxTextAlign.CENTER;
		optionText.text = '';
		for (option in options) {
			optionText.text += '${option}\n';
		}
		optionText.screenCenter();

		optionDot = new FlxSprite(0, 0);
		optionDot.frames = Paths.getSparrowAtlas('NOTE_assets', 'shared');
		optionDot.animation.addByPrefix("idle", "arrowRIGHT0");
		optionDot.animation.play("idle");
		optionDot.setGraphicSize(50);
		optionDot.updateHitbox();
		add(optionDot);

		camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(optionText.width), Std.int(optionText.height), 0xAAFF0000);

		optionDot.y = optionText.y - optionDot.height / 5; // red dot offset

		topText = new FlxText(0, optionDot.y - 360, 0, "OPTIONS", 32);
		topText.screenCenter(X);
		// add(topText);

		FlxG.camera.follow(camFollow, null, 0.06);

		super.create();
	}

	public override function update(elapsed:Float) {
		options = ['Controls ${!FlxG.save.data.dfjk ? 'WASD' : 'DFJK'}',
		'Epilepsy Mode ${FlxG.save.data.epilepsyMode ? 'ON' : 'OFF'}',
		'Ghost Tapping ${FlxG.save.data.gtapping ? 'ON' : 'OFF'}',
		'Disable Distractions ${FlxG.save.data.noDistractions ? 'ON' : 'OFF'}',
		'RESET SETTINGS'];
		optionText.screenCenter();

		optionDot.x = optionText.x - 60;

		camFollow.screenCenter();
		camFollow.y = optionDot.y - camFollow.height / 2;

		topText.y = optionDot.y;

		// OLD! -- FlxG.camera.y = -FlxMath.lerp(-FlxG.height * 2, optionDot.y, 0.8); // camera following the red dot

		background.screenCenter();

		optionText.text = '';
		for (option in options) {
			optionText.text += '${option}\n';
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
			if (options[curSelected].startsWith('Epilepsy Mode')) {
				FlxG.save.data.epilepsyMode = !FlxG.save.data.epilepsyMode;
			}
			if (options[curSelected].startsWith('Ghost Tapping')) {
				FlxG.save.data.gtapping = !FlxG.save.data.gtapping;
			}
			if (options[curSelected].startsWith('Disable Distractions')) {
				FlxG.save.data.noDistractions = !FlxG.save.data.noDistractions;
			}
			if (options[curSelected].startsWith('RESET SETTINGS')) {
				FlxG.save.data.dfjk = null;
				FlxG.save.data.epilepsyMode = false;
				FlxG.save.data.gtapping = false;
				FlxG.save.data.noDistractions = false;
			}
		}

		if (controls.BACK) {
			FlxG.switchState(new MainMenuState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (controls.UP_P) {
			curSelected--;
			optionDot.y -= 16 * 2.5;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		if (controls.DOWN_P) {
			curSelected++;
			optionDot.y += 16 * 2.5;
			FlxG.sound.play(Paths.sound('scrollMenu'));
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