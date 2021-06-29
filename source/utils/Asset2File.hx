package utils;

import haxe.crypto.Md5;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;

class Asset2File
{
	static var path:String = lime.system.System.applicationStorageDirectory;

	public static function getPath(id:String)
	{
		#if android
		var file = Assets.getBytes(id);

		var md5 = Md5.make(file);

		if (FileSystem.exists(path + md5))
			return path + md5;

		File.saveBytes(path + md5, file);

		return path + md5;
		#else
		return Sys.getCwd() + id;
		#end
	}
}
