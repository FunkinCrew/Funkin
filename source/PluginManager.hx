package;

import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.addons.effects.FlxTrail;
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
        reterp.variables.set("FlxSprite", DynamicSprite);
        reterp.variables.set("FlxSound", flixel.system.FlxSound);
        reterp.variables.set("FlxAtlasFrames", DynamicSprite.DynamicAtlasFrames);
        reterp.variables.set("FlxGroup", flixel.group.FlxGroup);
        reterp.variables.set("FlxAngle", flixel.math.FlxAngle);
        reterp.variables.set("FlxMath", flixel.math.FlxMath);
        reterp.variables.set("TitleState", TitleState);
        reterp.variables.set("makeRangeArray", CoolUtil.numberArray);
        reterp.variables.set("FNFAssets", HScriptAssets);
        reterp.variables.set("FlxG", flixel.FlxG);
        reterp.variables.set("FlxTimer", flixel.util.FlxTimer);
        reterp.variables.set("FlxTween", flixel.tweens.FlxTween);
        reterp.variables.set("Std", Std);
        reterp.variables.set("StringTools", StringTools);
        reterp.variables.set("MetroSprite",MetroSprite);
        reterp.variables.set("FlxTrail", FlxTrail);
        reterp.variables.set("FlxEase", FlxEase);
        reterp.variables.set("Reflect", Reflect);
        return reterp;
    }
}