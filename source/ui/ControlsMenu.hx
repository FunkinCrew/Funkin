package ui;

import Controls;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.actions.FlxActionInput;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import ui.AtlasText;
import ui.MenuList;
import ui.TextMenuList;

class ControlsMenu extends ui.OptionsState.Page
{
	inline static public var COLUMNS = 2;
	static var controlList = Control.createAll();
	/*
	 * Defines groups of controls that cannot share inputs, like left and right. Say, if ACCEPT is Z, Back is X,
	 * if the player sets Back to Z it also set ACCEPT to X. This prevents the player from setting the controls in
	 * a way the prevents them from changing more controls or exiting the menu.
	 */
	static var controlGroups:Array<Array<Control>> = [
		[NOTE_UP, NOTE_DOWN, NOTE_LEFT, NOTE_RIGHT],
		[UI_UP, UI_DOWN, UI_LEFT, UI_RIGHT, ACCEPT, BACK]
	];

	var itemGroups:Array<Array<InputItem>> = [for (i in 0...controlGroups.length) []];

	var controlGrid:MenuTypedList<InputItem>;
	var deviceList:TextMenuList;
	var menuCamera:FlxCamera;
	var prompt:Prompt;
	var camFollow:FlxObject;
	var labels:FlxTypedGroup<AtlasText>;

	var currentDevice:Device = Keys;
	var deviceListSelected = false;

	public function new()
	{
		super();

		menuCamera = new FlxCamera();
		FlxG.cameras.add(menuCamera, false);
		menuCamera.bgColor = 0x0;
		camera = menuCamera;

		labels = new FlxTypedGroup<AtlasText>();
		var headers = new FlxTypedGroup<AtlasText>();
		controlGrid = new MenuTypedList(Columns(COLUMNS), Vertical);

		add(labels);
		add(headers);
		add(controlGrid);

		if (FlxG.gamepads.numActiveGamepads > 0)
		{
			var devicesBg = new FlxSprite();
			devicesBg.makeGraphic(FlxG.width, 100, 0xFFfafd6d);
			add(devicesBg);
			deviceList = new TextMenuList(Horizontal, None);
			add(deviceList);
			deviceListSelected = true;

			var item;

			item = deviceList.createItem("Keyboard", Bold, selectDevice.bind(Keys));
			item.x = FlxG.width / 2 - item.width - 30;
			item.y = (devicesBg.height - item.height) / 2;

			item = deviceList.createItem("Gamepad", Bold, selectDevice.bind(Gamepad(FlxG.gamepads.firstActive.id)));
			item.x = FlxG.width / 2 + 30;
			item.y = (devicesBg.height - item.height) / 2;
		}

		// FlxG.debugger.drawDebug = true;
		var y = deviceList == null ? 30 : 120;
		var spacer = 70;
		var currentHeader:String = null;
		// list order is determined by enum order
		for (i in 0...controlList.length)
		{
			var control = controlList[i];
			var name = control.getName();
			if (currentHeader != "UI_" && name.indexOf("UI_") == 0)
			{
				currentHeader = "UI_";
				headers.add(new BoldText(0, y, "UI")).screenCenter(X);
				y += spacer;
			}
			else if (currentHeader != "NOTE_" && name.indexOf("NOTE_") == 0)
			{
				currentHeader = "NOTE_";
				headers.add(new BoldText(0, y, "NOTES")).screenCenter(X);
				y += spacer;
			}

			if (currentHeader != null && name.indexOf(currentHeader) == 0)
				name = name.substr(currentHeader.length);

			var label = labels.add(new BoldText(150, y, name));
			label.alpha = 0.6;
			for (i in 0...COLUMNS)
				createItem(label.x + 400 + i * 300, y, control, i);

			y += spacer;
		}

		camFollow = new FlxObject(FlxG.width / 2, 0, 70, 70);
		if (deviceList != null)
		{
			camFollow.y = deviceList.selectedItem.y;
			controlGrid.selectedItem.idle();
			controlGrid.enabled = false;
		}
		else
			camFollow.y = controlGrid.selectedItem.y;

		menuCamera.follow(camFollow, null, 0.06);
		var margin = 100;
		menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
		menuCamera.minScrollY = 0;
		controlGrid.onChange.add(function(selected)
		{
			camFollow.y = selected.y;

			labels.forEach((label) -> label.alpha = 0.6);
			labels.members[Std.int(controlGrid.selectedIndex / COLUMNS)].alpha = 1.0;
		});

		prompt = new Prompt("\nPress any key to rebind\n\n\n\n    Escape to cancel", None);
		prompt.create();
		prompt.createBgFromMargin(100, 0xFFfafd6d);
		prompt.back.scrollFactor.set(0, 0);
		prompt.exists = false;
		add(prompt);
	}

	function createItem(x = 0.0, y = 0.0, control:Control, index:Int)
	{
		var item = new InputItem(x, y, currentDevice, control, index, onSelect);
		for (i in 0...controlGroups.length)
		{
			if (controlGroups[i].contains(control))
				itemGroups[i].push(item);
		}

		return controlGrid.addItem(item.name, item);
	}

