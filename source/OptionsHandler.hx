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
    var useCustomInput:Bool;
    var DJFKKeys:Bool;
    var allowEditOptions:Bool;
    var downscroll:Bool;
    var useSaveDataMenu:Bool;
    var preferredSave:Int;
    var showSongPos:Bool;
    var style:Bool;
    var stressTankmen:Bool;
    var ignoreShittyTiming:Bool;
    var ignoreUnlocks:Bool;
}
class OptionsHandler {
    public static var options(get, set):TOptions;
    // Preformance!
    // We only read the file once...
    // As all calls to options should go through options handler
    // we can just cache the last options read until the file gets edited. 
    static var lastOptions:TOptions;
    static var needToRefresh:Bool = true;
    static function get_options() {
        #if sys
        // update the file
        if (needToRefresh) {
			lastOptions = CoolUtil.parseJson(Assets.getText('assets/data/options.json'));
            needToRefresh = false;
			
        }
		return lastOptions;
        #else
        if (!Reflect.hasField(FlxG.save.data, "options"))
			FlxG.save.data.options = CoolUtil.parseJson(Assets.getText('assets/data/options.json'));
        return FlxG.save.data.options;
        #end
    }
    static function set_options(opt:TOptions) {
        #if sys
        needToRefresh = true;
        File.saveContent('assets/data/options.json', CoolUtil.stringifyJson(opt));
        #else
        FlxG.save.data.options = CoolUtil.stringifyJson(opt);
        #end
        return opt;
    }
}