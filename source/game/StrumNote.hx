package game;

import states.PlayState;
import flixel.FlxSprite;

using StringTools;

/*
credit to psych engine devs (sorry idk who made this originally, all ik is that srperez modified it for shaggy and then i got it from there)
*/
class StrumNote extends FlxSprite
{
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;

	public var swagWidth:Float = 0;

	public function new(x:Float, y:Float, leData:Int) {
		noteData = leData;
		super(x, y);
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;

			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		//updateHitbox();
        centerOrigin();

		if(anim == "static")
			swagWidth = width;

		if(PlayState.SONG.ui_Skin != "pixel")
		{
			offset.x = frameWidth / 2;
			offset.y = frameHeight / 2;
	
			var scale = Std.parseFloat(PlayState.instance.ui_Settings[0]) * (Std.parseFloat(PlayState.instance.ui_Settings[2]) - (Std.parseFloat(PlayState.instance.mania_size[PlayState.SONG.keyCount - 1])));
	
			offset.x -= 156 * scale / 2;
			offset.y -= 156 * scale / 2;
		}
		else
			centerOffsets();
	}
}