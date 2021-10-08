package game;

import utilities.Ratings;
import flixel.FlxG;

class Highscore
{
	#if (haxe >= "4.0.0")
	public static var songScores:Map<String, Int> = new Map();
	public static var songRanks:Map<String, String> = new Map();
	#else
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRanks:Map<String, String> = new Map<String, String>();
	#end

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

	public static function saveRank(song:String, rank:String = "N/A", ?diff:String = "easy"):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songRanks.exists(daSong))
		{
			if (Ratings.rankToInt(Ratings.stringToRank(songRanks.get(daSong))) > Ratings.rankToInt(Ratings.stringToRank(rank)))
				setRank(daSong, rank);
		}
		else
			setRank(daSong, rank);
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
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function setRank(song:String, rank:String):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRanks.set(song, rank);
		FlxG.save.data.songRanks = songRanks;
		FlxG.save.flush();
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

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;
		
		if (FlxG.save.data.songRanks != null)
			songRanks = FlxG.save.data.songRanks;
	}
}
