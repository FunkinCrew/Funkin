package game;

import utilities.NoteHandler;
import game.Song.SwagSong;
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

	public var shouldHit:Bool = true;
	public var hitDamage:Float = 0.0;
	public var missDamage:Float = 0.07;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?character:Int = 0, ?arrowType:String = "default", ?song:SwagSong)
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

		if(song == null)
			song = PlayState.SONG;

		x += 100;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y = -2000;

		if(!PlayState.instance.arrow_Type_Sprites.exists(arrow_Type))
		{
			if(PlayState.instance.types.contains(arrow_Type))
				PlayState.instance.arrow_Type_Sprites.set(arrow_Type, Paths.getSparrowAtlas('ui skins/' + song.ui_Skin + "/arrows/" + arrow_Type, 'shared'));
			else
				PlayState.instance.arrow_Type_Sprites.set(arrow_Type, Paths.getSparrowAtlas("ui skins/default/arrows/" + arrow_Type, 'shared'));
		}

		frames = PlayState.instance.arrow_Type_Sprites.get(arrow_Type);

		animation.addByPrefix("default", NoteVariables.Other_Note_Anim_Stuff[song.keyCount - 1][noteData] + "0");
		animation.addByPrefix("hold", NoteVariables.Other_Note_Anim_Stuff[song.keyCount - 1][noteData] + " hold0");
		animation.addByPrefix("holdend", NoteVariables.Other_Note_Anim_Stuff[song.keyCount - 1][noteData] + " hold end0");

		var lmaoStuff = Std.parseFloat(PlayState.instance.ui_Settings[0]) * (Std.parseFloat(PlayState.instance.ui_Settings[2]) - (Std.parseFloat(PlayState.instance.mania_size[song.keyCount-1])));

		setGraphicSize(Std.int(width * lmaoStuff));
		updateHitbox();
		
		antialiasing = PlayState.instance.ui_Settings[3] == "true";

		x += swagWidth * noteData;
		animation.play("default");

		if(!PlayState.instance.arrow_Configs.exists(arrow_Type))
		{
			if(PlayState.instance.types.contains(arrow_Type))
				PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFilePolymod(Paths.txt("ui skins/" + song.ui_Skin + "/" + arrow_Type)));
			else
				PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFilePolymod(Paths.txt("ui skins/default/" + arrow_Type)));

			PlayState.instance.type_Configs.set(arrow_Type, CoolUtil.coolTextFilePolymod(Paths.txt("arrow types/" + arrow_Type)));
		}

		offset.y += Std.parseFloat(PlayState.instance.arrow_Configs.get(arrow_Type)[0]) * lmaoStuff;

		shouldHit = PlayState.instance.type_Configs.get(arrow_Type)[0] == "true";
		hitDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[1]);
		missDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[2]);

		if (FlxG.save.data.downscroll && sustainNote) 
			flipY = true;

		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;

			if(song.ui_Skin != 'pixel')
				x += width / 2;

			animation.play("holdend");
			updateHitbox();

			if(song.ui_Skin != 'pixel')
				x -= width / 2;

			if (song.ui_Skin == 'pixel')
				x += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play("hold");

				prevNote.scale.y *= (Conductor.nonmultilmao_stepCrochet / 100) * 1.5 * song.speed;
				prevNote.updateHitbox();
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