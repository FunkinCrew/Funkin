package;

import Song.SwagSong;
import haxe.Json;
import haxe.io.Path;
import lime.tools.AssetType;
import lime.utils.Assets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

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

		#if web
		var textFiles:Array<String> = Assets.list(lime.utils.AssetType.TEXT);

		var detectedSongs:Array<String> = [];
		for (file in textFiles)
		{
			if (file.startsWith("songs/"))
			{
				var dir = Path.withoutDirectory(new Path(file).dir);
				if (dir != "songs")
					if (!detectedSongs.contains(dir))
						detectedSongs.push(dir);
			}
		}

		for (song in detectedSongs)
		{
			var metaPath = 'songs/$song/song.json';
			trace(metaPath);

			if (Assets.exists(metaPath))
				songs.push(LoadMetadata(metaPath, song));
			else
				trace('No metadata found for $song, skipping...');
		}
		#else
		var path = "./songs/";
		var folders = FileSystem.readDirectory(path);

		for (i in 0...folders.length)
		{
			var jsonPath = path + folders[i] + "/song.json";

			if (FileSystem.exists(jsonPath))
			{
				trace(folders[i]);
				var toAdd = LoadMetadata(jsonPath, folders[i]);

				songs.push(toAdd);
			}
			else
			{
				trace("No song found in " + folders[i] + ", skipping...");
			}
		}
		#end
	}

	public static function LoadMetadata(path:String, ?rootFolder:String):SongMetadata
	{
		#if web
		var songDynamic:Dynamic = Json.parse(Assets.getText(path));
		var songDir = rootFolder;
		#else
		var songDynamic:Dynamic = Json.parse(File.getContent(path));
		var songDir = Path.withoutDirectory(new Path(path).dir);
		if (!FileSystem.exists(Path.join([songDir, "song.json"])))
			songDir = rootFolder;
		#end
		// Shut up i like nicely named Json fields
		var toReturn:SongMetadata = {
			folder: songDir,
			name: songDynamic.Name,
			instrumental: songDynamic.Instrumental,
			voices: songDynamic.Voices,
			difficulties: songDynamic.Difficulties
		}

		return toReturn;
	}

	public function LoadWeeks()
	{
		weeks = [];

		// Make this something modular,
		// maybe include what week a song
		// belongs to in the song json itself
		var jsonContent = Assets.getText("assets/data/campaign.json");
		/*
			var path:String = "assets/data/campaign.json";

			var weekJson:Dynamic = Json.parse(File.getContent(path));
		 */

		var weekJson:Dynamic = Json.parse(jsonContent);
		var weekIterator:Array<Dynamic> = cast weekJson;

		for (weekData in weekIterator)
		{
			var songList:Array<SongMetadata> = [];
			var songIterator:Array<String> = cast weekData.Songs;
			for (song in songIterator)
			{
				var toAdd:SongMetadata = GetSongByName(song);
				if (toAdd != null)
					songList.push(toAdd);
			}
			var week:WeekMetadata = {
				name: weekData.Name,
				characters: weekData.Characters,
				songs: songList
			}
			weeks.push(week);
		}
	}

	public function LoadSongData(song:SongMetadata, difficulty:Int):SwagSong
	{
		if (difficulty > song.difficulties.length || difficulty < 0)
			return null;

		var path = "songs/" + song.folder + "/" + song.difficulties[difficulty];

		#if !web
		if (!FileSystem.exists(path) || song.difficulties[difficulty] == "")
			return null;
		#end

		return SwagSong.loadFromJson(path, song);
	}

	public function GetSongByName(name:String):SongMetadata
	{
		for (i in 0...songs.length)
			if (songs[i].name == name)
				return songs[i];

		return null;
	}

	public function GetSongByFolder(folder:String):SongMetadata
	{
		for (i in 0...songs.length)
			if (songs[i].folder == folder)
				return songs[i];

		return null;
	}
}
