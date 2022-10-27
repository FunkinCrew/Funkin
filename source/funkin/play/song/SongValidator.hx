package funkin.play.song;

import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongMetadata;
import funkin.play.song.SongData.SongPlayData;
import funkin.play.song.SongData.SongTimeChange;
import funkin.play.song.SongData.SongTimeFormat;
import funkin.util.Constants;

/**
 * For SongMetadata and SongChartData objects,
 * ensures mandatory fields are present and populates optional fields with default values.
 */
class SongValidator
{
	public static final DEFAULT_SONGNAME:String = "Unknown";
	public static final DEFAULT_ARTIST:String = "Unknown";
	public static final DEFAULT_TIMEFORMAT:SongTimeFormat = SongTimeFormat.MILLISECONDS;
	public static final DEFAULT_DIVISIONS:Int = -1;
	public static final DEFAULT_LOOP:Bool = false;
	public static final DEFAULT_STAGE:String = "mainStage";
	public static final DEFAULT_SCROLLSPEED:Float = 1.0;

	public static var DEFAULT_GENERATEDBY(get, null):String;

	static function get_DEFAULT_GENERATEDBY():String
	{
		return '${Constants.TITLE} - ${Constants.VERSION}';
	}

	/**
	 * Validates the fields of a SongMetadata object (excluding the version field).
	 * 
	 * @param input The SongMetadata object to validate.
	 * @param songId The ID of the song being validated. Only used for error messages.
	 * @return The validated SongMetadata object.
	 */
	public static function validateSongMetadata(input:SongMetadata, songId:String = 'unknown'):SongMetadata
	{
		if (input == null)
		{
			trace('[SONGDATA] Could not parse metadata for song ${songId}');
			return null;
		}

		if (input.songName == null)
		{
			trace('[SONGDATA] Song ${songId} is missing a songName field. ');
			input.songName = DEFAULT_SONGNAME;
		}
		if (input.artist == null)
		{
			trace('[SONGDATA] Song ${songId} is missing an artist field. ');
			input.artist = DEFAULT_ARTIST;
		}
		if (input.timeFormat == null)
		{
			trace('[SONGDATA] Song ${songId} is missing a timeFormat field. ');
			input.timeFormat = DEFAULT_TIMEFORMAT;
		}
		if (input.generatedBy == null)
		{
			input.generatedBy = DEFAULT_GENERATEDBY;
		}

		input.timeChanges = validateTimeChanges(input.timeChanges, songId);
		input.playData = validatePlayData(input.playData, songId);

		input.variation = '';

		return input;
	}

	/**
	 * Validates the fields of a SongPlayData object.
	 * 
	 * @param input The SongPlayData object to validate.
	 * @param songId The ID of the song being validated. Only used for error messages.
	 * @return The validated SongPlayData object.
	 */
	public static function validatePlayData(input:SongPlayData, songId:String = 'unknown'):SongPlayData
	{
		return input;
	}

	/**
	 * Validates the fields of a TimeChange object.
	 * 
	 * @param input The TimeChange object to validate.
	 * @param songId The ID of the song being validated. Only used for error messages.
	 * @return The validated TimeChange object.
	 */
	public static function validateTimeChange(input:SongTimeChange, songId:String = 'unknown'):SongTimeChange
	{
		return input;
	}

	/**
	 * Validates multiple TimeChange objects in an array.
	 */
	public static function validateTimeChanges(input:Array<SongTimeChange>, songId:String = 'unknown'):Array<SongTimeChange>
	{
		if (input == null)
		{
			trace('[SONGDATA] Song ${songId} is missing a timeChanges field. ');
			return [];
		}

		input = input.map((timeChange) -> validateTimeChange(timeChange, songId));

		return input;
	}

	/**
	 * Validates the fields of a SongChartData object (excluding the version field).
	 * 
	 * @param input The SongChartData object to validate.
	 * @param songId The ID of the song being validated. Only used for error messages.
	 * @return The validated SongChartData object.
	 */
	public static function validateSongChartData(input:SongChartData, songId:String = 'unknown'):SongChartData
	{
		if (input == null)
		{
			trace('[SONGDATA] Could not parse chart data for song ${songId}');
			return null;
		}

		return input;
	}
}
