package;

import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalKeyboard;
import flixel.FlxBasic;
import Controls.Control;
import flixel.input.actions.FlxActionInput.FlxInputDevice;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;
import ui.Hitbox;
import ui.Mobilecontrols;
import ui.FlxVirtualPad;
import flixel.addons.ui.FlxUISubState;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
import haxe.ds.Vector;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import haxe.Json;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUI;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import flixel.input.FlxPointer;
import flixel.input.mouse.FlxMouse;
import flixel.util.typeLimit.OneOfTwo;
import flixel.input.touch.FlxTouch;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIButton;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

class ControlEditorState extends FlxState
{

	static var dPadList:Array<String> = ['buttonLeft', 'buttonUp', 'buttonRight', 'buttonDown'];
	static var actionsList:Array<String> = ['buttonA', 'buttonB'];

	var controlItems:Array<String> = ['hitbox', 'right control', 'left control', 'custom', 'keyboard'];
	var curSelected:Int;
	var virtualpad:FlxVirtualPad;
	var hitbox:Hitbox;
	var variantChoicer:CoolVariantChoicer;
	var deletebar:FlxSprite;
	
	var saveItem:String = 'VPAD_RIGHT';

	var curKeySelected:Int = 0;
	var keyboardSettings:KeyboardButtonBinder;

	override function create() 
	{
		#if !mobile
		FlxG.save.data.lastmousevisible = FlxG.mouse.visible;
		FlxG.mouse.visible = true;
		#end
		curSelected = 3;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic('assets/images/menuBG.png');
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		hitbox = new Hitbox();
		hitbox.visible = false;
		add(hitbox);

		virtualpad = new FlxVirtualPad(FULL, A_B);
		virtualpad.visible = false;
		add(virtualpad);

		variantChoicer = new CoolVariantChoicer(100, 35, findbigger());
		variantChoicer.text = controlItems[curSelected];
		variantChoicer.onClick = changeSelection;
		add(variantChoicer);

		var exitbutton = new FlxUIButton(FlxG.width - 650,25,"exit", exit);
		exitbutton.resize(125, 50);
		exitbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(exitbutton);

		var exitSavebutton = new FlxUIButton((exitbutton.x + exitbutton.width + 25),25,"exit and save",() -> 
		{
			save();
			// config.setcontrolmode(curSelected);
			exit();
		});
		exitSavebutton.resize(250,50);
		exitSavebutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(exitSavebutton);

		var optionsbutton = new FlxUIButton(exitSavebutton.x + exitSavebutton.width + 50, 25, "options");
		optionsbutton.resize(125,50);
		optionsbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(optionsbutton);

		deletebar = new FlxSprite().loadGraphic('assets/android/delbar.png');
		deletebar.y = FlxG.height - 77;
		deletebar.alpha = 0;
		add(deletebar);

		keyboardSettings = new KeyboardButtonBinder();
		keyboardSettings.visible = false;
		keyboardSettings.active = false;
		add(keyboardSettings);

		changeSelection();

		// FlxG.save.data.padPositions = null;
		// saveCustomPosition();
		// loadCustomPosition(virtualpad);

		super.create();
	}

	public function save() {
		switch (curSelected)
		{
			case ControlsGroup.VIRTUALPAD_CUSTOM:
				saveCustomPosition();
			case ControlsGroup.KEYBOARD:
				keyboardSettings.saveBind();
		}
		Config.controlMode = curSelected;
	}

