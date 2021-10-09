package debuggers;

import ui.FlxUIDropDownMenuCustom;
import utilities.PlayerSettings;
import states.MainMenuState;
import utilities.Controls;
import states.MusicBeatState;
import utilities.CoolUtil;
import game.StageGroup;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.addons.plugin.taskManager.FlxTask;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.ui.FlxButton;
import flixel.FlxState;

/*
    MOVE CODE
        if (FlxG.mouse.overlaps(sick) && FlxG.mouse.pressed)
        {
            sick.x = FlxG.mouse.x - sick.width / 2;
            sick.y = FlxG.mouse.y - sick.height;
        }
*/

class StageMakingState extends MusicBeatState
{
    /* STAGE STUFF */
    public var stages:Array<String>;

    public var stage_Name:String = 'chromatic-stage';
    private var stage:StageGroup;

    /* UI */
    private var beat_Button:FlxButton;
    private var stage_Dropdown:FlxUIDropDownMenuCustom;
    private var cam_Zoom:FlxText;

    private var startY:Int = 50;
    private var zoom:Float;

    /* CAMERA */
    private var stageCam:FlxCamera;
    private var camHUD:FlxCamera;

    private var camSpeed:Float = 1.0;

    public function new(selectedStage:String)
    {
        super();
        #if sys
        stages = CoolUtil.coolTextFilePolymod(Paths.txt('stageList'));
        #else
        stages = CoolUtil.coolTextFile(Paths.txt('stageList'));
        #end

        if(selectedStage != null)
        {
            stage_Name = selectedStage;
        }

        FlxG.mouse.visible = true;
    }

    override public function create()
    {
        stageCam = new FlxCamera();
        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;

        FlxG.cameras.add(stageCam, true);
        FlxG.cameras.add(camHUD, false);

        stage = new StageGroup(stage_Name);
        add(stage);

        stage_Dropdown = new FlxUIDropDownMenuCustom(10, startY + 50, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stageName:String)
        {
            trace(stageName);
            stage_Name = stages[Std.parseInt(stageName)];
            stage.updateStage(stage_Name);
        });

        stage_Dropdown.selectedLabel = stage_Name;
        stage_Dropdown.cameras = [camHUD];
        add(stage_Dropdown);

        cam_Zoom = new FlxText(10, startY + 100, 0, "Camera Zoom: " + stageCam.zoom, 32);
        cam_Zoom.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        cam_Zoom.cameras = [camHUD];
        add(cam_Zoom);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        // camera movement zoom
        if(FlxG.keys.justPressed.E)
        {
            stageCam.zoom += 0.1;
        }

        if(FlxG.keys.justPressed.Q)
        {
            stageCam.zoom -= 0.1;
        }

        if(controls.BACK)
        {
            FlxG.switchState(new MainMenuState());
        }

        // zoom lock
        if(stageCam.zoom < 0.1)
        {
            stageCam.zoom = 0.1;
        }

        // da math
        zoom = stageCam.zoom;
        zoom = zoom * Math.pow(10, 1);
        zoom = Math.round(zoom) / Math.pow(10, 1);

        cam_Zoom.text = "Camera Zoom: " + zoom;
    }
}
