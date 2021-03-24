package;

import Controls.KeyboardScheme;
import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

class OptionsMenu extends MusicBeatState
{
	var selector:FlxText;
	var curSelected:Int = 0;
	var chartSpeed:FlxText;
	var speedState:String;

	var controlsStrings:Array<String> = [];

	private var grpControls:FlxTypedGroup<Alphabet>;
	var versionShit:FlxText;
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		controlsStrings = CoolUtil.coolStringFile(
			(FlxG.save.data.dfjk ? 'DFJK' : 'WASD') + 
			"\n" + (FlxG.save.data.newInput ? "New input" : "Old Input") + 
			"\n" + (FlxG.save.data.downscroll ? 'Downscroll' : 'Upscroll') + 
			"\nAccuracy " + (!FlxG.save.data.accuracyDisplay ? "off" : "on") + 
			"\nSong Position " + (!FlxG.save.data.songPosition ? "off" : "on") +
			"\nNote Speed" +
			"\nEtterna Mode " + (!FlxG.save.data.etternaMode ? "off" : "on") +
			"\nLoad replays");
		
		trace(controlsStrings);

		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...controlsStrings.length)
		{
				var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, controlsStrings[i], true, false);
				controlLabel.isMenuItem = true;
				controlLabel.targetY = i;
				grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}


		versionShit = new FlxText(5, FlxG.height - 18, 0, "Offset (Left, Right): " + FlxG.save.data.offset, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		var tmp_Speed:Float = FlxG.save.data.noteSpeed;

		chartSpeed = new FlxText(FlxG.width - 387, FlxG.height - 18, 0, "Note Speed (Hover, then Left and Right): " + tmp_Speed, 12);
		chartSpeed.scrollFactor.set();
		chartSpeed.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		if(tmp_Speed == -1) chartSpeed.x = FlxG.width - 470;
		else if(tmp_Speed == 1.5 || tmp_Speed == 2.5 || tmp_Speed == 3.5) chartSpeed.x = FlxG.width - 405;
		else chartSpeed.x = FlxG.width - 387;

		if(FlxG.save.data.noteSpeed > 0) chartSpeed.text = "Note Speed (Hover, then Left and Right): " + FlxG.save.data.noteSpeed.toString();
		else chartSpeed.text = "Note Speed (Hover, then Left and Right): Song Based";
		add(chartSpeed);
		
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

			if (controls.BACK)
				FlxG.switchState(new MainMenuState());
			if (controls.UP_P)
				changeSelection(-1);
			if (controls.DOWN_P)
				changeSelection(1);
			
			if (controls.RIGHT_R)
			{
				if(curSelected != 5)
				{
					FlxG.save.data.offset++;
					versionShit.text = "Offset (Left, Right): " + FlxG.save.data.offset;
				}else {
					if(FlxG.save.data.noteSpeed < 4.0) 
						if(FlxG.save.data.noteSpeed == -1) FlxG.save.data.noteSpeed = 1.0;
						else FlxG.save.data.noteSpeed += 0.5;
					
					grpControls.remove(grpControls.members[curSelected]);
					var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, "Note Speed", true, false);
					ctrl.isMenuItem = true;
					ctrl.targetY = curSelected - 5;
					grpControls.add(ctrl);
					
					if(FlxG.save.data.noteSpeed > 0) speedState = FlxG.save.data.noteSpeed.toString();
					else speedState = "Song Based";
					
					chartSpeed.text = "Note Speed (Hover, then Left and Right): " + speedState;
					
					trace(FlxG.save.data.noteSpeed);
				}
			}

			if (controls.LEFT_R)
			{
				if(curSelected != 5)
				{
					FlxG.save.data.offset--;
					versionShit.text = "Offset (Left, Right): " + FlxG.save.data.offset;
				}else {
					if(FlxG.save.data.noteSpeed > 1.0) FlxG.save.data.noteSpeed -= 0.5;
					else FlxG.save.data.noteSpeed = -1;
					
					trace(FlxG.save.data.noteSpeed);
					var speedState = "";
					
					if(FlxG.save.data.noteSpeed > 0) speedState = FlxG.save.data.noteSpeed.toString();
					else speedState = "Song Based";
					
					chartSpeed.text = "Note Speed (Hover, then Left and Right): " + speedState;
					
					grpControls.remove(grpControls.members[curSelected]);
					var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, "Note Speed", true, false);
					ctrl.isMenuItem = true;
					ctrl.targetY = curSelected - 5;
					grpControls.add(ctrl);
					
					trace(FlxG.save.data.noteSpeed);
				}
			}
	
			if(controls.LEFT_R  && curSelected == 5 || controls.RIGHT_R && curSelected == 5 )
			{
				var tmp_Speed:Float = FlxG.save.data.noteSpeed;
				
				if(tmp_Speed == -1) chartSpeed.x = FlxG.width - 470;
				else if(tmp_Speed == 1.5 || tmp_Speed == 2.5 || tmp_Speed == 3.5) chartSpeed.x = FlxG.width - 405;
				else chartSpeed.x = FlxG.width - 387;
			}

			if (controls.ACCEPT)
			{
				if (curSelected != 7 && curSelected != 5)
					grpControls.remove(grpControls.members[curSelected]);
				
				switch(curSelected)
				{
					case 0:
						FlxG.save.data.dfjk = !FlxG.save.data.dfjk;
						var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, (FlxG.save.data.dfjk ? 'DFJK' : 'WASD'), true, false);
						ctrl.isMenuItem = true;
						ctrl.targetY = curSelected;
						grpControls.add(ctrl);
						if (FlxG.save.data.dfjk)
							controls.setKeyboardScheme(KeyboardScheme.Solo, true);
						else
							controls.setKeyboardScheme(KeyboardScheme.Duo(true), true);
						
					case 1:
						FlxG.save.data.newInput = !FlxG.save.data.newInput;
						var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, (FlxG.save.data.newInput ? "New input" : "Old Input"), true, false);
						ctrl.isMenuItem = true;
						ctrl.targetY = curSelected - 1;
						grpControls.add(ctrl);
					case 2:
						FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
						var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, (FlxG.save.data.downscroll ? 'Downscroll' : 'Upscroll'), true, false);
						ctrl.isMenuItem = true;
						ctrl.targetY = curSelected - 2;
						grpControls.add(ctrl);
					case 3:
						FlxG.save.data.accuracyDisplay = !FlxG.save.data.accuracyDisplay;
						var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, "Accuracy " + (!FlxG.save.data.accuracyDisplay ? "off" : "on"), true, false);
						ctrl.isMenuItem = true;
						ctrl.targetY = curSelected - 3;
						grpControls.add(ctrl);
					case 4:
						FlxG.save.data.songPosition = !FlxG.save.data.songPosition;
						var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, "Song Position " + (!FlxG.save.data.songPosition ? "off" : "on"), true, false);
						ctrl.isMenuItem = true;
						ctrl.targetY = curSelected - 4;
						grpControls.add(ctrl);
					case 6:
						FlxG.save.data.etternaMode = !FlxG.save.data.etternaMode;
						var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, "Etterna Mode " + (!FlxG.save.data.etternaMode ? "off" : "on"), true, false);
						ctrl.isMenuItem = true;
						ctrl.targetY = curSelected - 6;
						grpControls.add(ctrl);
					case 7:
						trace('switch');
						FlxG.switchState(new LoadReplayState());
				}
			}
		FlxG.save.flush();
	}

	var isSettingControl:Bool = false;

	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (item in grpControls.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