	override function update(elapsed:Float) 
	{
		#if android
		var androidback:Bool = FlxG.android.justReleased.BACK;
		#else
		var androidback:Bool = false;
		#end
		if (/*exitbutton.justReleased ||*/ androidback){
			FlxG.switchState(new OptionsMenu());
		}

		if (FlxG.keys.justReleased.RIGHT)
		{
			changeSelection(1);
		}

		if (FlxG.keys.justReleased.LEFT)
		{
			changeSelection(-1);
		}
		// broken
		// if (deletebar.overlaps(virtualpad))
		// 	deletebar.alpha = 1; // FlxMath.lerp(deletebar.alpha, 1, 0.5 * elapsed)
		// else
		// 	deletebar.alpha = 0; // FlxMath.lerp(deletebar.alpha, 0, 0.5 * elapsed)

		// if (curSelected == 4)
		// {

		// }

		if (curSelected == 3)
		{
			// virtualpad.forEachAlive(cast trackButton);
			virtualpad.forEach(cast trackButton);
		}

		// sry
		if (FlxG.mouse.justPressed && curSelected == 3){
			fpos[0] = FlxG.mouse.x;
			fpos[1] = FlxG.mouse.y;

			new FlxTimer().start(0.25, _ -> {
				if (FlxG.mouse.pressed && 
				Math.abs(FlxG.mouse.x - fpos[0]) < 50 && 
				Math.abs(FlxG.mouse.x - fpos[0]) < 50)
				{
					if (FlxG.mouse.overlaps(virtualpad)){
						virtualpad.forEachAlive(b -> {
							if (FlxG.mouse.overlaps(b))
								showButtonOption(cast b);
						});
					}
				}
			});
		}

		super.update(elapsed);
	}

	function showButtonOption(button:FlxButton) {
		var optState = new ButtonOptionSubState();
		optState.button = button;
		this.openSubState(optState);
	}

	var fpos:Vector<Int> = new Vector(2);
	function saveCustomPosition() 
	{
		var saveData:Array<SaveData> = [];

		for (button in virtualpad.members)
		{
			saveData.push({
				name: findButtonName(button),
				control: 'note_' + button.frame.name,
				position: { 
					x: button.x, y: 
					button.y, 
					width: button.frames.getByIndex(0).frame.width, 
					height: button.frames.getByIndex(0).frame.height 
				},
				alpha: button.alpha,
				scale: button.scale.x
			});
		}

		FlxG.save.data.padPositions = saveData;
		FlxG.save.flush();
	}

	// for test
	public static function loadCustomPosition(virtualpad:FlxVirtualPad) 
	{
		if (FlxG.save.data.padPositions == null)
			return virtualpad;

		var data:Array<SaveData> = FlxG.save.data.padPositions;
		trace(data);

		for (button in virtualpad.members)
			destroyAndRemove(virtualpad, button);

		for (button in data)
		{
			var graphicName = button.name.replace('button', '').toLowerCase();

			var btn = virtualpad.createButton(button.position.x, button.position.y, button.position.width, button.position.height, graphicName);

			if (button.scale != 1)
			{
				btn.scale.x = btn.scale.y = button.scale;
				btn.updateHitbox();
			}

			btn.alpha = button.alpha;

			if (Reflect.hasField(virtualpad, button.name) && Reflect.field(virtualpad, button.name) == null)
				Reflect.setField(virtualpad, button.name, btn);

			if (dPadList.contains(button.name))
				virtualpad.dPad.add(btn);
			else
				virtualpad.actions.add(btn);

			virtualpad.add(btn);
		}

		return virtualpad;
	}

	static function destroyAndRemove(virtualpad:FlxVirtualPad, button:FlxSprite) {
		virtualpad.remove(button);
		virtualpad.dPad.remove(button);
		virtualpad.actions.remove(button);
		button.destroy();
	}

	function findButtonName(button:FlxSprite) {
		var fs = Reflect.fields(virtualpad);

		for (field in fs)
		{
			var fbutton = Reflect.field(virtualpad, field);
			if (fbutton == button && Std.isOfType(fbutton, FlxButton)) //  && field.indexOf("button") != -1
				return field;
		}
		
		trace(button.frame);
		trace(button.animation.name);
		if (button.frame.name != null)
			return 'button' + button.frame.name.charAt(0).toUpperCase() + button.frame.name.substr(1, button.frame.name.length);

		return 'unknown' + FlxG.random.int(0, 100);
	}
	
