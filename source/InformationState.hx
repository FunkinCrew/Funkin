package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class InformationState extends MusicBeatState
{
	var logoBl:FlxSprite;
	var credits:String =	'SpunBlue - Programmer\n'+
							'Swaggus - Made the Remixes\n'+
							'thepercentageguy - Created the Original Version of this Engine\n';
	
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('stageback', 'shared'));
		bg.screenCenter();
		add(bg);

		logoBl = new FlxSprite(0, -64);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.screenCenter(X);
		logoBl.updateHitbox();
		add(logoBl);

		var tint:FlxSprite = new FlxSprite().makeGraphic(1280, 720, FlxColor.CYAN);
		tint.alpha = 0.3;
		add(tint);
		
		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"FNFSL Engine Credits\n" + credits + '\n\nPress Space or Escape to Exit',32);
		
		txt.setFormat("PhantomMuff 1.5", 32, FlxColor.WHITE, CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT)
		{
			FlxG.switchState(new optionshit.OptionsMenu());
		}
		if (controls.BACK)
		{
			FlxG.switchState(new optionshit.OptionsMenu());
		}
		super.update(elapsed);
	}

	override function beatHit()
		{
			super.beatHit();
	
			logoBl.animation.play('bump');
		}
}
