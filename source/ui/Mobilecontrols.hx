package ui;

// import options.CustomControlsState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalKeyboard;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal;
import flixel.input.IFlxInputManager;
import flixel.util.typeLimit.OneOfTwo;
import flixel.input.actions.FlxActionInput;
import flixel.input.FlxInput.FlxInputState;
import flixel.ui.FlxButton;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalIFlxInput;
import flixel.input.actions.FlxAction.FlxActionDigital;
import Controls.Control;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import ui.FlxVirtualPad;
import ui.Hitbox;

// import Config;

class Mobilecontrols extends FlxSpriteGroup
{
	public var mode:ControlsGroup = 'HITBOX';

	public var _hitbox:Hitbox;
	public var _virtualPad:FlxVirtualPad;
	public var _keyboard:Keyboard;

	var cHandler:ControlHandler;

	public static var isEnabled(get, never):Bool;
	public function new() 
	{
		super();

		switch(FlxG.save.data.mobilecontrols)
		{
			case 'VPAD_RIGHT':
				initVirtualPad(0);
			case VIRTUALPAD_LEFT:
				initVirtualPad(1);
			case VIRTUALPAD_CUSTOM:
				initVirtualPad(2);
			case HITBOX:
				_hitbox = new Hitbox(null, true);
				add(_hitbox);
			case KEYBOARD:
				_keyboard = new Keyboard();
				FlxG.state.add(_keyboard);
		}
	}

	function initVirtualPad(vpadMode:Int) 
	{
		switch (vpadMode)
		{
			case 1:
				_virtualPad = new FlxVirtualPad(FULL, NONE);
			case 2:
				_virtualPad = new FlxVirtualPad(FULL, NONE);
				ControlEditorState.loadCustomPosition(_virtualPad);
				// _virtualPad = config.loadcustom(_virtualPad);
				// _virtualPad = CustomControlsState.loadCustomPosition(_virtualPad); // for test, null in controls.hx
			default: // 0
				_virtualPad = new FlxVirtualPad(RIGHT_FULL, NONE);
		}
		
		_virtualPad.alpha = 0.75;
		add(_virtualPad);	
	}

	// adding pad to state (not substate)
	public static function addVirtualPad(?DPad:FlxDPadMode, ?Action:FlxActionMode) {
		var pad = createVirtualPad(DPad, Action);

		if (pad != null)
			FlxG.state.add(pad);

		return pad;
	}

	public static function createVirtualPad(?DPad:FlxDPadMode, ?Action:FlxActionMode, isNewCamera:Bool = false):Null<FlxVirtualPad> 
	{
		if (!Mobilecontrols.isEnabled)
			return null;
		
		var virtualPad = new FlxVirtualPad(DPad, Action, true);

		if (isNewCamera){
			var camcontrol = new FlxCamera();
			FlxG.cameras.add(camcontrol);
			camcontrol.bgColor.alpha = 0;
			camcontrol.alpha = 0;
			virtualPad.cameras = [camcontrol];
		}

		return virtualPad;
	}

	static function get_isEnabled():Bool {
		return FlxG.onMobile #if true || true #end;
	}
}


// maybe do this in ControlHandler??
@:access(Controls)
class Keyboard extends FlxBasic {
	var keys:Array<FlxKey>;
	var keyInputs:Array<FlxActionInput>;

	public function new() {
		visible = false;
		active = false;
		if (FlxG.save.data.keys == null)
			return;

		var controls = PlayerSettings.player1.controls;
		keys = FlxG.save.data.keys;
		keyInputs = [];

		trace(keys.map(f -> f.toString()).join(':'));

		inline controls.bindKeys(Control.LEFT, [keys[0], FlxKey.UP]);
		inline controls.bindKeys(Control.DOWN, [keys[1], FlxKey.DOWN]);
		inline controls.bindKeys(Control.UP, [keys[2], FlxKey.LEFT]);
		inline controls.bindKeys(Control.RIGHT, [keys[3], FlxKey.RIGHT]);

		inline controls.unbindKeys(Control.UP, [FlxKey.W]);
		inline controls.unbindKeys(Control.DOWN, [FlxKey.S]);
		inline controls.unbindKeys(Control.LEFT, [FlxKey.A]);
		inline controls.unbindKeys(Control.RIGHT, [FlxKey.D]);
		
		super();
	}

	inline function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
	{
		for (key in keys)
		{
			var input = new FlxActionInputDigitalKeyboard(key, state);
			keyInputs.push(input);

			action.add(input);
		}
	}

