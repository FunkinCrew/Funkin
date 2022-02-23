package ui;

import flixel.FlxCamera;
import flash.geom.Rectangle;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IHasParams;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUISpriteButton;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.FlxUI;


/*
THIS IS AN EDIT OF FlxUIDropDownMenu I'VE MADE BECAUSE I'M TIRED OF IT NOT SUPPORTING SCROLLING UP/DOWN
BAH!
The differences are the following:
* Support to scrolling up/down with mouse wheel or arrow keys
* THe default drop direction is "Down" instead of "Automatic"
*/



/**
 * @author larsiusprime
 */
class FlxUIDropDownMenuCustom extends FlxUIGroup implements IFlxUIWidget implements IFlxUIClickable implements IHasParams
{
	public var skipButtonUpdate(default, set):Bool;

	private function set_skipButtonUpdate(b:Bool):Bool
	{
		skipButtonUpdate = b;
		header.button.skipButtonUpdate = b;
		return b;
	}

	public var selectedId(get, set):String;
	public var selectedLabel(get, set):String;

	private var _selectedId:String;
	private var _selectedLabel:String;

	private var currentScroll:Int = 0; //Handles the scrolling
	public var canScroll:Bool = true;

	private function get_selectedId():String
	{
		return _selectedId;
	}

	private function set_selectedId(str:String):String
	{
		if (_selectedId == str)
			return str;

		var i:Int = 0;
		for (btn in list)
		{
			if (btn != null && btn.name == str)
			{
				var item:FlxUIButton = list[i];
				_selectedId = str;
				if (item.label != null)
				{
					_selectedLabel = item.label.text;
					header.text.text = item.label.text;
				}
				else
				{
					_selectedLabel = "";
					header.text.text = "";
				}
				return str;
			}
			i++;
		}
		return str;
	}

	private function get_selectedLabel():String
	{
		return _selectedLabel;
	}

	private function set_selectedLabel(str:String):String
	{
		if (_selectedLabel == str)
			return str;

		var i:Int = 0;
		for (btn in list)
		{
			if (btn.label.text == str)
			{
				var item:FlxUIButton = list[i];
				_selectedId = item.name;
				_selectedLabel = str;
				header.text.text = str;
				return str;
			}
			i++;
		}
		return str;
	}

	/**
	 * The header of this dropdown menu.
	 */
	public var header:FlxUIDropDownHeader;

	/**
	 * The list of items that is shown when the toggle button is clicked.
	 */
	public var list:Array<FlxUIButton> = [];

	/**
	 * The background for the list.
	 */
	public var dropPanel:FlxUI9SliceSprite;

	public var params(default, set):Array<Dynamic>;

