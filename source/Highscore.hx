package;

import flixel.FlxG;

class Highscore
{
	public static var songScores = new Map<String, Int>();


	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);


		#if !switch
		NGio.postScore(score, song);
		#end


		if (songScores.exists(daSong))
		{
			if (songScores[daSong] < score)
				setScore(daSong, score);
		}
		else
			setScore(daSong, score);
	}

	public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:Int = 0):Void
	{

		#if !switch
		NGio.postScore(score, "Week " + week);
		#end


		var daWeek:String = formatSong('week' + week, diff);

		if (songScores.exists(daWeek))
		{
			if (songScores[daWeek] < score)
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
		songScores[song] = score;
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return switch (song)
		{
			case 0: '$song-easy';
			case 2: '$song-hard';
			default: song;
		};
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var daSong = formatSong(song, diff);
		
		if (!songScores.exists(daSong))
			setScore(daSong, 0);

		return songScores[daSong];
	}

	public static function getWeekScore(week:Int, diff:Int):Int
	{
		var daSong = formatSong('week$week', diff);
		
		if (!songScores.exists(daSong))
			setScore(daSong, 0);

		return songScores[daSong];
	}

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
	}
}
