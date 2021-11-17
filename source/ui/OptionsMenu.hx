package ui;

using StringTools;

class OptionsMenu extends Page
{
	var items:TextMenuList;

	override public function new(a:Bool)
	{
		super();
		items = new TextMenuList();
		add(items);
	}
}