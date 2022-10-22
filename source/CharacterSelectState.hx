package;

import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxTimer;
import flixel.graphics.frames.FlxAtlasFrames;
import Song.SwagSong;

class CharacterSelectState extends MusicBeatState
{
    // default char is bf
    var playableChar:Int = 0;
    var selectedChar:String = 'bf';
    var char:Int = 0;

    var charList:Array<String> = ["bf", "pico"];
    var charNameList:Array<String> = ["BOYFRIEND", "PICO"];

    var bg:FlxSprite;
    var danceey:Character;
    var nameTxt:FlxText;

    var ui_frames:FlxAtlasFrames;

    var leftarrow:FlxSprite;
    var rightarrow:FlxSprite;

    override public function create():Void
    {
        bg = new FlxSprite(0, 125).makeGraphic(FlxG.width, 450, 0xFFF9CF51);
        add(bg);

        var titleTxt:Alphabet = new Alphabet(0, FlxG.height * 0.05, "Choose a Character", true);
        titleTxt.screenCenter(X);
        add(titleTxt);

        ui_frames = Paths.getSparrowAtlas("arrows");

        leftarrow = new FlxSprite(FlxG.width * 0.05, 0);
        leftarrow.frames = ui_frames;
        leftarrow.antialiasing = true;

        leftarrow.animation.addByPrefix('idle', 'left idle', 24, true);
        leftarrow.animation.addByPrefix('press', 'left press', 24, false);
        
        leftarrow.animation.play('idle');
        leftarrow.updateHitbox();
        leftarrow.screenCenter(Y);
        add(leftarrow);

        rightarrow = new FlxSprite((FlxG.width / 2) - (leftarrow.width / 2), 0);
        rightarrow.frames = ui_frames;
        rightarrow.antialiasing = true;

        rightarrow.animation.addByPrefix('idle', 'right idle', 24, true);
        rightarrow.animation.addByPrefix('press', 'right press', 24, false);
        
        rightarrow.animation.play('idle');
        rightarrow.updateHitbox();
        rightarrow.screenCenter(Y);
        add(rightarrow);

        danceey = new Character(0, 0, charList[char]);
        danceey.playAnim("idle");
        add(danceey);

        danceey.setGraphicSize(Std.int(325));

        danceey.x = (FlxG.width / 2) - (danceey.width / 2);
        danceey.y = (FlxG.height / 2) - (danceey.height / 2);

        danceey.animation.play('bfIdle');
        add(danceey);

        nameTxt = new FlxText(0, 125, FlxG.width, charNameList[0], 32);
        nameTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
        trace(nameTxt.x, nameTxt.y);
        add(nameTxt);

        super.create();
    }

    function changeChar(change:Int = 0)
    {
        char += change;

        trace("change: " + change + "\n char: " + char);

        FlxG.sound.play(Paths.sound('scrollMenu'));

        if (char < 0) 
            char = (charList.length - 1);
        if (char > (charList.length - 1))
            char = 0;

        selectedChar = charList[char];

        nameTxt.text = charNameList[char];
        trace(char + 'Idle');
        danceey.animation.play(selectedChar + 'Idle');
    }
    
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.LEFT)
            leftarrow.animation.play('press');
        else
            leftarrow.animation.play('idle');

        if (controls.RIGHT)
            rightarrow.animation.play('press');
        else
            rightarrow.animation.play('idle');

        if (controls.RIGHT_P)
            changeChar(1);
        if (controls.LEFT_P)
            changeChar(-1);

        if (controls.BACK)
            FlxG.sound.play(Paths.sound("cancelMenu"));
            FlxG.switchState(new FreeplayState());

        if (controls.ACCEPT)
        {
            FlxG.sound.play(Paths.sound('confirmMenu'));

            new FlxTimer().start(1, function(tmr:FlxTimer)
            {
                trace(selectedChar);
                //PlayState.selectedBf = selectedChar;

                //LoadingState.loadAndSwitchState(new PlayState(), true);
            });
        }
    }
}