package fmf;

import Song.SwagSong;

class DaddyDearest extends SongPlayer
{

    override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('vanilla/DADDY_DEAREST');
		dad.frames = tex;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;
		animation.addByPrefix('idle', 'Dad idle dance', 24);
		animation.addByPrefix('singUP', 'Dad Sing Note UP', 24);
		animation.addByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24);
		animation.addByPrefix('singDOWN', 'Dad Sing Note DOWN', 24);
		animation.addByPrefix('singLEFT', 'Dad Sing Note LEFT', 24);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", -6, 50);
		dad.addOffset("singRIGHT", 0, 27);
		dad.addOffset("singLEFT", -10, 10);
		dad.addOffset("singDOWN", 0, -30);
	}

	override function createDad()
	{
        dad = new Dad(0, 125);
		getDadTex();
		createDadAnimations();
		createDadAnimationOffsets();
		dad.dance();
    }

        
	override function midSongEventUpdate(curBeat:Int):Void
	{
		if (PlayState.CURRENT_SONG == "bopeebo")
		{
			if (curBeat > 5 && curBeat < 130)
			{
				if (curBeat % 8 == 7)
				{
					gf.playAnim('cheer');
                    gf.lockAnim(0.5);
				}
			}

			if (curBeat % 8 == 7)
			{
				bf.playAnim('hey', true);
                bf.lockAnim(0.5);
			}

			switch (curBeat)
			{
				case 128, 129, 130:
					playState.vocals.volume = 0;
			}		
        }
	}
}