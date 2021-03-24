package;

import flixel.FlxG;

class Highscore
{
	#if (haxe >= "4.0.0")
	public static var songScores:Map<String, Int> = new Map();
	#else
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	#end


	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var formattedSong:String = formatSong(song, diff);

		#if newgrounds
		NGio.postScore(score, song);
		#end

		if (songScores.exists(formattedSong))
		{
			if (songScores.get(formattedSong) < score)
				setScore(formattedSong, score);
		}
		else
			setScore(formattedSong, score);
	}

	public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:Int = 0):Void
	{
		#if newgrounds
		NGio.postScore(score, "Week " + week);
		#end

		var formattedSong:String = formatSong('week' + week, diff);

		if (songScores.exists(formattedSong))
		{
			if (songScores.get(formattedSong) < score)
				setScore(formattedSong, score);
		}
		else
			setScore(formattedSong, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(formattedSong:String, score:Int):Void
	{
		/** GeoKureli
		 * References to Highscore were wrapped in `#if !switch` blocks. I wasn't sure if this
		 * is because switch doesn't use NGio, or because switch has a different saving method.
		 * I moved the compiler flag here, rather than using it everywhere else.
		 */
		#if !switch
		
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(formattedSong, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
		#end
	}

	public static function formatSong(song:String, diff:Int):String
	{
		var daSong:String = song;

		if (diff == 0)
			daSong += '-easy';
		else if (diff == 2)
			daSong += '-hard';

		return daSong;
	}

	public static function getScore(song:String, diff:Int):Int
	{
		if (!songScores.exists(formatSong(song, diff)))
			setScore(formatSong(song, diff), 0);

		return songScores.get(formatSong(song, diff));
	}

	public static function getWeekScore(week:Int, diff:Int):Int
	{
		if (!songScores.exists(formatSong('week' + week, diff)))
			setScore(formatSong('week' + week, diff), 0);

		return songScores.get(formatSong('week' + week, diff));
	}

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
	}
}
