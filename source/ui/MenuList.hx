package ui;

import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.util.FlxSignal;

class MenuTypedList<T:MenuItem> extends FlxTypedGroup<T>
{
	public var selectedIndex(default, null) = 0;
	/** Called when a new item is highlighted */
	public var onChange(default, null) = new FlxTypedSignal<T->Void>();
	/** Called when an item is accepted */
	public var onAcceptPress(default, null) = new FlxTypedSignal<T->Void>();
	/** The navigation control scheme to use */
	public var navControls:NavControls;
	/** Set to false to disable nav control */
	public var enabled:Bool = true;
	
	var byName = new Map<String, T>();
	/** Set to true, internally to disable controls, without affecting vars like `enabled` */
	var busy:Bool = false;
	
	public function new (navControls:NavControls = Vertical)
	{
		this.navControls = navControls;
		super();
	}
	
	function addItem(name:String, item:T):T
	{
		if (length == selectedIndex)
			item.select();
		
		byName[name] = item;
		return add(item);
	}
	
	public function resetItem(oldName:String, newName:String, ?callback:Void->Void):T
	{
		if (!byName.exists(oldName))
			throw "No item named:" + oldName;
		
		var item = byName[oldName];
		byName.remove(oldName);
		byName[newName] = item;
		item.setItem(newName, callback);
		
		return item;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (enabled && !busy)
			updateControls();
	}
	
	inline function updateControls()
	{
		var controls = PlayerSettings.player1.controls;
		
		switch(navControls)
		{
			case Vertical:
			{
				if (controls.UP_P  ) prev();
				if (controls.DOWN_P) next();
			}
			case Horizontal:
			{
				if (controls.LEFT_P ) prev();
				if (controls.RIGHT_P) next();
			}
			case Both:
			{
				if (controls.LEFT_P  || controls.UP_P  ) prev();
				if (controls.RIGHT_P || controls.DOWN_P) next();
			}
		}
		
		//Todo: bypass popup blocker on firefox
		if (controls.ACCEPT)
			accept();
	}
	
	public function accept()
	{
		var selected = members[selectedIndex];
		onAcceptPress.dispatch(selected);
		
		if (selected.fireInstantly)
			selected.callback();
		else
		{
			busy = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxFlicker.flicker(selected, 1, 0.06, true, false, function(_)
			{
				busy = false;
				selected.callback();
			});
		}
	}
	
	inline function prev() changeItem(-1);
	inline function next() changeItem(1);
	
	function changeItem(amount:Int)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		var index = selectedIndex + amount;
		if (index >= length)
			index = 0;
		else if (index < 0)
			index = length - 1;
		
		selectItem(index);
	}
	
	public function selectItem(index:Int)
	{
		members[selectedIndex].idle();
		
		selectedIndex = index;
		
		var selected = members[selectedIndex];
		selected.select();
		onChange.dispatch(selected);
	}
	
	public function has(name:String)
	{
		return byName.exists(name);
	}
	
	public function getItem(name:String)
	{
		return byName[name];
	}
	
	override function destroy()
	{
		super.destroy();
		byName.clear();
	}
}

class MenuItem extends FlxSprite
{
	public var callback:Void->Void;
	public var name:String;
	/**
	 * Set to true for things like opening URLs otherwise, it may it get blocked.
	 */
	public var fireInstantly = false;
	public var selected(get, never):Bool;
	function get_selected() return alpha == 1.0;
	
	public function new (x = 0.0, y = 0.0, name:String, callback)
	{
		super(x, y);
		
		antialiasing = true;
		setData(name, callback);
		idle();
	}
	
	function setData(name:String, ?callback:Void->Void)
	{
		this.name = name;
		
		if (callback != null)
			this.callback = callback;
	}
	
	/**
	 * Calls setData and resets/redraws the state of the item
	 * @param name 
	 * @param callback 
	 */
	public function setItem(name:String, ?callback:Void->Void)
	{
		setData(name, callback);
		
		if (selected)
			select();
		else
			idle();
	}
	
	public function idle()
	{
		alpha = 0.6;
	}
	
	public function select()
	{
		alpha = 1.0;
	}
}

class MenuTypedItem<T:FlxSprite> extends MenuItem
{
	public var label(default, set):T;
	
	public function new (x = 0.0, y = 0.0, label:T, name:String, callback)
	{
		super(x, y, name, callback);
		// set label after super otherwise setters fuck up
		this.label = label;
	}
	
	/**
	 * Use this when you only want to show the label
	 */
	function setEmptyBackground()
	{
		var oldWidth = width;
		var oldHeight = height;
		makeGraphic(1, 1, 0x0);
		width = oldWidth;
		height = oldHeight;
	}
	
	function set_label(value:T)
	{
		if (value != null)
		{
			value.x = x;
			value.y = y;
			value.alpha = alpha;
		}
		return this.label = value;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (label != null)
			label.update(elapsed);
	}
	
	override function draw()
	{
		super.draw();
		if (label != null)
		{
			label.cameras = cameras;
			label.scrollFactor.copyFrom(scrollFactor);
			label.draw();
		}
	}

	override function set_alpha(value:Float):Float
	{
		super.set_alpha(value);
		
		if (label != null)
			label.alpha = alpha;
		
		return alpha;
	}

	override function set_x(value:Float):Float
	{
		super.set_x(value);
		
		if (label != null)
			label.x = x;
		
		return x;
	}

	override function set_y(Value:Float):Float
	{
		super.set_y(Value);
		
		if (label != null)
			label.y = y;
		
		return y;
	}
}

enum NavControls
{
	Horizontal;
	Vertical;
	Both;
}