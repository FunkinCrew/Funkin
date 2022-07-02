package;

import ui.FlxVirtualPad;
import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

class Config {

    public static var ghost(get, set):Bool;
    public static var downscroll(get, set):Bool;
    public static var splash(get, set):Bool;
    public static var cutscenes(get, set):Bool;
    public static var cam(get, set):Float;
    public static var frameRate(get, set):Int;
    public static var controlMode(get, set):Int;
    public static var osu(get, set):Bool;
    public static var icon(get, set):Bool;
    public static var glow(get, set):Bool;
    public static var mid(get, set):Bool;

	// ghost tapping

	static function get_ghost()
		return if (FlxG.save.data.ghost != null) FlxG.save.data.ghost else false;

	static function set_ghost(bool:Bool){
		FlxG.save.data.ghost = bool;
		FlxG.save.flush();
		return FlxG.save.data.ghost;
	}

	// downscroll
	
	static function get_downscroll():Bool
    {
        if (FlxG.save.data.isdownscroll != null) return FlxG.save.data.isdownscroll;
		return false;
    }
	
	static function set_downscroll(downscroll:Bool):Bool
    {
        if (FlxG.save.data.isdownscroll == null) FlxG.save.data.isdownscroll = false;
		
		FlxG.save.data.isdownscroll = downscroll;
		FlxG.save.flush();
		return FlxG.save.data.isdownscroll;
    }


	// splash settings
	
	static function get_splash():Bool{
		if (FlxG.save.data.splash != null) return FlxG.save.data.splash;
		return false;//i hate flx save.
	}
	
	static function set_splash(splash:Bool):Bool{
		if (FlxG.save.data.splash == null) FlxG.save.data.splash = true;
		
		FlxG.save.data.splash = !FlxG.save.data.splash;
		FlxG.save.flush();
		return FlxG.save.data.splash;
	}

	// cutscenes settings
	
	static function get_cutscenes():Bool
    {
        if (FlxG.save.data.cutscenes != null) return FlxG.save.data.cutscenes;
		return false;
    }
	
	static function set_cutscenes(cutscenes:Bool):Bool
    {
        if (FlxG.save.data.cutscenes == null) FlxG.save.data.cutscenes = true;
		
		FlxG.save.data.cutscenes = !FlxG.save.data.cutscenes;
		FlxG.save.flush();
		return FlxG.save.data.cutscenes;
    }

	public static function set_cam(value:Float):Float {
		if (FlxG.save.data.cam == null) FlxG.save.data.cam = 0.06;
		
		FlxG.save.data.cam = value;
		FlxG.save.flush();
		return FlxG.save.data.cam;
	}

	public static function get_cam():Float {
		if (FlxG.save.data.cam != null) {
			return FlxG.save.data.cam;
		}
		else {
			return 0.06;
		}
	}

	public static function set_frameRate(fps:Int = 60):Int {
		if (fps < 10) return FlxG.save.data.framerate;
		
		FlxG.stage.frameRate = fps;
		FlxG.save.data.framerate = fps;
		FlxG.save.flush();
        return fps;
	}

	public static function get_frameRate():Int {
		if (FlxG.save.data.framerate != null) return FlxG.save.data.framerate;
		return 60;
	}

	public static function get_controlMode():Int {
		// load control mode num from FlxSave
		if (FlxG.save.data.controlmode != null) return FlxG.save.data.controlmode;
		return 0;
	}

	public static function set_controlMode(mode:Int = 0):Int {
		// save control mode num from FlxSave
		if (FlxG.save.data.controlmode == null) FlxG.save.data.controlmode = mode;
		FlxG.save.flush();

		return FlxG.save.data.controlmode;
	}

	static function get_osu():Bool {
		return if (FlxG.save.data.osu != null) FlxG.save.data.osu else false;
	}

	static function set_osu(value:Bool):Bool {
		return FlxG.save.data.osu = value;
	}

	static function get_icon():Bool {
		return if (FlxG.save.data.icon2 != null) FlxG.save.data.icon2 else false;
	}

	static function set_icon(value:Bool):Bool {
		return FlxG.save.data.icon2 = value;
	}

	static function get_glow():Bool {
		return if (FlxG.save.data.glow != null) FlxG.save.data.glow else false;
	}

	static function set_glow(value:Bool):Bool {
		return FlxG.save.data.glow = value;
	}

	static function get_mid():Bool {
		return if (FlxG.save.data.mid != null) FlxG.save.data.mid else false;
	}

	static function set_mid(value:Bool):Bool {
		return FlxG.save.data.mid = value;
	}
}