package ui;

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
	var controlGrid:TextMenuList;
	var labels:FlxTypedGroup<AtlasText>;
	var menuCamera:FlxCamera;
	
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
		
		add(labels = new FlxTypedGroup<AtlasText>());
		labels.camera = menuCamera;
		
		add(controlGrid = new TextMenuList(Columns(2)));
		controlGrid.camera = menuCamera;
		
		// FlxG.debugger.drawDebug = true;
		var controlList = Control.createAll();
		for (i in 0...controlList.length)
		{
			var control = controlList[i];
			var name = control.getName();
			var y = (70 * i) + 30;
			var label = labels.add(new BoldText(0, y, name));
			label.x += 250;
			createItem(label.x + 400, y, control, 0);
			createItem(label.x + 600, y, control, 1);
		}
		
		var selected = controlGrid.members[0];
		var camFollow = new FlxObject(FlxG.width / 2, selected.y, 70, 70);
		menuCamera.follow(camFollow, null, 0.06);
		var margin = 100;
		menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
		controlGrid.onChange.add(function (selected) camFollow.y = selected.y);
	}
	
	function createItem(x = 0.0, y = 0.0, control:Control, index:Int)
	{
		var list = PlayerSettings.player1.controls.getInputsFor(control, Keys);
		var name = "---";
		if (list.length > index)
		{
			if (list[index] == FlxKey.ESCAPE)
				return createItem(x, y, control, 2);
			
			name = InputFormatter.format(list[index], Keys);
		}
		
		trace(control.getName() + " " + index + ": " + name);
		return controlGrid.createItem(x, y, name, Default, onSelect.bind(name, control, index));
	}
	
	function onSelect(name:String, control:Control, index:Int):Void
	{
		controlGrid.enabled = false;
		// var prompt = new Prompt();
	}
	
	override function set_enabled(value:Bool)
	{
		controlGrid.enabled = value;
		return super.set_enabled(value);
	}
}