	private function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		return params = p;
	}

	public var dropDirection(default, set):FlxUIDropDownMenuDropDirection = Down;

	private function set_dropDirection(dropDirection):FlxUIDropDownMenuDropDirection
	{
		this.dropDirection = dropDirection;
		updateButtonPositions();
		return dropDirection;
	}

	public static inline var CLICK_EVENT:String = "click_dropdown";

	public var callback:String->Void;

	// private var _ui_control_callback:Bool->FlxUIDropDownMenuCustom->Void;

	/**
	 * This creates a new dropdown menu.
	 *
	 * @param	X					x position of the dropdown menu
	 * @param	Y					y position of the dropdown menu
	 * @param	DataList			The data to be displayed
	 * @param	Callback			Optional Callback
	 * @param	Header				The header of this dropdown menu
	 * @param	DropPanel			Optional 9-slice-background for actual drop down menu
	 * @param	ButtonList			Optional list of buttons to be used for the corresponding entry in DataList
	 * @param	UIControlCallback	Used internally by FlxUI
	 */
	public function new(X:Float = 0, Y:Float = 0, DataList:Array<StrNameLabel>, ?Callback:String->Void, ?Header:FlxUIDropDownHeader,
			?DropPanel:FlxUI9SliceSprite, ?ButtonList:Array<FlxUIButton>, ?UIControlCallback:Bool->FlxUIDropDownMenuCustom->Void, ?Camera:FlxCamera)
	{
		if(Camera != null)
		{
			this.cameras = [Camera];
			this.camera = Camera;
		}

		super(X, Y);
		callback = Callback;
		header = Header;
		dropPanel = DropPanel;

		if (header == null)
			header = new FlxUIDropDownHeader(120, null, null, null, this.camera);

		header.camera = this.camera;

		if (dropPanel == null)
		{
			var rect = new Rectangle(0, 0, header.background.width, header.background.height);
			dropPanel = new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_BOX, rect, [1, 1, 14, 14]);
			dropPanel.camera = this.camera;
		}

		if (DataList != null)
		{
			for (i in 0...DataList.length)
			{
				var data = DataList[i];
				list.push(makeListButton(i, data.label, data.name));
			}
			selectSomething(DataList[0].name, DataList[0].label);
		}
		else if (ButtonList != null)
		{
			for (btn in ButtonList)
			{
				list.push(btn);
				btn.resize(header.background.width, header.background.height);
				btn.x = 1;
			}
		}
		updateButtonPositions();

		dropPanel.resize(header.background.width, getPanelHeight());
		dropPanel.visible = false;
		add(dropPanel);

		for (btn in list)
		{
			add(btn);
			btn.visible = false;
		}

		// _ui_control_callback = UIControlCallback;
		header.button.onUp.callback = onDropdown;
		add(header);
	}

	private function updateButtonPositions():Void
	{
		var buttonHeight = header.background.height;
		dropPanel.y = header.background.y;
		if (dropsUp())
			dropPanel.y -= getPanelHeight();
		else
			dropPanel.y += buttonHeight;

		var offset = dropPanel.y;
		for (i in 0...currentScroll) { //Hides buttons that goes before the current scroll
			var button:FlxUIButton = list[i];
			if(button != null) {
				button.y = -99999;
			}
		}
		for (i in currentScroll...list.length)
		{
			var button:FlxUIButton = list[i];
			if(button != null) {
				button.y = offset;
				offset += buttonHeight;
			}
		}
	}

	override function set_visible(Value:Bool):Bool
	{
		var vDropPanel = dropPanel.visible;
		var vButtons = [];
		for (i in 0...list.length)
		{
			if (list[i] != null)
			{
				vButtons.push(list[i].visible);
			}
			else
			{
				vButtons.push(false);
			}
		}
		super.set_visible(Value);
		dropPanel.visible = vDropPanel;
		for (i in 0...list.length)
		{
			if (list[i] != null)
			{
				list[i].visible = vButtons[i];
			}
		}
		return Value;
	}

	private function dropsUp():Bool
	{
		return dropDirection == Up || (dropDirection == Automatic && exceedsHeight());
	}

	private function exceedsHeight():Bool
	{
		return y + getPanelHeight() + header.background.height > FlxG.height;
	}

	private function getPanelHeight():Float
	{
		return list.length * header.background.height;
	}

	/**
	 * Change the contents with a new data list
	 * Replaces the old content with the new content
	 */
	public function setData(DataList:Array<StrNameLabel>):Void
	{
		var i:Int = 0;

		if (DataList != null)
		{
			for (data in DataList)
			{
				var recycled:Bool = false;
				if (list != null)
				{
					if (i <= list.length - 1)
					{ // If buttons exist, try to re-use them
						var btn:FlxUIButton = list[i];
						if (btn != null)
						{
							btn.label.text = data.label; // Set the label
							list[i].name = data.name; // Replace the name
							recycled = true; // we successfully recycled it
						}
					}
				}
				else
				{
					list = [];
				}
				if (!recycled)
				{ // If we couldn't recycle a button, make a fresh one
					var t:FlxUIButton = makeListButton(i, data.label, data.name);
					list.push(t);
					add(t);
					t.visible = false;
				}
				i++;
			}

			// Remove excess buttons:
			if (list.length > DataList.length)
			{ // we have more entries in the original set
				for (j in DataList.length...list.length)
				{ // start counting from end of list
					var b:FlxUIButton = list.pop(); // remove last button on list
					b.visible = false;
					b.active = false;
					remove(b, true); // remove from widget
					b.destroy(); // destroy it
					b = null;
				}
			}

			selectSomething(DataList[0].name, DataList[0].label);
		}

		dropPanel.resize(header.background.width, getPanelHeight());
		updateButtonPositions();
	}

	private function selectSomething(name:String, label:String):Void
	{
		header.text.text = label;
		selectedId = name;
		selectedLabel = label;
	}

	private function makeListButton(i:Int, Label:String, Name:String):FlxUIButton
	{
		var t:FlxUIButton = new FlxUIButton(0, 0, Label);
		t.broadcastToFlxUI = false;
		t.onUp.callback = onClickItem.bind(i);
		t.camera = this.camera;

		t.name = Name;

		t.loadGraphicSlice9([FlxUIAssets.IMG_INVIS, FlxUIAssets.IMG_HILIGHT, FlxUIAssets.IMG_HILIGHT], Std.int(header.background.width),
			Std.int(header.background.height), [[1, 1, 3, 3], [1, 1, 3, 3], [1, 1, 3, 3]], FlxUI9SliceSprite.TILE_NONE);
		t.labelOffsets[FlxButton.PRESSED].y -= 1; // turn off the 1-pixel depress on click

		t.up_color = FlxColor.BLACK;
		t.over_color = FlxColor.WHITE;
		t.down_color = FlxColor.WHITE;

		t.resize(header.background.width - 2, header.background.height - 1);

		t.label.alignment = "left";
		t.autoCenterLabel();
		t.x = 1;

		for (offset in t.labelOffsets)
		{
			offset.x += 2;
		}

		return t;
	}

	/*public function setUIControlCallback(UIControlCallback:Bool->FlxUIDropDownMenuCustom->Void):Void {
		_ui_control_callback = UIControlCallback;
	}*/
	public function changeLabelByIndex(i:Int, NewLabel:String):Void
	{
		var btn:FlxUIButton = getBtnByIndex(i);
		if (btn != null && btn.label != null)
		{
			btn.label.text = NewLabel;
		}
	}

	public function changeLabelById(name:String, NewLabel:String):Void
	{
		var btn:FlxUIButton = getBtnById(name);
		if (btn != null && btn.label != null)
		{
			btn.label.text = NewLabel;
		}
	}

	public function getBtnByIndex(i:Int):FlxUIButton
	{
		if (i >= 0 && i < list.length)
		{
			return list[i];
		}
		return null;
	}

	public function getBtnById(name:String):FlxUIButton
	{
		for (btn in list)
		{
			if (btn.name == name)
			{
				return btn;
			}
		}
		return null;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if FLX_MOUSE
		if (dropPanel.visible)
		{
			if(list.length > 1 && canScroll) {
				if(FlxG.mouse.wheel > 0 || FlxG.keys.justPressed.UP) {
					// Go up
					--currentScroll;
					if(currentScroll < 0) currentScroll = 0;
					updateButtonPositions();
				}
				else if (FlxG.mouse.wheel < 0 || FlxG.keys.justPressed.DOWN) {
					// Go down
					currentScroll++;
					if(currentScroll >= list.length) currentScroll = list.length-1;
					updateButtonPositions();
				}
			}

			if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this, this.camera))
			{
				showList(false);
			}
		}
		#end
	}

	override public function destroy():Void
	{
		super.destroy();

		dropPanel = FlxDestroyUtil.destroy(dropPanel);

		list = FlxDestroyUtil.destroyArray(list);
		// _ui_control_callback = null;
		callback = null;
	}

	private function showList(b:Bool):Void
	{
		for (button in list)
		{
			button.visible = b;
			button.active = b;
		}

		dropPanel.visible = b;

		if(currentScroll != 0) {
			currentScroll = 0;
			updateButtonPositions();
		}

		FlxUI.forceFocus(b, this); // avoid overlaps
	}

	private function onDropdown():Void
	{
		(dropPanel.visible) ? showList(false) : showList(true);
	}

	private function onClickItem(i:Int):Void
	{
		var item:FlxUIButton = list[i];
		selectSomething(item.name, item.label.text);
		showList(false);

		if (callback != null)
		{
			callback(item.name);
		}

		if (broadcastToFlxUI)
		{
			FlxUI.event(CLICK_EVENT, this, item.name, params);
		}
	}

	/**
	 * Helper function to easily create a data list for a dropdown menu from an array of strings.
	 *
	 * @param	StringArray		The strings to use as data - used for both label and string ID.
	 * @param	UseIndexID		Whether to use the integer index of the current string as ID.
	 * @return	The StrIDLabel array ready to be used in FlxUIDropDownMenuCustom's constructor
	 */
	public static function makeStrIdLabelArray(StringArray:Array<String>, UseIndexID:Bool = false):Array<StrNameLabel>
	{
		var strIdArray:Array<StrNameLabel> = [];
		for (i in 0...StringArray.length)
		{
			var ID:String = StringArray[i];
			if (UseIndexID)
			{
				ID = Std.string(i);
			}
			strIdArray[i] = new StrNameLabel(ID, StringArray[i]);
		}
		return strIdArray;
	}
}

