package;

import Judge.Jury;
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
	public static var songJudge:Map<String, Int> = new Map();


	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?accuracy:Float = 0, ?rating:FCLevel, ?judge:Jury):Void
	{
		var daSong:String = formatSong(song, diff, "best-score");
		var recentSong:String = formatSong(song, diff, "recent");
		var bestAccuracy:String = formatSong(song, diff, "best-accuracy");
		var bestFC:String = formatSong(song, diff, "best-fullcombo");
		var bestOfAll:String = formatSong(song,diff,"best");

		setScore(recentSong, score);
		setAccuracy(recentSong, accuracy);
		setFCLevel(recentSong, rating);
		setJudge(recentSong, judge);
		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				setAccuracy(daSong, accuracy);
				setFCLevel(daSong, rating);
				setJudge(daSong,judge);
				setScore(bestOfAll, score);
			}
		} else {
			setScore(daSong, score);
			setAccuracy(daSong, accuracy);
			setFCLevel(daSong, rating);
			setJudge(daSong, judge);
			setScore(bestOfAll, score);
		}
		if (songAccuracy.exists(bestAccuracy)) {
			if (songAccuracy.get(bestAccuracy) < accuracy) {
				setScore(bestAccuracy, score);
				setAccuracy(bestAccuracy, accuracy);
				setFCLevel(bestAccuracy, rating);
				setJudge(bestAccuracy, judge);
				setAccuracy(bestOfAll, accuracy);
			}
		} else {
			setScore(bestAccuracy, score);
			setAccuracy(bestAccuracy, accuracy);
			setFCLevel(bestAccuracy, rating);
			setJudge(bestAccuracy, judge);
			setAccuracy(bestOfAll, accuracy);
		}
		
		if (songFCLevels.exists(bestFC)) {
			if (songFCLevels.get(bestFC) <= rating) {
				setScore(bestFC, score);
				setAccuracy(bestFC, accuracy);
				setFCLevel(bestFC, rating);
				setJudge(bestFC, judge);
				setFCLevel(bestOfAll, rating);
			}
		}
		
		
			
	}
	public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:Int = 0, ?accuracy:Float = 0, saving:String = "best"):Void
	{



		var daWeek:String = formatSong('week' + week, diff, saving);

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
	static function setJudge(song:String, judge:Int):Void
	{
		songJudge.set(song, judge);
		FlxG.save.data.songJudge = songJudge;
		FlxG.save.flush();
	}
	public static function formatSong(song:String, diff:Int, saving:String):String
	{
		// saving is just an extra thing
		// so like "recent"
		// "best-score"
		// "best-accuracy"
		var daSong:String = song;
		daSong += DifficultyIcons.getEndingFP(diff);
		if (saving != "best")
			daSong += "-" + saving;
		return daSong;
	}

	public static function getScore(song:String, diff:Int, useFor:String = "best"):Int
	{
		if (!songScores.exists(formatSong(song, diff, useFor)))
			setScore(formatSong(song, diff, useFor), 0);

		return songScores.get(formatSong(song, diff, useFor));
	}
	public static function getAccuracy(song:String, diff:Int, useFor:String = "best"):Float
	{
		if (!songAccuracy.exists(formatSong(song, diff, useFor)))
			setAccuracy(formatSong(song, diff, useFor), 0);

		return songAccuracy.get(formatSong(song, diff, useFor));
	}
	public static function getComplete(song:String, diff:Int, useFor:String = "best"):Bool {
		if (!songCompletions.exists(formatSong(song, diff, useFor)))
			setComplete(formatSong(song,diff, useFor), false);
		return songCompletions.get(formatSong(song,diff, useFor));
	}
	public static function getFCLevel(song:String, diff:Int, useFor:String):Int {
		if (!songFCLevels.exists(formatSong(song, diff, useFor)))
			setFCLevel(formatSong(song, diff, useFor), cast None);
		return songFCLevels.get(formatSong(song, diff, useFor));
	}
	public static function getJudge(song:String, diff:Int, useFor:String):Int
	{
		if (!songJudge.exists(formatSong(song, diff, useFor)))
			setJudge(formatSong(song, diff, useFor), cast Classic);
		return songJudge.get(formatSong(song, diff, useFor));
	}

	public static function getTotalScore():Int {
		var totalScore:Int = 0;
		for (key in songScores.keys()) {
			totalScore += songScores.get(key);
		}
		return totalScore;
	}
	public static function getWeekScore(week:Int, diff:Int, useFor:String = "best"):Int
	{
		if (!songScores.exists(formatSong('week' + week, diff, useFor)))
			setScore(formatSong('week' + week, diff, useFor), 0);

		return songScores.get(formatSong('week' + week, diff, useFor));
	}
	public static function getWeekAccuracy(week:Int, diff:Int, useFor:String = "best"):Float {
		if (!songAccuracy.exists(formatSong('week' + week, diff, useFor)))
			setAccuracy(formatSong('week' + week, diff, useFor), 0);

		return songAccuracy.get(formatSong('week' + week, diff, useFor));
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

		if (FlxG.save.data.songFCLevels != null) {
			songFCLevels = FlxG.save.data.songFCLevels;
		} else {
			songFCLevels = [];
		}
		if (FlxG.save.data.songJudge != null) {
			songJudge = FlxG.save.data.songJudge;
		} else {
			songJudge = [];
		}
	}
}
