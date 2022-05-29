package engine.functions;

import flixel.FlxG;

class Option
{
    public static function recieveValue(optionName:String)
    {
        var funnyMap:Map<String, Any> = FlxG.save.data.optionValueMap;
        if (funnyMap != null)
        {
            if (funnyMap[optionName] != null)
            {
                return funnyMap[optionName];
            }
            else
            {
                return null;
            }
        }
        else
        {
            return null;
        }
    }
}