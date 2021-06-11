package;

import FreeplayState.JsonMetadata;
import flixel.math.FlxMath;
import DifficultyIcons.DiffInfo;
typedef CoolCategory = {
    var name:String;
    var songs:Array<JsonMetadata>;
}
class DifficultyManager {
    static var diffJson:Dynamic;
    public static var supportedDiff:Map<String,Array<Int>> = [];
    public static function init() {
        diffJson = CoolUtil.parseJson(FNFAssets.getText("assets/images/custom_difficulties/difficulties.json"));
        var fpJson:Array<CoolCategory> = CoolUtil.parseJson(FNFAssets.getText("assets/data/freeplaySongJson.jsonc"));
        for (cat in fpJson) {
            for (song in cat.songs) {
                supportedDiff.set(song.name.toLowerCase(), []);
                for (diff in 0...diffJson.difficulties.length) {
                    if (FNFAssets.exists('assets/data/${song.name.toLowerCase()}/${song.name.toLowerCase()+getDiffEnding(diff)}.json')) {
                        // : )
                        supportedDiff.get(song.name.toLowerCase()).push(diff);
                    }
                }
            }
        }
    }
    public static function changeDifficulty(diff:Int, ?change:Int=0):DiffInfo {
        // we can do it directly because Ints are saved by value : )
        diff += change;
        diff = FlxMath.wrap(diff, 0, Std.int(diffJson.difficulties.length - 1));
        return {difficulty: diff, text: diffJson.difficulties[diff].name.toUpperCase()};
    }
    // sans : ) meaning without, this omits any 
    public static function changeDifficultySans(diff:Int, ?change:Int=0, ?song:String="tutorial"):DiffInfo {
        var foundSomething = false;
        var giveUpNum = 0;
        var giveUpResult = changeDifficulty(diff, change);
        var ignoreIfExists = change == 0;
        if (change == 0)
            change = 1;
        while (giveUpNum < diffJson.difficulties.length && !foundSomething) {
            if (supportedDiff.get(song.toLowerCase()).contains(diff) && ignoreIfExists) {
                return giveUpResult;
            }
            var sus = changeDifficulty(diff, change);
            diff = sus.difficulty;
            
            if (supportedDiff.get(song.toLowerCase()).contains(diff)) {
                return sus;
            }
            giveUpNum++;
        }
        return giveUpResult;
    }
    public static function getDiffName(diff:Int) {
		return diffJson.difficulties[diff].name.toUpperCase();
    }
    public static function getDiffEnding(diff:Int):String {
        var ending = "";
        if (diff != diffJson.defaultDiff) {
            ending = "-" + diffJson.difficulties[diff].name;
        
        }
         return ending;
    }
    // get a valid difficulty
    public static function getValidDiff(diff:Int, song:String):Int {
		var daThing = supportedDiff.get(song.toLowerCase());
        // if the diff is there, no problem
        if (daThing.contains(diff)) {
            return diff;
        }
        // otherwise if the default diff is there prefer that
        if (daThing.contains(diffJson.defaultDiff))
            return diffJson.defaultDiff;
        // otherwise prefer the hardest difficulty : )
		return daThing[daThing.length - 1];
    }
    public static function getDefaultDiff():Int {
        return diffJson.defaultDiff;
    }
}