	function delbarCheck(button:FlxButton) {
		if (button.y > FlxG.height - button.width / 2)
		{
			button.color = FlxColor.RED;
			deletebar.alpha = FlxMath.lerp(deletebar.alpha, 1, 0.9 * FlxG.elapsed * 3);
		}
		else
		{
			button.color = 0xffffff;
			deletebar.alpha = FlxMath.lerp(deletebar.alpha, 0, 0.9 * FlxG.elapsed * 3);

		}
	}

	function trackButton(button:FlxButton) 
	{
		delbarCheck(button);

		#if !desktop
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased)
			{
				// if (button.overlaps(deletebar))
				// 	destroyAndRemove(virtualpad, bindButtonsMap.get(touch.touchPointID).button);

				if (bindButtonsMap.exists(touch.touchPointID)){
					var btn = bindButtonsMap.get(touch.touchPointID).button;
					if (btn.y > FlxG.height - btn.width / 2)
						destroyAndRemove(virtualpad, btn);
				}

				bindButtonsMap.remove(touch.touchPointID);
			}

			if (button.exists && touch.overlaps(button) && touch.justPressed)
				bindButtonsMap.set(touch.touchPointID, {
					button: button, 
					offset: FlxPoint.get(touch.justPressedPosition.x - button.x, touch.justPressedPosition.y - button.y)
				});

			if (bindButtonsMap.exists(touch.touchPointID))
				moveButton(touch, bindButtonsMap.get(touch.touchPointID));
		}
		#else
		if (FlxG.mouse.pressed && button.pressed) // for debug
		{
			var p = FlxPoint.get(button.width / 2, button.height / 2);
			moveButton(FlxG.mouse, {button: button, offset: p});
			p = FlxDestroyUtil.put(p);
		}else{
			var btn = button;
				if (btn.y > FlxG.height - btn.width / 2)
					destroyAndRemove(virtualpad, btn);
		}
		#end
	}

	inline function moveButton(touch:FlxPointer, data:{ button:FlxButton, offset:FlxPoint }) 
	{
		data.button.x = touch.x - data.offset.x;
		data.button.y = touch.y - data.offset.y;
	}
	

	var bindButtonsMap:Map<Int, { button:FlxButton, offset:FlxPoint }> = new Map();

	function changeSelection(change:Int = 0, ?forceChange:Int)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = controlItems.length - 1;
		if (curSelected >= controlItems.length)
			curSelected = 0;
		trace('current control mode is: $curSelected');
	
		if (forceChange != null)
			curSelected = forceChange;
	
		variantChoicer.text = controlItems[curSelected];

		// what is that
		// if (forceChange != null)
		// {
		// 	if (curSelected == 2)
		// 	{
		// 		_pad.visible = true;
		// 	}
		// 	return;
		// }

		changeControl(curSelected);
	}

	inline function changeControl(mode:ui.Mobilecontrols.ControlsGroup) 
	{		
		switch(mode)
		{
			case 'HITBOX':
				hitbox.visible = true;
				virtualpad.visible = false;
				keyboardSettings.visible = false;
				keyboardSettings.active = false;
			
			case VIRTUALPAD_RIGHT:
				hitbox.visible = false;
				virtualpad.destroy();
				add(virtualpad = new FlxVirtualPad(RIGHT_FULL, NONE));
				keyboardSettings.visible = false;
				keyboardSettings.active = false;
				// virtualpad.visible = true;
				saveItem == 'VPAD_RIGHT';
			case 'VPAD_LEFT':
				hitbox.visible = false;
				virtualpad.destroy();
				add(virtualpad = new FlxVirtualPad(FULL, NONE));
				keyboardSettings.visible = false;
				keyboardSettings.active = false;
				// virtualpad.visible = true;
				saveItem == 'VPAD_LEFT';
			case 'VPAD_CUSTOM':
				hitbox.visible = false;
				virtualpad.destroy();
				add(virtualpad = new FlxVirtualPad(FULL, NONE));
				loadCustomPosition(virtualpad);
				keyboardSettings.visible = false;
				keyboardSettings.active = false;
				// saveCustomPosition();
				// virtualpad.visible = true;
				// loadshit()
				saveItem == 'VPAD_CUSTOM';
			case 'KEYBOARD':
				hitbox.visible = false;
				virtualpad.visible = false;
				keyboardSettings.visible = true;
				keyboardSettings.active = true;
		}
	}

	inline function findbigger() 
	{
		var mostbig = "";
		for (s in controlItems)
			if (s.length > mostbig.length)
				mostbig = s;
		return mostbig;
	}

	function exit() 
	{
		FlxG.mouse.visible = FlxG.save.data.lastmousevisible;
		FlxG.save.data.lastmousevisible = null;
		FlxG.switchState(new OptionsMenu());
	}
}

