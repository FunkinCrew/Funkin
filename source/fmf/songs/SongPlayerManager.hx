package fmf.songs;


//this class will handle which SongPlayer should be play
class SongPlayerManager
{
	public static function getCurrentSong(songName:String):SongPlayer
	{
		var songPlayer:SongPlayer = new Tutorial('gf');

		switch (songName.toLowerCase())
		{
			case 'tutorial':
				songPlayer = new Tutorial('gf');

			case 'bopeebo' | 'fresh' | 'dadbattle' | 'dad battle' | 'dad-battle':
				songPlayer = new DaddyDearest("dad");

			case 'spookeez' | 'south':
				songPlayer = new Spookez("spooky");

			case 'monster':
				songPlayer = new Monster("monster");

			case 'pico' | 'philly' | 'blammed' | 'philly nice' |  'philly-nice' | 'phillynice':
				songPlayer = new Philly("pico");

			case 'satin-panties' | "high" | "milf"  | 'satin panties' | 'satinpanties':
				songPlayer = new Mom("mom");

			case 'cocoa' | 'eggnog':
				songPlayer = new Parents("parents");

			case 'winter-horrorland' | 'winter horrorland' | 'winterhorrorland':
				songPlayer = new WinterHorrorland("monster-christmas");

			case 'senpai':
				songPlayer = new Senpai("school");

			case 'roses':
				songPlayer = new SenpaiAngry("school");

			case 'thorns':
				songPlayer = new SenpaiEvil("school");

			case 'light-it-up' | 'ruckus' | 'target-practice':
				songPlayer = new Matt("matt");

		}

		return songPlayer;
	}

}