package funkin.mobile.polymod;

#if android
import android.DocumentFileUtil;
import haxe.io.Bytes;
import polymod.fs.PolymodFileSystem;
import polymod.fs.SysFileSystem;

/**
 * An implementation of IFileSystem which accesses files using the Android DocumentFile API.
 * This allows for interaction with files and directories managed by the Android storage access framework.
 */
class AndroidDocumentFileSystem extends SysFileSystem
{
    public function new(params:PolymodFileSystemParams):Void
    {
        super(params);
    }

    public override function exists(path:String):Bool
    {
        return DocumentFileUtil.exists(path);
    }

    public override function isDirectory(path:String):Bool
    {
        return DocumentFileUtil.isDirectory(path);
    }

    public override function readDirectory(path:String):Array<String>
    {
        try
        {
            return DocumentFileUtil.readDirectory(path);
        }
        catch (e:Dynamic)
        {
            Polymod.warning(DIRECTORY_MISSING, 'Could not find directory "${path}"');
            return [];
        }
    }

    public override function getFileContent(path:String):String
    {
        return DocumentFileUtil.getContent(path);
    }

    public override function getFileBytes(path:String):Bytes
    {
        if (!exists(path))
            return null;

        return DocumentFileUtil.getBytes(path);
    }
}
#end
