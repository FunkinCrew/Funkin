package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
/**
 * Math for a number field.
 */
class NumberFormula
{
  static var line:String = '';
  static var at:Int = 0;
  static var base:Float = 0;

  /**
   * Whether the text is math and not a plain number.
   */
  public static function isFormula(text:Null<String>):Bool
  {
    if (text == null) return false;
    var s:String = clean(text);
    for (i in 0...s.length)
    {
      var c:String = s.charAt(i);
      if (c == '+' || c == '*' || c == '/' || c == '^' || c == '(' || c == ')') return true;
      if (c == '-' && i > 0) return true;
    }
    return false;
  }

  /**
   * What the text does to the old value, or null if it stands on its own.
   */
  public static function relativePart(text:String, old:String):Null<String>
  {
    var s:String = clean(text);
    if (s == '') return null;
    var o:String = clean(old);
    if (o != '' && s.length > o.length && s.substr(0, o.length) == o)
    {
      var next:String = s.charAt(o.length);
      if (next == '+' || next == '-' || next == '*' || next == '/' || next == '^') return s.substr(o.length);
    }

    // negative
    var first:String = s.charAt(0);
    if (first == '+' || first == '*' || first == '/' || first == '^') return s;

    return null;
  }

  /**
   * The value of the text, or NaN if it is not valid math.
   */
  public static function evaluate(text:Null<String>):Float
  {
    if (text == null) return Math.NaN;
    return run(clean(text));
  }

  /**
   * The value of `tail` done to `value`, so 10 and "*2" gives 20.
   */
  public static function evaluateOn(value:Float, tail:String):Float
  {
    base = value;
    return run('x' + clean(tail));
  }

  static function clean(text:String):String
  {
    return StringTools.replace(StringTools.replace(text, ' ', ''), ',', '.');
  }

  static function run(text:String):Float
  {
    line = text;
    at = 0;
    if (line == '') return Math.NaN;
    var v:Float = added();
    if (at != line.length) return Math.NaN;
    return v;
  }

  static function added():Float
  {
    var v:Float = multiplied();
    while (at < line.length)
    {
      var c:String = line.charAt(at);
      if (c != '+' && c != '-') break;
      at++;
      var next:Float = multiplied();
      v = c == '+' ? v + next : v - next;
    }
    return v;
  }

  static function multiplied():Float
  {
    var v:Float = signed();
    while (at < line.length)
    {
      var c:String = line.charAt(at);
      if (c != '*' && c != '/') break;
      at++;
      var next:Float = signed();
      v = c == '*' ? v * next : (next == 0 ? Math.NaN : v / next);
    }
    return v;
  }

  static function signed():Float
  {
    if (at < line.length)
    {
      var c:String = line.charAt(at);
      if (c == '-')
      {
        at++;
        return -signed();
      }
      if (c == '+')
      {
        at++;
        return signed();
      }
    }
    return powered();
  }

  static function powered():Float
  {
    var v:Float = single();
    if (at < line.length && line.charAt(at) == '^')
    {
      at++;
      v = Math.pow(v, signed());
    }
    return v;
  }

  static function single():Float
  {
    if (at >= line.length) return Math.NaN;
    var c:String = line.charAt(at);
    if (c == 'x')
    {
      at++;
      return base;
    }
    if (c == '(')
    {
      at++;
      var v:Float = added();
      if (at >= line.length || line.charAt(at) != ')') return Math.NaN;
      at++;
      return v;
    }
    var from:Int = at;
    var dots:Int = 0;
    while (at < line.length)
    {
      var d:String = line.charAt(at);
      if (d == '.') dots++;
      else if (d < '0' || d > '9') break;
      at++;
    }
    if (at == from || dots > 1) return Math.NaN;
    var number:String = line.substring(from, at);
    if (number == '.') return Math.NaN;
    return Std.parseFloat(number);
  }
}
#end
