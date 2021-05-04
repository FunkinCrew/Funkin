package;

import hscript.InterpEx;

class PluginManager {
    public static var interp = new InterpEx();

    public static function init() {
        var filelist = CoolUtil.coolTextFile("assets/scripts/plugin_classes/classes.txt");
        for (file in filelist) {
            if (FNFAssets.exists(file)) {
                interp.addModule(FNFAssets.getText(file));
            }
        }
    }
}