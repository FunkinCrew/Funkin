package optionshit;

import flixel.FlxState;
import flixel.util.FlxTimer;
import flixel.tweens.motion.LinearMotion;
import flixel.tweens.FlxTween;
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
	var inTween:Bool = false;
	var startListening:Bool = true;
	var endedCheck:Bool = true;

	var curSelected:Int = 0;

	var lastOptionY:Float = 0;
	var optionYoffset:Float = 0;

	var selected:FlxText;

	var background:FlxSprite;
	var text:FlxText;

	var tween:FlxTween;

	override function create() {
		super.create();

		background = new FlxSprite(0, 0, Paths.image('menuBGBlue'));
		//background.setGraphicSize(Std.int(background.width * 1.3));
		background.updateHitbox();
		background.screenCenter();
		background.antialiasing = true;
		add(background);

		createOptions();
		
		/*selected = new FlxText(0, lastOptionY, FlxG.width, options[curSelected]);
		selected.setFormat("PhantomMuff 1.5", 16, FlxColor.WHITE, "center");
		selected.y = lastOptionY;
		lastOptionY += selected.height;
		add(selected);*/
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UP_P && !inTween) {
			curSelected--;

			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeTextAlpha();

			if (curSelected < 0) {
				curSelected = 0;
			}
			else{
				changeTextAlpha();
				for (i in 0...optionGroup.members.length) {
					if (optionGroup.members[i] != null){
						inTween = true;
						FlxTween.linearMotion(optionGroup.members[i], optionGroup.members[i].x, optionGroup.members[i].y, 
							optionGroup.members[i].x, optionGroup.members[i].y + optionGroup.members[i].height, 0.3, true, {onComplete: disableInTween});
					}
				}
			}
		}
		else if (controls.DOWN_P && !inTween){
			curSelected++;

			FlxG.sound.play(Paths.sound('scrollMenu'));

			if (curSelected > options.length - 1) {
				curSelected = options.length - 1;
			}
			else{
				changeTextAlpha();
				for (i in 0...optionGroup.members.length) {
					if (optionGroup.members[i] != null){
						inTween = true;
						FlxTween.linearMotion(optionGroup.members[i], optionGroup.members[i].x, optionGroup.members[i].y, 
							optionGroup.members[i].x, optionGroup.members[i].y - optionGroup.members[i].height, 0.3, true, {onComplete: disableInTween});
					}
				}
			}
		}

		if (controls.ACCEPT && !inTween) {
			optionSelected();
		}

		if (controls.BACK && !inTween) {
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

		trace(type);

		switch(type.toLowerCase()) {
			default:
				inOptionSelector = true;

				options = ["Gameplay", "Graphics", "Keybinds"];
				ready = true;
			case 'gameplay':
				inOptionSelector = false;

				options = ['Ghost Tapping ${FlxG.save.data.gtapping ? 'ON' : 'OFF'}',
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
			case 'keybinds':
				FlxG.switchState(new Keybinds()); // dumb but works
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
			trace(lastOptionType);
		}
		else{
			optionYoffset = 0;
		}
	}

	function optionSelected(goingBack:Bool = false) {
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
				else if (options[curSelected].startsWith('Framerate')) {
					trace('dumbass');
				}
				
				updateOptions();
			}
		}
	}

	function disableInTween(tween:FlxTween):Void
		{
			//optionYoffset = optionGroup.members[optionGroup.length].y;
			for (i in 0...optionGroup.members.length) {
				if (optionGroup.members[i] != null){
					optionYoffset = optionGroup.members[i].y; //asdhdfh
				}
			}

			inTween = false;
		}

	function changeTextAlpha(){
		if (curSelected == -1 || curSelected >= options.length) { // why do i have to do it like this???
			return;
		}
		else{
			for (text in 0...optionGroup.members.length) {
				trace(text);
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