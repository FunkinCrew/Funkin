package ui;

import substates.MaxFPSMenu;
import utilities.Discord.DiscordClient;
import polymod.Polymod.ModMetadata;
import modding.ModList;
import substates.SongOffsetMenu;
import flixel.FlxSprite;
import substates.UISkinSelect;
import substates.ControlMenuSubstate;
import substates.MusicBeatSubstate;
import states.MusicBeatState;
import flixel.FlxSubState;
import states.LoadingState;
import states.PlayState;
import flixel.FlxState;
import debuggers.AnimationDebug;
import states.OptionsMenu;
import flixel.FlxG;
import flixel.group.FlxGroup;

/**
 * The base option class that all options inherit from.
 */
class Option extends FlxTypedGroup<FlxSprite>
{
	// variables //
	public var Alphabet_Text:Alphabet;

	// options //
	public var Option_Row:Int = 0;

	public var Option_Name:String = "-";
	public var Option_Value:String = "downscroll";
	
	public function new(_Option_Name:String = "-", _Option_Value:String = "downscroll", _Option_Row:Int = 0)
	{
		super();

		// SETTING VALUES //
		this.Option_Name = _Option_Name;
		this.Option_Value = _Option_Value;
		this.Option_Row = _Option_Row;

		// CREATING OTHER OBJECTS //
		Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
		Alphabet_Text.isMenuItem = true;
		Alphabet_Text.targetY = Option_Row;
		add(Alphabet_Text);
	}
}

/**
 * Simple Option with a checkbox that changes a bool value.
 */
class BoolOption extends Option
{
	// variables //
	var Checkbox_Object:Checkbox;

	// options //
	public var Option_Checked:Bool = false;

	override public function new(_Option_Name:String = "-", _Option_Value:String = "downscroll", _Option_Checked:Bool = false, _Option_Row:Int = 0)
	{
		super();

		// SETTING VALUES //
		this.Option_Name = _Option_Name;
		this.Option_Value = _Option_Value;
		this.Option_Checked = _Option_Checked;
		this.Option_Row = _Option_Row;

		// CREATING OTHER OBJECTS //
		Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
		Alphabet_Text.isMenuItem = true;
		Alphabet_Text.targetY = Option_Row;
		add(Alphabet_Text);

		Checkbox_Object = new Checkbox(Alphabet_Text);
		Checkbox_Object.checked = GetObjectValue();
		add(Checkbox_Object);
	}

	public function GetObjectValue():Bool
	{
		var Value:Bool = false;

		//    MAKE THIS A BETTER SYSTEM LATER!!!    //
		// (MAYBE SIMILAR TO HOW WEEK SCORES WORK?) //
		
		switch(Option_Value)
		{
			case "downscroll":
				Value = FlxG.save.data.downscroll;
			case "antiMash":
				Value = FlxG.save.data.antiMash;
			case "weekProgression":
				Value = FlxG.save.data.weekProgression;
			case "debugSongs":
				Value = FlxG.save.data.debugSongs;
			case "resetButtonOn":
				Value = FlxG.save.data.resetButtonOn;
			case "nohit":
				Value = FlxG.save.data.nohit;
			case "enemyGlow":
				Value = FlxG.save.data.enemyGlow;
			case "oldTitle":
				Value = FlxG.save.data.oldTitle;
			case "msText":
				Value = FlxG.save.data.msText;
			case "freeplayMusic":
				Value = FlxG.save.data.freeplayMusic;
			case "fpsCounter":
				Value = FlxG.save.data.fpsCounter;
			case "memoryCounter":
				Value = FlxG.save.data.memoryCounter;
			case "nightMusic":
				Value = FlxG.save.data.nightMusic;
			case "watermarks":
				Value = FlxG.save.data.watermarks;
			case "bot":
				Value = FlxG.save.data.bot;
			case "middleScroll":
				Value = FlxG.save.data.middleScroll;
			case "noteSplashes":
				Value = FlxG.save.data.noteSplashes;
			case "discordRPC":
				Value = FlxG.save.data.discordRPC;
			case "quickRestart":
				Value = FlxG.save.data.quickRestart;
		}

		return Value;
	}

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
            ChangeValue();
    }

    public function ChangeValue()
    {
        //    MAKE THIS A BETTER SYSTEM LATER!!!    //
		// (MAYBE SIMILAR TO HOW WEEK SCORES WORK?) //
		
		switch(Option_Value)
		{
			case "downscroll":
				FlxG.save.data.downscroll = !Option_Checked;
			case "antiMash":
				FlxG.save.data.antiMash = !Option_Checked;
			case "weekProgression":
				FlxG.save.data.weekProgression = !Option_Checked;
			case "debugSongs":
				FlxG.save.data.debugSongs = !Option_Checked;
			case "resetButtonOn":
				FlxG.save.data.resetButtonOn = !Option_Checked;
			case "nohit":
				FlxG.save.data.nohit = !Option_Checked;
			case "enemyGlow":
				FlxG.save.data.enemyGlow = !Option_Checked;
			case "oldTitle":
				FlxG.save.data.oldTitle = !Option_Checked;
			case "msText":
				FlxG.save.data.msText = !Option_Checked;
			case "freeplayMusic":
				FlxG.save.data.freeplayMusic = !Option_Checked;
			case "fpsCounter":
				FlxG.save.data.fpsCounter = !Option_Checked;
				Main.toggleFPS(FlxG.save.data.fpsCounter);
			case "memoryCounter":
				FlxG.save.data.memoryCounter = !Option_Checked;
				Main.toggleMem(FlxG.save.data.memoryCounter);
			case "nightMusic":
				FlxG.save.data.nightMusic = !Option_Checked;
			case "watermarks":
				FlxG.save.data.watermarks = !Option_Checked;
			case "bot":
				FlxG.save.data.bot = !Option_Checked;
			case "middleScroll":
				FlxG.save.data.middleScroll = !Option_Checked;
			case "noteSplashes":
				FlxG.save.data.noteSplashes  = !Option_Checked;
			case "discordRPC":
				FlxG.save.data.discordRPC = !Option_Checked;

				if(FlxG.save.data.discordRPC && !DiscordClient.active)
					DiscordClient.initialize();
				else if(!FlxG.save.data.discordRPC && DiscordClient.active)
					DiscordClient.shutdown();
			case "quickRestart":
				FlxG.save.data.quickRestart = !Option_Checked;
		}

        if(Option_Value != "muted")
            FlxG.save.flush();

        Option_Checked = !Option_Checked;
        Checkbox_Object.checked = Option_Checked;
    }
}

