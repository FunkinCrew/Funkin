package;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to menu','charting mode','default control','alternative control','left hand control'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	var _pad:FlxVirtualPad;
	var _saveconrtol:FlxSave;

	public function new(x:Float, y:Float)
	{
		super();

		pauseMusic = new FlxSound().loadEmbedded('assets/music/breakfast' + TitleState.soundExt, true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		_saveconrtol = new FlxSave();
    	_saveconrtol.bind("saveconrtol");
		_saveconrtol.data.boxPositions = new Array<FlxPoint>();
		
		_pad = new FlxVirtualPad(UP_DOWN, A);
    	_pad.alpha = 0.75;
    	this.add(_pad);
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		if(FlxG.android.justReleased.BACK == true){
			close();
		}
		
		var upP = _pad.buttonUp.justPressed;
		var downP = _pad.buttonDown.justPressed;
		var accepted = _pad.buttonA.justPressed;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (accepted)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					trace(_saveconrtol.data.boxPositions[0]);
					this.remove(_pad);
					_pad = null;
					close();
				case "Restart Song":
					FlxG.resetState();
				case "Exit to menu":
					FlxG.switchState(new MainMenuState());
				case "charting mode":
					close();
					FlxG.switchState(new ChartingState());
				case "default control":
					this.remove(_pad);
					_pad = null;
					_saveconrtol.data.boxPositions.push(3);
					_saveconrtol.flush();
					close();
				case "alternative control":
					this.remove(_pad);
					_pad = null;
					_saveconrtol.data.boxPositions.push(2);
					_saveconrtol.flush();
					close();
				case "left hand control":
					this.remove(_pad);
					_pad = null;
					_saveconrtol.data.boxPositions.push(1);
					_saveconrtol.flush();
					close();
			}
		}
		/*
		if (FlxG.keys.justPressed.J)
		{
			// for reference later!
			// PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxKey.J, null);
		}
		*/
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
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
