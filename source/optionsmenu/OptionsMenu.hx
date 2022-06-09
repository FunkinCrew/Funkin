package optionsmenu;

import cpp.abi.Abi;
import haxe.ds.Option;
import openfl.system.System;
import flixel.FlxState;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.FlxSubState;

using StringTools;

class OptionsMenu extends MusicBeatState {
	var options:Array<String> = ["option shit"];
	var lastOptionType:String = "default";

	var optionGroup = new FlxTypedGroup<FlxText>();
	
	var inOptionSelector:Bool = true;
	var startListening:Bool = true;
	var endedCheck:Bool = true;
	var forceCheck:Bool = false;

	var curSelected:Int = 0;
	var curOptionSelected:String = 'Gameplay';

	var lastOptionY:Float = 0;

	var selected:FlxText;

	var background:FlxSprite;
	var text:FlxText;
	var detailText:FlxText;
	var camFollow:FlxSprite;

	override function create() {
		super.create();

		background = new FlxSprite(0, 0, Paths.image('menuBGBlue'));
		background.scrollFactor.x = 0;
		background.scrollFactor.y = 0;
		background.updateHitbox();
		background.screenCenter();
		background.antialiasing = true;
		add(background);

		createOptions();

		detailText = new FlxText(0, 0, FlxG.width, "Options");
		detailText.scrollFactor.x = 0;
		detailText.scrollFactor.y = 0;
		detailText.setFormat("PhantomMuff 1.5", 16, FlxColor.LIME, "center");
		detailText.screenCenter(X);
		add(detailText);

		camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(optionGroup.members[0].width), Std.int(optionGroup.members[0].height), 0xAAFF0000);
		FlxG.camera.follow(camFollow, null, 0.06);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		curOptionSelected = options[curSelected].split(" ")[0];
		
		camFollow.screenCenter();
		if (optionGroup.members[curSelected] != null) {
			camFollow.y = optionGroup.members[curSelected].y - camFollow.height / 2;
		}

		if (controls.UP_P) {
			curSelected--;

			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeTextAlpha();

			if (curSelected < 0) {
				curSelected = 0;
			}
			else{
				changeTextAlpha();
			}
		}
		else if (controls.DOWN_P){
			curSelected++;

			FlxG.sound.play(Paths.sound('scrollMenu'));

			if (curSelected > options.length - 1) {
				curSelected = options.length - 1;
			}
			else{
				changeTextAlpha();
			}
		}

		if (controls.ACCEPT) {
			optionSelected();
		}

		if (controls.BACK) {
			if (!inOptionSelector)
				optionSelected(true);
			else
				FlxG.switchState(new MainMenuState());

			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		for (i in 0...optionGroup.members.length) {
			if (optionGroup.members[i] != null){
                // special stuff here
			}
		}
		
		if (options[curSelected].startsWith("null")){
			updateOptions();
		}

		if (curSelected > 3)
			detailText.y = FlxG.height - detailText.height;
		else
			detailText.y = 0;

		if (controls.DOWN_P || controls.UP_P || forceCheck){
			if (options[curSelected] == null){
				return;
			}

			switch(curOptionSelected.toLowerCase()){
                // option details here
			}

			if (forceCheck)
				!forceCheck;
		}

		if (!startListening && endedCheck){
			endedCheck = false;

			new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					startListening = true;
					endedCheck = true;
			});
		}
	}

	function createOptions(type:String = 'default') {
		var ready:Bool = false;
		lastOptionY = 0;

		if (inOptionSelector)
			curSelected = 0;

		switch(type.toLowerCase()) {
			default:
				inOptionSelector = true;

				options = ["Gameplay","Graphics","TOADD"];
				ready = true;
			case 'gameplay':
				inOptionSelector = false;

                options = ["Keybinds", 'Ghost-tapping ${FlxG.save.data.ghostTap ? 'ON' : 'OFF'}'];
				ready = true;
			case 'graphics':
				inOptionSelector = false;

                // array stuff here
				ready = true;
		}

		lastOptionType = type.toLowerCase();

		if (ready){
			for (i in 0...options.length) {
				text = new FlxText(0, lastOptionY, FlxG.width, options[i]);
				text.setFormat("PhantomMuff 1.5", 72, FlxColor.WHITE, "center");
                text.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 4, 1);
				text.alpha = 0.6;
				text.screenCenter(Y);
				text.y += lastOptionY - (curSelected * text.height);
                text.antialiasing = true;
				optionGroup.add(text);
				add(text);
				lastOptionY += text.height;
			}
		}

		changeTextAlpha();
		forceCheck = true;
	}

	function updateOptions() {
		
		if (optionGroup.members.length > 0) {
			for (i in 0...optionGroup.members.length) {
				if (optionGroup.members[i] != null){
					optionGroup.members[i].kill();
					optionGroup.remove(optionGroup.members[i]);
				}
			}
		}

		if (!inOptionSelector){
			createOptions(lastOptionType);
		}
	}

	function optionSelected(goingBack:Bool = false) {
		var dontAllowUpdate = false;

		if (goingBack){
			inOptionSelector = true;
			updateOptions();
			createOptions('default');
		}
		else{
			if (inOptionSelector) {
				trace('entering options ' + options[curSelected]);
				updateOptions();
				
				createOptions(options[curSelected]);
			}
			else{
				trace('already in options');

				switch(curOptionSelected.toLowerCase()) {
                    case 'keybinds':
                        FlxG.switchState(new KeybindsState());
                    case 'ghost-tapping':
                        FlxG.save.data.ghostTap = !FlxG.save.data.ghostTap;
				}

				if (!dontAllowUpdate){
					updateOptions();
				}
			}
		}
	}

	function changeTextAlpha(){
		if (curSelected == -1 || curSelected >= options.length) { // why do i have to do it like this???
			return;
		}
		else{
			for (text in 0...optionGroup.members.length) {
				if (text == curSelected && optionGroup.members[text] != null) {
					optionGroup.members[text].alpha = 1;
				}
	
				if (text != curSelected && optionGroup.members[text] != null) {
					optionGroup.members[text].alpha = 0.6;
				}
			}
		}
	}

	function updateFPS() {
		/*if (FlxG.save.data.frameRate > FlxG.drawFramerate){
			FlxG.updateFramerate = FlxG.save.data.frameRate;
			FlxG.drawFramerate = FlxG.save.data.frameRate;
		}
		else{
			FlxG.drawFramerate = FlxG.save.data.frameRate;
			FlxG.updateFramerate = FlxG.save.data.frameRate;
		}*/
	}
}
