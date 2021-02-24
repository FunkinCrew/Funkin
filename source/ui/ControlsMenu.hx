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

class ControlsMenu extends flixel.group.FlxGroup
{
    var controlGrid:TextMenuList;
    var labels:FlxTypedGroup<AtlasText>;
    var menuCamera:FlxCamera;
    
    public function new()
    {
        super();
        
        var menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        menuBG.color = 0xFFea71fd;
        menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
        menuBG.updateHitbox();
        menuBG.screenCenter();
        add(menuBG);
        
        camera = FlxG.camera;
        FlxG.cameras.add(menuCamera = new FlxCamera());
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
            label.x += 100;
            createItem(500, y, control, 0);
            createItem(700, y, control, 1);
        }
        
        var selected = controlGrid.members[0];
        var camFollow = new FlxObject(FlxG.width / 2, selected.y);
        menuCamera.follow(camFollow, LOCKON, 0.06);
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
}