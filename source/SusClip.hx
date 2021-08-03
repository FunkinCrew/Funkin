package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

import Note;

class SusClip extends FlxSprite
{
	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var mustPress:Bool = false;
	public var noteYOff:Int = 0;
	
	public function new(note:Note)
	{
		super();
		
		//Copy note data
		strumTime = note.strumTime;
		noteData = note.noteData;
		mustPress = note.mustPress;
		noteYOff = note.noteYOff;
		
		x = note.x;
		y = note.y;
		alpha = note.alpha;
		loadGraphicFromSprite(note);
		
		angle = note.angle;
		flipY = note.flipY;
		clipRect = note.clipRect;
		scale.copyFrom(note.scale);
		scrollFactor.copyFrom(note.scrollFactor);
		updateHitbox();
	}
	
	/*
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		angle = modAngle + localAngle;
	}
	*/
}