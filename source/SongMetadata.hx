package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

typedef SongMetadata =
{
	var folder:String;

	var name:String;
	var instrumental:String;
	var voices:String;
	var format:String;
	var difficulties:Array<String>;
}
