package utilities;

import flixel.FlxG;
import haxe.Json;
import openfl.Assets;
import flixel.util.FlxSave;

typedef DefaultOptions =
{
    var options:Array<DefaultOption>;
}

typedef DefaultOption = 
{
    var option:String; // option name
    var value:Dynamic; // self explanatory

    var min:Null<Float>; // min value for numbers
    var max:Null<Float>; // max value for numbers

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

        defaultOptions = Json.parse(Assets.getText(Paths.json("defaultOptions")));

        for(option in defaultOptions.options)
        {
            getData(option.option, option.save);
        }

        if(getData("binds", "binds") == null)
            setData(NoteVariables.Default_Binds, "binds", "binds");
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
        {
            if(Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey) == null)
                fixData(dataKey, saveKey);

            if(Std.isOfType(Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey), Float) || Std.isOfType(Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey), Int))
            {
                for(option in defaultOptions.options)
                { 
                    if(option.option == dataKey && option.save == saveKey)
                    {
                        if(option.max != null)
                        {
                            if(Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey) > option.max)
                                setData(option.max, dataKey, saveKey);
                        }

                        if(option.min != null)
                        {
                            if(Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey) < option.min)
                                setData(option.min, dataKey, saveKey);
                        }
                    }
                }
            }
            
            return Reflect.getProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey);
        }

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

    public static function fixData(dataKey:String, ?saveKey:String = "main")
    {
        if(saves.exists(saveKey))
        {
            for(option in defaultOptions.options)
            {
                if(option.option == dataKey && option.save == saveKey)
                    Reflect.setProperty(Reflect.getProperty(saves.get(saveKey), "data"), dataKey, option.value);
            }

            saves.get(saveKey).flush();
        }
    }
}