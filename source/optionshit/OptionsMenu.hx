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
	var detailText:FlxText;
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
		background.setGraphicSize(Std.int(background.width * 1.3));
		background.updateHitbox();
		background.screenCenter();
		background.antialiasing = true;

		add(background);

		optionText = new FlxText(0, 0, 512, 'OPTIONS LOLOLO', 32);
		optionText.font = 'PhantomMuff 1.5';
		add(optionText);
		optionText.alignment = FlxTextAlign.CENTER;
		
		optionText.text = '';
		for (option in options) {
			optionText.text += '${option}\n';
		}
		optionText.screenCenter(X);

		optionDot = new FlxSprite(0, 0);
		optionDot.frames = Paths.getSparrowAtlas('NOTE_assets', 'shared');
		optionDot.animation.addByPrefix("idle", "arrowRIGHT0");
		optionDot.animation.play("idle");
		optionDot.setGraphicSize(50);
		optionDot.updateHitbox();
		add(optionDot);

		detailText = new FlxText(0, optionDot.y - 360, 0, "", 13);
		detailText.font = 'PhantomMuff 1.5';
		detailText.screenCenter(X);
		add(detailText);

		camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(optionText.width), Std.int(optionText.height), 0xAAFF0000);

		optionDot.y = optionText.y - optionDot.height / 2.5; // red dot offset (bruh i hate this options menu but idk how to make a better one)

		topText = new FlxText(0, optionDot.y - 360, 0, "OPTIONS", 32);
		topText.screenCenter(X);
		// add(topText);

		FlxG.camera.follow(camFollow, null, 0.06);

		super.create();
	}

	public override function update(elapsed:Float) {
		//Controls ${!FlxG.save.data.dfjk ? 'WASD' : 'DFJK'}
		options = ['OPTIONS', 'Change Keybinds',
		'Epilepsy Mode ${FlxG.save.data.epilepsyMode ? 'ON' : 'OFF'}',
		'Ghost Tapping ${FlxG.save.data.gtapping ? 'ON' : 'OFF'}',
		'Judgement Type ${FlxG.save.data.judgeHits ? 'UNMODIFIED' : 'MODIFIED'}',
		'Lane Underlay ${FlxG.save.data.laneUnderlay ? 'ON' : 'OFF'}',
		'Disable Distractions ${FlxG.save.data.noDistractions ? 'ON' : 'OFF'}',
		'Custom Health Colors ${FlxG.save.data.disablehealthColor ? 'OFF' : 'ON'}',
		'Panicable Boyfriend ${FlxG.save.data.disablePanicableBF ? 'OFF' : 'ON'}',
		'CREDITS',
		'RESET SETTINGS'];

		optionText.screenCenter(X);

		optionDot.x = optionText.x - 60;

		camFollow.screenCenter();
		camFollow.y = optionDot.y - camFollow.height / 2;

		detailText.y = optionDot.y;
		detailText.x = optionText.x * 2.35;

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
			/*if (options[curSelected].startsWith('Controls')) {
				FlxG.save.data.dfjk = !FlxG.save.data.dfjk;
			}*/

			if (options[curSelected].startsWith('Change Keybinds')) {
				FlxG.switchState(new Keybinds());
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
			if (options[curSelected].startsWith('Custom Health Colors')) {
				FlxG.save.data.disablehealthColor = !FlxG.save.data.disablehealthColor;
			}
			if (options[curSelected].startsWith('Judgement Type')) {
				FlxG.save.data.judgeHits = !FlxG.save.data.judgeHits;
			}
			if (options[curSelected].startsWith('Panicable Boyfriend')) {
				FlxG.save.data.disablePanicableBF = !FlxG.save.data.disablePanicableBF;
			}
			if (options[curSelected].startsWith('Lane Underlay')) {
				FlxG.save.data.laneUnderlay = !FlxG.save.data.laneUnderlay;
			}
			if (options[curSelected].startsWith('CREDITS')){
				FlxG.switchState(new InformationState());
			}
			if (options[curSelected].startsWith('RESET SETTINGS')) {
				FlxG.save.data.epilepsyMode = false;
				FlxG.save.data.gtapping = false;
				FlxG.save.data.noDistractions = false;
				FlxG.save.data.disablehealthColor = false;
				FlxG.save.data.UP = "W";
				FlxG.save.data.DOWN = "S";
				FlxG.save.data.LEFT = "A";
				FlxG.save.data.RIGHT = "D";
			}
		}

		//Details
		if (controls.UP || controls.DOWN)
			{
				if (options[curSelected].startsWith('OPTIONS')) {
					detailText.text = '';
				}

				if (options[curSelected].startsWith('Change Keybinds')) {
					detailText.text = 'Change your Controls.';
				}

				if (options[curSelected].startsWith('Epilepsy Mode')){
					detailText.text = 'Prevents Epilepsy if enabled.';
				}
	
				if (options[curSelected].startsWith('Ghost Tapping')) {
					detailText.text = "You won't miss when tapping at the wrong time.";
				}
				
				if (options[curSelected].startsWith('Disable Distractions')){
					detailText.text = 'Disables annoying background objects.';
				}

				if (options[curSelected].startsWith('Custom Health Colors')){
					detailText.text = 'Disables or Enables the custom Health Bar Colors.';
				}

				if (options[curSelected].startsWith('Judgement Type')){
					detailText.text = 'Changes the difficulty on hitting notes.';
				}

				if (options[curSelected].startsWith('Panicable Boyfriend')){
					detailText.text = 'Makes the BF Panic when low on Health';
				}

				if (options[curSelected].startsWith('Lane Underlay')){
					detailText.text = 'Shows a lane under the Notes.';
				}

				if (options[curSelected].startsWith('CREDITS')){
					detailText.text = 'Shows the Credits of the Engine / Mod';
				}

				if (options[curSelected].startsWith('RESET SETTINGS')){
					detailText.text = 'Nukes your settings.';
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