/**
* Very simple option that transfers you to a different page when selecting it.
*/
class PageOption extends Option
{
    // OPTIONS //
    public var Page_Name:String = "Categories";

    override public function new(_Option_Name:String = "-", _Option_Row:Int = 0, _Page_Name:String = "Categories")
    {
        super();

        // SETTING VALUES //
        this.Option_Name = _Option_Name;
        this.Option_Row = _Option_Row;
        this.Page_Name = _Page_Name;

        // CREATING OTHER OBJECTS //
        Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
        Alphabet_Text.isMenuItem = true;
        Alphabet_Text.targetY = Option_Row;
        add(Alphabet_Text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Std.int(Alphabet_Text.targetY) == 0 && !OptionsMenu.inMenu)
            OptionsMenu.LoadPage(Page_Name);
    }
}

/**
* Option that opens the control menu when selected.
*/
class ControlMenuSubStateOption extends Option
{
    public function new(_Option_Name:String = "-", _Option_Row:Int = 0)
    {
        super();

        // SETTING VALUES //
        this.Option_Name = _Option_Name;
        this.Option_Row = _Option_Row;

        // CREATING OTHER OBJECTS //
        Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
        Alphabet_Text.isMenuItem = true;
        Alphabet_Text.targetY = Option_Row;
        add(Alphabet_Text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
			FlxG.state.openSubState(new ControlMenuSubstate());
    }
}

/**
* Option that opens the ui skin menu when selected.
*/
class UISkinSelectOption extends Option
{
    public function new(_Option_Name:String = "-", _Option_Row:Int = 0)
    {
        super();

        // SETTING VALUES //
        this.Option_Name = _Option_Name;
        this.Option_Row = _Option_Row;

        // CREATING OTHER OBJECTS //
        Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
        Alphabet_Text.isMenuItem = true;
        Alphabet_Text.targetY = Option_Row;
        add(Alphabet_Text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
			FlxG.state.openSubState(new UISkinSelect());
    }
}

/**
* Option that opens the song offset menu when selected.
*/
class SongOffsetOption extends Option
{
    public function new(_Option_Name:String = "-", _Option_Row:Int = 0)
    {
        super();

        // SETTING VALUES //
        this.Option_Name = _Option_Name;
        this.Option_Row = _Option_Row;

        // CREATING OTHER OBJECTS //
        Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
        Alphabet_Text.isMenuItem = true;
        Alphabet_Text.targetY = Option_Row;
        add(Alphabet_Text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
			FlxG.state.openSubState(new SongOffsetMenu());
    }
}

/**
* Very simple option that transfers you to a different game-state when selecting it.
*/
class GameStateOption extends Option
{
    // OPTIONS //
    public var Game_State:FlxState;