class CoolVariantChoicer extends FlxSpriteGroup
{
	var leftArrow:FlxButton;
	var txt:FlxText;
	var rightArrow:FlxButton;

	public var text(default, set):String;

	public function new(?x, ?y, text) {
		super(x, y);
		// var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var ui_tex = FlxAtlasFrames.fromSparrow('assets/images/campaign_menu_UI_assets.png',
			'assets/images/campaign_menu_UI_assets.xml');

		txt = new FlxText(0, 0, 0, text, 48);
		txt.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK, 1);

		leftArrow = new FlxButton(txt.x - 60, txt.y - 10, "", () -> onClick(-1));
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix("normal", "arrow left");
		leftArrow.animation.addByPrefix("highlight", "arrow left");
		leftArrow.animation.addByPrefix("pressed", "arrow push left");

		rightArrow = new FlxButton(txt.x + txt.width + 10, leftArrow.y, "", () -> onClick(1));
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix("normal", 'arrow right');
		rightArrow.animation.addByPrefix("highlight", 'arrow right');
		rightArrow.animation.addByPrefix("pressed", "arrow push right", 24, false);

		add(txt);
		add(leftArrow);
		add(rightArrow);
	}

	// why not
	public dynamic function onClick(num:Int, ?_) {
		
	} 

	function set_text(value:String):String {
		txt.text = value; // so sorry
		txt.x = ((rightArrow.x - (leftArrow.x + leftArrow.width)) / 2) - (txt.width / 2) - leftArrow.x + leftArrow.width + (x - 100);
		return value;
	}
}

@:access(Controls)
class KeyboardButtonBinder extends FlxTypedSpriteGroup<FlxText> {

	public var bindedKeys:Array<FlxKey> = new Array();

	var curKeySelected(default, null):Int;

	var selected:Bool = false;

	var lastbutton:FlxKey = NONE;

	public function new() {
		super(5);

		FlxG.save.data.keys = null;

		if (FlxG.save.data.keys != null)
			bindedKeys = FlxG.save.data.keys;
		else
			bindedKeys = getKeysFromControls();
		


		var ktextX = 0; // 500
		var ktextY = 0;
		var leftText = new FlxText(ktextX, 0 + ktextY, 0, ">Left arrow: " + bindedKeys[0], 48);
		add(leftText);
		var downText = new FlxText(ktextX, 50 + ktextY, 0, " Down arrow: " + bindedKeys[1], 48);
		add(downText);
		var upText = new FlxText(ktextX, 100 + ktextY, 0, " Up arrow: " + bindedKeys[2], 48);
		add(upText);
		var rightText = new FlxText(ktextX, 150 + ktextY, 0, " Right arrow: " + bindedKeys[3], 48);
		add(rightText);

		screenCenter();

		var infoText = new FlxText(-200, 400, 0, "press up or down to select and press enter to change", 24);
		add(infoText);
	}
	function getKeysFromControls():Array<Int> {
		var controls = PlayerSettings.player1.controls;

		var keys = new Array<Int>(); 

		for (input in controls._left.inputs)
			if (input.device == KEYBOARD)
			{
				keys[0] = (cast(input, FlxActionInputDigitalKeyboard)).inputID;
				break;
			}

		for (input in controls._down.inputs)
			if (input.device == KEYBOARD)
			{
				keys[1] = (cast(input, FlxActionInputDigitalKeyboard)).inputID;
				break;
			}

		for (input in controls._up.inputs)
			if (input.device == KEYBOARD)
			{
				keys[2] = (cast(input, FlxActionInputDigitalKeyboard)).inputID;
				break;
			}
		
		for (input in controls._right.inputs)
			if (input.device == KEYBOARD)
			{
				keys[3] = (cast(input, FlxActionInputDigitalKeyboard)).inputID;
				break;
			}

		trace(keys);
		return keys;
	}


