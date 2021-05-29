package;

import flixel.math.FlxMath;
import Highscore.FCLevel;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

import Judge.Jury;
enum abstract DisplayOptions(Int) from Int to Int {
    var BestScore;
    var Recent;
    var BestAccuracy;
    var BestFc;
    var BestOverall;
    @:op(A > B) static function _(_,_):Bool;
	@:op(A >= B) static function _(_, _):Bool;
	@:op(A < B) static function _(_, _):Bool;
	@:op(A <= B) static function _(_, _):Bool;
	@:op(A == B) static function _(_, _):Bool;
    @:op(A + B) static function _(_,_):DisplayOptions;
    @:from static public function fromString(s:String) {
        return switch (s) {
            case "best-score":
                BestScore;
            case "recent":
                Recent;
            case "best-accuracy":
                BestAccuracy;
            case "best-fullcombo":
                BestFc;
            case "best":
                BestOverall;
            default:
                Recent;
        }
    }
    @:to static public function toString(d:DisplayOptions):String {
        return switch(d) {
            case BestScore:
                "best-score";
            case Recent:
                "recent";
            case BestAccuracy:
                "best-accuracy";
            case BestFc:
                "best-fullcombo";
            case BestOverall:
                "best";
        }
    }
}
class SongInfoPanel extends FlxTypedSpriteGroup<FlxSprite> {
    var backpanel:FlxSprite;
    var scoreTxt:FlxText;
    var accuracyTxt:FlxText;
    var fcTxt:FlxText;
    var judgeTxt:FlxText;
    var displaying:String = "best";
    var curSong:String = "tutorial";
    var displayTxt:FlxText;
    var curDiff:Int = 1;
    public function new(X:Float, Y:Float, song:String, diff:Int) {
        super(X, Y);

        curSong = song;
        curDiff = diff;
        backpanel = new FlxSprite().makeGraphic(400, 400, 0xCC000000);
        scoreTxt = new FlxText(20, 20, 350, "a", 22);
        accuracyTxt = new FlxText(20, 80, 0, "a", 22);
        fcTxt = new FlxText(20, 140, 0, "a", 22);
		judgeTxt = new FlxText(20, 200, 0,"a", 22);
        displayTxt = new FlxText(20, 260, 0, displaying, 22);
        add(backpanel);
        add(scoreTxt);
        //add(accuracyTxt);
        //add(fcTxt);
        //add(judgeTxt);
        add(displayTxt);
    }   
    public function changeSong(song:String, diff:Int) {
        curSong = song;
        curDiff = diff;
        scoreTxt.text = "Score: " + Highscore.getScore(song, diff, displaying);
        //accuracyTxt.text = "Accuracy: " + CoolUtil.truncateFloat(Highscore.getAccuracy(song, diff, displaying) * 100, 2);
		scoreTxt.text += '\n' + "Accuracy: " + CoolUtil.truncateFloat(Highscore.getAccuracy(song, diff, displaying) * 100, 2);
        var fcUse:String = "FC Level:";
        switch (cast (Highscore.getFCLevel(song, diff, displaying) : FCLevel)) {
            case Sick:
                fcUse += "Sick";
            case Good:
                fcUse += "Good";
            case Bad:
                fcUse += "Bad";
            case Shit:
                fcUse += "Shit";
            case Sdcb:
                fcUse += "Sdcb";
            case None:
                fcUse += "Clear";
        } 
        scoreTxt.text += '\n' + fcUse;
        var sussyjudge = switch (cast (Highscore.getJudge(song, diff, displaying) : Judge.Jury)) {
            case Judge9:
                "Judge JUSTICE";
            case Classic:
                "Classic Judge";
            case Hard:
                "Hard Judge";
            case judgeee:
                "Judge " + (cast (judgeee : Int) + 1);
        }
		var songOptions = Highscore.getOptionsUsed(song, diff, displaying);
        var modifierUsed = Highscore.getModifiersUsed(song, diff, displaying);
        if (displaying != 'best') {
			scoreTxt.text += '\n' + sussyjudge;
            // Purge references to ignore shitty timing :)
            /*
			if (songOptions.ignoreShittyTiming)
				scoreTxt.text += '\nUses virgin ignore shitty timing';
			else
				scoreTxt.text += '\nDoes not ignore shitties :)';
            */
            if (modifierUsed.mfc.value || modifierUsed.gfc.value || modifierUsed.fc.value) {
                scoreTxt.text += "\nTotally grinded for this lmao";
            }
        }
            
       
        displayTxt.text = displaying;
     }
     public function changeDisplay(change:Int=0) {
         var sussyOption:DisplayOptions = cast (displaying : DisplayOptions);
         sussyOption += change;
         sussyOption = FlxMath.wrap(sussyOption, 0, BestOverall);
		displaying = switch (sussyOption)
		{
			case BestScore:
				"best-score";
			case Recent:
				"recent";
			case BestAccuracy:
				"best-accuracy";
			case BestFc:
				"best-fullcombo";
			case BestOverall:
				"best";
		};
        changeSong(curSong, curDiff);
     }
}