	function onSelect():Void
	{
		controlGrid.enabled = false;
		canExit = false;
		prompt.exists = true;
	}

	function goToDeviceList()
	{
		controlGrid.selectedItem.idle();
		labels.members[Std.int(controlGrid.selectedIndex / COLUMNS)].alpha = 0.6;
		controlGrid.enabled = false;
		deviceList.enabled = true;
		canExit = true;
		camFollow.y = deviceList.selectedItem.y;
		deviceListSelected = true;
	}

	function selectDevice(device:Device)
	{
		currentDevice = device;

		for (item in controlGrid.members)
			item.updateDevice(currentDevice);

		var inputName = device == Keys ? "key" : "button";
		var cancel = device == Keys ? "Escape" : "Back";
		// todo: alignment
		if (device == Keys)
			prompt.setText('\nPress any key to rebind\n\n\n\n    $cancel to cancel');
		else
			prompt.setText('\nPress any button\n   to rebind\n\n\n $cancel to cancel');

		controlGrid.selectedItem.select();
		labels.members[Std.int(controlGrid.selectedIndex / COLUMNS)].alpha = 1.0;
		controlGrid.enabled = true;
		deviceList.enabled = false;
		deviceListSelected = false;
		canExit = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var controls = PlayerSettings.player1.controls;
		if (controlGrid.enabled && deviceList != null && deviceListSelected == false && controls.BACK)
			goToDeviceList();

		if (prompt.exists)
		{
			switch (currentDevice)
			{
				case Keys:
					{
						// check released otherwise bugs can happen when you change the BACK key
						var key = FlxG.keys.firstJustReleased();
						if (key != NONE)
						{
							if (key != ESCAPE)
								onInputSelect(key);
							closePrompt();
						}
					}
				case Gamepad(id):
					{
						var button = FlxG.gamepads.getByID(id).firstJustReleasedID();
						if (button != NONE)
						{
							if (button != BACK)
								onInputSelect(button);
							closePrompt();
						}
					}
			}
		}
	}

	function onInputSelect(input:Int)
	{
		var item = controlGrid.selectedItem;

		// check if that key is already set for this
		var column0 = Math.floor(controlGrid.selectedIndex / 2) * 2;
		for (i in 0...COLUMNS)
		{
			if (controlGrid.members[column0 + i].input == input)
				return;
		}

		// Check if items in the same group already have the new input
		for (group in itemGroups)
		{
			if (group.contains(item))
			{
				for (otherItem in group)
				{
					if (otherItem != item && otherItem.input == input)
					{
						// replace that input with this items old input.
						PlayerSettings.player1.controls.replaceBinding(otherItem.control, currentDevice, item.input, otherItem.input);
						// Don't use resetItem() since items share names/labels
						otherItem.input = item.input;
						otherItem.label.text = item.label.text;
					}
				}
			}
		}

		PlayerSettings.player1.controls.replaceBinding(item.control, currentDevice, input, item.input);
		// Don't use resetItem() since items share names/labels
		item.input = input;
		item.label.text = item.getLabel(input);

		PlayerSettings.player1.saveControls();
	}

	function closePrompt()
	{
		prompt.exists = false;
		controlGrid.enabled = true;
		if (deviceList == null)
			canExit = true;
	}

	override function destroy()
	{
		super.destroy();

		itemGroups = null;

		if (FlxG.cameras.list.contains(menuCamera))
			FlxG.cameras.remove(menuCamera);
	}

	override function set_enabled(value:Bool)
	{
		if (value == false)
		{
			controlGrid.enabled = false;
			if (deviceList != null)
				deviceList.enabled = false;
		}
		else
		{
			controlGrid.enabled = !deviceListSelected;
			if (deviceList != null)
				deviceList.enabled = deviceListSelected;
		}
		return super.set_enabled(value);
	}
}

class InputItem extends TextMenuItem
{
	public var device(default, null):Device = Keys;
	public var control:Control;
	public var input:Int = -1;
	public var index:Int = -1;

	public function new(x = 0.0, y = 0.0, device, control, index, ?callback)
	{
		this.device = device;
		this.control = control;
		this.index = index;
		this.input = getInput();

		super(x, y, getLabel(input), Default, callback);
	}

	public function updateDevice(device:Device)
	{
		if (this.device != device)
		{
			this.device = device;
			input = getInput();
			label.text = getLabel(input);
		}
	}

	function getInput()
	{
		var list = PlayerSettings.player1.controls.getInputsFor(control, device);
		if (list.length > index)
		{
			if (list[index] != FlxKey.ESCAPE || list[index] != FlxGamepadInputID.BACK)
				return list[index];

			if (list.length > ControlsMenu.COLUMNS)
				// Escape isn't mappable, show a third option, instead.
				return list[ControlsMenu.COLUMNS];
		}

		return -1;
	}

	public function getLabel(input:Int)
	{
		return input == -1 ? "---" : InputFormatter.format(input, device);
	}
}
