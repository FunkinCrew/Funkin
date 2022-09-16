package funkin.noteStuff;

import flixel.FlxSprite;
import flixel.text.FlxText;

typedef RawNoteData =
{
	var strumTime:Float;
	var noteData:NoteType;
	var sustainLength:Float;
	var altNote:String;
	var noteKind:NoteKind;
}

@:forward
abstract NoteData(RawNoteData)
{
	public function new(strumTime = 0.0, noteData:NoteType = 0, sustainLength = 0.0, altNote = "", noteKind = NORMAL)
	{
		this = {
			strumTime: strumTime,
			noteData: noteData,
			sustainLength: sustainLength,
			altNote: altNote,
			noteKind: noteKind
		}
	}

	public var note(get, never):NoteType;

	inline function get_note()
		return this.noteData.value;

	public var int(get, never):Int;

	inline function get_int()
		return this.noteData.int;

	public var dir(get, never):NoteDir;

	inline function get_dir()
		return this.noteData.value;

	public var dirName(get, never):String;

	inline function get_dirName()
		return dir.name;

	public var dirNameUpper(get, never):String;

	inline function get_dirNameUpper()
		return dir.nameUpper;

	public var color(get, never):NoteColor;

	inline function get_color()
		return this.noteData.value;

	public var colorName(get, never):String;

	inline function get_colorName()
		return color.name;

	public var colorNameUpper(get, never):String;

	inline function get_colorNameUpper()
		return color.nameUpper;

	public var highStakes(get, never):Bool;

	inline function get_highStakes()
		return this.noteData.highStakes;

	public var lowStakes(get, never):Bool;

	inline function get_lowStakes()
		return this.noteData.lowStakes;
}

enum abstract NoteType(Int) from Int to Int
{
	// public var raw(get, never):Int;
	// inline function get_raw() return this;
	public var int(get, never):Int;

	inline function get_int()
		return this < 0 ? -this : this % 4;

	public var value(get, never):NoteType;

	inline function get_value()
		return int;

	public var highStakes(get, never):Bool;

	inline function get_highStakes()
		return this > 3;

	public var lowStakes(get, never):Bool;

	inline function get_lowStakes()
		return this < 0;
}

@:forward
enum abstract NoteDir(NoteType) from Int to Int from NoteType
{
	var LEFT = 0;
	var DOWN = 1;
	var UP = 2;
	var RIGHT = 3;
	var value(get, never):NoteDir;

	inline function get_value()
		return this.value;

	public var name(get, never):String;

	function get_name()
	{
		return switch (value)
		{
			case LEFT: "left";
			case DOWN: "down";
			case UP: "up";
			case RIGHT: "right";
		}
	}

	public var nameUpper(get, never):String;

	function get_nameUpper()
	{
		return switch (value)
		{
			case LEFT: "LEFT";
			case DOWN: "DOWN";
			case UP: "UP";
			case RIGHT: "RIGHT";
		}
	}
}

@:forward
enum abstract NoteColor(NoteType) from Int to Int from NoteType
{
	var PURPLE = 0;
	var BLUE = 1;
	var GREEN = 2;
	var RED = 3;
	var value(get, never):NoteColor;

	inline function get_value()
		return this.value;

	public var name(get, never):String;

	function get_name()
	{
		return switch (value)
		{
			case PURPLE: "purple";
			case BLUE: "blue";
			case GREEN: "green";
			case RED: "red";
		}
	}

	public var nameUpper(get, never):String;

	function get_nameUpper()
	{
		return switch (value)
		{
			case PURPLE: "PURPLE";
			case BLUE: "BLUE";
			case GREEN: "GREEN";
			case RED: "RED";
		}
	}
}

enum abstract NoteKind(String) from String to String
{
	/**
	 * The default note type.
	 */
	var NORMAL = "normal";

	// Testing shiz
	var PYRO_LIGHT = "pyro_light";
	var PYRO_KICK = "pyro_kick";
	var PYRO_TOSS = "pyro_toss";
	var PYRO_COCK = "pyro_cock"; // lol
	var PYRO_SHOOT = "pyro_shoot";
}
