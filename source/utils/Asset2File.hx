package utils;

import haxe.crypto.Md5;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
//hi
class Asset2File
{
	static var path:String = lime.system.System.applicationStorageDirectory;

	public static function getPath(id:String, ?ext:String = "")
	{
		#if android
		var file = Assets.getBytes(id);

		var md5 = Md5.encode(Md5.make(file).toString());

		if (FileSystem.exists(path + md5 + ext))
			return path + md5 + ext;


		File.saveBytes(path + md5 + ext, file);

		return path + md5 + ext;
		#else
		return #if sys Sys.getCwd() + #end id;
		#end
	}
}
