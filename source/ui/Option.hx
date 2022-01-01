package ui;

import openfl.events.FullScreenEvent;
import substates.ScrollSpeedMenu;
import substates.NoteColorSubstate;
import substates.NoteBGAlphaMenu;
#if discord_rpc
import utilities.Discord.DiscordClient;
#end

import substates.JudgementMenu;
import substates.MaxFPSMenu;
import modding.ModList;
import substates.SongOffsetMenu;
import flixel.FlxSprite;
import substates.UISkinSelect;
import substates.ControlMenuSubstate;
import flixel.FlxState;
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

	public function GetObjectValue():Bool { return Reflect.getProperty(FlxG.save.data, Option_Value); }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ENTER && Alphabet_Text.targetY == 0)
            ChangeValue();
    }

    public function ChangeValue()
    {
		Reflect.setProperty(FlxG.save.data, Option_Value, !Option_Checked);
		
		switch(Option_Value) // extra special cases
		{
			case "fpsCounter":
				Main.toggleFPS(FlxG.save.data.fpsCounter);
			case "memoryCounter":
				Main.toggleMem(FlxG.save.data.memoryCounter);
			#if discord_rpc
			case "discordRPC":
				if(FlxG.save.data.discordRPC && !DiscordClient.active)
					DiscordClient.initialize();
				else if(!FlxG.save.data.discordRPC && DiscordClient.active)
					DiscordClient.shutdown();
			#end
			case "versionDisplay":
				Main.toggleVers(FlxG.save.data.versionDisplay);
		}

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
* Option that opens the max fps menu when selected.
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
* Option that opens the judgement menu when selected.
*/
class JudgementMenuOption extends Option
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
			FlxG.state.openSubState(new JudgementMenu());
    }
}

/**
* Option that opens the note bg alpha menu when selected.
*/
class NoteBGAlphaMenuOption extends Option
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
			FlxG.state.openSubState(new NoteBGAlphaMenu());
    }
}

/**
* Option that opens the note color menu when selected.
*/
class NoteColorMenuOption extends Option
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
			FlxG.state.openSubState(new NoteColorSubstate());
    }
}

/**
* Option that opens the scroll speed menu when selected.
*/
class ScrollSpeedMenuOption extends Option
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
			FlxG.state.openSubState(new ScrollSpeedMenu());
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
	var Save_Data_Name:String;

    override public function new(_Option_Name:String = "String Switcher", _Modes:Array<String>, _Data:Dynamic, _Option_Row:Int = 0, _Save_Data_Name:String = "cutscenePlays")
    {
        super();

        // SETTING VALUES //
        this.Option_Row = _Option_Row;
		this.Modes = _Modes;
		this.Data = _Data;
		this.Current_Mode = Data;
		this.Cool_Name = _Option_Name;
		this.Option_Name = Cool_Name + " " + Current_Mode;
		this.Save_Data_Name = _Save_Data_Name;

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

	function SetDataIGuess()
	{
		Reflect.setProperty(FlxG.save.data, Save_Data_Name, Data);
		FlxG.save.flush();
	}
}

class DisplayFontOption extends StringSaveOption { override function SetDataIGuess() { super.SetDataIGuess(); Main.changeFont(FlxG.save.data.displayFont); } }