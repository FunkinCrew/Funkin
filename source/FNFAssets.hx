package;

// NO NOT WEEK 7 THAT CAN FUCK OFF
// A helper class to make supporting web easier
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import haxe.io.Path;
import flixel.FlxG;
import flash.net.FileReference;
import flash.events.Event;
import openfl.events.IOErrorEvent;
import haxe.io.Bytes;
class FNFAssets {
    public static var _file:FileReference;
    public static function getText(id:String):String {
        #if sys
            // if there a library strip it out..
            // future proofing ftw
			var path = Assets.exists(id) ? Assets.getPath(id) : null;
            if (path == null)
                path = id;
            return File.getContent(path);
        #else
            // no need to strip it out... 
            // assets handles it
            return Assets.getText(id);
        #end
    }
	public static function getBytes(id:String):Bytes
	{
		#if sys
		// if there a library strip it out..
		// future proofing ftw
			var path = Assets.exists(id) ? Assets.getPath(id) : null;
			if (path == null)
				path = id;
			return File.getBytes(path);
		#else
		// no need to strip it out...
		// assets handles it
		return LimeAssets.getBytes(id);
		#end
	}
    public static function exists(id:String):Bool {
        #if sys
            var path = Assets.exists(id) ? Assets.getPath(id) : null;
            if (path == null)
                path = id;
            return FileSystem.exists(path);
        #else
            return Assets.exists(id);
        #end
    }
    public static function getBitmapData(id:String, ?useCache:Bool=true):BitmapData {
        #if sys
            // idk if this works lol
			var path = Assets.exists(id) ? Assets.getPath(id) : null;
            if (path == null)
                path = id;
            return BitmapData.fromFile(path);
        #else
            return Assets.getBitmapData(id, useCache);
        #end
    }

    public static function getSound(id:String, ?useCache:Bool=true) {
        #if sys
			var path = Assets.exists(id) ? Assets.getPath(id) : null;
            if (path == null)
                path = id;
            return Sound.fromFile(path);
        #else
            return Assets.getSound(id, useCache);
        #end
    }
    public static function saveContent(id:String, data:String) {
        #if sys
            File.saveContent(id, data);
        #else
            _file = new FileReference();
		
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            var idSus = Path.withoutDirectory(id);
            _file.save(data, idSus);
        #end
    }
	public static function saveBytes(id:String, data:Bytes)
	{
		#if sys
		File.saveBytes(id, data);
		#else
		_file = new FileReference();

		_file.addEventListener(Event.COMPLETE, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		var idSus = Path.withoutDirectory(id);
		_file.save(data, idSus);
		#end
	}
    // you can save anything with this but you have to ask
	public static function askToSave(id:String, data:Dynamic)
	{
		_file = new FileReference();

		_file.addEventListener(Event.COMPLETE, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		var idSus = Path.withoutDirectory(id);
		_file.save(data, idSus);
	}
	static function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	};
	static function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	};
	static function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}

// a proxy for HScript that gives some but not all of the features of
// regular FNFAssets
class HScriptAssets {
	public static function getText(id:String):String {
		return FNFAssets.getText(id);
	}
	public static function getBytes(id:String):Bytes {
		return FNFAssets.getBytes(id);
	}
	public static function exists(id:String):Bool {
		return FNFAssets.exists(id);
	}
	public static function getBitmapData(id:String):BitmapData {
		return FNFAssets.getBitmapData(id);
	}
	public static function getSound(id:String):Sound {
		return FNFAssets.getSound(id);
	}
}