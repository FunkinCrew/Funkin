package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class NoteSplash extends FlxSprite
{
	public static var colors:Array<String> = ['purple', 'blue', 'green', 'red'];

	var colorsThatDontChange:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function new(nX:Float, nY:Float, color:Int)
	{
		x = nX;
		y = nY;
		super(x, y);

		switch (PlayState.SONG.noteskin){
			default:
				frames = Paths.getSparrowAtlas('noteSplashes', 'shared');
			case 'pixel':
				frames = Paths.getSparrowAtlas('weeb/pixelUI/noteSplashes', 'week6');
		}

		for (i in 0...colorsThatDontChange.length)
		{
			animation.addByPrefix('splash 0 ' + colorsThatDontChange[i], 'note impact 1 ' + colorsThatDontChange[i], 24, false);
			animation.addByPrefix('splash 1 ' + colorsThatDontChange[i], 'note impact 2 ' + colorsThatDontChange[i], 24, false);
		}
		//animation.play('splash');
		antialiasing = true;
		updateHitbox();
        

        makeSplash(nX, nY, color);

	}

	public function makeSplash(nX:Float, nY:Float, color:Int) 
	{
        switch (PlayState.SONG.noteskin){
            default:
                setPosition(nX - 76, nY - 76); //offsets for the splash except i cant make it perfect sadly
                angle = FlxG.random.int(0, 360);
                alpha = 0.6;
            case 'pixel':
				setPosition(nX - 104, nY - 108);
				alpha = 0.6;
        }
        animation.play('splash ${FlxG.random.int(0,1)} ${colors[color]}', true);
		//animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
    	//offset.set(90, 80);
        updateHitbox();
    }

	override public function update(elapsed) 
	{
        if (animation.curAnim.finished) {
            kill();
        }

        super.update(elapsed);
    }

}