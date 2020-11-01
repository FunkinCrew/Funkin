package io.newgrounds.swf.common;


import haxe.ds.StringMap;

import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.text.TextField;

class DropDown {
	
	public var value(default, set):String;
	function set_value(v:String):String {
		
		if (this.value == v)
			return v;
		
		this.value = v;
		_selectedLabel.text = _values.get(v);
		
		if (_onChange != null)
			_onChange();
		
		return v;
	}
	
	var _choiceContainer:Sprite;
	var _selectedLabel:TextField;
	var _onChange:Void->Void;
	var _values:StringMap<String>;
	var _unusedChoices:Array<MovieClip>;
	
	public function new(target:MovieClip, label:String = "", onChange:Void->Void = null) {
		
		_onChange = onChange;
		
		_selectedLabel = cast cast(target.getChildByName("currentItem"), MovieClip).getChildByName("label");
		_selectedLabel.text = label;
		
		_values = new StringMap<String>();
		
		new Button(cast target.getChildByName("button"), onClickExpand);
		new Button(cast target.getChildByName("currentItem"), onClickExpand);
		_choiceContainer = new Sprite();
		_choiceContainer.visible = false;
		target.addChild(_choiceContainer);
		
		_unusedChoices = new Array<MovieClip>();
		while(true) {
			
			var item:MovieClip = cast target.getChildByName('item${_unusedChoices.length}');
			if (item == null)
				break;
			
			target.removeChild(item);
			_unusedChoices.push(item);
		}
	}
	
	public function addItem(name:String, value:String):Void {
		
		_values.set(value, name);
		
		if (_unusedChoices.length == 0) {
			
			NG.core.logError('cannot create another dropBox item max=${_choiceContainer.numChildren}');
			return;
		}
		
		var button = _unusedChoices.shift();
		cast(button.getChildByName("label"), TextField).text = name;
		_choiceContainer.addChild(button);
		
		new Button(button, onChoiceClick.bind(value));
	}
	
	function onClickExpand():Void {
		
		_choiceContainer.visible = !_choiceContainer.visible;
	}
	
	function onChoiceClick(name:String):Void {
		
		value = name;
		
		_choiceContainer.visible = false;
	} 
}