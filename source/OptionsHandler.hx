package;
import lime.utils.Assets;
import sys.io.File;
typedef TOptions = {
    var skipVictoryScreen:Bool;
    var skipModifierMenu:Bool;
    var alwaysDoCutscenes:Bool;
    var useCustomInput:Bool;
    var DJFKKeys:Bool;
    var showMisses:Bool;
    var allowEditOptions:Bool;
    var useSaveDataMenu:Bool;
    var preferredSave:Int;
}
class OptionsHandler {
    public static var options(get, set):TOptions;
    static function get_options() {
        // update the file
        return CoolUtil.parseJson(Assets.getText('assets/data/options.json'));
    }
    static function set_options(opt:TOptions) {
        File.saveContent('assets/data/options.json', CoolUtil.stringifyJson(opt));
        return opt;
    }
}