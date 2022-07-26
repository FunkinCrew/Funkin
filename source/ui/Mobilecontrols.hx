package ui;

// import options.CustomControlsState;
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
	public var mode:ControlsGroup = HITBOX;

	public var _hitbox:Hitbox;
	public var _virtualPad:FlxVirtualPad;

	var cHandler:ControlHandler;

	public static var isEnabled(get, never):Bool;
	public function new() 
	{
		super();

		switch(FlxG.save.data.mobilecontrols)
		{
			case 'VPAD_RIGHT':
				initVirtualPad(0);
				cHandler = new ControlHandler(_virtualPad);
				cHandler.bind();
			case 'VPAD_LEFT':
				initVirtualPad(1);
				cHandler = new ControlHandler(_virtualPad);
				cHandler.bind();
			case 'VPAD_CUSTOM':
				initVirtualPad(2);
				cHandler = new ControlHandler(_virtualPad);
				cHandler.bind();
			case 'HITBOX':
				_hitbox = new Hitbox();
				add(_hitbox);
				cHandler = new ControlHandler(_hitbox);
				cHandler.bind();
			case 'KEYBOARD':
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

	public static function createVirtualPad(?DPad:FlxDPadMode, ?Action:FlxActionMode):Null<FlxVirtualPad> 
	{
		if (!Mobilecontrols.isEnabled)
			return null;
		
		var virtualPad = new FlxVirtualPad(DPad, Action);
		new ControlHandler(virtualPad).bind();
		return virtualPad;
	}

	static function get_isEnabled():Bool {
		return FlxG.onMobile #if true || true #end;
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
		trackedinputs = [];
		if (isPad)
			setVirtualPad();
		else
			setHitBox();
	}

	public function unBind() {
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
	var HITBOX = 0;
	var VIRTUALPAD_RIGHT = 1;
	var VIRTUALPAD_LEFT = 2;
	var VIRTUALPAD_CUSTOM = 3;
	var KEYBOARD = 4;
}