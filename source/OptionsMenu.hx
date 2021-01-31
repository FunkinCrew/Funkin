package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.system.macros.FlxMacroUtil;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.utils.Assets;


class OptionsMenu extends MusicBeatState
{

	var selector:FlxText;
	var curSelected:Int = 0;

	var controlsStrings:Array<String> = [];

	private var grpControls:FlxTypedGroup<Alphabet>;
	var changingInput:Bool = false;
	
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		controlsStrings = CoolUtil.coolTextFile('assets/data/controls.txt');
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);
		var i = 0;

		for(key => value in Controls.keyboardMap){
			var elements:Array<String> = controlsStrings[i].split(',');
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30,'set ' + key + ': ' + value, true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);
			i++;
		}
		
		//for (i in 0...controlsStrings.length)
		//{
		//	
		//	var elements:Array<String> = controlsStrings[i].split(',');
		//	var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30,'set ' + elements[0] + ': ' + elements[1], true, false);
		//	controlLabel.isMenuItem = true;
		//	controlLabel.targetY = i;
		//	grpControls.add(controlLabel);
		//	
		//	// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		//}

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!changingInput)
		{
			if (controls.BACK){
				FlxG.switchState(new MainMenuState());
				Controls.saveControls();
				controls.setKeyboardScheme(Solo,true);
			}
			if(controls.UP_P)
				changeSelection(-1);
			if(controls.DOWN_P)
				changeSelection(1);
			if(controls.ACCEPT)
				ChangeInput();
		}
		else
		{
			ChangingInput();
		}

		
	}

	function changeSelection(change:Int = 0)
		{
			#if !switch
			NGio.logEvent('Fresh');
			#end
	
			FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);
	
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
	function ChangeInput()
	{
		changingInput = true;
		FlxFlicker.flicker(grpControls.members[curSelected],0);
	}

	function ChangingInput()
	{				
		if(FlxG.keys.pressed.ANY){
			//Checks all known keys
			var keyMaps:Map<String, FlxKey> = FlxMacroUtil.buildMap("flixel.input.keyboard.FlxKey");
			for(key in keyMaps.keys())
			{
				if(FlxG.keys.checkStatus(key,2) && key != "ANY")
				{					
					FlxFlicker.stopFlickering(grpControls.members[curSelected]);
					
					var elements:Array<String> = grpControls.members[curSelected].text.split(':');
					var name:String = StringTools.replace(elements[0],'set ','');
					var controlLabel:Alphabet = new Alphabet(0, 0,'set ' + name + ': ' + key, true, false);
					controlLabel.isMenuItem = true;
					controlLabel.targetY = 0;

					grpControls.replace(grpControls.members[curSelected],controlLabel);
					changingInput = false;
					
					Controls.keyboardMap.set(name,keyMaps[key]);
					FlxG.log.add(name + " is bound to " + keyMaps[key]);
					

					break;
				}
			}			

		}
	}

}
