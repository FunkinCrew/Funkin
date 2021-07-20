package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;

class CharacterSetting
{
	public var x(default, null):Int;
	public var y(default, null):Int;
	public var scale(default, null):Float;
	public var flipped(default, null):Bool;

	public function new(x:Int = 0, y:Int = 0, scale:Float = 1.0, flipped:Bool = false)
	{
		this.x = x;
		this.y = y;
		this.scale = scale;
		this.flipped = flipped;
	}
}

class MenuCharacter extends FlxSprite
{
	private static var settings:Map<String, CharacterSetting> = [
		'bf' => new CharacterSetting(0, -20, 1.0, true),
		'gf' => new CharacterSetting(50, 80, 1.5, true),
		'dad' => new CharacterSetting(-15, 130),
		'spooky' => new CharacterSetting(20, 30),
		'pico' => new CharacterSetting(0, 0, 1.0, true),
		'mom' => new CharacterSetting(-30, 140, 0.85),
		'parents-christmas' => new CharacterSetting(100, 130, 1.8),
		'senpai' => new CharacterSetting(-40, -45, 1.4)
	];

	private var flipped:Bool = false;
	//questionable variable name lmfao
	private var goesLeftNRight:Bool = false;
	private var danceLeft:Bool = false;
	private var character:String = '';

	public function new(x:Int, y:Int, scale:Float, flipped:Bool)
	{
		super(x, y);
		this.flipped = flipped;

		if(FlxG.save.data.antialiasing)
			{
				antialiasing = true;
			}

		frames = Paths.getSparrowAtlas('campaign_menu_UI_characters');

		animation.addByPrefix('bf', "BF idle dance white", 24, false);
		animation.addByPrefix('bfConfirm', 'BF HEY!!', 24, false);
		animation.addByIndices('gf-left', 'GF Dancing Beat WHITE', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		animation.addByIndices('gf-right', 'GF Dancing Beat WHITE', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		animation.addByPrefix('dad', "Dad idle dance BLACK LINE", 24, false);
		animation.addByIndices('spooky-left', 'spooky dance idle BLACK LINES', [0, 2, 6], "", 12, false);
		animation.addByIndices('spooky-right', 'spooky dance idle BLACK LINES', [8, 10, 12, 14], "", 12, false);
		animation.addByPrefix('pico', "Pico Idle Dance", 24, false);
		animation.addByPrefix('mom', "Mom Idle BLACK LINES", 24, false);
		animation.addByPrefix('parents-christmas', "Parent Christmas Idle", 24, false);
		animation.addByPrefix('senpai', "SENPAI idle Black Lines", 24, false);

		setGraphicSize(Std.int(width * scale));
		updateHitbox();
	}

	public function setCharacter(character:String):Void
	{
		var sameCharacter:Bool = character == this.character;
		this.character = character;
		if (character == '')
		{
			visible = false;
			return;
		}
		else
		{
			visible = true;
		}

		if (!sameCharacter) {
			bopHead(true);
		}

		var setting:CharacterSetting = settings[character];
		offset.set(setting.x, setting.y);
		setGraphicSize(Std.int(width * setting.scale));
		flipX = setting.flipped != flipped;
	}

	public function bopHead(LastFrame:Bool = false):Void
	{
		if (character == 'gf' || character == 'spooky') {
			danceLeft = !danceLeft;

			if (danceLeft)
				animation.play(character + "-left", true);
			else
				animation.play(character + "-right", true);
		} else {
			//no spooky nor girlfriend so we do da normal animation
			if (animation.name == "bfConfirm")
				return;
			animation.play(character, true);
		}
		if (LastFrame) {
			animation.finish();
		}
	}
}
