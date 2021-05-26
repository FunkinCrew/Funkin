package;

import flixel.FlxG;
@:forward
enum abstract FCLevel(Int) from Int to Int {
	var None;
	var Sdcb;
	var Shit;
	var Bad;
	var Good;
	var Sick;
	@:op(A > B) static function _(_,_):Bool;
	@:op(A >= B) static function _(_, _):Bool;
	@:op(A < B) static function _(_, _):Bool;
	@:op(A <= B) static function _(_, _):Bool;
	@:op(A == B) static function _(_, _):Bool;
}
class Highscore
{
	public static var songScores:Map<String, Int> = new Map();
	public static var songAccuracy:Map<String, Float> = new Map();
	public static var songCompletions:Map<String, Bool> = new Map();
	public static var songFCLevels:Map<String, Int> = new Map();



	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?accuracy:Float = 0, ?combo:Bool, ?rating:FCLevel):Void
	{
		var daSong:String = formatSong(song, diff);





		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
			}
				
		}
		else {
			setScore(daSong, score);
		}
		if (songAccuracy.exists(daSong))
		{
			if (songAccuracy.get(daSong) < accuracy || (songAccuracy.get(daSong) > 100 && songAccuracy.get(daSong)/100 < accuracy))
			{
				setAccuracy(daSong, accuracy);
			}
		} else {
			setAccuracy(daSong, accuracy);
		}
		if (songCompletions.exists(daSong)) {
			if (!songCompletions.get(daSong)) {
				setComplete(daSong,combo);
			}
		} else {
			setComplete(daSong, combo);
		}
		if (songFCLevels.exists(daSong)) {
			switch (cast (songFCLevels.get(daSong) : FCLevel)) {
				case Sick:
					// nothing is better than a sick full combo...
				case Good if (rating >= Good):
					setFCLevel(daSong, rating);
				case Bad if (rating >= Bad):
					setFCLevel(daSong, rating);
				case Shit if (rating >= Shit):
					setFCLevel(daSong, rating);
				case Sdcb if (rating >= Sdcb):
					setFCLevel(daSong, rating);
				case None:
					setFCLevel(daSong, rating);
				default:
					// SUS
			}
		} else {
			setFCLevel(daSong, rating);
		}
			
	}
	public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:Int = 0, ?accuracy:Float = 0):Void
	{



		var daWeek:String = formatSong('week' + week, diff);

		if (songScores.exists(daWeek))
		{
			if (songScores.get(daWeek) < score) {
				setScore(daWeek, score);
				setAccuracy(daWeek, accuracy);
			} 
				
		}
		else {
			setScore(daWeek, score);
			setAccuracy(daWeek, accuracy);
		}
			
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
	public static function setComplete(song:String, combo:Bool) {
		songCompletions.set(song, combo);
		FlxG.save.data.songCompletions = songCompletions;
		FlxG.save.flush();
	}
	public static function setAccuracy(song:String, accuracy:Float):Void {
		songAccuracy.set(song,accuracy);
		FlxG.save.data.songAccuracy = songAccuracy;
		FlxG.save.flush();
	}
	static function setFCLevel(song:String, level:Int ):Void {
		songFCLevels.set(song, level);
		FlxG.save.data.songFCLevels = songFCLevels;
		FlxG.save.flush();
	}
	public static function formatSong(song:String, diff:Int):String
	{
		var daSong:String = song;
		daSong += DifficultyIcons.getEndingFP(diff);

		return daSong;
	}

	public static function getScore(song:String, diff:Int):Int
	{
		if (!songScores.exists(formatSong(song, diff)))
			setScore(formatSong(song, diff), 0);

		return songScores.get(formatSong(song, diff));
	}
	public static function getAccuracy(song:String, diff:Int):Float
	{
		if (!songAccuracy.exists(formatSong(song, diff)))
			setAccuracy(formatSong(song, diff), 0);

		return songAccuracy.get(formatSong(song, diff));
	}
	public static function getComplete(song:String, diff:Int):Bool {
		if (!songCompletions.exists(formatSong(song, diff)))
			setComplete(formatSong(song,diff), false);
		return songCompletions.get(formatSong(song,diff));
	}
	public static function getFCLevel(song:String, diff:Int):Int {
		if (!songFCLevels.exists(formatSong(song, diff)))
			setFCLevel(formatSong(song, diff), cast None);
		return songFCLevels.get(formatSong(song, diff));
	}
	public static function getTotalScore():Int {
		var totalScore:Int = 0;
		for (key in songScores.keys()) {
			totalScore += songScores.get(key);
		}
		return totalScore;
	}
	public static function getWeekScore(week:Int, diff:Int):Int
	{
		if (!songScores.exists(formatSong('week' + week, diff)))
			setScore(formatSong('week' + week, diff), 0);

		return songScores.get(formatSong('week' + week, diff));
	}
	public static function getWeekAccuracy(week:Int, diff:Int):Float {
		if (!songAccuracy.exists(formatSong('week' + week, diff)))
			setAccuracy(formatSong('week' + week, diff), 0);

		return songAccuracy.get(formatSong('week' + week, diff));
	}

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
			
		}
		if (FlxG.save.data.songAccuracy != null) {
			songAccuracy = FlxG.save.data.songAccuracy;
		} else {
			songAccuracy = [];
			FlxG.save.data.songAccuracy = songAccuracy;
		}
		if (FlxG.save.data.songCompletions != null) {
			songCompletions = FlxG.save.data.songCompletions;
			if (FlxG.save.data.songFCLevels == null) {
				FlxG.save.data.songFCLevels = new Map<String, Int>();
				for (thing in songCompletions.keyValueIterator()) {
					if (thing.value)
						FlxG.save.data.songFCLevels.set(thing.key, cast Shit);
					else
						FlxG.save.data.songFCLevels.set(thing.key, cast None);
				}
			}
		} else {
			songCompletions = [];
			FlxG.save.data.songCompletions = songCompletions;
			if (FlxG.save.data.songFCLevels == null)
				songFCLevels = [];
		}
		if (FlxG.save.data.songFCLevels != null) {
			songFCLevels = FlxG.save.data.songFCLevels;
		}
	}
}
