package fmf.songs;

import MenuCharacter.CharacterSetting;
import fmf.characters.*;

class DaddyDearest extends SongPlayer
{

    override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('DADDY_DEAREST', 'week1');
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
		dad.dance();

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
		if (playState.gfStep())
		{
			if (PlayState.CURRENT_SONG == "bopeebo")
			{
				switch (PlayState.CURRENT_SONG)
				{
					case 'bopeebo':
						bopeebooMidSongEvent(curBeat);

					case 'fresh':
						freshMidSongEvent(curBeat);
				}
			}
		}
	}

	function bopeebooMidSongEvent(curBeat:Int)
	{
		if (curBeat > 5 && curBeat < 130)
		{
			if (curBeat % 8 == 7)
			{
				gf.playAnimForce('cheer', 0.5);
			}
		}

		if (curBeat % 8 == 7)
		{
			bf.playAnimForce('hey', 0.5);
		}

		switch (curBeat)
		{
			case 128, 129, 130:
				playState.vocals.volume = 0;
		}
	}

	function freshMidSongEvent(curBeat:Int)
	{
		switch (curBeat)
		{
			case 16:
				playState.camZooming = true;
				playState.gfSpeed = 2;

			case 48:
				playState.gfSpeed = 1;

			case 80:
				playState.gfSpeed = 2;
				
			case 112:
				playState.gfSpeed = 1;
		}
	}

	public override function getDadIcon(icon:HealthIcon)
	{
		icon.loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		icon.animation.add('dad', [17, 18], 0, false, false);
		icon.animation.play("dad");
	}

	public override function setDadMenuCharacter(dad:MenuCharacter)
	{
		super.setDadMenuCharacter(dad);

		var frames = Paths.getSparrowAtlas('menucharacter/dad');
		dad.frames = frames;

		dad.animation.addByPrefix('dad', "Dad idle dance BLACK LINE", 24);
		dad.animation.play('dad');
		setMenuCharacter(dad, new CharacterSetting(-15, 230, 0.45));
	}
}