package utilities;

import haxe.Json;
import openfl.Assets;
import flixel.util.FlxSave;
import game.Conductor;

typedef DefaultOptions =
{
    var options:Array<DefaultOption>;
}

typedef DefaultOption = 
{
    var option:String; // option name
    var value:Dynamic; // self explanatory

    var save:Null<String>; // the save (KEY NAME) to use, by default is 'main'
}

class Options
{
    public static var bindNamePrefix:String = "leather_engine-";
    public static var bindPath:String = "leather128";

    public static var saves:Map<String, FlxSave> = [];

    public static var defaultOptions:DefaultOptions;

    public static function init()
    {
        createSave("main", "options");
        createSave("binds", "binds");
        createSave("scores", "scores");
        createSave("noteColors", "noteColors");
        createSave("autosave", "autosave");
        createSave("modlist", "modlist");

        defaultOptions = Json.parse(Assets.getText(Paths.json("defaultOptions")));

        for(option in defaultOptions.options)
        {
            var saveKey = option.save != null ? option.save : "main";
            var dataKey = option.option;

            if(Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey) == null)
                setData(option.value, option.option, saveKey);
        }

        Conductor.offset = getData("songOffset");

        if(getData("modlist", "modlist") == null)
            setData(new Map<String, Bool>(), "modlist", "modlist");

        if(getData("songScores", "scores") == null)
            setData(new Map<String, Int>(), "songScores", "scores");

        if(getData("songRanks", "scores") == null)
            setData(new Map<String, String>(), "songRanks", "scores");

        if(getData("songAccuracies", "scores") == null)
            setData(new Map<String, Float>(), "songAccuracies", "scores");

        if(getData("noteColors", "noteColors") == null)
            setData(new Map<String, Array<Int>>(), "noteColors", "noteColors");
    }

    public static function createSave(key:String, bindNameSuffix:String)
    {
        var save = new FlxSave();
        save.bind(bindNamePrefix + bindNameSuffix, bindPath);

        saves.set(key, save);
    }

    public static function getData(dataKey:String, ?saveKey:String = "main"):Dynamic
    {
        if(saves.exists(saveKey))
            return Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey);

        return null;
    }

    public static function setData(value:Dynamic, dataKey:String, ?saveKey:String = "main")
    {
        if(saves.exists(saveKey))
        {
            Reflect.setProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey, value);

            saves.get(saveKey).flush();
        }
    }

    public static function fixBinds()
    {
        if(getData("binds", "binds") == null)
            setData(NoteVariables.Default_Binds, "binds", "binds");
        else
        {
            var bindArray:Array<Dynamic> = getData("binds", "binds");

            if(bindArray.length < NoteVariables.Default_Binds.length)
            {
                for(i in Std.int(bindArray.length - 1)...NoteVariables.Default_Binds.length)
                {
                    bindArray[i] = NoteVariables.Default_Binds[i];
                }

                setData(bindArray, "binds", "binds");
            }
        }
    }
}