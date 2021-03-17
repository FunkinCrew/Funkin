class MissType
{
    public var direction:Int = 0;
    public var missed:Bool = false;
    public var missedNote:Note = null;

    public function new(dir:Int = 0, miss:Bool = false, note:Note = null)
    {
        direction = dir;
        missed = miss;
        missedNote = note;
    }
}