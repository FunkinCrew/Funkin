#if sys
package smTools;

class SMNote
{
    public var data:String;
    public var lane:Int;

    public function new(_data:String,_lane:Int)
    {
        data = _data;
        lane = _lane;
    }
}
#end