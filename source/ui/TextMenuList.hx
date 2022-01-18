package ui;

import ui.MenuTypedList;

using StringTools;

class TextMenuList extends MenuTypedList<TextMenuItem>
{
	override public function new(dir:NavControls = Vertical, ?wrapDir:WrapMode)
	{
		super(dir, wrapDir);
	}

	public function createItem(x:Float = 0, y:Float = 0, text:String, font:AtlasFont = Bold, callback:Dynamic, fireInstantly = false)
	{
		var item = new TextMenuItem(x, y, text, font, callback);
		item.fireInstantly = fireInstantly;
		return addItem(text, item);
	}
}