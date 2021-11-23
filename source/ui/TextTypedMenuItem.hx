package ui;

using StringTools;

class TextTypedMenuItem extends MenuTypedItem
{
	override public function new(x:Float = 0, y:Float = 0, c, d, e)
	{
		super(x, y, c, d, e);
	}

	override public function setItem(a:String, b:Dynamic = null)
	{
		if (label != null)
		{
			label.text = a;
			label.set_alpha(alpha);
			set_width(label.get_width());
			set_height(label.get_height());
		}
		super.setItem(a, b);
	}

	override public function set_label(a)
	{
		super.set_label(a);
		setItem(name, callback);
	}
}