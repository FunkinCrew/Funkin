package;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(char:String = 'bf', isPlayer:Bool = false, frame:Int = 0)
	{
		super();
		loadGraphic(Paths.image('iconGrid'), true, 150, 150);

		antialiasing = true;
		
		animation.add('bf', [0,1,2], 0, false, isPlayer);
		animation.add('bf-car', [0,1,2], 0, false, isPlayer);
		animation.add('bf-christmas', [0,1,2], 0, false, isPlayer);
		animation.add('spooky', [3,4,5], 0, false, isPlayer);
		animation.add('pico', [6,7,8], 0, false, isPlayer);
		animation.add('bf-pico', [6,7,8], 0, false, isPlayer);
		animation.add('bf-pico-car', [6,7,8], 0, false, isPlayer);
		animation.add('bf-pico-christmas', [6,7,8], 0, false, isPlayer);
		animation.add('mom', [9,10,11], 0, false, isPlayer);
		animation.add('mom-car', [9,10,11], 0, false, isPlayer);
		animation.add('tankman', [12,13,14], 0, false, isPlayer);
		animation.add('bf-bloops', [15, 16, 17], 0, false, isPlayer);
		animation.add('bf-bloops-christmas', [15, 16, 17], 0, false, isPlayer);
		animation.add('bf-bloops-car', [15, 16, 17], 0, false, isPlayer);
		animation.add('dad', [18, 19, 20], 0, false, isPlayer);
		animation.add('parents-christmas', [21, 22, 23], 0, false, isPlayer);
		animation.add('monster', [24, 25, 26], 0, false, isPlayer);
		animation.add('monster-christmas', [24, 25, 26], 0, false, isPlayer);
		animation.add('senpai', [27, 28, 29], 0, false, isPlayer);
		animation.add('bf-pixel', [30, 32, 31], 0, false, isPlayer);
		animation.add('senpai-angry', [33, 34, 35], 0, false, isPlayer);
		animation.add('spirit', [36, 37, 38], 0, false, isPlayer);
		animation.add('face', [39, 40, 41], 0, false, isPlayer);
		animation.add('kiryu', [39, 40, 41], 0, false, isPlayer);
		animation.add('bf-old', [42, 43, 44], 0, false, isPlayer);
		animation.add('gf', [45, 49, 48], 0, false, isPlayer);
		animation.add('bf-milne', [50, 51, 52], 0, false, isPlayer);
		animation.add('bf-milne-car', [50, 51, 52], 0, false, isPlayer);
		animation.add('bf-milne-christmas', [50, 51, 52], 0, false, isPlayer);
		animation.add('bf-dylan', [53, 54, 55], 0, false, isPlayer);
		animation.add('bf-dylan-car', [53, 54, 55], 0, false, isPlayer);
		animation.add('bf-dylan-christmas', [53, 54, 55], 0, false, isPlayer);
		
		animation.add('bf-bsides', [60,61,62], 0, false, isPlayer);
		animation.add('bf-car-bsides', [60,61,62], 0, false, isPlayer);
		animation.add('bf-christmas-bsides', [60,61,62], 0, false, isPlayer);
		animation.add('spooky-bsides', [63,64,63], 0, false, isPlayer);
		animation.add('pico-bsides', [66,67,68], 0, false, isPlayer);
		animation.add('bf-pico-bsides', [66,67,68], 0, false, isPlayer);
		animation.add('bf-pico-car-bsides', [66,67,68], 0, false, isPlayer);
		animation.add('bf-pico-christmas-bsides', [66,67,68], 0, false, isPlayer);
		animation.add('mom-bsides', [69,70,71], 0, false, isPlayer);
		animation.add('mom-car-bsides', [69,70,71], 0, false, isPlayer);
		animation.add('tankman-bsides', [72,73,74], 0, false, isPlayer);
		animation.add('bf-bloops-bsides', [75, 76, 77], 0, false, isPlayer);
		animation.add('bf-bloops-christmas-bsides', [75, 76, 77], 0, false, isPlayer);
		animation.add('bf-bloops-car-bsides', [75, 76, 77], 0, false, isPlayer);
		animation.add('dad-bsides', [78, 79, 80], 0, false, isPlayer);
		animation.add('parents-christmas-bsides', [81, 82, 83], 0, false, isPlayer);
		animation.add('monster-bsides', [84, 85, 86], 0, false, isPlayer);
		animation.add('monster-christmas-bsides', [84, 85, 86], 0, false, isPlayer);
		animation.add('senpai-bsides', [87, 88, 89], 0, false, isPlayer);
		animation.add('bf-pixel-bsides', [90, 91, 92], 0, false, isPlayer);
		animation.add('senpai-angry-bsides', [93, 94, 95], 0, false, isPlayer);
		animation.add('spirit-bsides', [96, 97, 98], 0, false, isPlayer);
		animation.add('face-bsides', [99, 100, 101], 0, false, isPlayer);
		animation.add('bf-old-bsides', [102, 103, 104], 0, false, isPlayer);
		animation.add('gf-bsides', [105, 109, 108], 0, false, isPlayer);
		animation.add('bf-dylan-bsides', [113, 114, 115], 0, false, isPlayer);
		animation.add('bf-dylan-car-bsides', [113, 114, 115], 0, false, isPlayer);
		animation.add('bf-dylan-christmas-bsides', [113, 114, 115], 0, false, isPlayer);
		
		animation.play(char);
		scrollFactor.set();
		animation.curAnim.curFrame = frame;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
