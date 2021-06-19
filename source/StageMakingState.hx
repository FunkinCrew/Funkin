package;

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

class StageMakingState extends FlxState
{
    /* STAGE STUFF */
    public static var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));

    public var stage_Name:String = 'chromatic-stage';
    private var stage:StageGroup;

    /* UI */
    private var beat_Button:FlxButton;
    private var stage_Dropdown:FlxUIDropDownMenu;

    public function new(?selectedStage:String)
    {
        super();

        if(selectedStage != null)
        {
            this.stage_Name = selectedStage;
        }
        
        this.stage = new StageGroup(stage_Name);
        add(stage);

        beat_Button = new FlxButton(0, 0, "Beat Hit", function(){
            if(stage != null)
            {
                stage.beatHit();
            }
        });

        add(beat_Button);

        stage_Dropdown = new FlxUIDropDownMenu(10, 500, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stageName:String)
        {
            //stage.updateStage(stageName);
        });

        stage_Dropdown.selectedLabel = stage_Name;
        add(stage_Dropdown);
    }
}