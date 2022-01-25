package game;

import shaders.NoteColors;
import shaders.ColorSwap;
import game.Song.SwagSong;
import utilities.CoolUtil;
import utilities.NoteVariables;
import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;

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

	public var sustains:Array<Note> = [];
	public var missesSustains:Bool = false;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var noteScore:Float = 1;

	public static var swagWidth:Float = 160 * 0.7;

	public var rawNoteData:Int = 0;

	public var modifiedByLua:Bool;
	public var modAngle:Float = 0;
	public var localAngle:Float = 0;

	public var character:Int = 0;

	public var characters:Array<Int> = [];
	
	public var arrow_Type:String;

	public var shouldHit:Bool = true;
	public var hitDamage:Float = 0.0;
	public var missDamage:Float = 0.07;
	public var heldMissDamage:Float = 0.035;
	public var playMissOnMiss:Bool = true;

	public var colorSwap:ColorSwap;

	public var inEditor:Bool = false;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?character:Int = 0, ?arrowType:String = "default", ?song:SwagSong, ?characters:Array<Int>, ?mustPress:Bool = false, ?inEditor:Bool = false)
	{
		super();

		if(prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.inEditor = inEditor;
		this.character = character;
		this.strumTime = strumTime;
		this.arrow_Type = arrowType;
		this.characters = characters;
		this.mustPress = mustPress;

		isSustainNote = sustainNote;

		if(song == null)
			song = PlayState.SONG;

		var localKeyCount = mustPress ? song.playerKeyCount : song.keyCount;

		this.noteData = noteData;

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

		animation.addByPrefix("default", NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + "0", 24);
		animation.addByPrefix("hold", NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + " hold0", 24);
		animation.addByPrefix("holdend", NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + " hold end0", 24);

		var lmaoStuff = Std.parseFloat(PlayState.instance.ui_Settings[0]) * (Std.parseFloat(PlayState.instance.ui_Settings[2]) - (Std.parseFloat(PlayState.instance.mania_size[localKeyCount-1])));

		if(isSustainNote)
			setGraphicSize(Std.int(width * lmaoStuff), Std.int(height * Std.parseFloat(PlayState.instance.ui_Settings[0]) * (Std.parseFloat(PlayState.instance.ui_Settings[2]) - (Std.parseFloat(PlayState.instance.mania_size[3])))));
		else
			setGraphicSize(Std.int(width * lmaoStuff));

		updateHitbox();
		
		antialiasing = PlayState.instance.ui_Settings[3] == "true";

		x += swagWidth * noteData;
		animation.play("default");

		if(!PlayState.instance.arrow_Configs.exists(arrow_Type))
		{
			if(PlayState.instance.types.contains(arrow_Type))
				PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/" + song.ui_Skin + "/" + arrow_Type)));
			else
				PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/default/" + arrow_Type)));

			PlayState.instance.type_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("arrow types/" + arrow_Type)));
		}

		offset.y += Std.parseFloat(PlayState.instance.arrow_Configs.get(arrow_Type)[0]) * lmaoStuff;

		shouldHit = PlayState.instance.type_Configs.get(arrow_Type)[0] == "true";
		hitDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[1]);
		missDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[2]);
 
		if(PlayState.instance.type_Configs.get(arrow_Type)[4] != null)
			playMissOnMiss = PlayState.instance.type_Configs.get(arrow_Type)[4] == "true";
		else
		{
			if(shouldHit)
				playMissOnMiss = true;
			else
				playMissOnMiss = false;
		}
		
		if(PlayState.instance.type_Configs.get(arrow_Type)[3] != null)
			heldMissDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[3]);

		if (utilities.Options.getData("downscroll") && sustainNote) 
			flipY = true;

		if (isSustainNote && prevNote != null)
		{
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

				var speed = song.speed;

				if(utilities.Options.getData("useCustomScrollSpeed"))
					speed = utilities.Options.getData("customScrollSpeed") / PlayState.songMultiplier;

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * speed;
				prevNote.updateHitbox();
			}

			centerOffsets();
			centerOrigin();
		}

		var affectedbycolor:Bool = false;

		if(PlayState.instance.arrow_Configs.get(arrow_Type)[5] != null)
		{
			if(PlayState.instance.arrow_Configs.get(arrow_Type)[5] == "true")
				affectedbycolor = true;
		}

		if(affectedbycolor)
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
	
			var noteColor = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData]);
	
			colorSwap.hue = noteColor[0] / 360;
			colorSwap.saturation = noteColor[1] / 100;
			colorSwap.brightness = noteColor[2] / 100;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		angle = modAngle + localAngle;

		calculateCanBeHit();

		if(!inEditor)
		{
			if(tooLate)
			{
				if (alpha > 0.3)
					alpha = 0.3;
			}
		}
	}

	public function calculateCanBeHit()
	{
		if(this != null)
		{
			if(mustPress)
			{
				if (isSustainNote)
				{
					if(shouldHit)
					{
						if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 1.5)
							&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
							canBeHit = true;
						else
							canBeHit = false;
					}
					else
					{
						if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset * 0.3
							&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset * 0.2)
							canBeHit = true;
						else
							canBeHit = false;
					}
				}
				else
				{
					/*
					TODO: make this shit use something from the arrow config .txt file
					*/ 
					if(shouldHit)
					{
						if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
							&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset)
							canBeHit = true;
						else
							canBeHit = false;
					}
					else
					{
						if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset * 0.3
							&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset * 0.2)
							canBeHit = true;
						else
							canBeHit = false;
					}
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
		}
	}
}

typedef NoteType = {
	var shouldHit:Bool;

	var hitDamage:Float;
	var missDamage:Float;
} 