package optionshit;

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
		//background.setGraphicSize(Std.int(background.width * 1.3));
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
		
		/*selected = new FlxText(0, lastOptionY, FlxG.width, options[curSelected]);
		selected.setFormat("PhantomMuff 1.5", 16, FlxColor.WHITE, "center");
		selected.y = lastOptionY;
		lastOptionY += selected.height;
		add(selected);*/

		camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(optionGroup.members[0].width), Std.int(optionGroup.members[0].height), 0xAAFF0000);
		FlxG.camera.follow(camFollow, null, 0.06);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		/*if (FlxG.save.data.frameRate == null){
			FlxG.save.data.frameRate == 60;
			updateFPS();
		}*/

		curOptionSelected = options[curSelected].split(" ")[0];
		
		camFollow.screenCenter();
		if (optionGroup.members[curSelected] != null) {
			camFollow.y = optionGroup.members[curSelected].y - camFollow.height / 2;
		}

		if (controls.CHEAT){
			FlxG.save.data.frameRate = 1000;
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
				if (optionGroup.members[curSelected].text.startsWith("Framerate") && startListening) {
					if (controls.LEFT) {
						FlxG.save.data.frameRate -= 1;
					}
					else if (controls.RIGHT)
						FlxG.save.data.frameRate += 1;
		
					if (controls.LEFT || controls.RIGHT){
						updateFPS();
						updateOptions();
						startListening = false;
					}
				}
			}
		}

		if (FlxG.save.data.frameRate > 256){
			FlxG.save.data.frameRate = 256;
			updateOptions();
		}
		else if (FlxG.save.data.frameRate < 30){
			FlxG.save.data.frameRate = 30;
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

			switch(curOptionSelected){
				case 'Keybinds':
					detailText.text = 'Change your Controls.';
				case 'Epilepsy':
					detailText.text = 'Prevents Epilepsy if enabled.';
				case 'Ghost':
					detailText.text = "You won't miss when tapping at the wrong time.";
				case 'Disable':
					detailText.text = 'Disables annoying background objects.';
				case 'Custom':
					detailText.text = 'Disables or Enables the custom Health Bar Colors.';
				case 'Judgement':
					detailText.text = 'Changes the difficulty on hitting notes.';
				case 'Panicable':
					detailText.text = 'Makes the BF Panic when low on Health';
				case 'Lane':
					detailText.text = 'Shows a lane under the Notes.';
				case 'Framerate':
					detailText.text = 'Changes your Framerate.';
				case 'Gameplay':
					detailText.text = 'Change Gameplay Options.';
				case 'Graphics':
					detailText.text = 'Change Graphical Options.';
				case 'Credits':
					detailText.text = 'View Credits.';
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

		//selected.text = options[curSelected];
	}

	function createOptions(type:String = 'default') {
		var ready:Bool = false;
		lastOptionY = 0;

		if (inOptionSelector)
			curSelected = 0; // lol don't want this changing when we're not in the option selector

		switch(type.toLowerCase()) {
			default:
				inOptionSelector = true;

				options = ["Gameplay", "Graphics", "Credits"];
				ready = true;
			case 'gameplay':
				inOptionSelector = false;

				options = ['Keybinds', 'Ghost Tapping ${FlxG.save.data.gtapping ? 'ON' : 'OFF'}',
				'Judgement Type ${FlxG.save.data.judgeHits ? 'UNMODIFIED' : 'MODIFIED'}',
				'Disable Distractions ${FlxG.save.data.noDistractions ? 'ON' : 'OFF'}',
				'Panicable Boyfriend ${FlxG.save.data.disablePanicableBF ? 'OFF' : 'ON'}'];
				ready = true;
			case 'graphics':
				inOptionSelector = false;

				options = ['Epilepsy Mode ${FlxG.save.data.epilepsyMode ? 'ON' : 'OFF'}',
				'Lane Underlay ${FlxG.save.data.laneUnderlay ? 'ON' : 'OFF'}',
				'Custom Health Colors ${FlxG.save.data.disablehealthColor ? 'OFF' : 'ON'}',
				'Framerate ${FlxG.save.data.frameRate} FPS'];
				ready = true;
			case 'credits':
				FlxG.switchState(new InformationState());
		}

		lastOptionType = type.toLowerCase();

		if (ready){
			for (i in 0...options.length) {
				text = new FlxText(0, lastOptionY, FlxG.width, options[i]);
				text.setFormat("PhantomMuff 1.5", 72, FlxColor.WHITE, "center");
				text.alpha = 0.6;
				text.screenCenter(Y);
				text.y += lastOptionY - (curSelected * text.height);
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

				switch(curOptionSelected){
					case 'Ghost': // ghost tapping
						FlxG.save.data.gtapping = !FlxG.save.data.gtapping;
						options[curSelected] = 'Ghost Tapping ${FlxG.save.data.gtapping ? "ON" : "OFF"}';
					case 'Judgement': // judgement type
						FlxG.save.data.judgeHits = !FlxG.save.data.judgeHits;
						options[curSelected] = 'Judgement Type ${FlxG.save.data.judgeHits ? "UNMODIFIED" : "MODIFIED"}';
					case 'Disable': // disable distractions
						FlxG.save.data.noDistractions = !FlxG.save.data.noDistractions;
						options[curSelected] = 'Disable Distractions ${FlxG.save.data.noDistractions ? "ON" : "OFF"}';
					case 'Panicable': // panicable boyfriend
						FlxG.save.data.disablePanicableBF = !FlxG.save.data.disablePanicableBF;
						options[curSelected] = 'Panicable Boyfriend ${FlxG.save.data.disablePanicableBF ? "OFF" : "ON"}';
					case 'Epilepsy': // epilepsy mode
						FlxG.save.data.epilepsyMode = !FlxG.save.data.epilepsyMode;
						options[curSelected] = 'Epilepsy Mode ${FlxG.save.data.epilepsyMode ? "ON" : "OFF"}';
					case 'Lane': // lane underlay
						FlxG.save.data.laneUnderlay = !FlxG.save.data.laneUnderlay;
						options[curSelected] = 'Lane Underlay ${FlxG.save.data.laneUnderlay ? "ON" : "OFF"}';
					case 'Custom': // Custom Health Colors
						FlxG.save.data.disablehealthColor = !FlxG.save.data.disablehealthColor;
						options[curSelected] = 'Custom Health Colors ${FlxG.save.data.disablehealthColor ? "OFF" : "ON"}';
					case 'Framerate': // framerate
						FlxG.save.data.frameRate = FlxG.save.data.frameRate == 60 ? 128 : 60;
						updateFPS();
					case 'Keybinds': // keybinds
						FlxG.switchState(new Keybinds());
						dontAllowUpdate = true;
				}
				
				if (!dontAllowUpdate)
					updateOptions();
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
		if (FlxG.save.data.frameRate > FlxG.drawFramerate){
			FlxG.updateFramerate = FlxG.save.data.frameRate;
			FlxG.drawFramerate = FlxG.save.data.frameRate;
		}
		else{
			FlxG.drawFramerate = FlxG.save.data.frameRate;
			FlxG.updateFramerate = FlxG.save.data.frameRate;
		}
	}
}