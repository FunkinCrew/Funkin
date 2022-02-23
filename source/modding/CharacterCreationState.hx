package modding;

import ui.FlxUIDropDownMenuCustom;
import utilities.CoolUtil;
import flixel.FlxSprite;
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

    var funnyBox:FlxSprite;

    var characters:Map<String, Array<String>> = new Map<String, Array<String>>();

    var charDropDown:FlxUIDropDownMenuCustom;
    var modDropDown:FlxUIDropDownMenuCustom;

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

        funnyBox = new FlxSprite(0,0);
        funnyBox.makeGraphic(32, 32, FlxColor.RED);

        reloadCharacterStuff();

        animList = new FlxText(0,0,0,"Corn", 24);
        animList.color = FlxColor.CYAN;
        animList.cameras = [camHUD];
        animList.font = Paths.font("vcr.ttf");
        animList.borderSize = 1;
        animList.borderStyle = OUTLINE;
        
        updateAnimList();
        
        add(animList);

        var characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));

		for(Text in characterList)
		{
			var Properties = Text.split(":");

			var name = Properties[0];
			var mod = Properties[1];

			var base_array;

			if(characters.exists(mod))
				base_array = characters.get(mod);
			else
				base_array = [];

			base_array.push(name);
			characters.set(mod, base_array);
		}

        var arrayCharacters = ["bf","gf"];
		var tempCharacters = characters.get("default");

        if(tempCharacters != null)
        {
            for(Item in tempCharacters)
            {
                arrayCharacters.push(Item);
            }
        }

        charDropDown = new FlxUIDropDownMenuCustom(10, 10, FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrayCharacters, true), function(character:String)
        {
            charStr = arrayCharacters[Std.parseInt(character)];
            reloadCharacterStuff();
        }, null, null, null, null, camHUD);

        charDropDown.x = FlxG.width - charDropDown.width;
        charDropDown.cameras = [camHUD];

        var mods:Array<String> = [];

		var iterator = characters.keys();

		for(i in iterator)
		{
			mods.push(i);
		}

        var selected_mod:String = "default";

		var modDropDown = new FlxUIDropDownMenuCustom(charDropDown.x - charDropDown.width, charDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(mods, true), function(mod:String)
		{
			selected_mod = mods[Std.parseInt(mod)];

			arrayCharacters = ["bf","gf"];
			tempCharacters = characters.get(selected_mod);
			
			for(Item in tempCharacters)
			{
				arrayCharacters.push(Item);
			}

			var character_Data_List = FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrayCharacters, true);
			
			charDropDown.setData(character_Data_List);
			charDropDown.selectedLabel = charStr;
		}, null, null, null, null, camHUD);

        modDropDown.selectedLabel = "default";

        add(modDropDown);
        add(charDropDown);

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

            updateAnimList();

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

    function reloadCharacterStuff()
    {
        if(charDropDown != null)
            remove(charDropDown);
        if(modDropDown != null)
            remove(modDropDown);

        remove(funnyBox);

        if(character != null)
        {
            remove(character);
            character.kill();
            character.destroy();
        }

        if(charStr == "")
            charStr = "bf";

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

        add(funnyBox);

        if(modDropDown != null)
            add(modDropDown);
        if(charDropDown != null)
            add(charDropDown);

        animations = character.animation.getNameList();

        if(animations.length < 1)
            animations = ["idle"];

        var coolPos:Array<Float> = stage.getCharacterPos(character.isPlayer ? 0 : 1, character);

        if(character.isPlayer)
            funnyBox.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
        else
            funnyBox.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

        character.setPosition(coolPos[0], coolPos[1]);

        if(animList != null)
            updateAnimList();
    }

    function updateAnimList()
    {
        animList.text = (Std.string(animations).replace("[", "").replace("]", "").replace(",", "\n") + "\n").replace(animations[curAnimation % animations.length]
            + "\n", '>${animations[curAnimation % animations.length]}<\n');
    }
}