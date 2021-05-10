package;

import plugins.tools.MetroSprite;
import FNFAssets.HScriptAssets;
import hscript.InterpEx;
import hscript.Interp;
class PluginManager {
    public static var interp = new InterpEx();
    public static var hscriptClasses:Array<String> = [];
    public static function init() {
        var filelist = hscriptClasses = CoolUtil.coolTextFile("assets/scripts/plugin_classes/classes.txt");
        for (file in filelist) {
            if (FNFAssets.exists(file)) {
                interp.addModule(FNFAssets.getText(file));
            }
        }
    }
    /**
     * Create a simple interp, that already added all the needed shit
     * @return Interp
     */
    public static function createSimpleInterp():Interp {
        var reterp = new Interp();
        reterp.variables.set("Conductor", Conductor);
        reterp.variables.set("FlxSprite", flixel.FlxSprite);
        reterp.variables.set("FlxSound", flixel.system.FlxSound);
        reterp.variables.set("FlxAtlasFrames", flixel.graphics.frames.FlxAtlasFrames);
        reterp.variables.set("FlxGroup", flixel.group.FlxGroup);
        reterp.variables.set("FlxAngle", flixel.math.FlxAngle);
        reterp.variables.set("FlxMath", flixel.math.FlxMath);
        reterp.variables.set("makeRangeArray", CoolUtil.numberArray);
        reterp.variables.set("FNFAssets", HScriptAssets);
        reterp.variables.set("FlxG", flixel.FlxG);
        reterp.variables.set("FlxTimer", flixel.util.FlxTimer);
        reterp.variables.set("FlxTween", flixel.tweens.FlxTween);
        reterp.variables.set("Std", Std);
        reterp.variables.set("StringTools", StringTools);
        reterp.variables.set("MetroSprite",MetroSprite);
        return reterp;
    }
}