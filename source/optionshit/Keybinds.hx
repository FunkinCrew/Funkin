package optionshit;

import flixel.input.keyboard.FlxKeyboard.FlxKeyInput;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxBasic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import Controls.Control;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;

using StringTools;

//Stole the options menu code lmao
class Keybinds extends MusicBeatState {
	var options:Array<String> = ['LEFT | ' + FlxG.save.data.LEFT, 'DOWN | ' + FlxG.save.data.DOWN, 'UP | ' + FlxG.save.data.UP,
	'RIGHT | ' + FlxG.save.data.RIGHT];

	var optionText:FlxText;
	var detailText:FlxText;
	var optionDot:FlxSprite;
	var camFollow:FlxSprite;

	var topText:FlxText;

	var curSelected:Int = 0;

	var background:FlxSprite;

	var startListening = false;
	var selectedKey = "LEFT";

	public override function create() {
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		background = new FlxSprite(0, 0, Paths.image('menuBGMagenta'));

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

		detailText = new FlxText(0, optionDot.y - 360, 0, "", 24);
		detailText.font = 'PhantomMuff 1.5';
		detailText.screenCenter(X);
		add(detailText);

		camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(optionText.width), Std.int(optionText.height), 0xAAFF0000);

		optionDot.y = optionText.y - optionDot.height / 5;

		topText = new FlxText(0, optionDot.y - 360, 0, "OPTIONS", 32);
		topText.screenCenter(X);
		// add(topText);

		FlxG.camera.follow(camFollow, null, 0.06);

