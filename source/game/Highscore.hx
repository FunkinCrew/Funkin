package game;

import flixel.math.FlxMath;

class Highscore
{
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRanks:Map<String, String> = new Map<String, String>();
	public static var songAccuracies:Map<String, Float> = new Map<String, Float>();

	public static function resetSong(song:String, ?diff:String = "easy"):Void
	{
		var daSong:String = formatSong(song, diff);

		setScore(daSong, 0);
		setRank(daSong, "N/A");
		setAccuracy(daSong, 0);
	}

	public static function resetWeek(week:Int = 1, ?diff:String = "easy", ?weekName:String = 'week'):Void
	{
		var daWeek:String = formatSong(weekName + week, diff);

		setScore(daWeek, 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:String = "easy"):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
				setScore(daSong, score);
		}
		else
			setScore(daSong, score);
	}

	public static function saveRank(song:String, rank:String = "N/A", diff:String = "easy", accuracy:Float = 0):Void
	{
		var daSong:String = formatSong(song, diff);

		if(songRanks.exists(daSong))
		{
			if(accuracy > getSongAccuracy(song, diff))
			{
				setRank(daSong, rank);
				setAccuracy(daSong, accuracy);
			}
		}
		else
		{
			setRank(daSong, rank);
			setAccuracy(daSong, accuracy);
		}
	}

	public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:String = "easy", ?weekName:String = 'week'):Void
	{
		var daWeek:String = formatSong(weekName + week, diff);

		if (songScores.exists(daWeek))
		{
			if (songScores.get(daWeek) < score)
				setScore(daWeek, score);
		}
		else
			setScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);

		utilities.Options.setData(songScores, "songScores", "scores");
	}

	static function setRank(song:String, rank:String):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRanks.set(song, rank);

		utilities.Options.setData(songRanks, "songRanks", "scores");
	}

	static function setAccuracy(song:String, accuracy:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songAccuracies.set(song, accuracy);

		utilities.Options.setData(songAccuracies, "songAccuracies", "scores");
	}

	public static function formatSong(song:String, diff:String):String
	{
		var daSong:String = song.toLowerCase();

		if(diff.toLowerCase() != "normal")
			daSong += "-" + diff.toLowerCase();

		return daSong;
	}

	public static function getScore(song:String, diff:String):Int
	{
		if (!songScores.exists(formatSong(song, diff)))
			setScore(formatSong(song, diff), 0);

		return songScores.get(formatSong(song, diff));
	}

	public static function getWeekScore(week:Int, diff:String, ?weekName:String = 'week'):Int
	{
		if (!songScores.exists(formatSong(weekName + week, diff)))
			setScore(formatSong(weekName + week, diff), 0);

		return songScores.get(formatSong(weekName + week, diff));
	}

	public static function getSongRank(song:String, diff:String):String
	{
		if(!songRanks.exists(formatSong(song, diff)))
			setRank(formatSong(song, diff), "N/A");

		return songRanks.get(formatSong(song, diff));
	}

	public static function getSongAccuracy(song:String, diff:String):Float
	{
		if(!songAccuracies.exists(formatSong(song, diff)))
			setAccuracy(formatSong(song, diff), 0);

		return FlxMath.roundDecimal(songAccuracies.get(formatSong(song, diff)), 2);
	}

	public static function load():Void
	{
		if(utilities.Options.getData("songScores", "scores") != null)
			songScores = utilities.Options.getData("songScores", "scores");

		if(utilities.Options.getData("songRanks", "scores") != null)
			songRanks = utilities.Options.getData("songRanks", "scores");

		if(utilities.Options.getData("songAccuracies", "scores") != null)
			songAccuracies = utilities.Options.getData("songAccuracies", "scores");
	}
}
