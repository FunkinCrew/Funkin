package;

import Song.SwagSong;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class SongLoader
{
	public static var instance:SongLoader;

	public var songs:Array<SongMetadata>;
	public var weeks:Array<WeekMetadata>;

	public function new()
	{
		instance = this;
	}

	public function LoadSongs()
	{
		songs = [];

		var path = "assets/data/songs/";
		var folders = FileSystem.readDirectory(path);

		for (i in 0...folders.length)
		{
			var jsonPath = path + folders[i] + "/song.json";

			if (FileSystem.exists(jsonPath))
			{
				var toAdd:SongMetadata = cast Json.parse(File.getContent(jsonPath));
				toAdd.folder = folders[i];
				songs.push(toAdd);
			}
			else
			{
				trace("No song found in " + folders[i] + ", skipping...");
			}
		}
	}

	public function LoadWeeks()
	{
		weeks = [];

		// Make this something modular,
		// maybe include what week a song
		// belongs to in the song json itself
		var path:String = "assets/data/campaign.json";

		var weekJson:Array<Dynamic> = cast Json.parse(File.getContent(path));

		trace(weekJson);
	}

	public function LoadSongData(song:SongMetadata, difficulty:Int):SwagSong
	{
		var path = "assets/data/songs/" + song.folder + "/" + song.difficulties[difficulty];

		return SwagSong.loadFromJson(path);
	}

	public function GetSongByName(name:String):SongMetadata
	{
		for (i in 0...songs.length)
			if (songs[i].name == name)
				return songs[i];

		return null;
	}
}
