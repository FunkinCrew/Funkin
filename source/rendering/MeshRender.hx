package rendering;

import flixel.FlxStrip;

/**
 * Yoinked from AustinEast, thanks hopefully u dont mind me using some of ur good code
 * instead of my dumbass ugly code bro
 */
class MeshRender extends FlxStrip
{
	public var vertex_count(default, null):Int = 0;
	public var index_count(default, null):Int = 0;

	var tri_offset:Int = 0;

	public function new(x, y)
	{
		super(x, y);
		makeGraphic(1, 1);
	}

	public inline function start()
	{
		tri_offset = vertex_count;
	}

	public inline function add_vertex(x:Float, y:Float, u:Float = 0, v:Float = 0)
	{
		final pos = vertex_count << 1;

		vertices[pos] = x;
		vertices[pos + 1] = y;

		uvtData[pos] = u;
		uvtData[pos + 1] = v;

		vertex_count++;
	}

	public function add_tri(a:Int, b:Int, c:Int)
	{
		indices[index_count] = a + tri_offset;
		indices[index_count + 1] = b + tri_offset;
		indices[index_count + 2] = c + tri_offset;

		index_count += 3;
	}

	/**
	 *
	 * top left - a
	 *
	 * top right - b
	 *
	 * bottom left  - c
	 *
	 * bottom right - d
	 */
	public function add_quad(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, au:Float = 0, av:Float = 0, bu:Float = 0,
			bv:Float = 0, cu:Float = 0, cv:Float = 0, du:Float = 0, dv:Float = 0)
	{
		start();
		// top left
		add_vertex(bx, by, bu, bv);
		// top right
		add_vertex(ax, ay, au, av);
		// bottom left
		add_vertex(cx, cy, cu, cv);
		// bottom right
		add_vertex(dx, dy, du, dv);

		add_tri(0, 1, 2);
		add_tri(0, 2, 3);
	}

	public function clear()
	{
		vertices.length = 0;
		indices.length = 0;
		vertex_count = 0;
		index_count = 0;
	}
}
