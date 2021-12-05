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

	public var ui_Skin:String = "default";
	public var ui_Settings:Array<String>;
	public var mania_size:Array<String>;
	public var keyCount:Int;

	public function new(x:Float, y:Float, leData:Int, ?ui_Skin:String, ?ui_Settings:Array<String>, ?mania_size:Array<String>, ?keyCount:Int) {
		if(ui_Skin == null)
			ui_Skin = PlayState.SONG.ui_Skin;

		if(ui_Settings == null)
			ui_Settings = PlayState.instance.ui_Settings;

		if(mania_size == null)
			mania_size = PlayState.instance.mania_size;

		if(keyCount == null)
			keyCount = PlayState.SONG.keyCount;

		noteData = leData;

		this.ui_Skin = ui_Skin;
		this.ui_Settings = ui_Settings;
		this.mania_size = mania_size;
		this.keyCount = keyCount;

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

		if(ui_Skin != "pixel")
		{
			offset.x = frameWidth / 2;
			offset.y = frameHeight / 2;
	
			var scale = Std.parseFloat(ui_Settings[0]) * (Std.parseFloat(ui_Settings[2]) - (Std.parseFloat(mania_size[keyCount - 1])));
	
			offset.x -= 156 * scale / 2;
			offset.y -= 156 * scale / 2;
		}
		else
			centerOffsets();
	}
}