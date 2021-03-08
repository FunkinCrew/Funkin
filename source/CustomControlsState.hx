package;

import lime.utils.Int16Array;
import lime.utils.Assets;
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


class CustomControlsState extends MusicBeatSubstate
{

	var _pad:FlxVirtualPad;
	var _saveconrtol:FlxSave;

	var exitbutton:FlxUIButton;

	var up_text:FlxText;
	var down_text:FlxText;
	var left_text:FlxText;
	var right_text:FlxText;

	var inputvari:FlxText;

	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
							//'hitbox',
	var controlitems:Array<String> = ['right control', 'left control','keyboard','custom'];

	var curSelected:Int = 0;


	public function new()
	{
		super();

		//save
		_saveconrtol = new FlxSave();
    	_saveconrtol.bind("saveconrtol");
		
		// bg
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic('assets/images/menuBG.png');
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		// buttons
		var savebutton = new FlxUIButton(FlxG.width - 150,25,"save",save);
		savebutton.resize(100,50);
		savebutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		
		var defbutton = new FlxUIButton(FlxG.width - 325,25,"default"/*,defaultcontrol*/);
		defbutton.resize(125,50);
		defbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		defbutton.alpha = 0;

		exitbutton = new FlxUIButton(FlxG.width - 650,25,"exit");
		exitbutton.resize(125,50);
		exitbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");

		add(exitbutton);
		add(defbutton);
		add(savebutton);


		// load curSelected
		if (_saveconrtol.data.buttonsmode == null){
			curSelected = 0;
		}else{
			curSelected = _saveconrtol.data.buttonsmode[0];
		}
		

		//pad
		_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
		_pad.alpha = 0;
		this.add(_pad);


		//text inputvari
		inputvari = new FlxText(125, 50, 0,controlitems[0], 48);
		add(inputvari);
		
		//arrows
		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		leftArrow = new FlxSprite(inputvari.x - 60,inputvari.y - 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		add(leftArrow);

		rightArrow = new FlxSprite(inputvari.x + inputvari.width + 10, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		add(rightArrow);

		changeSelection();

		//text
		up_text = new FlxText(200, 200, 0,"Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y, 24);
		down_text = new FlxText(200, 250, 0,"Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y, 24);
		left_text = new FlxText(200, 300, 0,"Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y, 24);
		right_text = new FlxText(200, 350, 0,"Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y, 24);
		
		
		add(up_text);
		add(down_text);
		add(left_text);
		add(right_text);


		
		//var curcontrol  = ParseConfig.getControl();
		/*
		var noticetext = new FlxText(125, 500, 0,"custom control is not working", 48);
		add(noticetext);
		*/
			
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

		
		if (exitbutton.justReleased || FlxG.android.justReleased.BACK == true){
			FlxG.switchState(new OptionsMenu());
		}
		
		for (touch in FlxG.touches.list){
			//left arrow animation
			arrowanimate(touch);
			
			//change Selection
			if(touch.overlaps(leftArrow) && touch.justPressed){
				changeSelection(-1);
			}else if (touch.overlaps(rightArrow) && touch.justPressed){
				changeSelection(1);
			}

			//custom pad 
			trackbutton(touch);
		}
	}

	function changeSelection(change:Int = 0,?forceChange:Int)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = controlitems.length - 1;
		if (curSelected >= controlitems.length)
			curSelected = 0;
		trace(curSelected);

		if (forceChange != null)
		{
			curSelected = forceChange;
		}

		inputvari.text = controlitems[curSelected];

		switch curSelected{
			case 0:
				this.remove(_pad);
				_pad = null;
				_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
				_pad.alpha = 0.75;
				this.add(_pad);
			case 1:
				this.remove(_pad);
				_pad = null;
				_pad = new FlxVirtualPad(FULL, NONE);
				_pad.alpha = 0.75;
				this.add(_pad);
			case 2:
				trace(2);
				_pad.alpha = 0;
			case 3:
				trace(3);
				_pad.alpha = 0.75;
				loadcustom();
		}

	}

	function arrowanimate(touch:flixel.input.touch.FlxTouch){
		if(touch.overlaps(leftArrow) && touch.pressed){
			leftArrow.animation.play('press');
		}
		
		if(touch.overlaps(leftArrow) && touch.released){
			leftArrow.animation.play('idle');
		}
		//right arrow animation
		if(touch.overlaps(rightArrow) && touch.pressed){
			rightArrow.animation.play('press');
		}
		
		if(touch.overlaps(rightArrow) && touch.released){
			rightArrow.animation.play('idle');
		}
	}

	function trackbutton(touch:flixel.input.touch.FlxTouch){
		//custom pad
		if(_pad.buttonUp.pressed)
		{
			//trace("buttonUp.pressed");
			up_text.text = "Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y;
			_pad.buttonUp.x = touch.x - _pad.buttonUp.width / 2;
			_pad.buttonUp.y = touch.y - _pad.buttonUp.height / 2;
		}else if(_pad.buttonDown.pressed)
		{
			//trace("buttonDown.pressed");
			down_text.text = "Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y;
			_pad.buttonDown.x = touch.x - _pad.buttonDown.width / 2;
			_pad.buttonDown.y = touch.y - _pad.buttonDown.height / 2;
		}else if(_pad.buttonRight.pressed)
		{
			//trace("buttonRight.pressed");
			_pad.buttonRight.x = touch.x - _pad.buttonRight.width / 2;
			_pad.buttonRight.y = touch.y - _pad.buttonRight.height / 2;
		}else if(_pad.buttonLeft.pressed)
		{
			//trace("buttonLeft.pressed");
			_pad.buttonLeft.x = touch.x - _pad.buttonLeft.width / 2;
			_pad.buttonLeft.y = touch.y -
			_pad.buttonLeft.height / 2;
		}
			left_text.text = "Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y;
			right_text.text = "Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y;

		if (_pad.buttonUp.justPressed || _pad.buttonDown.justPressed || _pad.buttonRight.justPressed || _pad.buttonLeft.justPressed){
			if (curSelected != 3){
				changeSelection(0,3);
			}
		}
	}

	function save() {

		if (_saveconrtol.data.buttonsmode == null)
		{
			_saveconrtol.data.buttonsmode = new Array();

			_saveconrtol.data.buttonsmode.push(curSelected);
		}else
		{
			_saveconrtol.data.buttonsmode[0] = curSelected;
		}


		_saveconrtol.flush();
		
		if (curSelected == 3){
			savecustom();
		}
	}

	function savecustom() {
		trace("saved");

		//Config.setdata(55);

		if (_saveconrtol.data.buttons == null)
		{
			_saveconrtol.data.buttons = new Array();

			for (buttons in _pad)
			{
				_saveconrtol.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
			}
		}else
		{
			var tempCount:Int = 0;
			for (buttons in _pad)
			{
				//_saveconrtol.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));

				_saveconrtol.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}
		
		_saveconrtol.flush();
	}

	function loadcustom():Void{
		//load pad
		if (_saveconrtol.data.buttons != null)
		{
			var tempCount:Int = 0;

			for(buttons in _pad)
			{
				buttons.x = _saveconrtol.data.buttons[tempCount].x;
				buttons.y = _saveconrtol.data.buttons[tempCount].y;
				tempCount++;
			}
		}	
	
	}

	override function destroy()
	{

		super.destroy();
	}

}