	public function saveBind() {
		var toSave = bindedKeys.copy();
		// for (i in 0...toSave.length) {
		// 	if (toSave[i] == 0)
		// 		toSave[i] = FlxKey.NONE; 
		// }
		FlxG.save.data.keys = toSave;
		trace(toSave);
		FlxG.save.flush();
		trace(toSave.map(f -> f.toString()).join(':'));
		// Config.initControls();
		// applyCustomBind();
	}

	
	// public static function applyCustomBind() {
		// var controls = PlayerSettings.player1.controls;
		// var newKeys:Vector<FlxKey> = FlxG.save.data.keys;

		// if (newKeys == null)
		// 	return;

		// // removeAllKeys(controls._up);
		// // removeAllKeys(controls._down);
		// // removeAllKeys(controls._left);
		// // removeAllKeys(controls._right);

		// trace(newKeys);
		// controls.replaceBinding(Control.LEFT, Keys, newKeys[0]);
		// controls.replaceBinding(Control.DOWN, Keys, newKeys[1]);
		// controls.replaceBinding(Control.UP, Keys, newKeys[2]);
		// controls.replaceBinding(Control.RIGHT, Keys, newKeys[3]);

	// }

	// static function removeAllKeys(action:FlxActionDigital) {
	// 	for (input in action.inputs)
	// 	{
	// 		if (input.device == FlxInputDevice.KEYBOARD)
	// 			action.inputs.remove(input);
	// 	}
	// }

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.DOWN && !selected)
			{
				var lastl = curKeySelected;
				curKeySelected++;
				if (curKeySelected < 0)
					curKeySelected = 4 - 1;
				if (curKeySelected >= 4)
					curKeySelected = 0;

				
				var lastText = members[lastl];
				lastText.text = " " + lastText.text.substr(1, lastText.text.length);
				
				var curText = members[curKeySelected];
				curText.text = ">" + curText.text.substr(1, curText.text.length);
			}

			if (FlxG.keys.justPressed.UP && !selected)
			{
				var lastl = curKeySelected;
				curKeySelected--;
				if (curKeySelected < 0)
					curKeySelected = 4 - 1;
				if (curKeySelected >= 4)
					curKeySelected = 0;

				var lastText = members[lastl];
				lastText.text = " " + lastText.text.substr(1, lastText.text.length);

				var curText = members[curKeySelected];
				curText.text = ">" + curText.text.substr(1, curText.text.length);
			}
			
			if (selected)
			{
				if (FlxG.keys.getIsDown().length != 0 && selected)
					if (FlxG.keys.getIsDown()[0].ID != FlxKey.ENTER)
						lastbutton = FlxG.keys.getIsDown()[0].ID;
				trace(lastbutton);

				if (FlxG.keys.justPressed.ENTER)
				{
					var curText = members[curKeySelected];
					curText.color = FlxColor.WHITE;
					selected = false;

					if (lastbutton != FlxKey.NONE)
					{
						bindedKeys[curKeySelected] = lastbutton;
						lastbutton = NONE;
					}
				}

				if (FlxG.keys.pressed.ANY && !FlxG.keys.pressed.ENTER)
				{
					var text = members[curKeySelected].text;
					var base = text.substring(0, text.indexOf(':') + 1);
					members[curKeySelected].text = base + " " + lastbutton.toString();
				}
			}else
			{
				if (FlxG.keys.justPressed.ENTER)
				{
					var curText = members[curKeySelected];
					curText.color = FlxColor.YELLOW;

					selected = true;
				}
			}
		
		super.update(elapsed);
	}
}


class ButtonOptionSubState extends FlxUISubState
{
	var buttonName:FlxText;
	var scaleSlider:FlxUISlider;
	var scale(default, set):Float;
	var alphaButton(default, set):Float;
	var bg:FlxSprite;
	var alphaSlider:FlxUISlider;
	public var button(default, set):FlxButton;
	
