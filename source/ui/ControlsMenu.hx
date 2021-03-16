package ui;

import ui.MenuList;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;

import Controls;
import ui.AtlasText;
import ui.TextMenuList;

class ControlsMenu extends ui.OptionsState.Page
{
	static var controlList = Control.createAll();
	/*
	 * Defines groups of controls that cannot share inputs, like left and right. Say, if ACCEPT is Z, Back is X,
	 * if the player sets Back to Z it also set ACCEPT to X. This prevents the player from setting the controls in
	 * a way the prevents them from changing more controls or exiting the menu.
	 */
	static var controlGroups:Array<Array<Control>> =
		[ [ NOTE_UP, NOTE_DOWN, NOTE_LEFT, NOTE_RIGHT ]
		, [ UI_UP, UI_DOWN, UI_LEFT, UI_RIGHT, ACCEPT, BACK ]
		];
	
	var itemGroups:Array<Array<InputItem>> = [for (i in 0...controlGroups.length) []];
	
	var controlGrid:MenuTypedList<InputItem>;
	var menuCamera:FlxCamera;
	var prompt:Prompt;
	
	public function new()
	{
		super();
		
		menuCamera = new FlxCamera();
		FlxG.cameras.add(menuCamera);// false);
		if (FlxCamera.defaultCameras.indexOf(menuCamera) != -1)
		{
			FlxCamera.defaultCameras = FlxCamera.defaultCameras.copy();
			FlxCamera.defaultCameras.remove(menuCamera);
		}
		menuCamera.bgColor = 0x0;
		camera = menuCamera;
		
		var labels = new FlxTypedGroup<AtlasText>();
		var headers = new FlxTypedGroup<AtlasText>();
		add(controlGrid = new MenuTypedList(Columns(2)));
		
		add(labels);
		add(headers);
		add(controlGrid);
		
		// FlxG.debugger.drawDebug = true;
		var y = 30;
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
			
			var label = labels.add(new BoldText(250, y, name));
			label.alpha = 0.6;
			createItem(label.x + 400, y, control, 0);
			createItem(label.x + 600, y, control, 1);
			y += spacer;
		}
		
		labels.members[0].alpha = 1.0;
		var selected = controlGrid.members[0];
		var camFollow = new FlxObject(FlxG.width / 2, selected.y, 70, 70);
		menuCamera.follow(camFollow, null, 0.06);
		var margin = 100;
		menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
		controlGrid.onChange.add(function (selected)
		{
			camFollow.y = selected.y;
			
			labels.forEach((label)->label.alpha = 0.6);
			labels.members[Std.int(controlGrid.selectedIndex / 2)].alpha = 1.0;
		});
		
		prompt = new Prompt("\nPress any key to rebind\n\n\n\n    Escape to cancel", None);
		prompt.create();
		prompt.createBgFromMargin();
		prompt.back.scrollFactor.set(0, 0);
		prompt.exists = false;
		add(prompt);
	}
	
	function createItem(x = 0.0, y = 0.0, control:Control, index:Int)
	{
		var item = new InputItem(x, y, control, index, onSelect);
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
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (prompt.exists)
		{
			var key = FlxG.keys.firstJustPressed();
			if (key != NONE)
			{
				if (key != ESCAPE)
					onKeySelect(key);
				closePrompt();
			}
		}
	}
	
	function onKeySelect(key:Int)
	{
		var item = controlGrid.selectedItem;
		for (group in itemGroups)
		{
			if (group.contains(item))
			{
				for (otherItem in group)
				{
					// Check if items in the same group have the new input
					if (otherItem != item && otherItem.input == key)
					{
						// replace that input with this items old input.
						PlayerSettings.player1.controls.replaceBinding(otherItem.control, Keys, item.input, otherItem.input);
						// Don't use resetItem() since items share names/labels
						otherItem.input = item.input;
						otherItem.label.text = item.label.text;
					}
				}
			}
		}
		
		PlayerSettings.player1.controls.replaceBinding(item.control, Keys, key, item.input);
		// Don't use resetItem() since items share names/labels
		item.input = key;
		item.label.text = item.getLabel(key);
	}
	
	function closePrompt()
	{
		controlGrid.enabled = true;
		canExit = true;
		prompt.exists = false;
	}
	
	override function destroy()
	{
		super.destroy();
		
		if (FlxG.cameras.list.contains(menuCamera))
			FlxG.cameras.remove(menuCamera);
	}
	
	override function set_enabled(value:Bool)
	{
		controlGrid.enabled = value;
		return super.set_enabled(value);
	}
}

class InputItem extends TextMenuItem
{
	public var control:Control;
	public var input:Int = -1;
	
	public function new (x = 0.0, y = 0.0, control, index, ?callback)
	{
		this.control = control;
		
		var list = PlayerSettings.player1.controls.getInputsFor(control, Keys);
		if (list.length > index)
		{
			if (list[index] != FlxKey.ESCAPE)
				input = list[index];
			else if (list.length > 2)
				// Escape isn't mappable, show a third option, instead.
				input = list[2];
		}
		
		;
		super(x, y, getLabel(input), Default, callback);
	}
	
	public function getLabel(input:Int)
	{
		return input == -1 ? "---" : InputFormatter.format(input, Keys);
	}
}