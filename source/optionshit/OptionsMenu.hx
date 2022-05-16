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

		// check if save data is null

		if (FlxG.save.data.frameRate == null) {
			FlxG.save.data.frameRate = 60;
		}

	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		
		camFollow.screenCenter();
		if (optionGroup.members[curSelected] != null) {
			camFollow.y = optionGroup.members[curSelected].y - camFollow.height / 2;
		}

		if (controls.CHEAT && !controls.RIGHT){
			/*FlxG.save.data.frameRate = 1000; // push the games limit
			updateFPS();*/

			FlxG.save.data.frameRate = 16; // testing purposes
			updateFPS();
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

						if (FlxG.save.data.frameRate > 256){
							FlxG.save.data.frameRate = 256;
							updateOptions();
						}
						else if (FlxG.save.data.frameRate < 30){
							FlxG.save.data.frameRate = 30;
							updateOptions();
						}
					}
				}
			}
		}

		if (curSelected > 3)
			detailText.y = FlxG.height - detailText.height;
		else
			detailText.y = 0;

		if (controls.DOWN_P || controls.UP_P || forceCheck){
			if (options[curSelected] == null){
				return;
			}

			// im so fucking sorry for this
			if (options[curSelected].startsWith('Keybinds')) {
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
			if (options[curSelected].startsWith('Framerate Cap')){
				detailText.text = 'Changes your Framerate.';
			}
			if (options[curSelected].startsWith('Lite Mode')){
				detailText.text = 'Makes the game run faster on some low-end devices by disabling almost all features.';
			}

			// menu details
			if (options[curSelected].startsWith('Gameplay')){
				detailText.text = 'Change Gameplay Options.';
			}
			if (options[curSelected].startsWith('Graphics')){
				detailText.text = 'Change Graphical Options.';
			}
			if (options[curSelected].startsWith('Nothing here!')){
				detailText.text = 'Nothing here, Don\'t click me.';
			}

			if (forceCheck)
				!forceCheck;
			// god it hurt writing this
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

				options = ["Gameplay", "Graphics", "Nothing here!"];
				ready = true;
			case 'gameplay':
				inOptionSelector = false;

				options = ['Keybinds', 'Ghost Tapping ${FlxG.save.data.gtapping ? 'ON' : 'OFF'}',
				'Judgement Type ${FlxG.save.data.judgeHits ? 'UNMODIFIED' : 'MODIFIED'}',
				'Panicable Boyfriend ${FlxG.save.data.disablePanicableBF ? 'OFF' : 'ON'}'];
				ready = true;
			case 'graphics':
				inOptionSelector = false;

				options = ['Epilepsy Mode ${FlxG.save.data.epilepsyMode ? 'ON' : 'OFF'}',
				'Disable Distractions ${FlxG.save.data.noDistractions ? 'ON' : 'OFF'}',
				'Lite Mode ${FlxG.save.data.liteMode ? 'ON' : 'OFF'}',
				'Lane Underlay ${FlxG.save.data.laneUnderlay ? 'ON' : 'OFF'}',
				'Custom Health Colors ${FlxG.save.data.disablehealthColor ? 'OFF' : 'ON'}',
				'Framerate Cap ${FlxG.save.data.frameRate} FPS'];
				ready = true;
			case 'nothing here!':
				#if cpp
				FlxG.openURL('https://www.youtube.com/watch?v=oavMtUWDBTM');
				System.exit(0);
				#else
				FlxG.sound.play(Paths.sound('GF_3', 'shared'));
				#end
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
				
				// yeah i know this is a bit of a stupid way to do this but i dont know how to do it with a switch statement
				if (options[curSelected].startsWith('Ghost Tapping')) {
					FlxG.save.data.gtapping = !FlxG.save.data.gtapping;
				}
				else if (options[curSelected].startsWith('Judgement Type')) {
					FlxG.save.data.judgeHits = !FlxG.save.data.judgeHits;
				}
				else if (options[curSelected].startsWith('Disable Distractions')) {
					FlxG.save.data.noDistractions = !FlxG.save.data.noDistractions;
				}
				else if (options[curSelected].startsWith('Panicable Boyfriend')) {
					FlxG.save.data.disablePanicableBF = !FlxG.save.data.disablePanicableBF;
				}
				else if (options[curSelected].startsWith('Epilepsy Mode')) {
					FlxG.save.data.epilepsyMode = !FlxG.save.data.epilepsyMode;
				}
				else if (options[curSelected].startsWith('Lane Underlay')) {
					FlxG.save.data.laneUnderlay = !FlxG.save.data.laneUnderlay;
				}
				else if (options[curSelected].startsWith('Custom Health Colors')) {
					FlxG.save.data.disablehealthColor = !FlxG.save.data.disablehealthColor;
				}
				else if (options[curSelected].startsWith('Framerate Cap')) {
					FlxG.save.data.frameRate = FlxG.save.data.frameRate == 60 ? 128 : 60;
					updateFPS();
				}
				else if (options[curSelected].startsWith('Keybinds')){
					FlxG.switchState(new Keybinds());
					dontAllowUpdate = true;
				}
				else if(options[curSelected].startsWith('Lite Mode')){
					FlxG.save.data.liteMode = !FlxG.save.data.liteMode;
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