package funkin.play.song;

import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongMetadata;
import funkin.util.VersionUtil;

class SongMigrator
{
	/**
	 * The current latest version string for the song data format.
	 * Handle breaking changes by incrementing this value
	 * and adding migration to the SongMigrator class.
	 */
	public static final CHART_VERSION:String = "2.0.0";

	public static final CHART_VERSION_RULE:String = "2.0.x";

	public static function migrateSongMetadata(jsonData:Dynamic, songId:String):SongMetadata
	{
		if (jsonData.version)
		{
			if (VersionUtil.validateVersion(jsonData.version, CHART_VERSION_RULE))
			{
				trace('[SONGDATA] Song (${songId}) metadata version (${jsonData.version}) is valid and up-to-date.');

				var songMetadata:SongMetadata = cast jsonData;

				return songMetadata;
			}
			else
			{
				trace('[SONGDATA] Song (${songId}) metadata version (${jsonData.version}) is outdated.');
				switch (jsonData.version)
				{
					// TODO: Add migration functions as cases here.
					default:
						// Unknown version.
						trace('[SONGDATA] Song (${songId}) unknown metadata version: ${jsonData.version}');
				}
			}
		}
		else
		{
			trace('[SONGDATA] Song metadata version is missing.');
		}
		return null;
	}

	public static function migrateSongChartData(jsonData:Dynamic, songId:String):SongChartData
	{
		if (jsonData.version)
		{
			if (VersionUtil.validateVersion(jsonData.version, CHART_VERSION_RULE))
			{
				trace('[SONGDATA] Song (${songId}) chart version (${jsonData.version}) is valid and up-to-date.');

				var songMetadata:SongMetadata = cast jsonData;

				return songMetadata;
			}
			else
			{
				trace('[SONGDATA] Song (${songId}) chart version (${jsonData.version}) is outdated.');
				switch (jsonData.version)
				{
					// TODO: Add migration functions as cases here.
					default:
						// Unknown version.
						trace('[SONGDATA] Song (${songId}) unknown chart version: ${jsonData.version}');
				}
			}
		}
		else
		{
			trace('[SONGDATA] Song chart version is missing.');
		}
		return null;
	}
}
