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

		animation.addByPrefix('bf', "BF", 24);
		animation.addByPrefix('bfConfirm', 'HEY_BF', 24, false);
		animation.addByPrefix('bf-bloops', "BLOOPS", 24);
		animation.addByPrefix('bf-bloopsConfirm', 'HEY_BLOOPS', 24, false);
		animation.addByPrefix('bf-pico', "PICO", 24);
		animation.addByPrefix('bf-picoConfirm', 'HEY_PICO', 24, false);
		animation.addByPrefix('gf', "GF Dancing Beat WHITE", 24);
		animation.addByPrefix('dad', "Dad idle dance BLACK LINE", 24);
		animation.addByPrefix('spooky', "spooky dance idle BLACK LINES", 24);
		animation.addByPrefix('pico', "Pico Idle Dance", 24);
		animation.addByPrefix('mom', "Mom Idle BLACK LINES", 24);
		animation.addByPrefix('parents-christmas', "Parent Christmas Idle Black Lines", 24);
		animation.addByPrefix('senpai', "SENPAI idle Black Lines", 24);
		animation.addByPrefix('bf-milne', "MILNE", 24);
		animation.addByPrefix('bf-milneConfirm', "HEY_MILNE", 24, false);
		animation.addByPrefix('bf-dylan', "DYLAN", 24);
		animation.addByPrefix('bf-dylanConfirm', "HEY_DYLAN", 24, false);
		// Parent Christmas Idle

		animation.play(character);
		updateHitbox();
	}
}
