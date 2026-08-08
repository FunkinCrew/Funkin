package funkin.util.macro;

#if macro
@:nullSafety
class FlxMacro
{
  /**
   * A macro to be called targeting the `FlxSprite` class.
   * @return An array of fields that the class contains.
   */
  public static macro function buildFlxSprite():Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    // The FlxSprite class. We can add new properties to this class.
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    // The fields of the FlxSprite.
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();
    var fieldsToAdd:Array<haxe.macro.Expr.Field> = (macro class TempClass
      {
        public var localX(get, set):Float;

        function get_localX():Float
        {
          return this.x;
        }

        function set_localX(value:Float):Float
        {
          return this.x = value;
        }

        public var localY(get, set):Float;

        function get_localY():Float
        {
          return this.y;
        }

        function set_localY(value:Float):Float
        {
          return this.y = value;
        }

        public var localAngle(get, set):Float;

        function get_localAngle():Float
        {
          return this.angle;
        }

        function set_localAngle(value:Float):Float
        {
          return this.angle = value;
        }

        public var localScale(get, set):flixel.math.FlxPoint;

        function get_localScale():flixel.math.FlxPoint
        {
          return this.scale;
        }

        function set_localScale(value:flixel.math.FlxPoint):flixel.math.FlxPoint
        {
          return this.scale = value;
        }

        public var localAlpha(get, set):Float;

        function get_localAlpha():Float
        {
          return this.alpha;
        }

        function set_localAlpha(value:Float):Float
        {
          return this.alpha = value;
        }

        public var localVisible(get, set):Bool;

        function get_localVisible():Bool
        {
          return this.visible;
        }

        function set_localVisible(value:Bool):Bool
        {
          return this.visible = value;
        }
      }).fields;

    var alreadyOwnedFields = [];

    for (f in fields)
    {
      for (a in fieldsToAdd)
      {
        if (f.name == a.name) alreadyOwnedFields.push(a.name);
      }
    }

    for (f in fieldsToAdd)
    {
      if (alreadyOwnedFields.contains(f.name)) continue;

      fields.push(f);
    }

    return fields;
  }
}
#end
