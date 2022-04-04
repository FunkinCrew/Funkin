package ui;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepad;
import Controls.Control;
import Controls.Device;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class ControlsMenu extends Page
{
	public static var controlList:Array<Control> = Control.createAll();
	public static var controlGroups:Array<Array<Control>> = [[NOTE_UP, NOTE_DOWN, NOTE_LEFT, NOTE_RIGHT], [UI_UP, UI_DOWN, UI_LEFT, UI_RIGHT, ACCEPT, BACK]];

	var currentDevice:Device = Device.Keys;
	var deviceList:TextMenuList;
	var deviceListSelected:Bool = false;
	var controlGrid:MenuTypedList<InputItem>;
	var itemGroups:Array<Array<InputItem>>;
	var menuCamera:FlxCamera;
	var camFollow:FlxObject;
	var labels:FlxTypedGroup<AtlasText>;
	var prompt:Prompt;

	override public function new()
	{
		var array:Array<Array<InputItem>> = [];
		for (i in 0...controlGroups.length)
		{
			array.push([]);
		}
		itemGroups = array;
		super();
		menuCamera = new FlxCamera();
		FlxG.cameras.add(menuCamera, false);
		menuCamera.bgColor = FlxColor.TRANSPARENT;
		camera = menuCamera;
		labels = new FlxTypedGroup<AtlasText>();
		var grpText:FlxTypedGroup<AtlasText> = new FlxTypedGroup<AtlasText>();
		controlGrid = new MenuTypedList(Columns(2), Vertical);
		add(labels);
		add(grpText);
		add(controlGrid);
		if (FlxG.gamepads.numActiveGamepads > 0)
		{
			var spr:FlxSprite = new FlxSprite();
			spr.makeGraphic(FlxG.width, 100, 0xFFFAFD6D);
			add(spr);
			deviceList = new TextMenuList(Horizontal, None);
			add(deviceList);
			deviceListSelected = true;
			var kbItem:TextMenuItem = deviceList.createItem(null, null, 'Keyboard', Bold, function()
			{
				selectDevice(Device.Keys);
			});
			kbItem.x = FlxG.width / 2 - kbItem.width - 30;
			kbItem.y = (spr.height - kbItem.height) / 2;
			var gpItem:TextMenuItem = deviceList.createItem(null, null, 'Gamepad', Bold, function()
			{
				selectDevice(Device.Gamepad(FlxG.gamepads.firstActive.id));
			});
			gpItem.x = FlxG.width / 2 + 30;
			gpItem.y = (spr.height - gpItem.height) / 2;
		}
		var ypos:Int = (deviceList == null) ? 30 : 120;
		var curSection:String = null;
		for (ctrl in controlList)
		{
			var name:String = ctrl.getName();
			if (curSection != 'UI_' && name.indexOf('UI_') == 0)
			{
				curSection = 'UI_';
				var sectionText:AtlasText = new AtlasText(0, ypos, 'UI', Bold);
				grpText.add(sectionText).screenCenter(X);
				ypos += 70;
			}
			else if (curSection != 'NOTE_' && name.indexOf('NOTE_') == 0)
			{
				curSection = 'NOTE_';
				var sectionText:AtlasText = new AtlasText(0, ypos, 'NOTES', Bold);
				grpText.add(sectionText).screenCenter(X);
				ypos += 70;
			}
			if (curSection != null && name.indexOf(curSection) == 0)
			{
				name = name.substr(curSection.length);
			}
			var text:AtlasText = new AtlasText(150, ypos, name, Bold);
			text = labels.add(text);
			text.alpha = 0.6;
			createItem(text.x + 400, ypos, ctrl, 0);
			createItem(text.x + 400 + 300, ypos, ctrl, 1);
			ypos += 70;
		}
		camFollow = new FlxObject(FlxG.width / 2, 0, 70, 70);
		if (deviceList != null)
		{
			camFollow.y = deviceList.members[deviceList.selectedIndex].y;
			controlGrid.members[controlGrid.selectedIndex].idle();
			controlGrid.enabled = false;
		}
		else
		{
			camFollow.y = controlGrid.members[controlGrid.selectedIndex].y;
		}
		menuCamera.follow(camFollow, null, 0.06);
		menuCamera.deadzone.set(0, 100, menuCamera.width, menuCamera.height - 200);
		menuCamera.minScrollY = 0;
		controlGrid.onChange.add(function(item:InputItem)
		{
			camFollow.y = item.y;
			labels.forEach(function(text:AtlasText)
			{
				text.alpha = 0.6;
			});
			labels.members[Std.int(controlGrid.selectedIndex / 2)].alpha = 1;
		});
		prompt = new Prompt('\nPress any key to rebind\n\n\n\n    Escape to cancel', None);
		prompt.create();
		prompt.createBgFromMargin(100, 0xFFFAFD6D);
		prompt.back.scrollFactor.set(0, 0);
		prompt.exists = false;
		add(prompt);
	}

	function createItem(?x:Float = 0, ?y:Float = 0, control:Control, index:Int)
	{
		var item:InputItem = new InputItem(x, y, currentDevice, control, index, onSelect);
		for (i in 0...controlGroups.length)
		{
			if (controlGroups[i].contains(control))
				itemGroups[i].push(item);
		}
		return controlGrid.addItem(item.name, item);
	}

	function onSelect()
	{
		canExit = false;
		controlGrid.enabled = false;
		prompt.exists = true;
	}

	function goToDeviceList()
	{
		controlGrid.members[controlGrid.selectedIndex].idle();
		labels.members[Std.int(controlGrid.selectedIndex / 2)].alpha = 0.6;
		controlGrid.enabled = false;
		canExit = true;
		deviceList.enabled = true;
		camFollow.y = deviceList.members[deviceList.selectedIndex].y;
		deviceListSelected = true;
	}

	function selectDevice(dev:Device)
	{
		currentDevice = dev;
		for (item in controlGrid.members)
		{
			item.updateDevice(currentDevice);
		}
		var cancelBtn:String = dev == Device.Keys ? 'Escape' : 'Back';
		if (dev == Device.Keys)
		{
			prompt.setText('\nPress any key to rebind\n\n\n\n    ' + cancelBtn + ' to cancel');
		}
		else
		{
			prompt.setText('\nPress any button\n   to rebind\n\n\n ' + cancelBtn + ' to cancel');
		}
		controlGrid.members[controlGrid.selectedIndex].select();
		labels.members[Std.int(controlGrid.selectedIndex / 2)].alpha = 1;
		controlGrid.enabled = true;
		canExit = false;
		deviceListSelected = false;
		deviceList.enabled = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var controls = PlayerSettings.player1.controls;
		if (controlGrid.enabled && deviceList != null && deviceListSelected == false && controls.BACK)
		{
			goToDeviceList();
		}
		if (prompt.exists)
		{
			switch (currentDevice)
			{
				case Keys:
					var released:Int = FlxG.keys.firstJustReleased();
					if (released != -1)
					{
						if (released != 27)
							onInputSelect(released);
						closePrompt();
					}
				case Gamepad(id):
					var pad:FlxGamepad = FlxG.gamepads.getByID(id);
					var released:FlxGamepadInputID = pad.mapping.getID(pad.firstJustReleasedRawID());
					if (released != -1)
					{
						if (released != 6)
							onInputSelect(released);
						closePrompt();
					}
			}
		}
	}

	function onInputSelect(input:Int)
	{
		var selected:InputItem = controlGrid.members[controlGrid.selectedIndex];
		var index:Int = 2 * Math.floor(controlGrid.selectedIndex / 2);
		if (controlGrid.members[index].input != input && controlGrid.members[index + 1].input != input)
		{
			for (group in itemGroups)
			{
				if (group.contains(selected))
				{
					for (item in group)
					{
						if (item != selected && item.input == input)
						{
							PlayerSettings.player1.controls.replaceBinding(item.control, currentDevice, selected.input, item.input);
							item.input = selected.input;
							item.label.text = selected.label.text;
						}
					}
				}
			}
			PlayerSettings.player1.controls.replaceBinding(selected.control, currentDevice, input, selected.input);
			selected.input = input;
			selected.label.text = selected.getLabel(input);
			PlayerSettings.player1.saveControls();
		}
	}

	function closePrompt()
	{
		prompt.exists = false;
		controlGrid.enabled = true;
		if (deviceList == null)
		{
			canExit = true;
		}
	}

	override public function destroy()
	{
		super.destroy();
		itemGroups = null;
		if (FlxG.cameras.list.contains(menuCamera))
			FlxG.cameras.remove(menuCamera);
	}

	override function set_enabled(state:Bool)
	{
		if (state == false)
		{
			controlGrid.enabled = false;
			if (deviceList != null)
			{
				deviceList.enabled = false;
			}
		}
		else
		{
			controlGrid.enabled = !deviceListSelected;
			if (deviceList != null)
			{
				deviceList.enabled = deviceListSelected;
			}
		}
		return super.set_enabled(state);
	}
}