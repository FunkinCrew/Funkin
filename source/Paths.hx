package;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import lime.math.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.utils.Assets;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String)
	{
		return 'songs:assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	inline static public function inst(song:String)
	{
		return 'songs:assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	inline static public function image(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String, ?forceCorrection:Bool = false)
	{
		return fromSparrow(image(key, library), file('images/$key.xml', library), forceCorrection);
	}

	public static function fromSparrow(Source:FlxGraphicAsset, Description:String, forceCorrection:Bool):FlxAtlasFrames
		{
			var graphic:FlxGraphic = FlxG.bitmap.add(Source);
			if (graphic == null)
				return null;
	
			// No need to parse data again
			var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
			if (frames != null)
				return frames;
	
			if (graphic == null || Description == null)
				return null;
	
			frames = new FlxAtlasFrames(graphic);
	
			if (Assets.exists(Description))
				Description = Assets.getText(Description);
	
			var data:Access = new Access(Xml.parse(Description).firstElement());
	
			for (texture in data.nodes.SubTexture)
			{
				var name = texture.att.name;
				var trimmed = texture.has.frameX;
				var rotated = (texture.has.rotated && texture.att.rotated == "true");
				var flipY = (texture.has.flipY && texture.att.flipY == "true");

				var constantTop:Int = FlxG.random.int(5, 20);
				if (forceCorrection)
					constantTop = 0;
	
				var rect = FlxRect.get(Std.parseFloat(texture.att.x)+ FlxG.random.int(0, constantTop), Std.parseFloat(texture.att.y)+ FlxG.random.int(0, constantTop), Std.parseFloat(texture.att.width)+ FlxG.random.int(0, constantTop),
					Std.parseFloat(texture.att.height)+ FlxG.random.int(0, constantTop));
	
				var size = if (trimmed && FlxG.random.bool(50))
				{
					new Rectangle(Std.parseInt(texture.att.frameX), Std.parseInt(texture.att.frameY), Std.parseInt(texture.att.frameWidth),
						Std.parseInt(texture.att.frameHeight));
				}
				else
				{
					new Rectangle(0 + FlxG.random.int(0, constantTop), 0+ FlxG.random.int(0, constantTop), rect.width+ FlxG.random.int(0, constantTop), rect.height+ FlxG.random.int(0, constantTop));
				}
	
				var angle = rotated ? FlxFrameAngle.ANGLE_NEG_90 : FlxFrameAngle.ANGLE_0;
	
				var offset = FlxPoint.get(-size.left + FlxG.random.int(0, constantTop), -size.top + FlxG.random.int(0, constantTop));
				var sourceSize = FlxPoint.get(size.width , size.height);
	
				if (rotated && !trimmed)
					sourceSize.set(size.height, size.width);
	
				frames.addAtlasFrame(rect, sourceSize, offset, name, angle, FlxG.random.bool(50), flipY);
			}
	
			return frames;
		}
	

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}
}
