package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class MenuCharacter extends FlxSprite
{
	public var character:String;

	private var listCharacters = ['dad', 'spooky', 'pico', 'mom', 'parents-christmas', 'senpai'];

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		this.character = character;

		var tex = Paths.getSparrowAtlas('menucharacter/campaign_menu_UI_characters');
		
		for (char in listCharacters){
			var chartex = Paths.getSparrowAtlas('menucharacter/' + char);
				
			for (frame in chartex.frames){
				tex.pushFrame(frame);
			}
		}

		frames = tex;

		animation.addByPrefix('bf', "BF idle dance white", 24);
		animation.addByPrefix('bfConfirm', 'BF HEY!!', 24, false);
		animation.addByPrefix('gf', "GF Dancing Beat WHITE", 24);
		animation.addByPrefix('dad', "Dad idle dance BLACK LINE", 24);
		animation.addByPrefix('spooky', "spooky dance idle BLACK LINES", 24);
		animation.addByPrefix('pico', "Pico Idle Dance", 24);
		animation.addByPrefix('mom', "Mom Idle BLACK LINES", 24);
		animation.addByPrefix('parents-christmas', "Parent Christmas Idle Black Lines", 24);
		animation.addByPrefix('senpai', "SENPAI idle Black Lines", 24);
		// Parent Christmas Idle

		animation.play(character);
		updateHitbox();
	}
}
