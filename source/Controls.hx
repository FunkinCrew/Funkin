package;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Control
{
	// List notes in order from left to right on gameplay screen.
	NOTE_LEFT;
	NOTE_DOWN;
	NOTE_UP;
	NOTE_RIGHT;
	UI_UP;
	UI_LEFT;
	UI_RIGHT;
	UI_DOWN;
	RESET;
	ACCEPT;
	BACK;
	PAUSE;
	#if CAN_CHEAT
	CHEAT;
	#end
}

@:enum
abstract Action(String) to String from String
{
	var UI_UP      = "ui_up";
	var UI_LEFT    = "ui_left";
	var UI_RIGHT   = "ui_right";
	var UI_DOWN    = "ui_down";
	var UI_UP_P    = "ui_up-press";
	var UI_LEFT_P  = "ui_left-press";
	var UI_RIGHT_P = "ui_right-press";
	var UI_DOWN_P  = "ui_down-press";
	var UI_UP_R    = "ui_up-release";
	var UI_LEFT_R  = "ui_left-release";
	var UI_RIGHT_R = "ui_right-release";
	var UI_DOWN_R  = "ui_down-release";
	var NOTE_UP      = "note_up";
	var NOTE_LEFT    = "note_left";
	var NOTE_RIGHT   = "note_right";
	var NOTE_DOWN    = "note_down";
	var NOTE_UP_P    = "note_up-press";
	var NOTE_LEFT_P  = "note_left-press";
	var NOTE_RIGHT_P = "note_right-press";
	var NOTE_DOWN_P  = "note_down-press";
	var NOTE_UP_R    = "note_up-release";
	var NOTE_LEFT_R  = "note_left-release";
	var NOTE_RIGHT_R = "note_right-release";
	var NOTE_DOWN_R  = "note_down-release";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
	#if CAN_CHEAT
	var CHEAT = "cheat";
	#end
}

enum Device
{
	Keys;
	Gamepad(id:Int);
}

enum KeyboardScheme
{
	Solo;
	Duo(first:Bool);
	None;
	Custom;
}

/**
 * A list of actions that a player would invoke via some input device.
 * Uses FlxActions to funnel various inputs to a single action.
 */
class Controls extends FlxActionSet
{
	var _ui_up     = new FlxActionDigital(Action.UI_UP);
	var _ui_left   = new FlxActionDigital(Action.UI_LEFT);
	var _ui_right  = new FlxActionDigital(Action.UI_RIGHT);
	var _ui_down   = new FlxActionDigital(Action.UI_DOWN);
	var _ui_upP    = new FlxActionDigital(Action.UI_UP_P);
	var _ui_leftP  = new FlxActionDigital(Action.UI_LEFT_P);
	var _ui_rightP = new FlxActionDigital(Action.UI_RIGHT_P);
	var _ui_downP  = new FlxActionDigital(Action.UI_DOWN_P);
	var _ui_upR    = new FlxActionDigital(Action.UI_UP_R);
	var _ui_leftR  = new FlxActionDigital(Action.UI_LEFT_R);
	var _ui_rightR = new FlxActionDigital(Action.UI_RIGHT_R);
	var _ui_downR  = new FlxActionDigital(Action.UI_DOWN_R);
	var _note_up     = new FlxActionDigital(Action.NOTE_UP);
	var _note_left   = new FlxActionDigital(Action.NOTE_LEFT);
	var _note_right  = new FlxActionDigital(Action.NOTE_RIGHT);
	var _note_down   = new FlxActionDigital(Action.NOTE_DOWN);
	var _note_upP    = new FlxActionDigital(Action.NOTE_UP_P);
	var _note_leftP  = new FlxActionDigital(Action.NOTE_LEFT_P);
	var _note_rightP = new FlxActionDigital(Action.NOTE_RIGHT_P);
	var _note_downP  = new FlxActionDigital(Action.NOTE_DOWN_P);
	var _note_upR    = new FlxActionDigital(Action.NOTE_UP_R);
	var _note_leftR  = new FlxActionDigital(Action.NOTE_LEFT_R);
	var _note_rightR = new FlxActionDigital(Action.NOTE_RIGHT_R);
	var _note_downR  = new FlxActionDigital(Action.NOTE_DOWN_R);
	var _accept = new FlxActionDigital(Action.ACCEPT);
	var _back = new FlxActionDigital(Action.BACK);
	var _pause = new FlxActionDigital(Action.PAUSE);
	var _reset = new FlxActionDigital(Action.RESET);
	#if CAN_CHEAT
	var _cheat = new FlxActionDigital(Action.CHEAT);
	#end
	
