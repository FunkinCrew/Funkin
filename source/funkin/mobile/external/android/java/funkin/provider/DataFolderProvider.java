package funkin.provider;

import android.annotation.SuppressLint;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.graphics.Point;
import android.os.CancellationSignal;
import android.os.ParcelFileDescriptor;
import android.provider.DocumentsProvider;
import android.provider.DocumentsContract.Root;
import android.provider.DocumentsContract.Document;
import android.util.Log;
import android.webkit.MimeTypeMap;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Path;

public class DataFolderProvider extends DocumentsProvider
{
  private static final String TAG = "DataFolderProvider";

  private static final String ROOT = "root";

  private static final String[] DEFAULT_ROOT_PROJECTION = new String[]{Root.COLUMN_ROOT_ID, Root.COLUMN_MIME_TYPES, Root.COLUMN_FLAGS, Root.COLUMN_ICON, Root.COLUMN_TITLE, Root.COLUMN_SUMMARY, Root.COLUMN_DOCUMENT_ID, Root.COLUMN_AVAILABLE_BYTES};

  private static final String[] DEFAULT_DOCUMENT_PROJECTION = new String[]{Document.COLUMN_DOCUMENT_ID, Document.COLUMN_MIME_TYPE, Document.COLUMN_DISPLAY_NAME, Document.COLUMN_LAST_MODIFIED, Document.COLUMN_FLAGS, Document.COLUMN_SIZE};

  private File rootDir;

  @Override
  public Cursor queryRoots(String[] projection) throws FileNotFoundException
  {
    final MatrixCursor result = new MatrixCursor(projection != null ? projection : DEFAULT_ROOT_PROJECTION);

    final MatrixCursor.RowBuilder row = result.newRow();

    row.add(Root.COLUMN_ROOT_ID, ROOT);

    row.add(Root.COLUMN_FLAGS, Root.FLAG_LOCAL_ONLY | Root.FLAG_SUPPORTS_CREATE | Root.FLAG_SUPPORTS_IS_CHILD);

    row.add(Root.COLUMN_SUMMARY, "Data Folder");

    row.add(Root.COLUMN_DOCUMENT_ID, getDocumentID(rootDir));

    ::if (APP_TITLE != "")::row.add(Root.COLUMN_TITLE, "::APP_TITLE::");::end::

    ::if (APP_PACKAGE != "")::row.add(Root.COLUMN_ICON, ::APP_PACKAGE::.R.mipmap.ic_launcher);::end::

    return result;
  }

  @Override
  public Cursor queryDocument(String documentId, String[] projection) throws FileNotFoundException
  {
    final MatrixCursor result = new MatrixCursor(projection != null ? projection : DEFAULT_DOCUMENT_PROJECTION);

    includeFile(result, getFileFromDocumentID(documentId));

    return result;
  }

  @Override
  public Cursor queryChildDocuments(String parentDocumentId, String[] projection, String sortOrder) throws FileNotFoundException
  {
    final MatrixCursor result = new MatrixCursor(projection != null ? projection : DEFAULT_DOCUMENT_PROJECTION);

    for (File file : getFileFromDocumentID(parentDocumentId).listFiles())
    {
      includeFile(result, file);
    }

    return result;
  }

  @Override
  public ParcelFileDescriptor openDocument(String documentId, String mode, CancellationSignal signal) throws FileNotFoundException
  {
    return ParcelFileDescriptor.open(getFileFromDocumentID(documentId), ParcelFileDescriptor.parseMode(mode));
  }

  @SuppressLint({"SetWorldReadable", "SetWorldWritable"})
  @Override
  public String createDocument(String parentDocumentId, String mimeType, String displayName) throws FileNotFoundException
  {
    File parentPath = getFileFromDocumentID(parentDocumentId);

    try
    {
      File file = new File(parentPath, displayName);

      if (mimeType.equals(Document.MIME_TYPE_DIR))
        assert file.mkdir();
      else
        assert file.createNewFile();

      assert file.setReadable(true, false);
      assert file.setWritable(true, false);

      return getDocumentID(file);
    }
    catch (IOException e)
    {
      throw new FileNotFoundException("Cannot create file with id " + parentDocumentId + "/" + displayName);
    }
  }

  @Override
  public void deleteDocument(String documentId) throws FileNotFoundException
  {
    File file = getFileFromDocumentID(documentId);

    Boolean result = false;

    try
    {
      if (file.isDirectory())
      {
        result = deleteFolderRecursively(file);
      }
      else
      {
        result = file.delete();
      }
    }
    catch (Exception e)
    {
      Log.e(TAG, e.toString());

      e.printStackTrace();
    }

    if (!result)
    {
      throw new FileNotFoundException("Failed to delete document with id " + documentId);
    }
  }

