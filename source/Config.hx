package;

import ui.FlxVirtualPad;
import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

class Config {
	var save:FlxSave;

	// ---- new config

	/**
		how to use:

		config.downscroll = true; // set downscroll

		trace(config.downscroll); // get downscroll

	**/

	// downscroll
	public var downscroll(get, set):Bool;
	
	function get_downscroll():Bool
		return getdownscroll();
	
	function set_downscroll(downscroll:Bool):Bool
		return setdownscroll(downscroll);


	// splash settings
	public var splash(get, set):Bool;
	
	function get_splash():Bool
		return getsplash();
	
	function set_splash(splash:Bool):Bool
		return setsplash(splash);

	// cutscenes settings

	public var cutscenes(get, set):Bool;
	
	function get_cutscenes():Bool
		return getcutscenes();
	
	function set_cutscenes(cutscenes:Bool):Bool
		return setcutscenes(cutscenes);

	// ---- end

	public function new() 
	{
		save = new FlxSave();
		save.bind("saveconrtol");
	}

	// --- old config
	public function setdownscroll(?value:Bool):Bool {
		if (save.data.isdownscroll == null) save.data.isdownscroll = false;
		
		save.data.isdownscroll = !save.data.isdownscroll;
		save.flush();
		return save.data.isdownscroll;
	}

	public function setcutscenes(?value:Bool):Bool {
		if (save.data.cutscenes == null) save.data.cutscenes = true;
		
		save.data.cutscenes = !save.data.cutscenes;
		save.flush();
		return save.data.cutscenes;
	}

	public function setsplash(?value:Bool):Bool {
		if (save.data.splash == null) save.data.splash = true;
		
		save.data.splash = !save.data.splash;
		save.flush();
		return save.data.splash;
	}

	public function camSave(value:Float):Float {
		if (save.data.cam == null) save.data.cam = 0.06;
		
		save.data.cam = value;
		save.flush();
		return save.data.cam;
	}

	public function camLoad():Float {
		if (save.data.cam != null) {
			return save.data.cam;
		}
		else {
			return 0.06;
		}
	}

	public function getdownscroll():Bool {
		if (save.data.isdownscroll != null) return save.data.isdownscroll;
		return false;
	}

	public function getcutscenes():Bool {
		if (save.data.cutscenes != null) return save.data.cutscenes;
		return false;
	}

	public function getsplash():Bool {
		if (save.data.splash != null) return save.data.splash;
		return false;//i hate flx save.
	}

	public function getcontrolmode():Int {
		// load control mode num from FlxSave
		if (save.data.buttonsmode != null) return save.data.buttonsmode[0];
		return 0;
	}

	public function setcontrolmode(mode:Int = 0):Int {
		// save control mode num from FlxSave
		if (save.data.buttonsmode == null) save.data.buttonsmode = new Array();
		save.data.buttonsmode[0] = mode;
		save.flush();

		return save.data.buttonsmode[0];
	}

	public function savecustom(_pad:FlxVirtualPad) {
		trace("saved");

		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();

			for (buttons in _pad)
			{
				save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
			}
		}else
		{
			var tempCount:Int = 0;
			for (buttons in _pad)
			{
				save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}
		save.flush();
	}

	public function loadcustom(_pad:FlxVirtualPad):FlxVirtualPad {
		//load pad
		if (save.data.buttons == null) return _pad;
		var tempCount:Int = 0;

		for(buttons in _pad)
		{
			buttons.x = save.data.buttons[tempCount].x;
			buttons.y = save.data.buttons[tempCount].y;
			tempCount++;
		}	
		return _pad;
	}

	public function setFrameRate(fps:Int = 60) {
		if (fps < 10) return;
		
		FlxG.stage.frameRate = fps;
		save.data.framerate = fps;
		save.flush();
	}

	public function getFrameRate():Int {
		if (save.data.framerate != null) return save.data.framerate;
		return 60;
	}
}