	var byName:Map<String, FlxActionDigital> = new Map<String, FlxActionDigital>();

	public var gamepadsAdded:Array<Int> = [];
	public var keyboardScheme = KeyboardScheme.None;

	public var UI_UP   (get, never):Bool; inline function get_UI_UP   () return _ui_up   .check();
	public var UI_LEFT (get, never):Bool; inline function get_UI_LEFT () return _ui_left .check();
	public var UI_RIGHT(get, never):Bool; inline function get_UI_RIGHT() return _ui_right.check();
	public var UI_DOWN (get, never):Bool; inline function get_UI_DOWN () return _ui_down .check();

	public var UI_UP_P   (get, never):Bool; inline function get_UI_UP_P   () return _ui_upP   .check();
	public var UI_LEFT_P (get, never):Bool; inline function get_UI_LEFT_P () return _ui_leftP .check();
	public var UI_RIGHT_P(get, never):Bool; inline function get_UI_RIGHT_P() return _ui_rightP.check();
	public var UI_DOWN_P (get, never):Bool; inline function get_UI_DOWN_P () return _ui_downP .check();

	public var UI_UP_R   (get, never):Bool; inline function get_UI_UP_R   () return _ui_upR   .check();
	public var UI_LEFT_R (get, never):Bool; inline function get_UI_LEFT_R () return _ui_leftR .check();
	public var UI_RIGHT_R(get, never):Bool; inline function get_UI_RIGHT_R() return _ui_rightR.check();
	public var UI_DOWN_R (get, never):Bool; inline function get_UI_DOWN_R () return _ui_downR .check();
	
	public var NOTE_UP   (get, never):Bool; inline function get_NOTE_UP   () return _note_up   .check();
	public var NOTE_LEFT (get, never):Bool; inline function get_NOTE_LEFT () return _note_left .check();
	public var NOTE_RIGHT(get, never):Bool; inline function get_NOTE_RIGHT() return _note_right.check();
	public var NOTE_DOWN (get, never):Bool; inline function get_NOTE_DOWN () return _note_down .check();

	public var NOTE_UP_P   (get, never):Bool; inline function get_NOTE_UP_P   () return _note_upP   .check();
	public var NOTE_LEFT_P (get, never):Bool; inline function get_NOTE_LEFT_P () return _note_leftP .check();
	public var NOTE_RIGHT_P(get, never):Bool; inline function get_NOTE_RIGHT_P() return _note_rightP.check();
	public var NOTE_DOWN_P (get, never):Bool; inline function get_NOTE_DOWN_P () return _note_downP .check();

	public var NOTE_UP_R   (get, never):Bool; inline function get_NOTE_UP_R   () return _note_upR   .check();
	public var NOTE_LEFT_R (get, never):Bool; inline function get_NOTE_LEFT_R () return _note_leftR .check();
	public var NOTE_RIGHT_R(get, never):Bool; inline function get_NOTE_RIGHT_R() return _note_rightR.check();
	public var NOTE_DOWN_R (get, never):Bool; inline function get_NOTE_DOWN_R () return _note_downR .check();

	public var ACCEPT(get, never):Bool; inline function get_ACCEPT() return _accept.check();
	public var BACK  (get, never):Bool; inline function get_BACK  () return _back  .check();
	public var PAUSE (get, never):Bool; inline function get_PAUSE () return _pause .check();
	public var RESET (get, never):Bool; inline function get_RESET () return _reset .check();
	#if CAN_CHEAT
	public var CHEAT (get, never):Bool; inline function get_CHEAT () return _cheat.check ();
	#end
	
	public function new(name, scheme:KeyboardScheme = null)
	{
		super(name);

		add(_ui_up);
		add(_ui_left);
		add(_ui_right);
		add(_ui_down);
		add(_ui_upP);
		add(_ui_leftP);
		add(_ui_rightP);
		add(_ui_downP);
		add(_ui_upR);
		add(_ui_leftR);
		add(_ui_rightR);
		add(_ui_downR);
		add(_note_up);
		add(_note_left);
		add(_note_right);
		add(_note_down);
		add(_note_upP);
		add(_note_leftP);
		add(_note_rightP);
		add(_note_downP);
		add(_note_upR);
		add(_note_leftR);
		add(_note_rightR);
		add(_note_downR);
		add(_accept);
		add(_back);
		add(_pause);
		add(_reset);
		#if CAN_CHEAT
		add(_cheat);
		#end

		for (action in digitalActions)
			byName[action.name] = action;

		if (scheme == null)
			scheme = None;
		
		setKeyboardScheme(scheme, false);
	}