		super.create();
	}

	public override function update(elapsed:Float) {
		options = ['LEFT | ' + FlxG.save.data.LEFT, 'DOWN | ' + FlxG.save.data.DOWN, 'UP | ' + FlxG.save.data.UP,
		'RIGHT | ' + FlxG.save.data.RIGHT];

		optionText.screenCenter(X);

		optionDot.x = optionText.x - 32;

		camFollow.screenCenter();
		camFollow.y = optionDot.y - camFollow.height / 2;

		detailText.y = optionDot.y;
		detailText.x = optionText.x * 2.35;

		topText.y = optionDot.y;

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

			if (options[curSelected].startsWith('LEFT')){
				selectedKey = "LEFT";
				startListening = true;
			}

			if (options[curSelected].startsWith('DOWN')){
				selectedKey = "DOWN";
				startListening = true;
			}

			if (options[curSelected].startsWith('UP')){
				selectedKey = "UP";
				startListening = true;
			}

			if (options[curSelected].startsWith('RIGHT')){
				selectedKey = "RIGHT";
				startListening = true;
			}
		}

		//Change Keybinds
		if (startListening == true){
			detailText.text = 'Waiting for Input...';
			if (FlxG.keys.justPressed.ANY && !controls.ACCEPT){
				if (selectedKey == "LEFT"){
					controls.unbindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.LEFT), FlxKey.LEFT]);

					FlxG.save.data.LEFT = FlxG.keys.getIsDown()[0].ID.toString();
					trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown());
					detailText.text = "";

					controls.bindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.LEFT), FlxKey.LEFT]);

					selectedKey = "";
					//Delayed so it doesn't move the Arrow
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
						{
							detailText.text = "";
							startListening = false;
					});
				}

				if (selectedKey == "DOWN"){
					controls.unbindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.DOWN), FlxKey.DOWN]);

					FlxG.save.data.DOWN = FlxG.keys.getIsDown()[0].ID.toString();
					trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown());
					detailText.text = "";

					controls.bindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.DOWN), FlxKey.DOWN]);

					selectedKey = "";
					//Delayed so it doesn't move the Arrow
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
						{
							detailText.text = "";
							startListening = false;
					});
				}

				if (selectedKey == "UP"){
					controls.unbindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.UP), FlxKey.UP]);

					FlxG.save.data.UP = FlxG.keys.getIsDown()[0].ID.toString();
					trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown()[0]);
					detailText.text = "";

					controls.bindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.UP), FlxKey.UP]);

					selectedKey = "";
					//Delayed so it doesn't move the Arrow
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
						{
							detailText.text = "";
							startListening = false;
					});
				}

				if (selectedKey == "RIGHT"){
					controls.unbindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.RIGHT), FlxKey.RIGHT]);

					FlxG.save.data.RIGHT = FlxG.keys.getIsDown()[0].ID.toString();
					trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown()[0]);
					detailText.text = "";

					controls.bindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.RIGHT), FlxKey.RIGHT]);

					selectedKey = "";

					//Delayed so it doesn't move the Arrow
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
						{
							detailText.text = "";
							startListening = false;
					});
				}
			}
		}

		if (controls.BACK) {
			FlxG.switchState(new OptionsMenu());
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (startListening == false){
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
		}

		if (curSelected < 0) {
			curSelected = 0;
			optionDot.y += 16 * 2.5;
		}
		if (curSelected > options.length - 1) {
			curSelected = options.length - 1;
			optionDot.y -= 16 * 2.5;
		}

		//FORBIDDEN KEYBINDS (I'm so fucking sorry about these if statements...)
		if (FlxG.save.data.UP == "ONE" || FlxG.save.data.UP == "SEVEN" || FlxG.save.data.UP == "EIGHT" || FlxG.save.data.UP == "NINE"
			|| FlxG.save.data.UP == "ZERO" || FlxG.save.data.UP == "ESCAPE" || FlxG.save.data.UP == "BACKSPACE" || FlxG.save.data.UP == "SPACE" ||
			FlxG.save.data.UP == "ENTER" || FlxG.save.data.UP == "WIN"){
				controls.unbindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.UP), FlxKey.UP]);
				FlxG.save.data.UP = "W";
				controls.bindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.UP), FlxKey.UP]);
			}
		if (FlxG.save.data.DOWN == "ONE" || FlxG.save.data.DOWN == "SEVEN" || FlxG.save.data.DOWN == "EIGHT" || FlxG.save.data.DOWN == "NINE"
			|| FlxG.save.data.DOWN == "ZERO" || FlxG.save.data.DOWN == "ESCAPE" || FlxG.save.data.DOWN == "BACKSPACE" || FlxG.save.data.DOWN == "SPACE" ||
			FlxG.save.data.DOWN == "ENTER" || FlxG.save.data.DOWN == "WIN"){
				controls.unbindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.DOWN), FlxKey.DOWN]);
				FlxG.save.data.DOWN = "S";
				controls.bindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.DOWN), FlxKey.DOWN]);
			}
		if (FlxG.save.data.LEFT == "ONE" || FlxG.save.data.LEFT == "SEVEN" || FlxG.save.data.LEFT == "EIGHT" || FlxG.save.data.LEFT == "NINE"
			|| FlxG.save.data.LEFT == "ZERO" || FlxG.save.data.LEFT == "ESCAPE" || FlxG.save.data.LEFT == "BACKSPACE" || FlxG.save.data.LEFT == "SPACE" ||
			FlxG.save.data.LEFT == "ENTER" || FlxG.save.data.LEFT == "WIN"){
				controls.unbindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.LEFT), FlxKey.LEFT]);
				FlxG.save.data.LEFT = "A";
				controls.bindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.LEFT), FlxKey.LEFT]);
			}
		if (FlxG.save.data.RIGHT == "ONE" || FlxG.save.data.RIGHT == "SEVEN" || FlxG.save.data.RIGHT == "EIGHT" || FlxG.save.data.RIGHT == "NINE"
			|| FlxG.save.data.RIGHT == "ZERO" || FlxG.save.data.RIGHT == "ESCAPE" || FlxG.save.data.RIGHT == "BACKSPACE" || FlxG.save.data.RIGHT == "SPACE" ||
			FlxG.save.data.RIGHT == "ENTER" || FlxG.save.data.RIGHT == "WIN"){
				controls.unbindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.RIGHT), FlxKey.RIGHT]);
				FlxG.save.data.RIGHT = "D";
				controls.bindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.RIGHT), FlxKey.RIGHT]);
			}

		super.update(elapsed);
	}
}