package;

/// Code created by Rozebud for FPS Plus (thanks rozebud)
// modified by KadeDev for use in Kade Engine/Tricky

import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import io.newgrounds.NG;
import lime.app.Application;
import lime.utils.Assets;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;


using StringTools;

class KeyBindMenu extends FlxSubState
{

    var keyTextDisplay:FlxText;
    var keyWarning:FlxText;
    var warningTween:FlxTween;
    var keyText:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];
    var defaultKeys:Array<String> = ["A", "S", "W", "D", "R"];
    var defaultGpKeys:Array<String> = ["DPAD_LEFT", "DPAD_DOWN", "DPAD_UP", "DPAD_RIGHT"];
    var curSelected:Int = 0;

    var keys:Array<String> = [FlxG.save.data.leftBind,
                              FlxG.save.data.downBind,
                              FlxG.save.data.upBind,
                              FlxG.save.data.rightBind];
    var gpKeys:Array<String> = [FlxG.save.data.gpleftBind,
                              FlxG.save.data.gpdownBind,
                              FlxG.save.data.gpupBind,
                              FlxG.save.data.gprightBind];
    var tempKey:String = "";
    var blacklist:Array<String> = ["ESCAPE", "ENTER", "BACKSPACE", "SPACE", "TAB"];

    var blackBox:FlxSprite;
    var infoText:FlxText;

    var state:String = "select";

	override function create()
	{	

        for (i in 0...keys.length)
        {
            var k = keys[i];
            if (k == null)
                keys[i] = defaultKeys[i];
        }

        for (i in 0...gpKeys.length)
        {
            var k = gpKeys[i];
            if (k == null)
                gpKeys[i] = defaultGpKeys[i];
        }
	
		//FlxG.sound.playMusic('assets/music/configurator' + TitleState.soundExt);

		persistentUpdate = true;

        keyTextDisplay = new FlxText(-10, 0, 1280, "", 72);
		keyTextDisplay.scrollFactor.set(0, 0);
		keyTextDisplay.setFormat("VCR OSD Mono", 42, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		keyTextDisplay.borderSize = 2;
		keyTextDisplay.borderQuality = 3;

        blackBox = new FlxSprite(0,0).makeGraphic(FlxG.width,FlxG.height,FlxColor.BLACK);
        add(blackBox);

        infoText = new FlxText(-10, 580, 1280, 'Current Mode: ${KeyBinds.gamepad ? 'GAMEPAD' : 'KEYBOARD'}. Press TAB to switch\n(${KeyBinds.gamepad ? 'RIGHT Trigger' : 'Escape'} to save, ${KeyBinds.gamepad ? 'LEFT Trigger' : 'Backspace'} to leave without saving. ${KeyBinds.gamepad ? 'START To change a keybind' : ''})', 72);
		infoText.scrollFactor.set(0, 0);
		infoText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 2;
		infoText.borderQuality = 3;
        infoText.alpha = 0;
        infoText.screenCenter(FlxAxes.X);
        add(infoText);
        add(keyTextDisplay);

        blackBox.alpha = 0;
        keyTextDisplay.alpha = 0;

        FlxTween.tween(keyTextDisplay, {alpha: 1}, 1, {ease: FlxEase.expoInOut});
        FlxTween.tween(infoText, {alpha: 1}, 1.4, {ease: FlxEase.expoInOut});
        FlxTween.tween(blackBox, {alpha: 0.7}, 1, {ease: FlxEase.expoInOut});

        OptionsMenu.instance.acceptInput = false;

        textUpdate();

		super.create();
	}

    var frames = 0;

	override function update(elapsed:Float)
	{
        var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

        if (frames <= 10)
            frames++;

        infoText.text = 'Current Mode: ${KeyBinds.gamepad ? 'GAMEPAD' : 'KEYBOARD'}. Press TAB to switch\n(${KeyBinds.gamepad ? 'RIGHT Trigger' : 'Escape'} to save, ${KeyBinds.gamepad ? 'LEFT Trigger' : 'Backspace'} to leave without saving. ${KeyBinds.gamepad ? 'START To change a keybind' : ''})\n${lastKey != "" ? lastKey + " is blacklisted!" : ""}';

        switch(state){

            case "select":
                if (FlxG.keys.justPressed.UP)
                {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    changeItem(-1);
                }

                if (FlxG.keys.justPressed.DOWN)
                {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    changeItem(1);
                }

                if (FlxG.keys.justPressed.TAB)
                {
                    KeyBinds.gamepad = !KeyBinds.gamepad;
                    textUpdate();
                }

                if (FlxG.keys.justPressed.ENTER){
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    state = "input";
                }
                else if(FlxG.keys.justPressed.ESCAPE){
                    quit();
                }
                else if (FlxG.keys.justPressed.BACKSPACE){
                    reset();
                }
                if (gamepad != null) // GP Logic
                {
                    if (gamepad.justPressed.DPAD_UP)
                    {
                        FlxG.sound.play(Paths.sound('scrollMenu'));
                        changeItem(-1);
                        textUpdate();
                    }
                    if (gamepad.justPressed.DPAD_DOWN)
                    {
                        FlxG.sound.play(Paths.sound('scrollMenu'));
                        changeItem(1);
                        textUpdate();
                    }

                    if (gamepad.justPressed.START && frames > 10){
                        FlxG.sound.play(Paths.sound('scrollMenu'));
                        state = "input";
                    }
                    else if(gamepad.justPressed.LEFT_TRIGGER){
                        quit();
                    }
                    else if (gamepad.justPressed.RIGHT_TRIGGER){
                        reset();
                    }
                }

            case "input":
                tempKey = keys[curSelected];
                keys[curSelected] = "?";
                if (KeyBinds.gamepad)
                    gpKeys[curSelected] = "?";
                textUpdate();
                state = "waiting";

            case "waiting":
                if (gamepad != null && KeyBinds.gamepad) // GP Logic
                {
                    if(FlxG.keys.justPressed.ESCAPE){ // just in case you get stuck
                        gpKeys[curSelected] = tempKey;
                        state = "select";
                        FlxG.sound.play(Paths.sound('confirmMenu'));
                    }

                    if (gamepad.justPressed.START)
                    {
                        addKeyGamepad(defaultKeys[curSelected]);
                        save();
                        state = "select";
                    }

                    if (gamepad.justPressed.ANY)
                    {
                        trace(gamepad.firstJustPressedID());
                        addKeyGamepad(gamepad.firstJustPressedID());
                        save();
                        state = "select";
                        textUpdate();
                    }

                }
                else
                {
                    if(FlxG.keys.justPressed.ESCAPE){
                        keys[curSelected] = tempKey;
                        state = "select";
                        FlxG.sound.play(Paths.sound('confirmMenu'));
                    }
                    else if(FlxG.keys.justPressed.ENTER){
                        addKey(defaultKeys[curSelected]);
                        save();
                        state = "select";
                    }
                    else if(FlxG.keys.justPressed.ANY){
                        addKey(FlxG.keys.getIsDown()[0].ID.toString());
                        save();
                        state = "select";
                    }
                }


            case "exiting":


            default:
                state = "select";

        }

        if(FlxG.keys.justPressed.ANY)
			textUpdate();

		super.update(elapsed);
		
	}

    function textUpdate(){

        keyTextDisplay.text = "\n\n";

        if (KeyBinds.gamepad)
        {
            for(i in 0...4){

                var textStart = (i == curSelected) ? "> " : "  ";
                trace(gpKeys[i]);
                keyTextDisplay.text += textStart + keyText[i] + ": " + gpKeys[i] + "\n";
                
            }
        }
        else
        {
            for(i in 0...4){

                var textStart = (i == curSelected) ? "> " : "  ";
                keyTextDisplay.text += textStart + keyText[i] + ": " + ((keys[i] != keyText[i]) ? (keys[i] + " / ") : "" ) + keyText[i] + " ARROW\n";

            }
        }

        keyTextDisplay.screenCenter();

    }

    function save(){

        FlxG.save.data.upBind = keys[2];
        FlxG.save.data.downBind = keys[1];
        FlxG.save.data.leftBind = keys[0];
        FlxG.save.data.rightBind = keys[3];
        
        FlxG.save.data.gpupBind = gpKeys[2];
        FlxG.save.data.gpdownBind = gpKeys[1];
        FlxG.save.data.gpleftBind = gpKeys[0];
        FlxG.save.data.gprightBind = gpKeys[3];

        FlxG.save.flush();

        PlayerSettings.player1.controls.loadKeyBinds();

    }

    function reset(){

        for(i in 0...5){
            keys[i] = defaultKeys[i];
        }
        quit();

    }

    function quit(){

        state = "exiting";

        save();

        OptionsMenu.instance.acceptInput = true;

        FlxTween.tween(keyTextDisplay, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
        FlxTween.tween(blackBox, {alpha: 0}, 1.1, {ease: FlxEase.expoInOut, onComplete: function(flx:FlxTween){close();}});
        FlxTween.tween(infoText, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
    }


    function addKeyGamepad(r:String){

        var shouldReturn:Bool = true;

        var notAllowed:Array<String> = ["START"];

        for(x in 0...gpKeys.length)
            {
                var oK = gpKeys[x];
                if(oK == r)
                    gpKeys[x] = null;
                if (notAllowed.contains(oK))
                {
                    gpKeys[x] = null;
                    lastKey = r;
                    return;
                }
            }

        if(shouldReturn){
            gpKeys[curSelected] = r;
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        else{
            gpKeys[curSelected] = tempKey;
            lastKey = r;
        }

	}

    public var lastKey:String = "";

	function addKey(r:String){

        var shouldReturn:Bool = true;

        var notAllowed:Array<String> = [];

        for(x in blacklist){notAllowed.push(x);}

        trace(notAllowed);

        for(x in 0...keys.length)
            {
                var oK = keys[x];
                if(oK == r)
                    keys[x] = null;
                if (notAllowed.contains(oK))
                {
                    keys[x] = null;
                    lastKey = oK;
                    return;
                }
            }

        if (r.contains("NUMPAD"))
        {
            keys[curSelected] = null;
            lastKey = r;
            return;
        }

        lastKey = "";

        if(shouldReturn){
            keys[curSelected] = r;
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        else{
            keys[curSelected] = tempKey;
            lastKey = r;
        }

	}

    function changeItem(_amount:Int = 0)
    {
        curSelected += _amount;
                
        if (curSelected > 3)
            curSelected = 0;
        if (curSelected < 0)
            curSelected = 3;
    }
}
