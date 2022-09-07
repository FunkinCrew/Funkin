package funkin.play.song;

import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.SongData.SongMetadata;

/**
 * This is a data structure managing information about the current song.
 * This structure is created when the game starts, and includes all the data
 * from the `metadata.json` file.
 * It also includes the chart data, but only when this is the currently loaded song.
 *
 * It also receives script events; scripted classes which extend this class
 * can be used to perform custom gameplay behaviors only on specific songs.
 */
class Song // implements IPlayStateScriptedClass
{
	public var songId(default, null):String;

	public var songName(get, null):String;

	final _metadata:SongMetadata;

	// final _chartData:SongChartData;

	public function new(id:String)
	{
		this.songId = id;

		_metadata = SongDataParser.parseSongMetadata(songId);
		if (_metadata == null)
		{
			throw 'Could not find song data for songId: $songId';
		}
	}

	function get_songName():String
	{
		if (_metadata == null)
			return null;
		return _metadata.name;
	}

	public function toString():String
	{
		return 'Song($songId)';
	}
}
