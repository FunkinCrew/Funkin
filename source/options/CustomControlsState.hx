package options;

import flixel.system.FlxAssets.VirtualInputData;
import flixel.ui.FlxButton;
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
import ui.FlxVirtualPad;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;
import haxe.Json;
import ui.Hitbox;
#if lime
import lime.system.Clipboard;
#end

using StringTools;

class CustomControlsState extends MusicBeatSubstate
{

	var _pad:FlxVirtualPad;
	var _hb:Hitbox;

	var _saveconrtol:FlxSave;
	var exitbutton:FlxUIButton;
	var exportbutton:FlxUIButton;
	var importbutton:FlxUIButton;

	var up_text:FlxText;
	var down_text:FlxText;
	var left_text:FlxText;
	var right_text:FlxText;

	var inputvari:FlxText;

	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
							//'hitbox',
	var controlitems:Array<String> = ['right control', 'left control','keyboard','custom', 'hitbox'];

	var curSelected:Int = 0;

	var buttonistouched:Bool = false;

	var bindbutton:flixel.ui.FlxButton;


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

		// load curSelected
		if (_saveconrtol.data.buttonsmode == null){
			curSelected = 0;
		}else{
			curSelected = _saveconrtol.data.buttonsmode[0];
		}
		

		//pad
		_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
		_pad.alpha = 0;
		


		//text inputvari
		inputvari = new FlxText(125, 50, 0,controlitems[0], 48);
		
		//arrows
		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		leftArrow = new FlxSprite(inputvari.x - 60,inputvari.y - 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');

		rightArrow = new FlxSprite(inputvari.x + inputvari.width + 10, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');


		//text
		up_text = new FlxText(200, 200, 0,"Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y, 24);
		down_text = new FlxText(200, 250, 0,"Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y, 24);
		left_text = new FlxText(200, 300, 0,"Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y, 24);
		right_text = new FlxText(200, 350, 0,"Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y, 24);
		
		//hitboxes

		_hb = new Hitbox();
		_hb.visible = false;

		// buttons

		exitbutton = new FlxUIButton(FlxG.width - 650,25,"exit");
		exitbutton.resize(125,50);
		exitbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");

		var savebutton = new FlxUIButton((exitbutton.x + exitbutton.width + 25),25,"exit and save",() -> {
			save();
			FlxG.switchState(new options.OptionsMenu());
		});
		savebutton.resize(250,50);
		savebutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");

		exportbutton = new FlxUIButton(FlxG.width - 150, 25, "export", () -> { savetoclipboard(_pad); } );
		exportbutton.resize(125,50);
		exportbutton.setLabelFormat("VCR OSD Mono", 24, FlxColor.BLACK,"center");

		importbutton = new FlxUIButton(exportbutton.x, 100, "import", () -> { loadfromclipboard(_pad); });
		importbutton.resize(125,50);
		importbutton.setLabelFormat("VCR OSD Mono", 24, FlxColor.BLACK,"center");

		// add bg
		add(bg);

		// add buttons
		add(exitbutton);
		add(savebutton);
		add(exportbutton);
		add(importbutton);

		// add virtualpad
		this.add(_pad);

		//add hb
		add(_hb);


		// add arrows and text
		add(inputvari);
		add(leftArrow);
		add(rightArrow);

		// add texts
		add(up_text);
		add(down_text);
		add(left_text);
		add(right_text);

		// change selection
		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		#if android
		var androidback:Bool = FlxG.android.justReleased.BACK;
		#else
		var androidback:Bool = false;
		#end
		if (exitbutton.justReleased || androidback){
			FlxG.switchState(new options.OptionsMenu());
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

			if (forceChange != null)
				{
					if (curSelected == 2){
						_pad.visible = true;
					}
					
					return;
				}
			
			_hb.visible = false;
	
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
					this.add(_pad);
					_pad.alpha = 0.75;
					loadcustom();
				case 4:
					remove(_pad);
					_pad.alpha = 0;
					_hb.visible = true;

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

		if (buttonistouched){
			
			if (bindbutton.justReleased && touch.justReleased)
			{
				bindbutton = null;
				buttonistouched = false;
			}else 
			{
				movebutton(touch, bindbutton);
				setbuttontexts();
			}

		}else {
			if (_pad.buttonUp.justPressed) {
				if (curSelected != 3)
					changeSelection(0,3);

				movebutton(touch, _pad.buttonUp);
			}
			
			if (_pad.buttonDown.justPressed) {
				if (curSelected != 3)
					changeSelection(0,3);

				movebutton(touch, _pad.buttonDown);
			}

			if (_pad.buttonRight.justPressed) {
				if (curSelected != 3)
					changeSelection(0,3);

				movebutton(touch, _pad.buttonRight);
			}

			if (_pad.buttonLeft.justPressed) {
				if (curSelected != 3)
					changeSelection(0,3);

				movebutton(touch, _pad.buttonLeft);
			}
		}
	}

	function movebutton(touch:flixel.input.touch.FlxTouch, button:flixel.ui.FlxButton) {
		button.x = touch.x - _pad.buttonUp.width / 2;
		button.y = touch.y - _pad.buttonUp.height / 2;
		bindbutton = button;
		buttonistouched = true;
	}

	function setbuttontexts() {
		up_text.text = "Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y;
		down_text.text = "Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y;
		left_text.text = "Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y;
		right_text.text = "Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y;
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

	function resizebuttons(vpad:FlxVirtualPad, ?int:Int = 200) {
		for (button in vpad)
		{
				button.setGraphicSize(260);
				button.updateHitbox();
		}
	}

	function savetoclipboard(pad:FlxVirtualPad) {
		trace("saved");
		
		var json = {
			buttonsarray : []
		};

		var tempCount:Int = 0;
		var buttonsarray = new Array();
		
		for (buttons in pad)
		{
			buttonsarray[tempCount] = FlxPoint.get(buttons.x, buttons.y);

			tempCount++;
		}

		json.buttonsarray = buttonsarray;

		trace(json);

		var data:String = Json.stringify(json);

		openfl.system.System.setClipboard(data.trim());
	}

	function loadfromclipboard(pad:FlxVirtualPad):Void{
		//load pad

		if (curSelected != 3)
			changeSelection(0,3);

		var cbtext:String = Clipboard.text; // this not working on android 10 or higher

		if (!cbtext.endsWith("}")) return;

		var json = Json.parse(cbtext);

		var tempCount:Int = 0;

		for(buttons in pad)
		{
			buttons.x = json.buttonsarray[tempCount].x;
			buttons.y = json.buttonsarray[tempCount].y;
			tempCount++;
		}	
		setbuttontexts();
	}

	override function destroy()
	{
		super.destroy();
	}
}
