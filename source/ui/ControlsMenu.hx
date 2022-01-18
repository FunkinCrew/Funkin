package ui;

import Controls.Control;
import Controls.Device;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

using StringTools;

class ControlsMenu extends Page
{
	public static var controlList:Array<Control> = Control.createAll();
	public static var controlGroups:Array<Array<Control>> = [[NOTE_UP, NOTE_DOWN, NOTE_LEFT, NOTE_RIGHT], [UI_UP, UI_DOWN, UI_LEFT, UI_RIGHT, ACCEPT, BACK]];

	var deviceList:TextMenuList;
	var deviceListSelected = false;
	var controlGrid:MenuTypedList<InputItem>;
	var currentDevice = Device.Keys;
	var itemGroups:Array<Array<InputItem>>;
	var menuCamera:FlxCamera;
	var camFollow:FlxObject;
	var labels:FlxTypedGroup<AtlasText>;
	var prompt:Prompt;

	override public function new()
	{
		var a = [];
		for (i in 0...controlGroups.length)
		{
			a.push([]);
		}
		itemGroups = a;
		super();
		menuCamera = new FlxCamera();
		FlxG.cameras.add(menuCamera, false);
		menuCamera.bgColor = FlxColor.TRANSPARENT;
		set_camera(menuCamera);
		labels = new FlxTypedGroup<AtlasText>();
		var grpText = new FlxTypedGroup<AtlasText>();
		controlGrid = new MenuTypedList(Columns(2), Vertical);
		add(labels);
		add(grpText);
		add(controlGrid);
		if (FlxG.gamepads.getActiveGamepads().length > 0)
		{
			var spr = new FlxSprite().makeGraphic(FlxG.width, 100, 0xFFFAFD6D);
			add(spr);
			deviceList = new TextMenuList(Horizontal, None);
			add(deviceList);
			deviceListSelected = true;
			var kbItem = deviceList.createItem(0, 0, 'Keyboard', Bold, function()
			{
				selectDevice(Device.Keys);
			});
			kbItem.x = FlxG.width / 2 - kbItem.width - 30;
			kbItem.y = (spr.height - kbItem.height) / 2;
			var gp = Device.Gamepad(FlxG.gamepads.firstActive.id);
			var gpItem = deviceList.createItem(0, 0, 'Gamepad', Bold, function()
			{
				selectDevice(gp);
			});
			gpItem.x = FlxG.width / 2 + 30;
			gpItem.y = (spr.height - gpItem.height) / 2;
		}
		var ypos = (deviceList == null) ? 30 : 120;
		var curSection:String = null;
		for (i in 0...controlList.length)
		{
			var ctrl = controlList[i];
			var name = ctrl.getName();
			if (curSection != 'UI_' && name.indexOf('UI_') == 0)
			{
				curSection = 'UI_';
				var sectionText = new AtlasText(0, ypos, 'UI', Bold);
				grpText.add(sectionText);
				sectionText.screenCenter(X);
				ypos += 70;
			}
			else if (curSection != 'NOTE_' && name.indexOf('NOTE_') == 0)
			{
				curSection = 'NOTE_';
				var sectionText = new AtlasText(0, ypos, 'NOTES', Bold);
				grpText.add(sectionText);
				sectionText.screenCenter(X);
				ypos += 70;
			}
			if (curSection != null && name.indexOf(curSection) == 0)
			{
				name = name.substr(curSection.length);
			}
			var text = new AtlasText(150, ypos, name, Bold);
			labels.add(text);
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
		menuCamera.deadzone.x = 0;
		menuCamera.deadzone.y = 100;
		menuCamera.deadzone.width = menuCamera.width;
		menuCamera.deadzone.height = menuCamera.height - 200;
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
		prompt = new Prompt('\nPress any key to rebind\n\n\n    Escape to cancel', None);
		prompt.create();
		prompt.createBgFromMargin(100, 0xFFFAFD6D);
		prompt.back.scrollFactor.set(0, 0);
		prompt.set_exists(false);
		add(prompt);
	}

	public function createItem(x:Float = 0, y:Float = 0, c, d)
	{
		var item = new InputItem(x, y, currentDevice, c, d, onSelect);
		for (i in 0...controlGroups.length)
		{
			if (controlGroups[i].indexOf(c) != -1)
				itemGroups[i].push(item);
		}
		return controlGrid.addItem(item.name, item);
	}

	public function onSelect()
	{
		canExit = false;
		controlGrid.enabled = false;
		prompt.set_exists(true);
	}

	public function goToDeviceList()
	{
		controlGrid.members[controlGrid.selectedIndex].idle();
		labels.members[Std.int(controlGrid.selectedIndex)].alpha = 0.6;
		controlGrid.enabled = false;
		canExit = true;
		deviceList.enabled = true;
		camFollow.y = deviceList.members[deviceList.selectedIndex].y;
		deviceListSelected = true;
	}

	public function selectDevice(dev:Device)
	{
		currentDevice = dev;
		for (item in controlGrid.members)
		{
			item.updateDevice(currentDevice);
		}
		var b = (dev == Device.Keys) ? 'Escape' : 'Back';
		if (dev == Device.Keys)
		{
			prompt.setText('\nPress any key to rebind\n\n\n\n    ' + b + ' to cancel');
		}
		else
		{
			prompt.setText('\nPress any button\n   to rebind\n\n\n ' + b + ' to cancel');
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
			goToDeviceList();
		if (prompt.exists)
		{
			switch (currentDevice)
			{
				case Keys:
					var released = FlxG.keys.firstJustReleased();
					if (released != -1)
					{
						if (released != 27) onInputSelect(released);
						closePrompt();
					}
				case Gamepad(id):
					var pad = FlxG.gamepads.getByID(id);
					var released = pad.mapping.getID(pad.firstJustReleasedRawID());
					if (released != -1)
					{
						if (released != 6) onInputSelect(released);
						closePrompt();
					}
			}
		}
	}

	public function onInputSelect(rawInput:Int)
	{
		var b = controlGrid.members[controlGrid.selectedIndex];
		var c = 2 * Math.floor(controlGrid.selectedIndex / 2);
		if (controlGrid.members[c].input != rawInput && controlGrid.members[c + 1].input != rawInput)
		{
			for (i in 0...itemGroups.length)
			{
				var e:Array<InputItem> = itemGroups[i];
				if (e.indexOf(b) != -1)
					for (j in 0...e.length)
					{
						var h = e[j];
						if (h != b && h.input == rawInput)
						{
							PlayerSettings.player1.controls.replaceBinding(h.control, currentDevice, b.input, h.input);
							h.input = b.input;
							h.label.set_text(b.label.text);
						}
					}
			}
			PlayerSettings.player1.controls.replaceBinding(b.control, currentDevice, rawInput, b.input);
			b.input = rawInput;
			b.label.set_text(b.getLabel(rawInput));
			PlayerSettings.player1.saveControls();
		}
	}

	public function closePrompt()
	{
		prompt.set_exists(false);
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
		if (FlxG.cameras.list.indexOf(menuCamera) != -1)
			FlxG.cameras.remove(menuCamera);
	}

	override public function set_enabled(state:Bool)
	{
		if (state == false)
		{
			controlGrid.enabled = false;
			if (deviceList != null)
			{
				deviceList.enabled = deviceListSelected;
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