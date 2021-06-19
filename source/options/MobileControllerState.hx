package options;

import extension.admob.AdMob;

import lime.utils.Assets;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
//import io.newgrounds.NG;
import lime.app.Application;
import ui.FlxVirtualPad;
import flixel.input.mouse.FlxMouseEventManager;
import ui.FlxVirtualPad;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;
import haxe.Json;
import ui.Hitbox;
#if lime
import lime.system.Clipboard;
#end

using StringTools;

class MobileControllerState extends MusicBeatState
{

	var _pad:FlxVirtualPad;
	var _hb:Hitbox;

	var _saveconrtol:FlxSave;

	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<Alphabet>;
	
	var optionShit:Array<String> = ['Pad Right', 'Pad Left', 'Pad Full', 'Hitbox', 'Auto Play', 'Downscroll'];


	var magenta:FlxSprite;
	var camFollow:FlxObject;



    function selectItem(item:Alphabet){
		if (item.ID == 0)
		{
			this.remove(_pad);
			_pad = null;
			_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
			_pad.alpha = 0.855;
			this.add(_pad);
		}
		else
		{
			remove(_pad);
			_pad.alpha = 0;
			_hb.visible = true;
		}

		save();

    }

	override function create()
        {
            transIn = FlxTransitionableState.defaultTransIn;
            transOut = FlxTransitionableState.defaultTransOut;
            

            _saveconrtol = new FlxSave();
            _saveconrtol.bind("saveconrtol");  

            _pad = new FlxVirtualPad(RIGHT_FULL, NONE);
            _pad.alpha = 0;

            _hb = new Hitbox();
            _hb.visible = false;


            if (!FlxG.sound.music.playing)
            {
                FlxG.sound.playMusic(Paths.music('freakyMenu'));
            }
    
            persistentUpdate = persistentDraw = true;
    
            var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
            bg.scrollFactor.x = 0;
            bg.scrollFactor.y = 0.18;
            bg.setGraphicSize(Std.int(bg.width * 1.1));
            bg.updateHitbox();
            bg.screenCenter();
            bg.antialiasing = true;
            add(bg);
    
            camFollow = new FlxObject(0, 0, 1, 1);
            add(camFollow);
    
            magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
            magenta.scrollFactor.x = 0;
            magenta.scrollFactor.y = 0.18;
            magenta.setGraphicSize(Std.int(magenta.width * 1.1));
            magenta.updateHitbox();
            magenta.screenCenter();
            magenta.visible = false;
            magenta.antialiasing = true;
            magenta.color = 0xFFfd719b;
            add(magenta);
            // magenta.scrollFactor.set();
    



            menuItems = new FlxTypedGroup<Alphabet>();
            add(menuItems);
    
    
            for (i in 0...optionShit.length)
            {
				var label =  optionShit[i];
				if(label == 'Downscroll'){
					label =	FlxG.save.data.downscroll ? "Downscroll" : "Upscroll";
				}
				if (label == 'Auto Play')
				{
					label = (FlxG.save.data.botplay ? "Auto Play ON" : "Auto Play OFF");
				}
				var controlLabel:Alphabet = new Alphabet(0, 15 + (i * 85), label, true, false);
				// controlLabel.isMenuItem = true;
                controlLabel.ID = i;
				controlLabel.targetY = i;
                // var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 165));
                controlLabel.screenCenter(X);
                menuItems.add(controlLabel);
                controlLabel.scrollFactor.set();
                controlLabel.antialiasing = true;


                // FlxMouseEventManager.add(controlLabel, selectItem, null, null, null);
    
            }
    
            FlxG.camera.follow(camFollow, null, 0.06);
    
    
            _pad = new FlxVirtualPad(UP_DOWN, A_B);
			_pad.alpha = 0.855;
            this.add(_pad);

            changeItem(0);
            super.create();
            AdMob.showBanner();
        }
    
        var selectedSomethin:Bool = false;
    
