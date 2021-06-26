package fmf.songs;


//this class will handle which SongPlayer should be play
class SongPlayerManager
{
	public static function getCurrentSong(songName:String):SongPlayer
	{
		var songPlayer:SongPlayer = new Tutorial();

		switch (songName.toLowerCase())
		{
			case 'tutorial':
				songPlayer = new Tutorial();

			case 'bopeebo' | 'fresh' | 'dadbattle' | 'dad battle' | 'dad-battle':
				songPlayer = new DaddyDearest();

			case 'spookeez' | 'south':
				songPlayer = new Spookez();

			case 'monster':
				songPlayer = new Monster();

			case 'pico' | 'philly' | 'blammed' | 'philly nice' |  'philly-nice' | 'phillynice':
				songPlayer = new Philly();

			case 'satin-panties' | "high" | "milf"  | 'satin panties' | 'satinpanties':
				songPlayer = new Mom();

			case 'cocoa' | 'eggnog':
				songPlayer = new Parents();

			case 'winter-horrorland' | 'winter horrorland' | 'winterhorrorland':
				songPlayer = new WinterHorrorland();

			case 'senpai':
				songPlayer = new Senpai();

			case 'roses':
				songPlayer = new SenpaiAngry();

			case 'thorns':
				songPlayer = new SenpaiEvil();

			case 'light-it-up' | 'ruckus' | 'target-practice':
				songPlayer = new Matt();

		}

		return songPlayer;
	}
}