    public function new(_Option_Name:String = "-", _Option_Row:Int = 0, _Game_State:Dynamic)
    {
        super();

        // SETTING VALUES //
        this.Option_Name = _Option_Name;
        this.Option_Row = _Option_Row;
        this.Game_State = _Game_State;

        // CREATING OTHER OBJECTS //
        Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
        Alphabet_Text.isMenuItem = true;
        Alphabet_Text.targetY = Option_Row;
        add(Alphabet_Text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
			FlxG.switchState(Game_State);
    }
}

#if sys
/**
 * Option for enabling and disabling mods.
 */
 class ModOption extends FlxTypedGroup<FlxSprite>
 {
	// variables //
	public var Alphabet_Text:Alphabet;
	public var Mod_Icon:ModIcon;

	public var Mod_Enabled:Bool = false;

	// options //
	public var Option_Row:Int = 0;

	public var Option_Name:String = "-";
	public var Option_Value:String = "Template Mod";
	
	public function new(_Option_Name:String = "-", _Option_Value:String = "Template Mod", _Option_Row:Int = 0)
	{
		super();

		// SETTING VALUES //
		this.Option_Name = _Option_Name;
		this.Option_Value = _Option_Value;
		this.Option_Row = _Option_Row;

		// CREATING OTHER OBJECTS //
		Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
		Alphabet_Text.isMenuItem = true;
		Alphabet_Text.targetY = Option_Row;
		add(Alphabet_Text);

		Mod_Icon = new ModIcon(Option_Value);
		Mod_Icon.sprTracker = Alphabet_Text;
		add(Mod_Icon);

		Mod_Enabled = ModList.modList.get(Option_Value);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
		{
			Mod_Enabled = !Mod_Enabled;
			ModList.setModEnabled(Option_Value, Mod_Enabled);
		}

		if(Mod_Enabled)
		{
			Alphabet_Text.alpha = 1;
			Mod_Icon.alpha = 1;
		}
		else
		{
			Alphabet_Text.alpha = 0.6;
			Mod_Icon.alpha = 0.6;
		}
	}
}
#end

/**
* Option that opens the song offset menu when selected.
*/
class MaxFPSOption extends Option
{
    public function new(_Option_Name:String = "-", _Option_Row:Int = 0)
    {
        super();

        // SETTING VALUES //
        this.Option_Name = _Option_Name;
        this.Option_Row = _Option_Row;

        // CREATING OTHER OBJECTS //
        Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
        Alphabet_Text.isMenuItem = true;
        Alphabet_Text.targetY = Option_Row;
        add(Alphabet_Text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
			FlxG.state.openSubState(new MaxFPSMenu());
    }
}

/**
* A Option for save data that is saved a string with multiple pre-defined states (aka like accuracy option or cutscene option)
*/
class StringSaveOption extends Option
{
	// VARIABLES //
	var Current_Mode:String = "option 2";
	var Modes:Array<String> = ["option 1", "option 2", "option 3"];
	var Data:Dynamic;
	var Cool_Name:String;

	function SetDataIGuess() { FlxG.save.flush(); }

    override public function new(_Option_Name:String = "String Switcher", _Modes:Array<String>, _Data:Dynamic, _Option_Row:Int = 0)
    {
        super();

        // SETTING VALUES //
        this.Option_Row = _Option_Row;
		this.Modes = _Modes;
		this.Data = _Data;
		this.Current_Mode = Data;
		this.Cool_Name = _Option_Name;
		this.Option_Name = Cool_Name + " " + Current_Mode;

        // CREATING OTHER OBJECTS //
        Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
        Alphabet_Text.isMenuItem = true;
        Alphabet_Text.targetY = Option_Row;
        add(Alphabet_Text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Std.int(Alphabet_Text.targetY) == 0 && !OptionsMenu.inMenu)
        {
			var prevIndex = Modes.indexOf(Current_Mode);

			if(prevIndex != -1)
			{
				if(prevIndex + 1 > Modes.length - 1)
					prevIndex = 0;
				else
					prevIndex++;
			}
			else
				prevIndex = 0;

			Current_Mode = Modes[prevIndex];

			this.Option_Name = Cool_Name + " " + Current_Mode;

			remove(Alphabet_Text);
			Alphabet_Text.destroy();

			Alphabet_Text = new Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
			Alphabet_Text.isMenuItem = true;
			Alphabet_Text.targetY = Option_Row;
			add(Alphabet_Text);

			Data = Current_Mode;

			SetDataIGuess();
		}
    }
}

class AccuracyOption extends StringSaveOption { override function SetDataIGuess() { FlxG.save.data.accuracyMode = Data; super.SetDataIGuess(); } }
class CutsceneOption extends StringSaveOption { override function SetDataIGuess() { FlxG.save.data.cutscenePlays = Data; super.SetDataIGuess(); } }