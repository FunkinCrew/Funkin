package funkin.graphics;

/**
 * A script that can be tied to a FunkinSprite.
 * Create a scripted class that extends FunkinSprite to use this.
 */
@:hscriptClass
class ScriptedFunkinSprite extends funkin.graphics.FunkinSprite implements polymod.hscript.HScriptedClass
{
  /**
   * Initialize a new instance of a scripted class.
   * @param clsName The class name of the script to initialize.
   * @param args Any additional arguments for the constructor
   * @return A newly constructed instance.
   */
  @:deprecated('Use scriptInit(clsName, args) instead.')
  public static function init(clsName:String, ...args:Dynamic):ScriptedFunkinSprite
  {
    return scriptInit(clsName, args);
  }
}
