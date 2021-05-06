package;
import lime.utils.Assets;
#if sys
import sys.io.File;
#end
import flixel.FlxG;
typedef TOptions = {
    var skipVictoryScreen:Bool;
    var skipModifierMenu:Bool;
    var alwaysDoCutscenes:Bool;
    var allowEditOptions:Bool;
    var downscroll:Bool;
    var useSaveDataMenu:Bool;
    var preferredSave:Int;
}
class OptionsHandler {
    public static var options(get, set):TOptions;
    static function get_options() {
        #if sys
        // update the file
        return CoolUtil.parseJson(Assets.getText('assets/data/options.json'));
        #else
        if (!Reflect.hasField(FlxG.save.data, "options"))
			FlxG.save.data.options = CoolUtil.parseJson(Assets.getText('assets/data/options.json'));
        return FlxG.save.data.options;
        #end
    }
    static function set_options(opt:TOptions) {
        #if sys
        File.saveContent('assets/data/options.json', CoolUtil.stringifyJson(opt));
        #else
        FlxG.save.data.options = CoolUtil.stringifyJson(opt);
        #end
        return opt;
    }
}