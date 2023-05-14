package game.ui.gameplay.note;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import game.state.PlayState;

class StaticNote extends FlxSprite
{
	public var animReset:Float = 0;

    public function new(x:Float, y:Float, data:Int, player:Int)
    {
        super(x, y);
        loadStaticArrow(data);
        scrollFactor.set();
    }

    function loadStaticArrow(data:Int)
    {
        if (PlayState.isPixel)
		{
			loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purplel', [4]);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			updateHitbox();
			antialiasing = false;

			switch (Math.abs(data) % 4)
			{
				case 0:
					x += Note.swagWidth * 0;
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					x += Note.swagWidth * 1;
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					x += Note.swagWidth * 2;
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					x += Note.swagWidth * 3;
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas('NOTE_assets');
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = true;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(data) % 4)
			{
				case 0:
					x += Note.swagWidth * 0;
					animation.addByPrefix('static', 'arrow static instance 1');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					x += Note.swagWidth * 1;
					animation.addByPrefix('static', 'arrow static instance 2');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					x += Note.swagWidth * 2;
					animation.addByPrefix('static', 'arrow static instance 4');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					x += Note.swagWidth * 3;
					animation.addByPrefix('static', 'arrow static instance 3');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();
        playStrumAnim('static', true);
    }

	override function update(elapsed:Float)
	{
		if (animReset > 0) {
			animReset -= elapsed;
			if (animReset <= 0) {
				playStrumAnim('static', true);
				animReset = 0;
			}
		}
		super.update(elapsed);
	}

    public function playStrumAnim(anim:String, ?forced:Bool = false):Void
    {
        animation.play(anim, forced);

        if (anim == 'confirm' && !PlayState.isPixel)
        {
            centerOffsets();
            offset.x -= 13;
            offset.y -= 13;
        }
        else
            centerOffsets();
    }
}