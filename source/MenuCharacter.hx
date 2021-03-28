package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class MenuCharacter extends FlxSprite
{
	public var character:String;

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		this.character = character;

		var tex = Paths.getSparrowAtlas('campaign_menu_UI_characters');
		frames = tex;

		animation.addByPrefix('bf', "BF Idle dance white", 24);
		animation.addByPrefix('bfConfirm', 'BF HEY!!', 24, false);
		animation.addByPrefix('gf', "GF Dancing Beat WHITE", 24);
		animation.addByPrefix('dad', "Dad Idle dance BLACK LINE", 24);
		animation.addByPrefix('spooky', "spooky dance Idle BLACK LINES", 24);
		animation.addByPrefix('pico', "Pico Idle Dance", 24);
		animation.addByPrefix('mom', "Mom Idle BLACK LINES", 24);
		animation.addByPrefix('parents-christmas', "Parent-Christmas Idle", 24);
		animation.addByPrefix('senpai', "SENPAI Idle BLACK Lines", 24);
		animation.addByPrefix('cye', "Cye Idle", 24);
		// Parent Christmas Idle

		animation.play(character);
		updateHitbox();
	}
}
