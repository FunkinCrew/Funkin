package utils;

class Rank
{
	var percentHit:Float;

	public var misses:Int;

	public var goodhit:Int;

	public var perfect:Int;

	public function new()
	{
		misses = 0;
		goodhit = 0;
		perfect = 0;
		percentHit = 100;
	}

	public function calcRank():String
	{
		percentHit = (goodhit / (misses + goodhit)) * 100;

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
/*
	old code

	for (section in notes)
	{
		for (songNotes in section.sectionNotes)
		{
			var gottaHitNote:Bool = section.mustHitSection; // true is bf note

			if (songNotes[1] > 3)
			{
				gottaHitNote = !section.mustHitSection;
			}
			trace(gottaHitNote);

			var susLength:Float = songNotes[2];

			susLength = susLength / Conductor.stepCrochet;

			var totalsus:Int = 0;
			for (susNote in 0...Math.floor(susLength))
				totalsus += 1;

			trace('before $totalsus');

			if (gottaHitNote)
			{
				trace('after $totalsus');
				totalnotes = totalnotes + totalsus + 1;
			}
		}
	}

	trace(totalnotes);



	percentHit = (goodhit / totalnotes) * 100; old rank

 */
