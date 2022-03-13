package funkin.util;

/**
 * A static extension which provides utility functions for Iterators.
 * 
 * For example, add `using IteratorTools` then call `iterator.array()`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 */
class IteratorTools
{
	public static function array<T>(iterator:Iterator<T>):Array<T>
	{
		return [for (i in iterator) i];
	}
}
