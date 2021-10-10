package;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxSprite;

using StringTools;
class GamemodeSelectorState extends MusicBeatState {
    var options = [];
    var optionDot:FlxSprite;
    var optionText:FlxText;
    var camFollow:FlxSprite;

    var curSelected:Int;
    
    public override function create() {
        transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

        options = ['O'];

        var bg = new FlxSprite(0, 0).loadGraphic(Paths.image('menuBGBlue', 'preload'));
        bg.scrollFactor.set(0, 0.18);
        bg.setGraphicSize(Std.int(bg.width * 1.1));
        bg.antialiasing = true;
        add(bg);

        var titleText = new FlxText(0, 20, 0, "Select Gamemode", 32);
        titleText.setFormat(Paths.font("handwriting.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        titleText.screenCenter(X);
        titleText.scrollFactor.set(0, 0);
        titleText.antialiasing = true;
        add(titleText);

        optionText = new FlxText(0, 20, 0, "gamemodes lolololo", 32);
        optionText.setFormat(Paths.font("handwriting.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        optionText.screenCenter();
        optionText.antialiasing = true;
        add(optionText);

        super.create();

        optionDot = new FlxSprite(0, 0).makeGraphic(10, 10, FlxColor.RED);
		add(optionDot);

		camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width), Std.int(optionText.height), 0xA0FF0000);

        add(camFollow);

        optionDot.y = optionText.y - 55; // red dot offset, adjust when adding new setting!

        curSelected = 0;

        FlxG.camera.follow(camFollow, null, 0.06);
    }

    public override function update(elapsed:Float) {
        super.update(elapsed);

        // camFollow.width = optionText.width;

        options = ['Standard - the normal game', '1Key - Everything is up-arrow', 'Chaos - Notes are still on time just randomly placed', 'SineScroll - The scrollspeed speeds up or slows down based on a sine wave', 'SineHUD - The HUD spins based on a sine', 'InstaDeath - A single miss kills you instantly'];

        optionText.screenCenter();

        optionDot.x = optionText.x - 20;


		camFollow.screenCenter(X);
		camFollow.y = optionDot.y - camFollow.height / 2;

		// OLD! -- FlxG.camera.y = -FlxMath.lerp(-FlxG.height * 2, optionDot.y, 0.8); // camera following the red dot

		optionText.text = '';
		for (option in options) {
			optionText.text += '\n${option}';
		}
        optionText.text += '\n${options[options.length]}';

		if (FlxG.save.data.offset == null) FlxG.save.data.offset = 0;

		if (FlxG.save.data.offset < 0.1 && FlxG.save.data.offset > -10) {
			FlxG.save.data.offset = 0;
		}

		if (FlxG.save.data.sspeed == null) FlxG.save.data.sspeed = 0;

		if (FlxG.save.data.sspeed < 0.1) {
			FlxG.save.data.sspeed = 0;
		}

		if (controls.ACCEPT) {
			var arr = options[curSelected].split('-');
            PlayState.curGM = arr[0].trim().toLowerCase();
            LoadingState.loadAndSwitchState(new PlayState(), true);
		}

		if (controls.BACK) {
			FlxG.switchState(new MainMenuState());
		}

		if (controls.UP_P) {
			curSelected--;
			optionDot.y -= 16 * 1.6;
		}
		if (controls.DOWN_P) {
			curSelected++;
			optionDot.y += 16 * 1.6;
		}

		if (curSelected < 0) {
			curSelected = 0;
			optionDot.y += 16 * 1.6;
		}
		if (curSelected > options.length - 1) {
			curSelected = options.length - 1;
			optionDot.y -= 16 * 1.6;
		}

        FlxG.watch.addQuick("curSelected/options.length", '${curSelected}/${options.length}');
    }
}