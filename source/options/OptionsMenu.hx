package options;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;
import WebViewVideo;

import flixel.util.FlxSave;

class OptionsMenu extends MusicBeatState
{
	var selector:FlxText;
	var curSelected:Int = 0;

	var insubstate:Bool = false;

	//var controlsStrings:Array<String> = [];

	private var grpControls:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['controls', 'set fps', 'note splash: on', 'downscroll: off', 'cutscenes: on', 'About', 'test cutscene'];

	var UP_P:Bool;
	var DOWN_P:Bool;
	var BACK:Bool;
	var ACCEPT:Bool;
	var notice:FlxText;

	var _saveconrtol:FlxSave;

	var config:Config = new Config();

	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		//controlsStrings = CoolUtil.coolTextFile('assets/data/controls.txt');
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		notice = new FlxText(0, 0, 0,"", 24);

		notice.x = (FlxG.width / 2) - (notice.width / 2);
		notice.y = FlxG.height - 56;
		notice.alpha = 0.5;

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		if (FlxG.save.data.downscroll = true){
			menuItems[menuItems.indexOf('downscroll: off')] = 'downscroll: on';
		}
		if (FlxG.save.data.cutscene = false){
			menuItems[menuItems.indexOf('cutscenes: on')] = 'cutscenes: off';
		}
		if (FlxG.save.data.splash = false){
			menuItems[menuItems.indexOf('note splash: on')] = 'note splash: off';
		}

		for (i in 0...menuItems.length)
		{ 
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}
		add(notice);

		#if mobileC
		addVirtualPad(FULL, A_B);
		#end
		
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		notice.text= "Camera Movement: " + MusicBeatState.camMove + " Press LEFT or RIGHT to change values\n";
		if (controls.ACCEPT)
		{
			var daSelected:String = menuItems[curSelected];
			FlxG.save.data.camMove == MusicBeatState.camMove;

			switch (daSelected)
			{
				case "controls":
					FlxG.switchState(new options.CustomControlsState());
				
				case "config":
					trace("hello");
				
				case "set fps":
					insubstate = true;
					openSubState(new options.SetFpsSubState());
				
				case "note splash: on" | "note splash: off":
					if (FlxG.save.data.splash = false)
						FlxG.save.data.splash = true;

					if (FlxG.save.data.splash = true)
						FlxG.save.data.splash = false;

					FlxG.resetState();
				
				case "downscroll: on" | "downscroll: off":
					if (FlxG.save.data.downscroll = false)
						FlxG.save.data.downscroll = true;

					if (FlxG.save.data.downscroll = true)
						FlxG.save.data.downscroll = false;

					FlxG.resetState();
				
				case "cutscenes: on" | "cutscenes: off":
					if (FlxG.save.data.cutscene = false)
						FlxG.save.data.cutscene = true;

					if (FlxG.save.data.cutscene = true)
						FlxG.save.data.cutscene = false;

					FlxG.resetState();
				
				case "About":
					FlxG.switchState(new options.AboutState());
				case "test cutscene":
					#if extension-webview
					WebViewVideo.openVideo('ughCutscene');
					#end
			}
		}
		if (controls.RIGHT && MusicBeatState.camMove < 1.1)
		{
			MusicBeatState.camMove += 0.01;
		}
		if (controls.LEFT && MusicBeatState.camMove > 0)
		{
			MusicBeatState.camMove -= 0.01;
		}

		if (isSettingControl)
			waitingInput();
		else
		{
			if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
				FlxG.switchState(new MainMenuState());
			if (controls.UP_P)
				changeSelection(-1);
			if (controls.DOWN_P)
				changeSelection(1);
		}
		FlxG.save.flush();
	}

	function waitingInput():Void
	{
		if (false)// fix this FlxG.keys.getIsDown().length > 0
		{
			//PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxG.keys.getIsDown()[0].ID, null);
		}
		// PlayerSettings.player1.controls.replaceBinding(Control)
	}

	var isSettingControl:Bool = false;

	function changeBinding():Void
	{
		if (!isSettingControl)
		{
			isSettingControl = true;
		}
	}

	function changeSelection(change:Int = 0)
	{
		/* #if !switch
		NGio.logEvent('Fresh');
		#end
		*/
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

	// (this function is not working)
	function changeLabel(i:Int, text:String) {
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, text, true, false);
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		
		grpControls.forEach((basic)->{
			trace(basic.text);
			if (basic.text == menuItems[i])
			{
				grpControls.remove(basic);
			}
		});
		grpControls.insert(i, controlLabel);	
		menuItems[i] = text;
	}

	override function closeSubState()
		{
			insubstate = false;
			super.closeSubState();
		}	
}
