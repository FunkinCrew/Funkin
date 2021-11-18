package ui;

using StringTools;

class TextMenuItem extends TextTypedMenuItem
{
	override public function new (a = 0, b = 0, c, d = Bold, e)
	{
		super(a, b, new Oe(0, 0, c, d), c, e);
		setEmptyBackground();
	}
}