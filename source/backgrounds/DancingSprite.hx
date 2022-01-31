package backgrounds;

import utilities.CoolUtil;
import flixel.FlxSprite;

class DancingSprite extends FlxSprite
{
    var dancingRight:Bool = false;
    var oneDanceAnimation:Bool = false;

    public function new(x:Float, y:Float, ?oneDanceAnimation:Bool = false, ?antialiasing:Bool = true)
    {
        super(x, y);

        this.antialiasing = antialiasing;
        this.oneDanceAnimation = oneDanceAnimation;
    }

    public function dance(?altAnim:String = ''):Void
    {
        if(!oneDanceAnimation)
        {
            dancingRight = !dancingRight;

            if(dancingRight)
                animation.play('danceRight' + altAnim, true);
            else
                animation.play('danceLeft' + altAnim, true);
        }
        else
            animation.play('dance' + altAnim, true);
    }
}

class BackgroundDancer extends DancingSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas("limo/limoDancer", "stages");
		animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

		animation.play('danceLeft');
	}
}

class BackgroundGirls extends DancingSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y, false, false);

		// BG fangirls dissuaded
		frames = Paths.getSparrowAtlas('school/bgFreaks', "stages");

		animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);

		animation.play('danceLeft');
	}

	public function getScared():Void
	{
		animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);

		dance();
	}
}