  public boolean deleteFolderRecursively(File folder)
  {
    boolean isSuccessful = true;

    final File[] files = folder.listFiles();

    if (files == null || !folder.exists())
      return false;

    for (File item : files)
    {
      if (item.isDirectory())
      {
        isSuccessful = isSuccessful && deleteFolderRecursively(item);
      }
      else
      {
        isSuccessful = isSuccessful && item.delete();
      }
    }

    isSuccessful = isSuccessful && folder.delete();

    return isSuccessful;
  }

  @Override
  public String renameDocument(String documentId, String displayName) throws FileNotFoundException
  {
    File origin = getFileFromDocumentID(documentId);
    File dest = new File(origin.getParentFile(), displayName);

    if (!origin.renameTo(dest))
    {
      throw new FileNotFoundException("Failed to rename document with id " + documentId + " to " + displayName);
    }

    return getDocumentID(dest);
  }

  @Override
  public boolean isChildDocument(String parentDocumentId, String documentId)
  {
    return documentId.startsWith(parentDocumentId);
  }

  @Override
  public AssetFileDescriptor openDocumentThumbnail(String documentId, Point sizeHint, CancellationSignal signal) throws FileNotFoundException
  {
    final File file = getFileFromDocumentID(documentId);
    final ParcelFileDescriptor parcelFileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
    return new AssetFileDescriptor(parcelFileDescriptor, 0, AssetFileDescriptor.UNKNOWN_LENGTH);
  }

  private String getDocumentID(File file)
  {
    Path filePath = file.toPath().normalize();
    Path rootPath = rootDir.toPath();

    if (!filePath.startsWith(rootPath))
      return null;

    return ROOT + ":" + rootPath.relativize(filePath).toString();
  }

  private File getFileFromDocumentID(String id)
  {
    final String[] separatedPath = id.split(":", 2);

    if (separatedPath.length < 2)
      return null;

    if (!separatedPath[0].equals(ROOT))
      return null;

    final String filePath = separatedPath[1];

    if (filePath.isEmpty())
      return rootDir;

    final Path rootPath = rootDir.toPath().normalize().toAbsolutePath();
    final Path desiredPath = rootPath.resolve(filePath).normalize().toAbsolutePath();

    if (!desiredPath.startsWith(rootPath))
    {
      return null;
    }

    return desiredPath.toFile();
  }

  private void includeFile(MatrixCursor result, File file)
  {
    if (file == null)
      file = rootDir;

    int flags = 0;
    final String mimeType = getTypeForFile(file);

    if (file.canWrite())
    {
      flags |= Document.FLAG_SUPPORTS_WRITE |
          Document.FLAG_SUPPORTS_DELETE |
          Document.FLAG_SUPPORTS_RENAME;

      if (file.isDirectory())
        flags |= Document.FLAG_DIR_SUPPORTS_CREATE;
    }

    if (mimeType.startsWith("image/"))
    {
      flags |= Document.FLAG_SUPPORTS_THUMBNAIL;
    }

    final  MatrixCursor.RowBuilder row = result.newRow();
    row.add(Document.COLUMN_DOCUMENT_ID, getDocumentID(file));
    row.add(Document.COLUMN_DISPLAY_NAME, file.getName());
    row.add(Document.COLUMN_SIZE, file.length());
    row.add(Document.COLUMN_MIME_TYPE, mimeType);
    row.add(Document.COLUMN_LAST_MODIFIED, file.lastModified());
    row.add(Document.COLUMN_FLAGS, flags);
  }

  private static String getTypeForFile(File file)
  {
    if (file.isDirectory())
    {
      return Document.MIME_TYPE_DIR;
    }
    else
    {
      return getTypeForName(file.getName());
    }
  }

  private static String getTypeForName(String name)
  {
    final int lastDot = name.lastIndexOf('.');
    if (lastDot >= 0)
    {
      final String extension = name.substring(lastDot + 1);

      if (extension.equals("hxc") || extension.equals("hx"))
        return "application/*";

      final String mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
      if (mime != null)
      {
        return mime;
      }
    }
    return "application/octet-stream";
  }

  @Override
  public boolean onCreate()
  {
    rootDir = getContext().getExternalFilesDir(null);

    return true;
  }
}
