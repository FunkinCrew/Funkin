package ui;

import flixel.FlxG;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal;
import haxe.ds.StringMap;

class MenuTypedList extends FlxTypedGroup<MenuItem>
{
	public var busy:Bool;
	public var byName:StringMap<MenuItem>;
	public var wrapMode:WrapMode;
	public var enabled:Bool;
	public var selectedIndex:Int;
	public var navControls:NavControls;

	public var onAcceptPress:FlxTypedSignal<MenuItem->Void>;
	public var onChange:FlxTypedSignal<MenuItem->Void>;

	public function new(dir:NavControls = Vertical, ?wrapDir:WrapMode)
	{
		busy = false;
		byName = new StringMap<MenuItem>();
		wrapMode = Both;
		enabled = true;
		onAcceptPress = new FlxTypedSignal<MenuItem->Void>();
		onChange = new FlxTypedSignal<MenuItem->Void>();
		selectedIndex = 0;
		navControls = dir;
		if (wrapDir != null) wrapMode = wrapDir;
		else
		{
			switch (dir.getIndex())
			{
				case 0:
					wrapMode = Horizontal;
				case 1:
					wrapMode = Vertical;
				default:
					wrapMode = Both;
			}
		}
		super();
	}

	public function addItem(name:String, item:MenuItem)
	{
		if (length == selectedIndex) item.select();
		byName.set(name, item);
		return add(item);
	}

	public function resetItem(name:String, newName:String, callback:Dynamic = null)
	{
		if (!byName.exists(name)) throw ("No item named:"+name);
		var item = byName.get(name);
		if (byName.exists(name)) byName.remove(name);
		byName.set(newName, item);
		item.setItem(newName, callback);
		return item;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (enabled && !busy)
		{
			var b, c, d, e, f, g;
			switch (wrapMode)
			{
				case Horizontal | Both:
					b = true;
				default:
					b = false;
			}
			switch (wrapMode)
			{
				case Vertical | Both:
					c = true;
				default:
					c = false;
			}
			d = navControls;
			switch (d)
			{
				case Horizontal:
					e = PlayerSettings.player1.controls.UI_LEFT_P;
					f = PlayerSettings.player1.controls.UI_RIGHT_P;
					g = navAxis(selectedIndex, length, e, f, b);
				case Vertical:
					e = PlayerSettings.player1.controls.UI_UP_P;
					f = PlayerSettings.player1.controls.UI_DOWN_P;
					g = navAxis(selectedIndex, length, e, f, c);
				case Both:
					e = PlayerSettings.player1.controls.UI_LEFT_P || PlayerSettings.player1.controls.UI_UP_P;
					f = PlayerSettings.player1.controls.UI_RIGHT_P || PlayerSettings.player1.controls.UI_DOWN_P;
					g = navAxis(selectedIndex, length, e, f, wrapMode != None);
				case Columns:
					g = navGrid(d.getIndex(), PlayerSettings.player1.controls.UI_LEFT_P, PlayerSettings.player1.controls.UI_RIGHT_P, b, PlayerSettings.player1.controls.UI_UP_P, PlayerSettings.player1.controls.UI_DOWN_P, c);
				case Rows:
					g = navGrid(d.getIndex(), PlayerSettings.player1.controls.UI_UP_P, PlayerSettings.player1.controls.UI_DOWN_P, c, PlayerSettings.player1.controls.UI_LEFT_P, PlayerSettings.player1.controls.UI_RIGHT_P, b);
			}
			if (g != selectedIndex)
			{
				FlxG.sound.play(Paths.sound("scrollMenu"));
				selectItem(g);
			}
			if (PlayerSettings.player1.controls.ACCEPT) accept();
		}
	}

	function navAxis(a, b, c, d, e)
	{
		if (c == d) return a;
		c ? 0 < a ? --a : if (e) a = b - 1 : a < b - 1 ? ++a : if (e) a = 0;
		return a;
	}

	function navGrid(a, b, c, d, e, f, h)
	{
		var m = Math.ceil(this.length / a),
			n = Math.floor(this.selectedIndex / a),
			k = this.selectedIndex % a;
		k = this.navAxis(k, a, b, c, d);
		n = this.navAxis(n, m, e, f, h);
		return Std.int(Math.min(this.length - 1, n * a + k));
	}

	public function accept()
	{
		var selected = members[selectedIndex];
		onAcceptPress.dispatch(selected);
		if (selected.fireInstantly)
		{
			selected.callback();
		}
		else
		{
			busy = true;
			FlxG.sound.play(Paths.sound("confirmMenu"));
			FlxFlicker.flicker(selected, 1, 0.06, true, false, function(flicker)
			{
				busy = false;
				selected.callback();
			});
		}
	}

	public function selectItem(index:Int)
	{
		members[selectedIndex].idle();
		selectedIndex = index;
		members[selectedIndex].select();
		onChange.dispatch(members[selectedIndex]);
	}

	public function has(name:String)
	{
		return byName.exists(name);
	}

	public function getItem(name:String)
	{
		return byName.get(name);
	}
}