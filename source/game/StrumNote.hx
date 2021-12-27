package game;

import utilities.NoteVariables;
import shaders.ColorSwap;
import shaders.NoteColors;
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

	public var modAngle:Float = 0;

	public var colorSwap:ColorSwap;

	var noteColor:Array<Int> = [0,0,0];

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

		noteColor = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[keyCount - 1][noteData]);

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		colorSwap.hue = noteColor[0] / 360;
		colorSwap.saturation = noteColor[1] / 100;
		colorSwap.brightness = noteColor[2] / 100;
	}

	override function update(elapsed:Float) {
		angle = modAngle;
		
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
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;

			swagWidth = width;
		}
		else
		{
			colorSwap.hue = noteColor[0] / 360;
			colorSwap.saturation = noteColor[1] / 100;
			colorSwap.brightness = noteColor[2] / 100;
		}

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