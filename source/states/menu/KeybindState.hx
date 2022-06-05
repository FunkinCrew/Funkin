//! I took this from Sublime Engine.
//! not my code.

package states.menu;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKeyboard.FlxKeyInput;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxBasic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import engine.base.Controls.Control;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import engine.io.Paths;

using StringTools;

class KeybindState extends engine.base.MusicBeatState {
	var options:Array<String> = ['shit'];

	var optionText:FlxText;
	var detailText:FlxText;
	var optionDot:FlxSprite;

	var topText:FlxText;

	var curSelected:Int = 0;

	var startListening = false;
	var selectedKey = "LEFT";

	public override function create() {
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		var background = new FlxSprite(0, 0, Paths.image('menuBGBlue'));
		background.updateHitbox();
		background.screenCenter();
		background.antialiasing = true;
		add(background);

		var backtext = new FlxSprite().makeGraphic(1024, 208, FlxColor.BLACK);
		backtext.alpha = 0.6;
		backtext.screenCenter();
		backtext.y -= 48;
		add(backtext);

		optionText = new FlxText(0, FlxG.height / 3, 512, 'OPTIONS LOLOLO', 32);
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
		optionDot.animation.addByPrefix("confirm", "right confirm");
		optionDot.animation.play("idle");
		optionDot.setGraphicSize(50);
		optionDot.updateHitbox();
		add(optionDot);

		detailText = new FlxText(0, optionText.y + optionText.width + 24, 0, "", 24);
		detailText.font = 'PhantomMuff 1.5';
		detailText.screenCenter(X);
		add(detailText);

		optionDot.y = optionText.y - optionDot.height / 5;

		topText = new FlxText(0, optionDot.y - 360, 0, "OPTIONS", 32);
		topText.screenCenter(X);
		// add(topText);

		super.create();
	}

	public override function update(elapsed:Float) {
		options = ['LEFT | ' + FlxG.save.data.LEFT, 'DOWN | ' + FlxG.save.data.DOWN, 'UP | ' + FlxG.save.data.UP,
		'RIGHT | ' + FlxG.save.data.RIGHT];

		optionText.screenCenter(X);

		optionDot.x = optionText.x - 32;

		detailText.x = optionText.x + 512;
		detailText.y = optionDot.y;

		/*camFollow.screenCenter();
		camFollow.y = optionDot.y - camFollow.height / 2;*/

		topText.y = optionDot.y;

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