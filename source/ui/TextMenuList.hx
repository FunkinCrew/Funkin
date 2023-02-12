package ui;

import ui.AtlasText;
import ui.MenuList;

class TextMenuList extends MenuTypedList<TextMenuItem>
{
	public function new(navControls:NavControls = Vertical, ?wrapMode)
	{
		super(navControls, wrapMode);
	}

	public function createItem(x = 0.0, y = 0.0, name:String, font:AtlasFont = Bold, callback, fireInstantly = false)
	{
		var item = new TextMenuItem(x, y, name, font, callback);
		item.fireInstantly = fireInstantly;
		return addItem(name, item);
	}
}

class TextMenuItem extends TextTypedMenuItem<AtlasText>
{
	public function new(x = 0.0, y = 0.0, name:String, font:AtlasFont = Bold, callback)
	{
		super(x, y, new AtlasText(0, 0, name, font), name, callback);
		setEmptyBackground();
	}
}

class TextTypedMenuItem<T:AtlasText> extends MenuTypedItem<T>
{
	public function new(x = 0.0, y = 0.0, label:T, name:String, callback)
	{
		super(x, y, label, name, callback);
	}

	override function setItem(name:String, ?callback:Void->Void)
	{
		if (label != null)
		{
			label.text = name;
			label.alpha = alpha;
			width = label.width;
			height = label.height;
		}

		super.setItem(name, callback);
	}

	override function set_label(value:T):T
	{
		super.set_label(value);
		setItem(name, callback);
		return value;
	}
}
