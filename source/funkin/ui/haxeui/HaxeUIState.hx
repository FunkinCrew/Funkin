package funkin.ui.haxeui;

import haxe.ui.components.CheckBox;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import funkin.ui.MusicBeatState;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.RuntimeComponentBuilder;
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

  override function create():Void
  {
    super.create();

    if (component == null) component = buildComponent(_componentKey);
    if (component != null) add(component);
  }

  public function buildComponent(assetPath:String):Component
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
    if (contextMenu != null) contextMenu.destroy();

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
      Screen.instance.registerEvent(MouseEvent.RIGHT_CLICK, function(e:MouseEvent) {
        showContextMenu(assetPath, e.screenX, e.screenY);
      });
    }
    else
    {
      target.registerEvent(MouseEvent.RIGHT_CLICK, function(e:MouseEvent) {
        showContextMenu(assetPath, e.screenX, e.screenY);
      });
    }
  }

  /**
   * Add an onClick listener to a HaxeUI menu bar item.
   */
  function addUIClickListener(key:String, callback:MouseEvent->Void):Void
  {
    var target:Component = findComponent(key);
    if (target == null)
    {
      // Gracefully handle the case where the item can't be located.
      trace('WARN: Could not locate menu item: $key');
    }
    else
    {
      target.onClick = callback;
    }
  }

  /**
   * Add an onRightClick listener to a HaxeUI menu bar item.
   */
  function addUIRightClickListener(key:String, callback:MouseEvent->Void):Void
  {
    var target:Component = findComponent(key);
    if (target == null)
    {
      // Gracefully handle the case where the item can't be located.
      trace('WARN: Could not locate menu item: $key');
    }
    else
    {
      target.onRightClick = callback;
    }
  }

  function setComponentText(key:String, text:String):Void
  {
    var target:Component = findComponent(key);
    if (target == null)
    {
      // Gracefully handle the case where the item can't be located.
      trace('WARN: Could not locate menu item: $key');
    }
    else
    {
      target.text = text;
    }
  }

  function setComponentShortcutText(key:String, text:String):Void
  {
    var target:MenuItem = findComponent(key, MenuItem);
    if (target == null)
    {
      // Gracefully handle the case where the item can't be located.
      trace('WARN: Could not locate menu item: $key');
    }
    else
    {
      target.shortcutText = text;
    }
  }

  function addTooltip(key:String, text:String):Void
  {
    var target:Component = findComponent(key);
    if (target == null)
    {
      // Gracefully handle the case where the item can't be located.
      trace('WARN: Could not locate menu item: $key');
    }
    else
    {
      target.tooltip = text;
    }
  }

  /**
   * Add an onChange listener to a HaxeUI input component such as a slider or text field.
   */
  function addUIChangeListener(key:String, callback:UIEvent->Void):Void
  {
    var target:Component = findComponent(key);
    if (target == null)
    {
      // Gracefully handle the case where the item can't be located.
      trace('WARN: Could not locate menu item: $key');
    }
    else
    {
      target.onChange = callback;
    }
  }

  /**
   * Set the value of a HaxeUI component.
   * Usually modifies the text of a label or value of a text field.
   */
  function setUIValue<T>(key:String, value:T):T
  {
    var target:Component = findComponent(key);
    if (target == null)
    {
      // Gracefully handle the case where the item can't be located.
      trace('WARN: Could not locate menu item: $key');
      return value;
    }
    else
    {
      return target.value = value;
    }
  }

  /**
   * Set the value of a HaxeUI checkbox,
   * since that's on 'selected' instead of 'value'.
   */
  public function setUICheckboxSelected<T>(key:String, value:Bool):Bool
  {
    var targetA:CheckBox = findComponent(key, CheckBox);

    if (targetA != null)
    {
      return targetA.selected = value;
    }

    var targetB:MenuCheckBox = findComponent(key, MenuCheckBox);
    if (targetB != null)
    {
      return targetB.selected = value;
    }

    // Gracefully handle the case where the item can't be located.
    trace('WARN: Could not locate check box: $key');
    return value;
  }

  public function findComponent<T:Component>(criteria:String = null, type:Class<T> = null, recursive:Null<Bool> = null, searchType:String = "id"):Null<T>
  {
    if (component == null) return null;

    return component.findComponent(criteria, type, recursive, searchType);
  }

  override function destroy():Void
  {
    if (component != null) remove(component);
    component = null;

    super.destroy();
  }
}
