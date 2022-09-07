package funkin.ui.haxeui;

import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.core.Component;

class HaxeUIState extends MusicBeatState
{
	public var component:Component;

	var _componentKey:String;

	public function new(key:String)
	{
		super();
		_componentKey = key;
	}

	override function create()
	{
		super.create();

		if (component == null)
			component = buildComponent(_componentKey);
		if (component != null)
			add(component);
	}

	public function buildComponent(assetPath:String)
	{
		try
		{
			return RuntimeComponentBuilder.fromAsset(assetPath);
		}
		catch (e)
		{
			trace('[ERROR] Failed to build component from asset: ' + assetPath);
			trace(e);
			return null;
		}
	}

	override function destroy()
	{
		if (component != null)
			remove(component);
		component = null;
	}
}