	public function new() 
	{
		super();
		bg = new FlxSprite().makeGraphic(150, 100, FlxColor.BLACK);
		bg.alpha = 0.75;
		add(bg);
		buttonName = new FlxText(5, 0, 0, 'button name');
		buttonName.size = 16;
		add(buttonName);
		scaleSlider = new FlxUISlider(this, 'scale', 5, 10, 0.5, 3);
		add(scaleSlider);
		alphaSlider = new FlxUISlider(this, 'alphaButton', 5, 20, 0.1, 1);
		add(alphaSlider);
	}

	override function update(elapsed:Float) {
		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(bg))
			close();
		super.update(elapsed);
	}

	function setSliderScale(slider:FlxUISlider, scale:Float = 1.5) 
	{
		for (obj in [slider.body, slider.handle, slider.minLabel, slider.maxLabel, slider.nameLabel, slider.valueLabel])
		{
			obj.scale.x = obj.scale.y = scale;
			obj.updateHitbox();
		}	
		slider.handle.setPosition(slider.handle.x * scale, slider.handle.y);
	}

	function set_button(value:FlxButton):FlxButton 
	{
		button = value;
		scale = value.scale.x;
		bg.setPosition(value.x, value.y);
		buttonName.setPosition(value.x + 5, value.y);
		scaleSlider.setPosition(value.x + 5, value.y + 20);
		// setSliderScale(scaleSlider);
		alphaSlider.setPosition(value.x + 5, value.y + 60);
		// setSliderScale(alphaSlider);
		return value;
	}

	function set_scale(value:Float):Float {
		scale = button.scale.x = button.scale.y = value;
		button.updateHitbox();
		return value;
	}

	function set_alphaButton(value:Float):Float {
		return alphaButton = button.alpha = value;
	}
}

// class ButtonOptions extends FlxTypedGroup<FlxObject> {
// 	var buttonName:FlxText;
// 	var scaleSlider:FlxUISlider;
// 	var scale:Float;
	
// 	public function new() 
// 	{
// 		super();
// 		var bg = new FlxSprite().makeGraphic(100, 50, FlxColor.GRAY);
// 		add(bg);
// 		buttonName = new FlxText(5, 0, 0, 'button name');
// 		add(buttonName);
// 		scaleSlider = new FlxUISlider(this, 'scale', 5, 10, 0.5, 3);
// 		add(scaleSlider);
// 	}
// }

typedef SaveData = {
	var name:String; // graphicName
	var control:String; // like Control.UP
	var position:{ x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic }; // w and h graphic
	var alpha:Float;
	var scale:Float;
}

		// var fields = Reflect.fields(virtualpad);

		// for (button in data)
		// {
		// 	if (fields.contains(button.name)) // oh no
		// 	{
		// 		if (Reflect.field(virtualpad, button.name) != null)
		// 			destroyAndRemove(Reflect.field(virtualpad, button.name)); // todo(maybe): destory and remove for all buttons, not only default

		// 		var graphicName = button.name.replace('button', '').toLowerCase();

		// 		var btn = virtualpad.createButton(button.position.x, button.position.y, button.position.width, button.position.height, graphicName);
		// 		Reflect.setField(virtualpad, button.name, btn);

		// 		if (graphicName.length == 1)
		// 			virtualpad.actions.add(btn);
		// 		else
		// 			virtualpad.dPad.add(btn);

		// 		virtualpad.add(btn);
		// 	}
		// 	else 
		// 	{
		// 		var graphicName = button.name.replace('button', '').toLowerCase();
		// 		var btn = virtualpad.createButton(button.position.x, button.position.y, button.position.width, button.position.height, graphicName);

		// 		if (graphicName.length == 1)
		// 			virtualpad.actions.add(btn);
		// 		else
		// 			virtualpad.dPad.add(btn);

		// 		virtualpad.add(btn);
		// 	}
		// 	trace(button.name);
		// }
		// trace(virtualpad.members);