	override function update()
	{
		super.update();
	}

	// inline
	public function checkByName(name:Action):Bool
	{
		#if debug
		if (!byName.exists(name))
			throw 'Invalid name: $name';
		#end
		return byName[name].check();
	}

	public function getDialogueName(action:FlxActionDigital):String
	{
		var input = action.inputs[0];
		return switch input.device
		{
			case KEYBOARD: return '[${(input.inputID : FlxKey)}]';
			case GAMEPAD: return '(${(input.inputID : FlxGamepadInputID)})';
			case device: throw 'unhandled device: $device';
		}
	}

	public function getDialogueNameFromToken(token:String):String
	{
		return getDialogueName(getActionFromControl(Control.createByName(token.toUpperCase())));
	}

	function getActionFromControl(control:Control):FlxActionDigital
	{
		return switch (control)
		{
			case UI_UP: _ui_up;
			case UI_DOWN: _ui_down;
			case UI_LEFT: _ui_left;
			case UI_RIGHT: _ui_right;
			case NOTE_UP: _note_up;
			case NOTE_DOWN: _note_down;
			case NOTE_LEFT: _note_left;
			case NOTE_RIGHT: _note_right;
			case ACCEPT: _accept;
			case BACK: _back;
			case PAUSE: _pause;
			case RESET: _reset;
			#if CAN_CHEAT
			case CHEAT: _cheat;
			#end
		}
	}

	static function init():Void
	{
		var actions = new FlxActionManager();
		FlxG.inputs.add(actions);
	}

