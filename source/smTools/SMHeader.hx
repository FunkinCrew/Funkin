#if sys
package smTools;

class SMHeader
{
    private var _header:Array<String>;

    public var TITLE = "";
    public var SUBTITLE = "";
    public var ARTIST = "";
    public var GENRE = "";
    public var CREDIT = "";
    public var MUSIC = "";
    public var BANNER = "";
    public var BACKGROUND = "";
    public var CDTITLE = "";
    public var OFFSET = "";
    public var BPMS = "";

    public function new(headerData:Array<String>)
    {
        _header = headerData;
        for (i in headerData)
            readHeaderLine(i);
    }

    function readHeaderLine(line:String)
    {
        var propName = line.split('#')[1].split(':')[0];
        var value = line.split(':')[1].split(';')[0];
        var prop = Reflect.getProperty(this,propName);

        if (prop != null)
        {
            Reflect.setProperty(this,propName,value);
        }
    }
}
#end