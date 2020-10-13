package;

class Section
{
	/**
	 * NOT ACTUAL NOTE DATA! Just holds strum time and which part of the chart it is!
	 */
	public var notes:Array<Dynamic> = [];

	public var lengthInSteps:Int = 16;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}
