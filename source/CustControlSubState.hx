package;

import flixel.addons.ui.FlxUIButton;
import flixel.text.FlxText;
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

class CustControlSubState extends MusicBeatSubstate
{

	var _pad:FlxVirtualPad;
	var _saveconrtol:FlxSave;

	var up_text:FlxText;
	var down_text:FlxText;
	var left_text:FlxText;
	var right_text:FlxText;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic('assets/images/menuBG.png');
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		_saveconrtol = new FlxSave();
    	_saveconrtol.bind("saveconrtol");
		_saveconrtol.data.boxPositions = new Array<FlxPoint>();
		/*
		_pad = new FlxVirtualPad(UP_DOWN, A);
    	_pad.alpha = 0.75;
		this.add(_pad);
		*/
		_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
		_pad.alpha = 0.75;
		this.add(_pad);

		up_text = new FlxText(200, 200, 0,"Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y, 24);
		down_text = new FlxText(200, 250, 0,"Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y, 24);
		left_text = new FlxText(200, 300, 0,"Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y, 24);
		right_text = new FlxText(200, 350, 0,"Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y, 24);
		
		
		add(up_text);
		add(down_text);
		add(left_text);
		add(right_text);

		var savebutton = new FlxUIButton(FlxG.width - 150,25,"save",savebuttons);
		savebutton.resize(100,50);
		savebutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		
		var defbutton = new FlxUIButton(FlxG.width - 325,25,"default",defaultcontrol);
		defbutton.resize(125,50);
		defbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");

		add(defbutton);
		add(savebutton);
		
	}

	function savebuttons() {
		trace("saved");
		_saveconrtol.data.boxPositions.push(4);

		_saveconrtol.data.boxPositions.push(_pad.buttonUp.x);

		trace(_saveconrtol.data.boxPositions[1]);
		//_saveconrtol.data.boxPositions[1].push(_pad.buttonUp.x);
		
		_saveconrtol.flush();

		trace(_saveconrtol.data.boxPositions[2]);

	}
	function defaultcontrol() {
		trace("default");
		
		this.remove(_pad);
		_pad = null;
		_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
		_pad.alpha = 0.75;
		this.add(_pad);

	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (touch in FlxG.touches.list){
			if(_pad.buttonUp.pressed)
			{
				trace("buttonUp.pressed");
				up_text.text = "Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y;
				_pad.buttonUp.x = touch.x - _pad.buttonUp.width / 2;
				_pad.buttonUp.y = touch.y - _pad.buttonUp.height / 2;
			}else if(_pad.buttonDown.pressed)
			{
				trace("buttonDown.pressed");
				down_text.text = "Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y;
				_pad.buttonDown.x = touch.x - _pad.buttonDown.width / 2;
				_pad.buttonDown.y = touch.y - _pad.buttonDown.height / 2;
			}else if(_pad.buttonRight.pressed)
			{
				trace("buttonRight.pressed");
				_pad.buttonRight.x = touch.x - _pad.buttonRight.width / 2;
				_pad.buttonRight.y = touch.y - _pad.buttonRight.height / 2;
			}else if(_pad.buttonLeft.pressed){
				trace("buttonLeft.pressed");
				_pad.buttonLeft.x = touch.x - _pad.buttonLeft.width / 2;
				_pad.buttonLeft.y = touch.y -
				_pad.buttonLeft.height / 2;
			}
			left_text.text = "Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y;
			right_text.text = "Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y;

			/*
			_pad.buttonDown.x = touch.x + _pad.buttonDown.width;
			_pad.buttonDown.y = touch.y + _pad.buttonDown.height;

			_pad.buttonRight.x = touch.x + _pad.buttonRight.width;
			_pad.buttonRight.y = touch.y + _pad.buttonRight.height;

			_pad.buttonLeft.x = touch.x + _pad.buttonLeft.width;
			_pad.buttonLeft.y = touch.y + _pad.buttonLeft.height;
			*/
			if(touch.justReleased){
				//trace(_pad.buttonUp.x);
				trace(_pad.buttonUp.y);
				trace(FlxG.camera.y);
				/*
				trace("touched x: " + touch.x);
				trace("touched y: " + touch.y);
				trace(FlxG.stage.stageHeight);
				trace(FlxG.stage.stageWidth);*/
			}
		}

		if(FlxG.android.justReleased.BACK == true){
			FlxG.switchState(new MainMenuState());
		}
		
	}

	override function destroy()
	{

		super.destroy();
	}

}
