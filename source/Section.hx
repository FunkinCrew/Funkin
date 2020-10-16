package;

class Section
{
	/**
	 * NOT ACTUAL NOTE DATA! Just holds strum time and which part of the chart it is!
	 */
	public var notes:Array<Dynamic> = [];

	public var lengthInSteps:Int = 16;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}
