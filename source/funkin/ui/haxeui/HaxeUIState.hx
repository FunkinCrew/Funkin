package funkin.ui.haxeui;

import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import lime.app.Application;

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
			Application.current.window.alert('Error building component "$assetPath": $e', 'HaxeUI Parsing Error');
			// trace('[ERROR] Failed to build component from asset: ' + assetPath);
			// trace(e);

			return null;
		}
	}

	/**
	 * The currently active context menu.
	 */
	public var contextMenu:Component;

	/**
	 * This function is called when right clicking on a component, to display a context menu.
	 */
	function showContextMenu(assetPath:String, xPos:Float, yPos:Float):Component
	{
		if (contextMenu != null)
			contextMenu.destroy();

		contextMenu = buildComponent(assetPath);

		if (contextMenu != null)
		{
			// Move the context menu to the mouse position.
			contextMenu.left = xPos;
			contextMenu.top = yPos;
			Screen.instance.addComponent(contextMenu);
		}

		return contextMenu;
	}

	/**
	 * Register a context menu to display when right clicking.
	 * @param component Only display the menu when clicking this component. If null, display the menu when right clicking anywhere.
	 * @param assetPath The asset path to the context menu XML.
	 */
	public function registerContextMenu(target:Null<Component>, assetPath:String):Void
	{
		if (target == null)
		{
			Screen.instance.registerEvent(MouseEvent.RIGHT_CLICK, function(e:MouseEvent)
			{
				showContextMenu(assetPath, e.screenX, e.screenY);
			});
		}
		else
		{
			target.registerEvent(MouseEvent.RIGHT_CLICK, function(e:MouseEvent)
			{
				showContextMenu(assetPath, e.screenX, e.screenY);
			});
		}
	}

	public function findComponent<T:Component>(criteria:String = null, type:Class<T> = null, recursive:Null<Bool> = null, searchType:String = "id"):Null<T>
	{
		if (component == null)
			return null;

		return component.findComponent(criteria, type, recursive, searchType);
	}

	override function destroy()
	{
		if (component != null)
			remove(component);
		component = null;

		super.destroy();
	}
}