        override function update(elapsed:Float)
        {
            if (FlxG.sound.music.volume < 0.8)
            {
                FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
            }
    
            if (!selectedSomethin)
            {
                var UP_P = _pad.buttonUp.justPressed || controls.UP_P;
                var DOWN_P = _pad.buttonDown.justPressed || controls.DOWN_P;
                var BACK = _pad.buttonB.justPressed || controls.BACK;
                var ACCEPT = _pad.buttonA.justPressed || controls.ACCEPT;
    
                if (UP_P)
                {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    changeItem(-1);
                }
    
                if (DOWN_P)
                {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    changeItem(1);
                }
    
                if (BACK)
                {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					selectedSomethin = true;
					AdMob.showInterstitial();
                    FlxG.switchState(new MainMenuState());
                }

    
                if (ACCEPT)
                {
                    
                        selectedSomethin = true;
                        FlxG.sound.play(Paths.sound('confirmMenu'));
    
                        FlxFlicker.flicker(magenta, 1.1, 0.15, false);
    
                        AdMob.showInterstitial(60);
    
                        menuItems.forEach(function(spr:FlxSprite)
                        {
                            if (curSelected != spr.ID)
                            {
                                FlxTween.tween(spr, {alpha: 0}, 0.4, {
                                    ease: FlxEase.quadOut,
                                    onComplete: function(twn:FlxTween)
                                    {
                                        spr.kill();
                                    }
                                });
                            }
                            else
                            {
                                FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
                                {
                                    var daChoice:String = optionShit[curSelected];
									save();
									FlxG.switchState(new MainMenuState());

                                    // switch (daChoice)
                                    // {
                                    //     case 'Right':
                                    //         this.remove(_pad);
                                    //         _pad = null;
                                    //         _pad = new FlxVirtualPad(FULL, NONE);
									// 		_pad.alpha = 0.855;
                                    //         this.add(_pad);
									// 		save();

                                                    
                                    
                                    //         FlxG.switchState(new MainMenuState());
									// 	//KUDORADOtrace("Story Menu Selected");
                                    //     case 'Hitbox':
									// 	remove(_pad);
									// 	_pad.alpha = 0;
									// 	_hb.visible = true;
									// 	FlxG.switchState(new MainMenuState());
									// 	save();

    
                                    //         //KUDORADOtrace("Freeplay Menu Selected");
    
                            
                                    // }
                                });
                            }
                        });
                    
                }
            }
    
            super.update(elapsed);
    
