package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import DifficultyIcons;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxUITabMenu;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import sys.FileSystem;
import flash.media.Sound;

#end
import lime.ui.FileDialog;
import lime.app.Event;
import haxe.Json;
import tjson.TJSON;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.ui.FileDialogType;
using StringTools;


class ChooseCharState extends MusicBeatState
{
    public static var characters:Array<String>;
    var char:Character;
    var anim:String = PlayState.SONG.player1;
    var grpAlphabet:FlxTypedGroup<Alphabet>;

    var curSelected:Int = 0;
    var curChar:String = PlayState.SONG.player1;

    var dadMenu:Bool = false;


    public function new(anim:String = "bf")
    {
        super();
        this.anim = anim;
    }

    override function create()
    {
        var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
        menuBG.color = 0xFFea71fd;
        grpAlphabet = new FlxTypedGroup<Alphabet>();
        menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
        menuBG.updateHitbox();
        menuBG.screenCenter();
        menuBG.antialiasing = true;
        add(menuBG);

        var charJson:Dynamic = null;

        char = new Character(400, 100, anim);
        add(char);

        char.flipX = false;


        var regCharacters:Array<String> = CoolUtil.coolTextFile('assets/data/characterList.txt');

        charJson = CoolUtil.parseJson(Assets.getText('assets/images/custom_chars/custom_chars.jsonc'));

        if (characters == null) {
            characters = mergeArray(Reflect.fields(charJson), Reflect.fields(regCharacters)); // this doesn't work, try to make this work or just ignore it
        }


        for(character in 0...characters.length){ //add chars
            var awesomeChar = new Alphabet(0, 10, "   "+characters[character], true, false, false);
            awesomeChar.isMenuItem = true;
            awesomeChar.targetY = character;
            grpAlphabet.add(awesomeChar);
        }

        add(grpAlphabet);
        trace("it's 11 pm"); //it's 12 pm

        super.create();

    }

    function mergeArray(base:Dynamic, ext:Dynamic){ //need this to combine regular chars and customs, CHANGE THIS if you know a better way
        var res = Reflect.copy(base);
        for(f in Reflect.fields(ext)) Reflect.setField(res,f,Reflect.field(res,f));
        return res;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        if (controls.BACK) {
                FlxG.switchState(new ModifierState());
        }
        if (controls.UP_P)
        {
            changeSelection(-1);
        }
        if (controls.DOWN_P)
        {
            changeSelection(1);
        }

        if (controls.RIGHT_P || controls.LEFT_P) {
                swapMenus();
        }

        if (controls.ACCEPT)
            chooseSelection();
    }

    function changeSelection(change:Int = 0)
    {

        FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

        curSelected += change;
        curChar = characters[curSelected].toString();

        if (curSelected < 0)
            curSelected = characters.length - 1;
        if (curSelected >= characters.length)
            curSelected = 0;


        var bullShit:Int = 0;

        for (item in grpAlphabet.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6;
            // item.setGraphicSize(Std.int(item.width * 0.8));

            if (item.targetY == 0)
            {
                item.alpha = 1;
                // item.setGraphicSize(Std.int(item.width));
            }
        }
    }

    function chooseSelection()
    {
        remove(char);
        char = new Character(400, 100, curChar);
        if (!dadMenu) //cleaned up
        {
            char.flipX = true;
            PlayState.SONG.player1 = curChar;
            trace("BF is now " + curChar);
        }
        else
        {
            char.flipX = false;
            PlayState.SONG.player2 = curChar;
            trace("DAD is now " + curChar);
        }
        if (curChar == null)
            curChar = "bf";
        add(char);

    }

    function swapMenus() { //this lags somewhat on my end so please try to optimize it
        FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);
        dadMenu = !dadMenu;
        remove(char);
        if (!dadMenu){ //cleaned this too
            char = new Character(400, 100, PlayState.SONG.player1);
            char.flipX = true;
        }
        else{
            char = new Character(400, 100, PlayState.SONG.player2);
            char.flipX = false;
        }
        add(char);
        trace('switchin the swag');
    }
}