/**
 * Header for a FlxUIDropDownMenuCustom
 */
class FlxUIDropDownHeader extends FlxUIGroup
{
	/**
	 * The background of the header.
	 */
	public var background:FlxSprite;

	/**
	 * The text that displays the currently selected item.
	 */
	public var text:FlxUIText;

	/**
	 * The button that toggles the visibility of the dropdown panel.
	 */
	public var button:FlxUISpriteButton;

	/**
	 * Creates a new dropdown header to be used in a FlxUIDropDownMenuCustom.
	 *
	 * @param	Width	Width of the dropdown - only relevant when no back sprite was specified
	 * @param	Back	Optional sprite to be placed in the background
	 * @param 	Text	Optional text that displays the current value
	 * @param	Button	Optional button that toggles the dropdown list
	 */
	public function new(Width:Int = 120, ?Background:FlxSprite, ?Text:FlxUIText, ?Button:FlxUISpriteButton, ?Camera:FlxCamera)
	{
		if(Camera != null)
			this.camera = Camera;

		super();

		background = Background;
		text = Text;
		button = Button;

		// Background
		if (background == null)
		{
			background = new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_BOX, new Rectangle(0, 0, Width, 20), [1, 1, 14, 14]);
		}

		background.camera = this.camera;

		// Button
		if (button == null)
		{
			button = new FlxUISpriteButton(0, 0, new FlxSprite(0, 0, FlxUIAssets.IMG_DROPDOWN));
			button.loadGraphicSlice9([FlxUIAssets.IMG_BUTTON_THIN], 80, 20, [FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_BUTTON)],
				FlxUI9SliceSprite.TILE_NONE, -1, false, FlxUIAssets.IMG_BUTTON_SIZE, FlxUIAssets.IMG_BUTTON_SIZE);
		}
		button.camera = this.camera;
		button.resize(background.height, background.height);
		button.x = background.x + background.width - button.width;

		// Reposition and resize the button hitbox so the whole header is clickable
		button.width = Width;
		button.offset.x -= (Width - button.frameWidth);
		button.x = offset.x;
		button.label.offset.x += button.offset.x;

		// Text
		if (text == null)
		{
			text = new FlxUIText(0, 0, Std.int(background.width));
		}
		text.camera = this.camera;
		text.setPosition(2, 4);
		text.color = FlxColor.BLACK;

		add(background);
		add(button);
		add(text);
	}

	override public function destroy():Void
	{
		super.destroy();

		background = FlxDestroyUtil.destroy(background);
		text = FlxDestroyUtil.destroy(text);
		button = FlxDestroyUtil.destroy(button);
	}
}

enum FlxUIDropDownMenuDropDirection
{
	Automatic;
	Down;
	Up;
}