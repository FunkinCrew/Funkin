package fmf.songs;



class SongData
{
	public var weekName:String;
	public var weekCharacter:String;
	public var weekLabel:String;
	public var songList:Array<String>;

	public var copySongList(get, never):Array<String>;
	public inline function get_copySongList()
	{
		var copySongs:Array<String> = new Array<String>();

		for (song in songList)
		{
			copySongs.push(song);
		}
		return copySongs;
	}

	public var folder(get, never):String;
	public inline function get_folder()
	{
		return weekName + '/';
	}


	public function new(weekName:String, weekCharacter:String, weekLabel:String, songList:Array<String>)
	{
		this.weekName = weekName;
		this.weekCharacter = weekCharacter;
		this.songList = songList;
		this.weekLabel = weekLabel;
	}
}
