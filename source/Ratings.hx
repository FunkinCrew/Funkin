import Highscore.FCLevel;
import haxe.display.Display.Package;
import flixel.FlxG;

class Ratings
{
	public static function GenerateLetterRank(accuracy:Float) // generate a letter ranking
	{
		var ranking:String = "N/A";
		if (FlxG.save.data.botplay)
			ranking = "BotPlay";
		switch (CalculateFCRating()) {
			case Sick:
				ranking = "(MFC)";
			case Good:
				ranking = "(GFC)";
			case Shit | Bad:
				ranking = "(FC)";
			case Sdcb:
				ranking = "(SDCB)";
			default:
				ranking = "(Clear)";
		}

		// WIFE TIME :)))) (based on Wife3)

		var wifeConditions:Array<Bool> = [
			accuracy >= 99.9935, // AAAAA
			accuracy >= 99.980, // AAAA:
			accuracy >= 99.970, // AAAA.
			accuracy >= 99.955, // AAAA
			accuracy >= 99.90, // AAA:
			accuracy >= 99.80, // AAA.
			accuracy >= 99.70, // AAA
			accuracy >= 99, // AA:
			accuracy >= 96.50, // AA.
			accuracy >= 93, // AA
			accuracy >= 90, // A:
			accuracy >= 85, // A.
			accuracy >= 80, // A
			accuracy >= 70, // B
			accuracy >= 60, // C
			accuracy < 60 // D
		];

		for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				switch (i)
				{
					case 0:
						ranking += " AAAAA";
					case 1:
						ranking += " AAAA:";
					case 2:
						ranking += " AAAA.";
					case 3:
						ranking += " AAAA";
					case 4:
						ranking += " AAA:";
					case 5:
						ranking += " AAA.";
					case 6:
						ranking += " AAA";
					case 7:
						ranking += " AA:";
					case 8:
						ranking += " AA.";
					case 9:
						ranking += " AA";
					case 10:
						ranking += " A:";
					case 11:
						ranking += " A.";
					case 12:
						ranking += " A";
					case 13:
						ranking += " B";
					case 14:
						ranking += " C";
					case 15:
						ranking += " D";
				}
				break;
			}
		}

		if (accuracy == 0)
			ranking = "N/A";
		else if (FlxG.save.data.botplay)
			ranking = "BotPlay";

		return ranking;
	}

	public static function CalculateRating(noteDiff:Float, ?customSafeZone:Float):String // Generate a judgement through some timing shit
	{
		var customTimeScale = Conductor.safeZoneOffset / 166;


		// trace(customTimeScale + ' vs ' + Conductor.timeScale);

		// I HATE THIS IF CONDITION
		// IF LEMON SEES THIS I'M SORRY :(

		// trace('Hit Info\nDifference: ' + noteDiff + '\nZone: ' + Conductor.safeZoneOffset * 1.5 + "\nTS: " + customTimeScale + "\nLate: " + 155 * customTimeScale);
		// I assume these are in milliseconds? lmao
		if (ModifierState.namedModifiers.demo.value)
			return "good"; // FUNNY
		// ok these are actually in milliseconds
		if (noteDiff > Judge.wayoffJudge) // so god damn early its a miss
			return "miss";
		if (noteDiff > Judge.shitJudge ) 
			return "wayoff";
		if (noteDiff > Judge.badJudge) // way early
			return "shit";
		else if (noteDiff > Judge.goodJudge) // early
			return "bad";
		else if (noteDiff > Judge.sickJudge) // your kinda there
			return "good";
		else if (noteDiff < -1 * Judge.sickJudge) // little late
			return "good";
		else if (noteDiff < -1 * Judge.goodJudge) // late
			return "bad";
		else if (noteDiff < -1 * Judge.badJudge) // late as fuck
			return "shit";
		else if (noteDiff < -1 * Judge .shitJudge) // :grief:
			return "wayoff";
		else if (noteDiff < -1 * Judge.wayoffJudge) // so god damn late its a miss
			return "miss";
		return "sick";
	}
	public static function CalculateFullCombo(level:FCLevel):Bool {
		return switch (level) {
			case Sick:
				(PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods == 0);
			case Good:
				PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0;
			case Bad:
				PlayState.misses == 0 && PlayState.shits == 0;
			case Shit:
				PlayState.misses == 0;
			case Sdcb:
				PlayState.misses < 10;
			default:
				false;
		}
	}
	public static function CalculateFCRating():FCLevel {
		if (CalculateFullCombo(Sick))
			return Sick;
		if (CalculateFullCombo(Good))
			return Good;
		if (CalculateFullCombo(Bad))
			return Bad;
		if (CalculateFullCombo(Shit))
			return Shit;
		if (CalculateFullCombo(Sdcb))
			return Sdcb;
		return None;
	}
	public static function CalculateRanking(score:Int, scoreDef:Int, nps:Int, accuracy:Float):String
	{
		return (FlxG.save.data.npsDisplay ? "NPS: " + nps + (!FlxG.save.data.botplay ? " | " : "") : "") + (!FlxG.save.data.botplay ? // NPS Toggle
			"Score:"
			+ (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score)
			+ // Score
			" | Combo Breaks:"
			+ PlayState.misses
			+ // Misses/Combo Breaks
			" | Accuracy:"
			+ (FlxG.save.data.botplay ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %")
			+ // Accuracy
			" | "
			+ GenerateLetterRank(accuracy) : ""); // Letter Rank
	}
}