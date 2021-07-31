package ui;

import lime.utils.Assets;
#if sys
import sys.io.File;
import polymod.backends.PolymodAssets;
#end
import haxe.Json;
import flixel.FlxSprite;

class MenuCharacter extends FlxSprite
{
	public var character:String;
	var characterData:MenuCharacterData;

	public function new(x:Float, character:String = 'bf', ?looped:Bool = true)
	{
		super(x);

		this.character = character;
		
		loadCharacter();
	}

	public function loadCharacter()
	{
		if(character != "")
		{
			visible = true;
			
			if(animation.curAnim != null)
			{
				animation.curAnim.stop();
				animation.destroyAnimations();
			}
	
			#if sys
			characterData = cast Json.parse(PolymodAssets.getText(Paths.json("menu character data/" + character.toLowerCase())));
			#else
			characterData = cast Json.parse(Assets.getText(Paths.json("menu character data/" + character.toLowerCase())));
			#end
	
			#if sys
			// performance lol cuz it was laggy before
			if(Assets.exists(Paths.image('campaign menu/characters/' + characterData.File_Name)))
				frames = Paths.getSparrowAtlas('campaign menu/characters/' + characterData.File_Name);
			else
				frames = Paths.getSparrowAtlasSYS('campaign menu/characters/' + characterData.File_Name);
			#else
			frames = Paths.getSparrowAtlas('campaign menu/characters/' + characterData.File_Name);
			#end
	
			animation.addByPrefix("idle", characterData.Animation_Name, characterData.FPS, characterData.Animation_Looped);
			animation.play("idle");
	
			setGraphicSize(Std.int(width * characterData.Size));
			updateHitbox();
	
			offset.set(characterData.Offsets[0], characterData.Offsets[1]);
	
			flipX = characterData.Flipped;
		}
		else
		{
			visible = false;
		}
	}
}

typedef MenuCharacterData = 
{
	var Animation_Name:String;
	var FPS:Int;
	var Animation_Looped:Bool;
	var Offsets:Array<Float>;
	var File_Name:String;
	var Size:Float;
	var Flipped:Bool;
}