package modding;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxObject;
import game.Character;
import game.StageGroup;
import states.OptionsMenu;
import utilities.MusicUtilities;
import flixel.FlxG;
import game.Conductor;
import states.MusicBeatState;

#if discord_rpc
import utilities.Discord.DiscordClient;
#end

using StringTools;

class CharacterCreationState extends MusicBeatState
{
    var stage:StageGroup;
    var character:Character;
    var charStr:String = "bf";

    var animList:FlxText;

    var camFollow:FlxObject;

    var coolCam:FlxCamera;
    var camHUD:FlxCamera;

    var curAnimation:Int = 0;
    var animations:Array<String> = [];

    override public function new(?char:String = "bf")
    {
        super();

        charStr = char;
    }

    override function create()
    {
        FlxG.mouse.visible = true;

        coolCam = new FlxCamera();
        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;

        FlxG.cameras.reset();
        FlxG.cameras.add(coolCam, true);
        FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(coolCam, true);

		FlxG.camera = coolCam;

        camFollow = new FlxObject(0, 0, 2, 2);
        camFollow.screenCenter();
		add(camFollow);

        coolCam.follow(camFollow);

        stage = new StageGroup("stage");
        add(stage);
        add(stage.infrontOfGFSprites);
        add(stage.foregroundSprites);

        character = new Character(0, 0, charStr);
        character.shouldDance = false;

        @:privateAccess
        if(character.offsetsFlipWhenEnemy)
        {
            character.isPlayer = true;
            character.flipX = !character.flipX;
            character.loadOffsetFile(character.curCharacter);
        }

        add(character);

        animations = character.animation.getNameList();

        animList = new FlxText(0,0,0,"Corn", 24);
        animList.color = FlxColor.CYAN;
        animList.cameras = [camHUD];
        animList.font = Paths.font("vcr.ttf");
        animList.borderSize = 1;
        animList.borderStyle = OUTLINE;
        
        animList.text = Std.string(animations).replace("[", "").replace("]", "").replace(",", "\n").replace(animations[curAnimation] + "\n", '>${animations[curAnimation]}<\n')
        + '\nCurrent Selected: ${Std.string(curAnimation)}\n';
        
        add(animList);

        var coolPos:Array<Float> = stage.getCharacterPos(character.isPlayer ? 0 : 1, character);

        character.setPosition(coolPos[0], coolPos[1]);

        #if discord_rpc
        DiscordClient.changePresence("Creating characters.", null, null, true);
        #end

        if(FlxG.sound.music == null)
            FlxG.sound.playMusic(MusicUtilities.GetOptionsMenuMusic(), 0.7, true);

        super.create();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        if(controls.BACK)
            FlxG.switchState(new OptionsMenu());

        if(FlxG.keys.justPressed.SPACE)
            character.playAnim(animations[curAnimation % animations.length], true);

        if(FlxG.keys.justPressed.W)
            curAnimation -= 1;
        if(FlxG.keys.justPressed.S)
            curAnimation += 1;

        if(FlxG.keys.justPressed.S || FlxG.keys.justPressed.W)
        {
            if(curAnimation < 0)
                curAnimation = animations.length - 1;
            if(curAnimation > animations.length - 1)
                curAnimation = 0;

            animList.text = Std.string(animations).replace("[", "").replace("]", "").replace(",", "\n").replace(animations[curAnimation] + "\n", '>${animations[curAnimation]}<\n')
            + '\nCurrent Selected: ${Std.string(curAnimation)}\n';

            character.playAnim(animations[curAnimation % animations.length], true);
        }

        var shiftThing:Int = FlxG.keys.pressed.SHIFT ? 5 : 1;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L) // stolen from animation debug lmao
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90 * shiftThing;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90 * shiftThing;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90 * shiftThing;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90 * shiftThing;
			else
				camFollow.velocity.x = 0;
		}
		else
			camFollow.velocity.set();

        if (FlxG.keys.pressed.E)
			coolCam.zoom += 2 * elapsed;
		if (FlxG.keys.pressed.Q)
			coolCam.zoom -= 2 * elapsed;

        if(coolCam.zoom < 0.1)
            coolCam.zoom = 0.1;
        if(coolCam.zoom > 5)
            coolCam.zoom = 5;
    }
}