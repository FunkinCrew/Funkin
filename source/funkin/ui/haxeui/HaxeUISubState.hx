package funkin.ui.haxeui;

import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.core.Component;

class HaxeUISubState extends MusicBeatSubstate
{
  // The component representing the main UI.
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

    refreshComponent();
  }

  /**
   * Builds a component from a given XML file.
   * Call this in your code to load additional components at runtime.
   */
  public function buildComponent(assetPath:String)
  {
    trace('Building component $assetPath');
    return RuntimeComponentBuilder.fromAsset(assetPath);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    // Force quit.
    if (FlxG.keys.justPressed.F4) FlxG.switchState(new MainMenuState());

    // Refresh the component.
    if (FlxG.keys.justPressed.F5)
    {
      refreshComponent();
    }
  }

  function refreshComponent()
  {
    /*
      if (component != null)
      {
        remove(component);
        component = null;
      }

      if (component != null)
      {
        trace('Success!');
        add(component);
      }
      else
      {
        trace('Failed to build component $_componentKey');
      }
     */

    if (component == null)
    {
      component = buildComponent(_componentKey);
      add(component);
      trace(component);
    }
    else
    {
      var component2 = buildComponent(_componentKey);
      component2.x += 100;
      add(component2);
      trace(component2);
      remove(component);
    }
  }

  override function destroy()
  {
    if (component != null) remove(component);
    component = null;
  }
}
