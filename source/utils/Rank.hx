package utils;

class Rank
{
	public static var misses:Int = 0;

	public static var goodhit:Int = 0;

	public static var perfect:Int = 0;

	public static function clear() {
		misses = 0;
		goodhit = 0;
		perfect = 0;
	}

	public static function calcRank():String
	{
		if ((goodhit + misses + perfect) == 0)
			return "N/A";

		var percentHit = (goodhit / (misses + goodhit)) * 100;

		// trace('$percentHit% goodhit: $goodhit misses: $misses');

		if (percentHit > 95)
			return "S";
		if (percentHit > 85)
			return "A";
		if (percentHit > 70)
			return "B";
		if (percentHit > 55)
			return "C";
		if (percentHit > 40)
			return "D";

		return "F";
	}
}