	/**
	 * Calls a function passing each action bound by the specified control
	 * @param control
	 * @param func
	 * @return ->Void)
	 */
	function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void)
	{
		switch (control)
		{
			case UI_UP:
				func(_ui_up, PRESSED);
				func(_ui_upP, JUST_PRESSED);
				func(_ui_upR, JUST_RELEASED);
			case UI_LEFT:
				func(_ui_left, PRESSED);
				func(_ui_leftP, JUST_PRESSED);
				func(_ui_leftR, JUST_RELEASED);
			case UI_RIGHT:
				func(_ui_right, PRESSED);
				func(_ui_rightP, JUST_PRESSED);
				func(_ui_rightR, JUST_RELEASED);
			case UI_DOWN:
				func(_ui_down, PRESSED);
				func(_ui_downP, JUST_PRESSED);
				func(_ui_downR, JUST_RELEASED);
			case NOTE_UP:
				func(_note_up, PRESSED);
				func(_note_upP, JUST_PRESSED);
				func(_note_upR, JUST_RELEASED);
			case NOTE_LEFT:
				func(_note_left, PRESSED);
				func(_note_leftP, JUST_PRESSED);
				func(_note_leftR, JUST_RELEASED);
			case NOTE_RIGHT:
				func(_note_right, PRESSED);
				func(_note_rightP, JUST_PRESSED);
				func(_note_rightR, JUST_RELEASED);
			case NOTE_DOWN:
				func(_note_down, PRESSED);
				func(_note_downP, JUST_PRESSED);
				func(_note_downR, JUST_RELEASED);
			case ACCEPT:
				func(_accept, JUST_PRESSED);
			case BACK:
				func(_back, JUST_PRESSED);
			case PAUSE:
				func(_pause, JUST_PRESSED);
			case RESET:
				func(_reset, JUST_PRESSED);
			#if CAN_CHEAT
			case CHEAT:
				func(_cheat, JUST_PRESSED);
			#end
		}
	}

	public function replaceBinding(control:Control, device:Device, toAdd:Int, toRemove:Int)
	{
		if (toAdd == toRemove)
			return;

		switch (device)
		{
			case Keys:
				forEachBound(control, function(action, _) replaceKey(action, toAdd, toRemove));

			case Gamepad(id):
				forEachBound(control, function(action, _) replaceButton(action, id, toAdd, toRemove));
		}
	}
	
	function replaceKey(action:FlxActionDigital, toAdd:Int, toRemove:Int)
	{
		for (i in 0...action.inputs.length)
		{
			var input = action.inputs[i];
			if (input.device == KEYBOARD && input.inputID == toRemove)
			{
				@:privateAccess
				action.inputs[i].inputID = toAdd;
			}
		}
	}
	
	function replaceButton(action:FlxActionDigital, deviceID:Int, toAdd:Int, toRemove:Int)
	{
		for (i in 0...action.inputs.length)
		{
			var input = action.inputs[i];
			if (isGamepad(input, deviceID) && input.inputID == toRemove)
			{
				@:privateAccess
				action.inputs[i].inputID = toAdd;
			}
		}
	}

	public function copyFrom(controls:Controls, ?device:Device)
	{
		for (name in controls.byName.keys())
		{
			var action = controls.byName[name];
			for (input in action.inputs)
			{
				if (device == null || isDevice(input, device))
				byName[name].add(cast input);
			}
		}

		switch (device)
		{
			case null:
				// add all
				for (gamepad in controls.gamepadsAdded)
					if (gamepadsAdded.indexOf(gamepad) == -1)
					  gamepadsAdded.push(gamepad);

				mergeKeyboardScheme(controls.keyboardScheme);

			case Gamepad(id):
				gamepadsAdded.push(id);
			case Keys:
				mergeKeyboardScheme(controls.keyboardScheme);
		}
	}

	inline public function copyTo(controls:Controls, ?device:Device)
	{
		controls.copyFrom(this, device);
	}

	function mergeKeyboardScheme(scheme:KeyboardScheme):Void
	{
		if (scheme != None)
		{
			switch (keyboardScheme)
			{
				case None:
					keyboardScheme = scheme;
				default:
					keyboardScheme = Custom;
			}
		}
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function bindKeys(control:Control, keys:Array<FlxKey>)
	{
		forEachBound(control, function(action, state) addKeys(action, keys, state));
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function unbindKeys(control:Control, keys:Array<FlxKey>)
	{
		forEachBound(control, function(action, _) removeKeys(action, keys));
	}

	inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
	{
		for (key in keys)
			action.addKey(key, state);
	}

	static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1)
				action.remove(input);
		}
	}

	public function setKeyboardScheme(scheme:KeyboardScheme, reset = true)
	{
		if (reset)
			removeKeyboard();

		keyboardScheme = scheme;
		
		switch (scheme)
		{
			case Solo:
				bindKeys(Control.UI_UP, [W, FlxKey.UP]);
				bindKeys(Control.UI_DOWN, [S, FlxKey.DOWN]);
				bindKeys(Control.UI_LEFT, [A, FlxKey.LEFT]);
				bindKeys(Control.UI_RIGHT, [D, FlxKey.RIGHT]);
				bindKeys(Control.NOTE_UP, [W, FlxKey.UP]);
				bindKeys(Control.NOTE_DOWN, [S, FlxKey.DOWN]);
				bindKeys(Control.NOTE_LEFT, [A, FlxKey.LEFT]);
				bindKeys(Control.NOTE_RIGHT, [D, FlxKey.RIGHT]);
				bindKeys(Control.ACCEPT, [Z, SPACE, ENTER]);
				bindKeys(Control.BACK, [X, BACKSPACE, ESCAPE]);
				bindKeys(Control.PAUSE, [P, ENTER, ESCAPE]);
				bindKeys(Control.RESET, [R]);
			case Duo(true):
				bindKeys(Control.UI_UP, [W]);
				bindKeys(Control.UI_DOWN, [S]);
				bindKeys(Control.UI_LEFT, [A]);
				bindKeys(Control.UI_RIGHT, [D]);
				bindKeys(Control.NOTE_UP, [W]);
				bindKeys(Control.NOTE_DOWN, [S]);
				bindKeys(Control.NOTE_LEFT, [A]);
				bindKeys(Control.NOTE_RIGHT, [D]);
				bindKeys(Control.ACCEPT, [G, Z]);
				bindKeys(Control.BACK, [H, X]);
				bindKeys(Control.PAUSE, [ONE]);
				bindKeys(Control.RESET, [R]);
			case Duo(false):
				bindKeys(Control.UI_UP, [FlxKey.UP]);
				bindKeys(Control.UI_DOWN, [FlxKey.DOWN]);
				bindKeys(Control.UI_LEFT, [FlxKey.LEFT]);
				bindKeys(Control.UI_RIGHT, [FlxKey.RIGHT]);
				bindKeys(Control.NOTE_UP, [FlxKey.UP]);
				bindKeys(Control.NOTE_DOWN, [FlxKey.DOWN]);
				bindKeys(Control.NOTE_LEFT, [FlxKey.LEFT]);
				bindKeys(Control.NOTE_RIGHT, [FlxKey.RIGHT]);
				bindKeys(Control.ACCEPT, [O]);
				bindKeys(Control.BACK, [P]);
				bindKeys(Control.PAUSE, [ENTER]);
				bindKeys(Control.RESET, [BACKSPACE]);
			case None: // nothing
			case Custom: // nothing
		}
	}

	function removeKeyboard()
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var input = action.inputs[i];
				if (input.device == KEYBOARD)
					action.remove(input);
			}
		}
	}

	public function addGamepadWithSaveData(id:Int, ?padData:Dynamic):Void
	{
		gamepadsAdded.push(id);
		
		fromSaveData(padData, Gamepad(id));
	}

	inline function addGamepadLiteral(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
	{
		gamepadsAdded.push(id);

		for (control in buttonMap.keys())
			bindButtons(control, id, buttonMap[control]);
	}

	public function removeGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var input = action.inputs[i];
				if (isGamepad(input, deviceID))
					action.remove(input);
			}
		}

		gamepadsAdded.remove(deviceID);
	}

	public function addDefaultGamepad(id):Void
	{
		addGamepadLiteral(id, [
			
			Control.ACCEPT => [#if switch B #else A #end],
			Control.BACK => [#if switch A #else B #end, FlxGamepadInputID.BACK],
			Control.UI_UP => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
			Control.UI_DOWN => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
			Control.UI_LEFT => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
			Control.UI_RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
			// don't swap A/B or X/Y for switch on these. A is always the bottom face button
			Control.NOTE_UP => [DPAD_UP, Y, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
			Control.NOTE_DOWN => [DPAD_DOWN, A, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN],
			Control.NOTE_LEFT => [DPAD_LEFT, X, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT],
			Control.NOTE_RIGHT => [DPAD_RIGHT, B, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT],
			Control.PAUSE => [START],
			Control.RESET => [Y]
			#if CAN_CHEAT
			,Control.CHEAT => [X]
			#end
		]);
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function bindButtons(control:Control, id, buttons)
	{
		forEachBound(control, function(action, state) addButtons(action, buttons, state, id));
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function unbindButtons(control:Control, gamepadID:Int, buttons)
	{
		forEachBound(control, function(action, _) removeButtons(action, gamepadID, buttons));
	}

	inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state, id)
	{
		for (button in buttons)
			action.addGamepad(button, state, id);
	}

	static function removeButtons(action:FlxActionDigital, gamepadID:Int, buttons:Array<FlxGamepadInputID>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (isGamepad(input, gamepadID) && buttons.indexOf(cast input.inputID) != -1)
				action.remove(input);
		}
	}

	public function getInputsFor(control:Control, device:Device, ?list:Array<Int>):Array<Int>
	{
		if (list == null)
			list = [];

		switch (device)
		{
			case Keys:
				for (input in getActionFromControl(control).inputs)
				{
					if (input.device == KEYBOARD)
						list.push(input.inputID);
				}
			case Gamepad(id):
				for (input in getActionFromControl(control).inputs)
				{
					if (isGamepad(input, id))
						list.push(input.inputID);
				}
		}
		return list;
	}

	public function removeDevice(device:Device)
	{
		switch (device)
		{
			case Keys:
				setKeyboardScheme(None);
			case Gamepad(id):
				removeGamepad(id);
		}
	}

	public function fromSaveData(data:Dynamic, device:Device)
	{
		for (control in Control.createAll())
		{
			var inputs:Array<Int> = Reflect.field(data, control.getName());
			if (inputs != null)
			{
				switch(device)
				{
					case Keys: bindKeys(control, inputs.copy()); 
					case Gamepad(id): bindButtons(control, id, inputs.copy()); 
				}
			}
		}
	}
	
	public function createSaveData(device:Device):Dynamic
	{
		var isEmpty = true;
		var data = {};
		for (control in Control.createAll())
		{
			var inputs = getInputsFor(control, device);
			isEmpty = isEmpty && inputs.length == 0;
			
			Reflect.setField(data, control.getName(), inputs);
		}
		
		return isEmpty ? null : data;
	}

	static function isDevice(input:FlxActionInput, device:Device)
	{
		return switch device
		{
			case Keys: input.device == KEYBOARD;
			case Gamepad(id): isGamepad(input, id);
		}
	}

	inline static function isGamepad(input:FlxActionInput, deviceID:Int)
	{
		return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
	}
}


typedef SaveInputLists = {?keys:Array<Int>, ?pad:Array<Int>};