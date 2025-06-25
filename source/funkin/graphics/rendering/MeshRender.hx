package funkin.graphics.rendering;

import flixel.FlxStrip;
import flixel.util.FlxColor;

/**
 * Yoinked from AustinEast, thanks hopefully u dont mind me using some of ur good code
 * instead of my dumbass ugly code bro
 */
@:nullSafety
class MeshRender extends FlxStrip
{
  public var vertex_count(default, null):Int = 0;
  public var index_count(default, null):Int = 0;

  public function new(x, y, ?col:FlxColor = FlxColor.WHITE)
  {
    super(x, y);
    makeGraphic(1, 1, col);
  }

  /**
   * Add a vertex.
   */
  public inline function build_vertex(x:Float, y:Float, u:Float = 0, v:Float = 0):Int
  {
    final index = vertex_count;
    final pos = index << 1;

    vertices[pos] = x;
    vertices[pos + 1] = y;

    uvtData[pos] = u;
    uvtData[pos + 1] = v;

    vertex_count++;
    return index;
  }

  /**
   * Build a triangle from three vertex indexes.
   * @param a
   * @param b
   * @param c
   */
  public function add_tri(a:Int, b:Int, c:Int):Void
  {
    indices[index_count] = a;
    indices[index_count + 1] = b;
    indices[index_count + 2] = c;

    index_count += 3;
  }

  public function build_tri(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, au:Float = 0, av:Float = 0, bu:Float = 0, bv:Float = 0, cu:Float = 0,
      cv:Float = 0):Void
  {
    add_tri(build_vertex(ax, ay, au, av), build_vertex(bx, by, bu, bv), build_vertex(cx, cy, cu, cv));
  }

  /**
   * @param a top left vertex
   * @param b top right vertex
   * @param c bottom right vertex
   * @param d bottom left vertex
   */
  public function add_quad(a:Int, b:Int, c:Int, d:Int):Void
  {
    add_tri(a, b, c);
    add_tri(a, c, d);
  }

  /**
   * Build a quad from four points.
   *
   * top right - a
   * top left - b
   * bottom right  - c
   * bottom left - d
   */
  public function build_quad(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, au:Float = 0, av:Float = 0, bu:Float = 0,
      bv:Float = 0, cu:Float = 0, cv:Float = 0, du:Float = 0, dv:Float = 0):Void
  {
    // top left
    var b = build_vertex(bx, by, bu, bv);
    // top right
    var a = build_vertex(ax, ay, au, av);
    // bottom left
    var c = build_vertex(cx, cy, cu, cv);
    // bottom right
    var d = build_vertex(dx, dy, du, dv);

    add_tri(a, b, c);
    add_tri(a, c, d);
  }

  public function clear()
  {
    vertices.length = 0;
    indices.length = 0;
    uvtData.length = 0;
    colors.length = 0;
    vertex_count = 0;
    index_count = 0;
  }
}
