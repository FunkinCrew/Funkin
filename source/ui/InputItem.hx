package ui;

import flixel.input.keyboard.FlxKey;
import Controls.Control;
import Controls.Device;

using StringTools;

class InputItem extends TextMenuItem
{
	public var index:Int = -1;
	public var input:Int = -1;
	public var control:Control;
	public var device:Device;

	override public function new(x:Float = 0, y:Float = 0, dev:Device, ctrl:Control, index:Int, ?callback:Dynamic)
	{
		device = dev;
		control = ctrl;
		this.index = index;
		input = getInput();
		super(x, y, getLabel(input), Default, callback);
	}

	public function updateDevice(a)
	{
		if (device != a)
		{
			device = a;
			input = getInput();
			label.set_text(getLabel(input));
		}
	}

	public function getInput()
	{
		var inputs = PlayerSettings.player1.controls.getInputsFor(control, device);
		if (inputs.length > index)
		{
			if (inputs[index] != 27 || inputs[index] != 6) return inputs[index];
			if (inputs.length > 2) return inputs[2];
		}
		return -1;
	}

	public function getLabel(a)
	{
		return a == -1 ? '---' : InputFormatter.format(a, device);
	}
}