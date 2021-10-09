package game;

import flixel.graphics.frames.FlxFramesCollection;
import utilities.CoolUtil;
import utilities.NoteVariables;
import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var noteScore:Float = 1;

	public static var swagWidth:Float = 160 * 0.7;

	public var rawNoteData:Int = 0;

	public var modifiedByLua:Bool;
	public var modAngle:Float = 0;
	public var localAngle:Float = 0;

	public var character:Int = 0;
	
	public var arrow_Type:String;
	public var shouldHit:Bool;

	public var hitDamage:Float;
	public var missDamage:Float;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?character:Int = 0, ?arrowType:String = "default")
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.character = character;
		this.strumTime = strumTime;
		this.noteData = noteData;
		this.arrow_Type = arrowType;
		isSustainNote = sustainNote;

		x += 100;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y = -2000;

		if(!PlayState.arrow_Type_Sprites.exists(arrow_Type))
			PlayState.arrow_Type_Sprites.set(arrow_Type, Paths.getSparrowAtlas('ui skins/' + PlayState.SONG.ui_Skin + "/arrows/" + arrow_Type, 'shared'));

		frames = PlayState.arrow_Type_Sprites.get(arrow_Type);

		animation.addByPrefix("default", NoteVariables.Other_Note_Anim_Stuff[PlayState.SONG.keyCount - 1][noteData] + "0");
		animation.addByPrefix("hold", NoteVariables.Other_Note_Anim_Stuff[PlayState.SONG.keyCount - 1][noteData] + " hold0");
		animation.addByPrefix("holdend", NoteVariables.Other_Note_Anim_Stuff[PlayState.SONG.keyCount - 1][noteData] + " hold end0");

		setGraphicSize(Std.int((width * Std.parseFloat(PlayState.instance.ui_Settings[0])) * (Std.parseFloat(PlayState.instance.ui_Settings[2]) - (Std.parseFloat(PlayState.instance.mania_size[PlayState.SONG.keyCount-1])))));
		updateHitbox();
		
		antialiasing = PlayState.instance.ui_Settings[3] == "true";

		x += swagWidth * noteData;
		animation.play("default");

		centerOffsets();
		centerOrigin();

		if (FlxG.save.data.downscroll && sustainNote) 
			flipY = true;

		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;

			if(PlayState.SONG.ui_Skin != 'pixel')
				x += width / 2;

			animation.play("holdend");
			updateHitbox();

			if(PlayState.SONG.ui_Skin != 'pixel')
				x -= width / 2;

			if (PlayState.SONG.ui_Skin == 'pixel')
				x += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play("hold");

				prevNote.scale.y *= (Conductor.nonmultilmao_stepCrochet / 100) * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			centerOffsets();
			centerOrigin();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		angle = modAngle + localAngle;

		if (mustPress)
		{
			// old ass code i guess \_(:/)_/
			/*
			// The * 0.5 is so that it's easier to hit them too late, instead of too early
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset)
				canBeHit = true;
			else
				canBeHit = false;
			*/

			// taken from kade engine moment
			if (isSustainNote)
			{
				if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 1.5)
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
					canBeHit = true;
				else
					canBeHit = false;
			}
			else
			{
				if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
					&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset)
					canBeHit = true;
				else
					canBeHit = false;
			}

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}

typedef NoteType = {
	var shouldHit:Bool;

	var hitDamage:Float;
	var missDamage:Float;
} 