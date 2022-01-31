package ui;

import haxe.Constraints.Function;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;

using StringTools;

class Prompt extends FlxSubState
{
	public static var MARGIN = 100;
	
	var style:ButtonStyle;
	var buttons:TextMenuList;
	var field:AtlasText;
	public var back:FlxSprite;

	public var onYes:Function = null;
	public var onNo:Function = null;
	
	override public function new(text:String, style:ButtonStyle = Ok)
	{
		this.style = style;
		super(0x80000000);
		buttons = new TextMenuList(Horizontal);
		field = new AtlasText(0, 0, text, Bold);
		field.scrollFactor.set();
	}

	override function create()
	{
		super.create();
		field.y = 100;
		field.screenCenter(X);
		add(field);
		createButtons();
		add(buttons);
	}

	public function createBg(width:Int, height:Int, color:Int = 0xFF808080)
	{
		back = new FlxSprite().makeGraphic(width, height, color, false, 'prompt-bg');
		back.screenCenter(XY);
		add(back);
		members.unshift(members.pop());
	}

	public function createBgFromMargin(margin:Float = 100, color:Int = 0xFF808080)
	{
		createBg(Std.int(FlxG.width - 2 * margin), Std.int(FlxG.height - 2 * margin), color);
	}

	public function setButtons(style:ButtonStyle)
	{
		if (this.style != style)
		{
			this.style = style;
			createButtons();
		}
	}

	public function createButtons()
	{
		for (i in 0...buttons.members.length)
		{
			buttons.remove(buttons.members[0], true).destroy();
		}
		switch (style)
		{
			case Ok:
				createButtonsHelper('ok');
			case Yes_No:
				createButtonsHelper('yes', 'no');
			case Custom(yes, no):
				createButtonsHelper(yes, no);
			case None:
				buttons.exists = false;
		}
	}

	public function createButtonsHelper(a, ?b)
	{
		buttons.exists = true;
		var item = buttons.createItem(0, 0, a, Bold, function()
		{
			onYes();
		});
		item.screenCenter(X);
		item.y = FlxG.height - item.height - 100;
		item.scrollFactor.set();
		if (b != null)
		{
			item.x = FlxG.width - item.width - 100;
			var item2 = buttons.createItem(0, 0, b, Bold, function()
			{
				onNo();
			});
			item2.x = 100;
			item2.y = FlxG.height - item.height - 100;
			item2.scrollFactor.set();
		}
	}

	public function setText(text:String)
	{
		field.text = text;
		field.screenCenter(X);
	}
}