	override function destroy() {
		var controls = PlayerSettings.player1.controls;
		for (action in controls.digitalActions)
		{
			var i = action.inputs.length;
			
			while (i-- > 0)
			{
				var input = action.inputs[i];

				var x = keyInputs.length;
				while (x-- > 0)
					if (keyInputs[x] == input)
					{
						action.remove(input);
						input.destroy();
					}
			}
		}

		inline controls.bindKeys(Control.UP, [FlxKey.W]);
		inline controls.bindKeys(Control.DOWN, [FlxKey.S]);
		inline controls.bindKeys(Control.LEFT, [FlxKey.A]);
		inline controls.bindKeys(Control.RIGHT, [FlxKey.D]);

		super.destroy();
	}
}

@:access(Controls)
class ControlHandler 
{
	var isPad:Bool = true;
	var trackedinputs:Array<FlxActionInput>;

	public var virtualPad(default, null):FlxVirtualPad;
	public var hitbox(default, null):Hitbox;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public function new(obj:OneOfTwo<FlxVirtualPad, Hitbox>) 
	{
		if (obj is FlxVirtualPad)
		{
			isPad = true;
			virtualPad = obj;
		}
		else if (obj is Hitbox)
		{
			isPad = false;
			hitbox = obj;
		}
		else { trace("unknown control type"); }

		FlxG.signals.preGameReset.add(forceUnBind);
		FlxG.signals.preStateSwitch.add(forceUnBind);
	}

	// bind to controls class
	public function bind() {
		if (trackedinputs != null)
			unBind();

		trackedinputs = [];
		if (isPad)
			setVirtualPad();
		else
			setHitBox();
	}

	public function unBind() {
		if (trackedinputs == null)
			return;

		removeFlxInput(trackedinputs);
		trackedinputs = null;
	}

	function forceUnBind() {
		FlxG.signals.preGameReset.remove(forceUnBind);
		FlxG.signals.preStateSwitch.remove(forceUnBind);
		
		if (trackedinputs != null)
			unBind();
	}

	public function setVirtualPad() {
		var up = Control.UP;
		var down = Control.DOWN;
		var left = Control.LEFT;
		var right = Control.RIGHT;
		var a = Control.ACCEPT;
		var b = Control.BACK;

		for (button in virtualPad.members)
		{
			var name = button.frames.frames[0].name;

			switch (name)
			{
				case 'up':
					inline controls.forEachBound(up, (action, state) -> addbutton(action, cast button, state));
				case 'down':
					inline controls.forEachBound(down, (action, state) -> addbutton(action, cast button, state));
				case 'left':
					inline controls.forEachBound(left, (action, state) -> addbutton(action, cast button, state));
				case 'right':
					inline controls.forEachBound(right, (action, state) -> addbutton(action, cast button, state));

				case 'a':
					inline controls.forEachBound(a, (action, state) -> addbutton(action, cast button, state));
				case 'b':	
					inline controls.forEachBound(b, (action, state) -> addbutton(action, cast button, state));
			}
		}
	}

	public function setHitBox() 
	{
		var up = Control.UP;
		var down = Control.DOWN;
		var left = Control.LEFT;
		var right = Control.RIGHT;

		inline controls.forEachBound(up, (action, state) -> addbutton(action, hitbox.buttonUp, state));
		inline controls.forEachBound(down, (action, state) -> addbutton(action, hitbox.buttonDown, state));
		inline controls.forEachBound(left, (action, state) -> addbutton(action, hitbox.buttonLeft, state));
		inline controls.forEachBound(right, (action, state) -> addbutton(action, hitbox.buttonRight, state));	
	}

	public function addbutton(action:FlxActionDigital, button:FlxButton, state:FlxInputState) {
		var input = new FlxActionInputDigitalIFlxInput(button, state);
		trackedinputs.push(input);
		
		action.add(input);
		//action.addInput(button, state);
	}

	public function removeFlxInput(Tinputs:Array<FlxActionInput>) {
		for (action in controls.digitalActions)
		{
			var i = action.inputs.length;
			
			while (i-- > 0)
			{
				// uhhhhhhhhhhh
				var input = action.inputs[i];
				/*if (input.device == IFLXINPUT_OBJECT)
					action.remove(input);*/

				var x = Tinputs.length;
				while (x-- > 0)
					if (Tinputs[x] == input)
					{
						action.remove(input);
						input.destroy();
					}
			}
		}
	}
}

enum abstract ControlsGroup(Int) to Int from Int {
	var 'HITBOX' = 0;
	var 'VPAD_RIGHT' = 1;
	var 'VPAD_LEFT' = 2;
	var 'VPAD_CUSTOM' = 3;
	var 'KEYBOARD' = 4;
}