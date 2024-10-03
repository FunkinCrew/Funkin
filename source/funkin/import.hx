package;

#if !macro
// Only import these when we aren't in a macro.
import funkin.util.Constants;
import funkin.Assets;
import funkin.Paths;
import funkin.Preferences;
import flixel.FlxG; // This one in particular causes a compile error if you're using macros.
import flixel.system.debug.watch.Tracker;

// These are great.
using Lambda;
using StringTools;
using thx.Arrays;
using funkin.util.tools.ArraySortTools;
using funkin.util.tools.ArrayTools;
using funkin.util.tools.FloatTools;
using funkin.util.tools.Int64Tools;
using funkin.util.tools.IntTools;
using funkin.util.tools.IteratorTools;
using funkin.util.tools.MapTools;
using funkin.util.tools.SongEventDataArrayTools;
using funkin.util.tools.SongNoteDataArrayTools;
using funkin.util.tools.StringTools;
#end
