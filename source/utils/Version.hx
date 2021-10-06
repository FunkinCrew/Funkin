package utils;

import haxe.Json;
import openfl.utils.ByteArray;

@:keep @:file("version.json")
class VersionData extends ByteArrayData{}

class Version {
    public static function get():VersionJson {
        var v = new VersionData();
		return cast Json.parse(v.readUTFBytes(v.length));
    }
}

typedef VersionJson = {
    build:Float
}