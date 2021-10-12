package ui;

import states.StoryMenuState;
import flixel.graphics.frames.FlxFramesCollection;
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
				animation.curAnim.stop();
	
			characterData = cast Json.parse(Assets.getText(Paths.json("menu character data/" + character)));
	
			frames = Paths.getSparrowAtlas('campaign menu/characters/' + characterData.File_Name);
	
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