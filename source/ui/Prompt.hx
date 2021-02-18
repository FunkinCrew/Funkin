package ui;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class Prompt extends flixel.FlxSubState
{
	inline static var MARGIN = 100;
	
	public var onYes:Void->Void;
	public var onNo:Void->Void;
	public var buttons:MenuItemList;
	public var field:FlxText;
	public var back:FlxSprite;
	
	var style:ButtonStyle;
	
	public function new (atlas, text:String, style:ButtonStyle = Ok)
	{
		this.style = style;
		super();
		
		var texture:FlxAtlasFrames;
		if (Std.is(atlas, String))
			texture = Paths.getSparrowAtlas(cast atlas);
		else
			texture = cast atlas;
		
		back = new FlxSprite();
		back.frames = texture;
		back.animation.addByPrefix("idle", "back");
		back.scrollFactor.set(0, 0);
		
		buttons = new MenuItemList(texture, Horizontal);
		
		field = new FlxText();
		field.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.BLACK, CENTER);
		field.text = text;
		field.scrollFactor.set(0, 0);
	}
	
	override function create()
	{
		super.create();
		
		back.animation.play("idle");
		back.updateHitbox();
		back.screenCenter(XY);
		add(back);
		
		field.y = back.y + MARGIN;
		field.screenCenter(X);
		add(field);
		
		createButtons();
		add(buttons);
	}
	
	public function setButtons(style:ButtonStyle)
	{
		if (this.style != style)
		{
			this.style = style;
			createButtons();
		}
	}
	
	function createButtons()
	{
		// destroy previous buttons
		while(buttons.members.length > 0)
		{
			buttons.remove(buttons.members[0], true).destroy();
		}
		
		switch(style)
		{
			case Yes_No         : createButtonsHelper("yes", "no");
			case Ok             : createButtonsHelper("ok");
			case Custom(yes, no): createButtonsHelper(yes, no);
			case None           : buttons.exists = false;
		};
	}
	
	function createButtonsHelper(yes:String, ?no:String)
	{
		buttons.exists = true;
		// pass anonymous functions rather than the current callbacks, in case they change later
		var yesButton = buttons.createItem(yes, function() onYes());
		yesButton.screenCenter(X);
		yesButton.y = back.y + back.height - yesButton.height - MARGIN;
		yesButton.scrollFactor.set(0, 0);
		if (no != null)
		{
			// place right
			yesButton.x = back.x + back.width - yesButton.width - MARGIN;
			
			var noButton = buttons.createItem(no, function() onNo());
			noButton.x = back.x + MARGIN;
			noButton.y = back.y + back.height - noButton.height - MARGIN;
			noButton.scrollFactor.set(0, 0);
		}
	}
	
	public function setText(text:String)
	{
		field.text = text;
		field.screenCenter(X);
	}
}

enum ButtonStyle
{
    Ok;
    Yes_No;
    Custom(yes:String, no:Null<String>);//Todo: more than 2
	None;
}