            // menuItems.forEach(function(spr:FlxSprite)
            // {
            //     spr.screenCenter(X);
            // });
        }
    
        function changeItem(huh:Int = 0)
        {
            curSelected += huh;
    
            if (curSelected >= menuItems.length)
                curSelected = 0;
            if (curSelected < 0)
                curSelected = menuItems.length - 1;
    
            menuItems.forEach(function(spr:FlxSprite)
            {
                // spr.animation.play('idle');
				spr.scale.x = 0.8;
				spr.scale.y = 0.8;
                if (spr.ID == curSelected)
                {
					spr.scale.x = 1.15;
					spr.scale.y = 1.15;
                    // spr.animation.play('selected');
                    camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
                }
    
                spr.updateHitbox();
            });
        }

	// public function new()
	// {
	// 	super();

	// 	//save
		
		
	// 	// bg
	// 	var bg:FlxSprite = new FlxSprite(-80).loadGraphic('assets/images/menuBG.png');
	// 	bg.scrollFactor.x = 0;
	// 	bg.scrollFactor.y = 0.18;
	// 	bg.setGraphicSize(Std.int(bg.width * 1.1));
	// 	bg.updateHitbox();
	// 	bg.screenCenter();
	// 	bg.antialiasing = true;

	// 	// load curSelected
	// 	if (_saveconrtol.data.buttonsmode == null){
	// 		curSelected = 0;
	// 	}else{
	// 		curSelected = _saveconrtol.data.buttonsmode[0];
	// 	}
		

	// 	//pad


	// 	//text inputvari
	// 	inputvari = new FlxText(125, 50, 0,controlitems[0], 48);
		
	// 	//arrows
	// 	var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

	// 	leftArrow = new FlxSprite(inputvari.x - 60,inputvari.y - 10);
	// 	leftArrow.frames = ui_tex;
	// 	leftArrow.animation.addByPrefix('idle', "arrow left");
	// 	leftArrow.animation.addByPrefix('press', "arrow push left");
	// 	leftArrow.animation.play('idle');

	// 	rightArrow = new FlxSprite(inputvari.x + inputvari.width + 10, leftArrow.y);
	// 	rightArrow.frames = ui_tex;
	// 	rightArrow.animation.addByPrefix('idle', 'arrow right');
	// 	rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
	// 	rightArrow.animation.play('idle');


	// 	//text
	// 	up_text = new FlxText(200, 200, 0,"Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y, 24);
	// 	down_text = new FlxText(200, 250, 0,"Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y, 24);
	// 	left_text = new FlxText(200, 300, 0,"Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y, 24);
	// 	right_text = new FlxText(200, 350, 0,"Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y, 24);
		
	// 	//hitboxes

		
	// 	// buttons

	// 	exitbutton = new FlxUIButton(FlxG.width - 650,25,"exit");
	// 	exitbutton.resize(125,50);
	// 	exitbutton.setLabelFormat("vcr.ttf",24,FlxColor.BLACK,"center");

	// 	var savebutton = new FlxUIButton((exitbutton.x + exitbutton.width + 25),25,"exit and save",() -> {
	// 		save();
	// 		FlxG.switchState(new options.OptionsMenu());
	// 	});
	// 	savebutton.resize(250,50);
	// 	savebutton.setLabelFormat("vcr.ttf",24,FlxColor.BLACK,"center");

	// 	exportbutton = new FlxUIButton(FlxG.width - 150, 25, "export", () -> { savetoclipboard(_pad); } );
	// 	exportbutton.resize(125,50);
	// 	exportbutton.setLabelFormat("vcr.ttf", 24, FlxColor.BLACK,"center");

	// 	importbutton = new FlxUIButton(exportbutton.x, 100, "import", () -> { loadfromclipboard(_pad); });
	// 	importbutton.resize(125,50);
	// 	importbutton.setLabelFormat("vcr.ttf", 24, FlxColor.BLACK,"center");

	// 	// add bg
	// 	add(bg);

	// 	// add buttons
	// 	add(exitbutton);
	// 	add(savebutton);
	// 	add(exportbutton);
	// 	add(importbutton);

	// 	// add virtualpad
	// 	this.add(_pad);

	// 	//add hb
	// 	add(_hb);


	// 	// add arrows and text
	// 	add(inputvari);
	// 	add(leftArrow);
	// 	add(rightArrow);

	// 	// add texts
	// 	add(up_text);
	// 	add(down_text);
	// 	add(left_text);
	// 	add(right_text);

	// 	// change selection
	// 	changeSelection();
	// }

	// override function update(elapsed:Float)
	// {
	// 	super.update(elapsed);

	// 	#if android
	// 	var androidback:Bool = FlxG.android.justReleased.BACK;
	// 	#else
	// 	var androidback:Bool = false;
	// 	#end
	// 	if (exitbutton.justReleased || androidback){
	// 		FlxG.switchState(new options.OptionsMenu());
	// 	}
		
	// 	for (touch in FlxG.touches.list){
	// 		//left arrow animation
	// 		arrowanimate(touch);
			
	// 		//change Selection
	// 		if(touch.overlaps(leftArrow) && touch.justPressed){
	// 			changeSelection(-1);
	// 		}else if (touch.overlaps(rightArrow) && touch.justPressed){
	// 			changeSelection(1);
	// 		}

	// 		//custom pad 
	// 		trackbutton(touch);
	// 	}
	// }

	// function changeSelection(change:Int = 0,?forceChange:Int)
	// 	{
	// 		curSelected += change;
	
	// 		if (curSelected < 0)
	// 			curSelected = controlitems.length - 1;
	// 		if (curSelected >= controlitems.length)
	// 			curSelected = 0;
	// 		//KUDORADOtrace(curSelected);
	
	// 		if (forceChange != null)
	// 		{
	// 			curSelected = forceChange;
	// 		}
	
	// 		inputvari.text = controlitems[curSelected];

	// 		if (forceChange != null)
	// 			{
	// 				if (curSelected == 2){
	// 					_pad.visible = true;
	// 				}
					
	// 				return;
	// 			}
			
	// 		_hb.visible = false;
	
	// 		switch curSelected{
	// 			case 0:
	// 				this.remove(_pad);
	// 				_pad = null;
	// 				_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
	// 				_pad.alpha = 0.855;
	// 				this.add(_pad);

    //                 remove(_pad);
	// 				_pad.alpha = 0;
	// 				_hb.visible = true;
	// 			case 1:
	// 				this.remove(_pad);
	// 				_pad = null;
	// 				_pad = new FlxVirtualPad(FULL, NONE);
	// 				_pad.alpha = 0.855;
	// 				this.add(_pad);
	// 			case 2:
	// 				//KUDORADOtrace(2);
	// 				_pad.alpha = 0;
	// 			case 3:
	// 				//KUDORADOtrace(3);
	// 				this.add(_pad);
	// 				_pad.alpha = 0.855;
	// 				loadcustom();
	// 			case 4:
	// 				remove(_pad);
	// 				_pad.alpha = 0;
	// 				_hb.visible = true;

	// 		}
	
	// 	}

	// function arrowanimate(touch:flixel.input.touch.FlxTouch){
	// 	if(touch.overlaps(leftArrow) && touch.pressed){
	// 		leftArrow.animation.play('press');
	// 	}
		
	// 	if(touch.overlaps(leftArrow) && touch.released){
	// 		leftArrow.animation.play('idle');
	// 	}
	// 	//right arrow animation
	// 	if(touch.overlaps(rightArrow) && touch.pressed){
	// 		rightArrow.animation.play('press');
	// 	}
		
	// 	if(touch.overlaps(rightArrow) && touch.released){
	// 		rightArrow.animation.play('idle');
	// 	}
	// }

	// function trackbutton(touch:flixel.input.touch.FlxTouch){
	// 	//custom pad

	// 	if (buttonistouched){
			
	// 		if (bindbutton.justReleased && touch.justReleased)
	// 		{
	// 			bindbutton = null;
	// 			buttonistouched = false;
	// 		}else 
	// 		{
	// 			movebutton(touch, bindbutton);
	// 			setbuttontexts();
	// 		}

	// 	}else {
	// 		if (_pad.buttonUp.justPressed) {
	// 			if (curSelected != 3)
	// 				changeSelection(0,3);

	// 			movebutton(touch, _pad.buttonUp);
	// 		}
			
	// 		if (_pad.buttonDown.justPressed) {
	// 			if (curSelected != 3)
	// 				changeSelection(0,3);

	// 			movebutton(touch, _pad.buttonDown);
	// 		}

	// 		if (_pad.buttonRight.justPressed) {
	// 			if (curSelected != 3)
	// 				changeSelection(0,3);

	// 			movebutton(touch, _pad.buttonRight);
	// 		}

	// 		if (_pad.buttonLeft.justPressed) {
	// 			if (curSelected != 3)
	// 				changeSelection(0,3);

	// 			movebutton(touch, _pad.buttonLeft);
	// 		}
	// 	}
	// }

	// function movebutton(touch:flixel.input.touch.FlxTouch, button:flixel.ui.FlxButton) {
	// 	button.x = touch.x - _pad.buttonUp.width / 2;
	// 	button.y = touch.y - _pad.buttonUp.height / 2;
	// 	bindbutton = button;
	// 	buttonistouched = true;
	// }

	// function setbuttontexts() {
	// 	up_text.text = "Button up x:" + _pad.buttonUp.x +" y:" + _pad.buttonUp.y;
	// 	down_text.text = "Button down x:" + _pad.buttonDown.x +" y:" + _pad.buttonDown.y;
	// 	left_text.text = "Button left x:" + _pad.buttonLeft.x +" y:" + _pad.buttonLeft.y;
	// 	right_text.text = "Button right x:" + _pad.buttonRight.x +" y:" + _pad.buttonRight.y;
	// }



	function save() {
		// curSelected = curSelected == 0 ? 0 : 4;
		if (curSelected == 5)
		{
			FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
			_saveconrtol.flush();

		}
		else if(curSelected == 4){
			FlxG.save.data.botplay = !FlxG.save.data.botplay;
		}
		else{
			if (_saveconrtol.data.buttonsmode == null)
			{
				_saveconrtol.data.buttonsmode = new Array();

				_saveconrtol.data.buttonsmode.push(curSelected);
			}
			else
			{
				_saveconrtol.data.buttonsmode[0] = curSelected;
			}

		_saveconrtol.flush();

		}


		
	}

	// function savecustom() {
	// 	//KUDORADOtrace("saved");

	// 	//Config.setdata(55);

	// 	if (_saveconrtol.data.buttons == null)
	// 	{
	// 		_saveconrtol.data.buttons = new Array();

	// 		for (buttons in _pad)
	// 		{
	// 			_saveconrtol.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
	// 		}
	// 	}else
	// 	{
	// 		var tempCount:Int = 0;
	// 		for (buttons in _pad)
	// 		{
	// 			//_saveconrtol.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));

	// 			_saveconrtol.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
	// 			tempCount++;
	// 		}
	// 	}
		
	// 	_saveconrtol.flush();
	// }

	// function loadcustom():Void{
	// 	//load pad
	// 	if (_saveconrtol.data.buttons != null)
	// 	{
	// 		var tempCount:Int = 0;

	// 		for(buttons in _pad)
	// 		{
	// 			buttons.x = _saveconrtol.data.buttons[tempCount].x;
	// 			buttons.y = _saveconrtol.data.buttons[tempCount].y;
	// 			tempCount++;
	// 		}
	// 	}	
	
	// }

	// function resizebuttons(vpad:FlxVirtualPad, ?int:Int = 200) {
	// 	for (button in vpad)
	// 	{
	// 			button.setGraphicSize(260);
	// 			button.updateHitbox();
	// 	}
	// }

	// function savetoclipboard(pad:FlxVirtualPad) {
	// 	//KUDORADOtrace("saved");
		
	// 	var json = {
	// 		buttonsarray : []
	// 	};

	// 	var tempCount:Int = 0;
	// 	var buttonsarray = new Array();
		
	// 	for (buttons in pad)
	// 	{
	// 		buttonsarray[tempCount] = FlxPoint.get(buttons.x, buttons.y);

	// 		tempCount++;
	// 	}

	// 	json.buttonsarray = buttonsarray;

	// 	//KUDORADOtrace(json);

	// 	var data:String = Json.stringify(json);

	// 	openfl.system.System.setClipboard(data.trim());
	// }

	// function loadfromclipboard(pad:FlxVirtualPad):Void{
	// 	//load pad

	// 	if (curSelected != 3)
	// 		changeSelection(0,3);

	// 	var cbtext:String = Clipboard.text; // this not working on android 10 or higher

	// 	if (!cbtext.endsWith("}")) return;

	// 	var json = Json.parse(cbtext);

	// 	var tempCount:Int = 0;

	// 	for(buttons in pad)
	// 	{
	// 		buttons.x = json.buttonsarray[tempCount].x;
	// 		buttons.y = json.buttonsarray[tempCount].y;
	// 		tempCount++;
	// 	}	
	// 	setbuttontexts();
	// }

	override function destroy()
	{
		super.destroy();
	}
}
