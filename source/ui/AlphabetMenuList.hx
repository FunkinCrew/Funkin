package ui;

import ui.MenuList;

class AlphabetMenuList extends MenuTypedList<AlphabetMenuItem>
{
	public function new (navControls:NavControls = Vertical)
	{
		super(navControls);
	}
	
	public function createItem(x = 0.0, y = 0.0, name:String, bold = true, callback, fireInstantly = false)
	{
		var item = new AlphabetMenuItem(x, y, name, bold, callback);
		item.fireInstantly = fireInstantly;
		return addItem(name, item);
	}
}

class AlphabetMenuItem extends AlphabetTypedMenuItem<Alphabet>
{
	public function new (x = 0.0, y = 0.0, name:String, bold = true, callback)
	{
		super(x, y, new Alphabet(x, y, name, bold), name, callback);
	}
}

class AlphabetTypedMenuItem<T:Alphabet> extends MenuTypedItem<T>
{
	public function new (x = 0.0, y = 0.0, label:T, name:String, callback)
	{
		super(x, y, label, name, callback);
	}
	
	override function setItem(name:String, ?callback:() -> Void)
	{
		if (label != null)
		{
			label.text = name;
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