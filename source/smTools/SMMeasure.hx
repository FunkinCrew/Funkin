#if sys
package smTools;

class SMMeasure
{
    public var notes:Array<SMNote>;

    private var _measure:Array<String>;

    public function new(measureData:Array<String>)
    {
        _measure = measureData;
        notes = [];
    }
}
#end