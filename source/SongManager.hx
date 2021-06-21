package;

import fmf.songs.*;


class SongManager
{
	public static function getCurrentSong():SongPlayer
	{
		var songPlayer:SongPlayer = null;

		switch (PlayState.CURRENT_SONG)
		{
			case 'tutorial':
				songPlayer = new Tutorial();

			case 'bopeebo' | 'fresh' | 'dadbattle':
				songPlayer = new DaddyDearest();

			case 'spookeez' | 'south':
				songPlayer = new Spookez();

			case 'monster':
				songPlayer = new Monster();

			case 'pico' | 'philly' | 'blammed':
				songPlayer = new Philly();

			case 'satin-panties' | "high" | "milf":
				songPlayer = new Mom();

			case 'cocoa' | 'eggnog':
				songPlayer = new Parents();

			case 'winter-horrorland':
				songPlayer = new WinterHorrorland();

			case 'senpai':
				songPlayer = new Senpai();

			case 'roese':
				songPlayer = new SenpaiAngry();

			case 'thorns':
				songPlayer = new SenpaiEvil();

			case 'light-it-up' | 'ruckus' | 'target-practice':
				songPlayer = new Matt();

		}

		return songPlayer;
	}

	public static function getArrow()
	{
		
	}
}