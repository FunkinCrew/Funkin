package ui;

import ui.MenuTypedList;

using StringTools;

enum AtlasFont
{
	Default;
	Bold;
}

class TextMenuList extends MenuTypedList
{
	override public function new(a, b)
	{
		if (a == null)
			a = MenuListDirection.Vertical;
		
		super(a, b);
	}

	public function createItem(a = 0, b = 0, c, d = Bold, e, f = false)
	{
		var item = new TextMenuItem(a, b, c, d, e);
		item.fireInstantly = f;
		return this.addItem(c, item);
	}
}