package funkin.modding.install;

import funkin.util.Constants;
import funkin.util.FileUtil;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Entry;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import polymod.PolymodConfig;

using StringTools;

/**
 * Downloads a mod archive from a one-click link and drops it into the mods folder.
 */
@:nullSafety
class ModInstaller
{
  /**
   * Parses a one-click link into its parts.
   *
   * `funkin-mod:<downloadUrl>,<modelName>,<itemId>`, where
   * the download URL is an `mmdl` link whose trailing id identifies the file.
   *
   * @param link The full URL, including the scheme.
   * @return The parsed request, or null if the link is malformed or points somewhere we don't trust.
   */
  public static function parseLink(link:Null<String>):Null<OneClickRequest>
  {
    if (link == null) return null;

    var body:String = link.trim();

    final prefix:String = '${Constants.ONE_CLICK_SCHEME}:';
    if (!body.toLowerCase().startsWith(prefix)) return null;

    body = body.substr(prefix.length);

    while (body.endsWith('/'))
      body = body.substr(0, body.length - 1);

    // Split from the right, since the download URL itself may legally contain commas.
    final lastComma:Int = body.lastIndexOf(',');
    if (lastComma == -1) return null;

    final firstComma:Int = body.lastIndexOf(',', lastComma - 1);
    if (firstComma == -1) return null;

    final downloadUrl:String = body.substring(0, firstComma).trim();
    final modelName:String = body.substring(firstComma + 1, lastComma).trim();
    final itemId:String = body.substring(lastComma + 1).trim();

    if (downloadUrl == '' || itemId == '') return null;

    if (!~/^[0-9]+$/.match(itemId)) return null;

    if (!isHostAllowed(downloadUrl)) return null;

    return {
      downloadUrl: downloadUrl,
      modelName: modelName == '' ? 'Mod' : modelName,
      itemId: itemId,
      fileId: extractTrailingId(downloadUrl)
    };
  }

  /**
   * Looks up the submission a one-click link points at.
   *
   * @param request The parsed link.
   * @param onSuccess Called with the resolved metadata.
   * @param onError Called with a human readable reason.
   */
  public static function fetchMetadata(request:OneClickRequest, onSuccess:OneClickMod->Void, onError:String->Void):Void
  {
    fetchProfile(request.modelName, request.itemId, request.fileId, true, onSuccess, onError);
  }

  /**
   * Looks up a submission listed in another one's requirements.
   *
   * @param requirement The requirement to resolve.
   * @param onSuccess Called with the resolved metadata.
   * @param onError Called with a human readable reason.
   */
  public static function fetchRequirement(requirement:OneClickRequirement, onSuccess:OneClickMod->Void, onError:String->Void):Void
  {
    if (requirement.model == null || requirement.itemId == null)
    {
      onError('That requirement isn\'t a GameBanana submission.');
      return;
    }

    fetchProfile(requirement.model, requirement.itemId, null, false, onSuccess, onError);
  }

  /**
   * Fetches and interprets a submission's profile.
   *
   * @param model The GameBanana model name, such as `Mod` or `Tool`.
   * @param itemId The submission ID.
   * @param fileId The specific file to pick, or null to take the only one.
   * @param enforceCategory Whether to refuse submissions outside the base game mod folder tree.
   */
  static function fetchProfile(model:String, itemId:String, fileId:Null<String>, enforceCategory:Bool, onSuccess:OneClickMod->Void,
      onError:String->Void):Void
  {
    final apiUrl:String = '${Constants.ONE_CLICK_API_URL}${model}/${itemId}/ProfilePage';

    loadUrl(apiUrl, URLLoaderDataFormat.TEXT, null, function(data:Dynamic):Void {
      var parsed:Null<OneClickMod> = null;

      try
      {
        parsed = interpretMetadata(fileId, haxe.Json.parse(Std.string(data)));
      }
      catch (e:Dynamic)
      {
        onError('Could not read the mod details from GameBanana.');
        trace('Failed to parse one-click metadata: ${e}');
        return;
      }

      if (parsed == null)
      {
        onError('That link does not point at a downloadable file.');
        return;
      }

      final mod:OneClickMod = parsed;

      if (!enforceCategory)
      {
        final problem:Null<String> = validate(mod, null);

        if (problem != null) onError(problem);
        else onSuccess(mod);

        return;
      }

      fetchModFolderCategories(function(allowed:Null<Array<Int>>):Void {
        final problem:Null<String> = validate(mod, allowed);
        if (problem != null)
        {
          onError(problem);
          return;
        }

        onSuccess(mod);
      });
    }, function(reason:String):Void {
      onError('Could not reach GameBanana. ${reason}');
    });
  }

  /**
   * The categories a base game mod folder is allowed to sit in.
   */
  static var modFolderCategories:Null<Array<Int>> = null;

  /**
   * Loads the mod folder category list, then hands it over.
   *
   * @param onReady Called with the allowed category IDs, or null if they couldn't be fetched.
   */
  static function fetchModFolderCategories(onReady:Null<Array<Int>>->Void):Void
  {
    if (modFolderCategories != null)
    {
      onReady(modFolderCategories);
      return;
    }

    loadUrl('${Constants.ONE_CLICK_CATEGORIES_URL}${Constants.ONE_CLICK_CATEGORY_ROOT}', URLLoaderDataFormat.TEXT, null,
      function(data:Dynamic):Void {
        final results:Array<Int> = [Constants.ONE_CLICK_CATEGORY_ROOT];

        try
        {
          final categories:Null<Array<Dynamic>> = cast haxe.Json.parse(Std.string(data));

          if (categories != null)
          {
            for (category in categories)
            {
              final id:Int = asInt(Reflect.field(category, '_idRow'));
              if (id != 0) results.push(id);
            }
          }
        }
        catch (e:Dynamic)
        {
          trace('Failed to parse the mod folder categories: ${e}');
          onReady(null);
          return;
        }

        modFolderCategories = results;
        onReady(results);
      }, function(reason:String):Void {
        trace('Failed to fetch the mod folder categories: ${reason}');
        onReady(null);
      });
  }

  /**
   * Downloads the archive described by the resolved metadata.
   *
   * @param mod The resolved metadata.
   * @param onProgress Called with a 0-1 ratio as the download runs.
   * @param onSuccess Called with the path of the downloaded archive, which the caller owns.
   * @param onError Called with a human readable reason.
   */
  public static function download(mod:OneClickMod, onProgress:Float->Void, onSuccess:String->Void, onError:String->Void):Void
  {
    if (!isHostAllowed(mod.downloadUrl))
    {
      onError('The download link points somewhere we don\'t trust.');
      return;
    }

    #if sys
    if (activeDownload != null)
    {
      onError('Another download is already running.');
      return;
    }

    // The download streams into the mods folder, so it has to exist before the transfer starts.
    PolymodHandler.createModRoot();

    // GameBanana already told us how big the file is, which covers the case where the CDN answers
    // with a chunked response and never sends a Content-Length for `sys.Http` to work from.
    final job:DownloadJob = new DownloadJob(mod.downloadUrl, mod.md5, mod.filesize, getTempPath());

    activeDownload = job;
    downloadOnProgress = onProgress;
    downloadOnSuccess = onSuccess;
    downloadOnError = onError;

    sys.thread.Thread.create(function():Void {
      runDownload(job);
    });
    #else
    onError('Downloading mods is not supported on this platform.');
    #end
  }

  #if sys
  /**
   * The download currently in flight, if any. Only one runs at a time.
   */
  static var activeDownload:Null<DownloadJob> = null;

  static var downloadOnProgress:Null<Float->Void> = null;
  static var downloadOnSuccess:Null<String->Void> = null;
  static var downloadOnError:Null<String->Void> = null;

  /**
   * The progress ratio last reported, so the callback only fires when it actually moves.
   */
  static var lastReportedProgress:Float = -1;

  /**
   * The install currently in flight, if any. Only one runs at a time.
   */
  static var activeInstall:Null<InstallJob> = null;

  static var installOnSuccess:Null<Array<String>->Void> = null;
  static var installOnError:Null<String->Void> = null;
  static var installOnProgress:Null<Float->Void> = null;

  static var lastReportedInstallProgress:Float = -1;

  #end

  /**
   * Moves a running download's progress and result back onto the main thread.
   */
  public static function pump():Void
  {
    #if sys
    pumpInstall();
    pumpDownload();
    #end
  }

  #if sys
  /**
   * Hands a finished install back to whoever asked for it.
   */
  static function pumpInstall():Void
  {
    final job:Null<InstallJob> = activeInstall;
    if (job == null) return;

    final snapshot = job.read();

    if (!snapshot.finished)
    {
      if (snapshot.progress - lastReportedInstallProgress < 0.005) return;

      lastReportedInstallProgress = snapshot.progress;

      if (installOnProgress != null) installOnProgress(snapshot.progress);

      return;
    }

    final onSuccess:Null<Array<String>->Void> = installOnSuccess;
    final onError:Null<String->Void> = installOnError;

    activeInstall = null;
    installOnSuccess = null;
    installOnError = null;
    installOnProgress = null;

    if (snapshot.error != null)
    {
      if (onError != null) onError(snapshot.error);
      return;
    }

    if (onSuccess != null) onSuccess(snapshot.destinations);
  }

  /**
   * Moves a running download's progress and result back onto the main thread.
   */
  static function pumpDownload():Void
  {
    final job:Null<DownloadJob> = activeDownload;
    if (job == null) return;

    final snapshot = job.read();

    if (!snapshot.finished)
    {
      if (snapshot.bytesTotal <= 0) return;

      final ratio:Float = snapshot.bytesLoaded / snapshot.bytesTotal;

      if (ratio - lastReportedProgress < 0.005) return;

      lastReportedProgress = ratio;

      if (downloadOnProgress != null) downloadOnProgress(ratio);

      return;
    }

    final onSuccess:Null<String->Void> = downloadOnSuccess;
    final onError:Null<String->Void> = downloadOnError;

    activeDownload = null;
    downloadOnProgress = null;
    downloadOnSuccess = null;
    downloadOnError = null;
    lastReportedProgress = -1;

    if (snapshot.error != null)
    {
      // A half written archive is no use to anybody.
      if (job != null) deleteTemp(job.tempPath);

      if (onError != null) onError(snapshot.error);
      return;
    }

    if (snapshot.result == null)
    {
      if (onError != null) onError('The download came back empty.');
      return;
    }

    if (onSuccess != null) onSuccess(snapshot.result);
  }
  #end

  /**
   * Abandons whatever is downloading. The thread finishes on its own and its result is discarded.
   */
  public static function cancelDownload():Void
  {
    #if sys
    final job:Null<DownloadJob> = activeDownload;

    activeDownload = null;
    downloadOnProgress = null;
    downloadOnSuccess = null;
    downloadOnError = null;
    lastReportedProgress = -1;

    // The thread may still be writing, so this is best effort. A leftover file gets reused by name
    // on the next attempt anyway.
    if (job != null) deleteTemp(job.tempPath);
    #end
  }

  #if sys
  /**
   * Where a download is streamed to before it becomes a mod.
   */
  static function getTempPath():String
  {
    return Path.join([getModFolder(), '.oneclick-download.part']);
  }

  /**
   * Removes a temp download, if it's still there.
   */
  static function deleteTemp(path:String):Void
  {
    try
    {
      if (sys.FileSystem.exists(path)) sys.FileSystem.deleteFile(path);
    }
    catch (e:Dynamic)
    {
      trace('Failed to clean up a downloaded archive: ${e}');
    }
  }
  #end

  #if sys
  /**
   * The body of the download thread. Follows redirects, transfers the archive, checks the hash.
   */
  static function runDownload(job:DownloadJob):Void
  {
    var current:String = job.url;

    for (hop in 0...MAX_REDIRECTS)
    {
      if (!isHostAllowed(current))
      {
        job.fail('That download redirected somewhere we don\'t trust.');
        return;
      }

      final http:haxe.Http = new haxe.Http(current);

      http.setHeader('User-Agent', Constants.ONE_CLICK_USER_AGENT);

      var status:Int = 0;
      http.onStatus = function(value:Int):Void {
        status = value;
      };
      http.onError = function(message:String):Void {
        trace('Download error: ${message}');
      };

      var output:Null<DownloadOutput> = null;
      var written:Int = 0;

      try
      {
        output = new DownloadOutput(job, job.tempPath);

        http.customRequest(false, output);

        written = output.close2();
      }
      catch (e:Dynamic)
      {
        if (output != null) output.close2();

        job.fail('The download failed. ${Std.string(e)}');
        return;
      }

      if (status >= 300 && status < 400)
      {
        final location:Null<String> = getResponseHeader(http, 'location');

        if (location == null)
        {
          job.fail('That download redirected without saying where to.');
          return;
        }

        current = location.startsWith('http') ? location : resolveRelative(current, location);

        job.reset();
        continue;
      }

      if (written == 0)
      {
        job.fail('The download came back empty.');
        return;
      }

      final problem:Null<String> = verify(job, written);

      if (problem != null)
      {
        job.fail(problem);
        return;
      }

      job.succeed(job.tempPath);
      return;
    }

    job.fail('That download redirected too many times.');
  }

  /**
   * Checks a finished download against what GameBanana said it should be.
   *
   * @return A human readable reason, or null if the file looks right.
   */
  static function verify(job:DownloadJob, written:Int):Null<String>
  {
    if (job.expectedSize > 0 && written != job.expectedSize)
    {
      trace('One-click size mismatch: expected ${job.expectedSize}, got ${written}');
      return 'The download was cut short.';
    }

    if (job.md5 == null || job.md5 == '') return null;

    if (written > Constants.ONE_CLICK_MAX_HASH_SIZE)
    {
      trace('Skipping the checksum for a ${written} byte archive, the size matched instead.');
      return null;
    }

    final actual:String = haxe.crypto.Md5.make(sys.io.File.getBytes(job.tempPath)).toHex();

    if (actual.toLowerCase() != job.md5.toLowerCase())
    {
      trace('One-click checksum mismatch: expected ${job.md5}, got ${actual}');
      return 'The downloaded file is corrupt.';
    }

    return null;
  }

  static inline final MAX_REDIRECTS:Int = 5;
  #end

  /**
   * Fetches the submission's preview image, so the prompt has something to show.
   *
   * @param mod The resolved metadata.
   * @param onSuccess Called with the decoded image.
   */
  public static function downloadIcon(mod:OneClickMod, onSuccess:openfl.display.BitmapData->Void):Void
  {
    final url:Null<String> = mod.iconUrl;
    if (url == null || !isHostAllowed(url)) return;

    loadUrl(url, URLLoaderDataFormat.BINARY, null, function(data:Dynamic):Void {
      try
      {
        final bitmap:Null<openfl.display.BitmapData> = openfl.display.BitmapData.fromBytes(cast(data, ByteArray));

        if (bitmap != null) onSuccess(bitmap);
      }
      catch (e:Dynamic)
      {
        trace('Failed to decode the preview image: ${e}');
      }
    }, function(reason:String):Void {
      trace('Failed to fetch the preview image: ${reason}');
    });
  }

  /**
   * Writes a verified archive into the mods folder, on a background thread.
   *
   * @param mod The resolved metadata.
   * @param archivePath The verified archive on disk. Consumed, so it is gone afterwards either way.
   * @param onProgress Called with how far through the archive the worker is, from 0 to 1.
   * @param onSuccess Called with every path written. Empty if the archive held no mod at all.
   * @param onError Called with a human readable reason.
   */
  public static function install(mod:OneClickMod, archivePath:String, onProgress:Float->Void, onSuccess:Array<String>->Void, onError:String->Void):Void
  {
    #if sys
    if (activeInstall != null)
    {
      onError('Another install is already running.');
      return;
    }

    final job:InstallJob = new InstallJob();

    activeInstall = job;
    installOnSuccess = onSuccess;
    installOnError = onError;
    installOnProgress = onProgress;
    lastReportedInstallProgress = -1;

    sys.thread.Thread.create(function():Void {
      try
      {
        job.succeed(write(mod, archivePath, job));
      }
      catch (e:Dynamic)
      {
        job.fail(Std.string(e));
      }

      deleteTemp(archivePath);
    });
    #else
    onError('Installing mods is not supported on this platform.');
    #end
  }

  /**
   * Abandons whatever is installing. The thread finishes on its own and its result is discarded.
   */
  public static function cancelInstall():Void
  {
    #if sys
    activeInstall = null;
    installOnSuccess = null;
    installOnError = null;
    installOnProgress = null;
    #end
  }

  /**
   * Puts a verified archive in the mods folder, if it holds any mods.
   *
   * @return Every path that was written.
   */
  static function write(mod:OneClickMod, archivePath:String, job:InstallJob):Array<String>
  {
    #if sys
    final entries:List<Entry> = readArchive(archivePath);

    final metadata:Null<Entry> = findMetadata(entries, PolymodConfig.modMetadataFile);

    if (metadata == null) return [];

    PolymodHandler.createModRoot();

    final destination:String = uniquePath(Path.join([getModFolder(), '${sanitizeName(mod.name)}.zip']));

    job.report(0.5);

    final patched:Null<Bytes> = buildPatchedMetadata(metadata, Path.withoutExtension(Path.withoutDirectory(destination)));

    if (patched == null)
    {
      // Nothing to change, so the archive goes in exactly as it was downloaded.
      sys.FileSystem.rename(archivePath, destination);
    }
    else
    {
      metadata.data = patched;
      metadata.fileSize = patched.length;
      metadata.dataSize = patched.length;
      metadata.compressed = false;

      // Cleared so the writer works out the checksum of what we just put in.
      metadata.crc32 = null;

      writeArchive(entries, destination);
    }

    job.report(1);

    return [destination];
    #else
    throw 'Installing mods is not supported on this platform.';
    #end
  }

  #if sys
  /**
   * Reads every entry out of an archive, leaving the payloads compressed.
   */
  static function readArchive(archivePath:String):List<Entry>
  {
    final input:sys.io.FileInput = sys.io.File.read(archivePath, true);

    try
    {
      final entries:List<Entry> = haxe.zip.Reader.readZip(input);

      input.close();

      return entries;
    }
    catch (e:Dynamic)
    {
      input.close();

      trace('Failed to read the downloaded archive: ${e}');
      throw 'That download is not a readable ZIP archive.';
    }
  }

  /**
   * Writes entries back out as an archive.
   *
   * Anything still compressed is carried across as is, so only the entry we replaced is rebuilt.
   */
  static function writeArchive(entries:List<Entry>, destination:String):Void
  {
    final output:sys.io.FileOutput = sys.io.File.write(destination, true);

    try
    {
      new haxe.zip.Writer(output).write(entries);
    }
    catch (e:Dynamic)
    {
      output.close();

      // A half written archive is worse than none, Polymod picks it up on the next scan.
      if (FileUtil.pathExists(destination)) FileUtil.deleteFile(destination);

      throw e;
    }

    output.close();
  }

  /**
   * Finds the mod's metadata, at the archive's root or in the folder inside it.
   */
  static function findMetadata(entries:List<Entry>, metaFile:String):Null<Entry>
  {
    for (entry in entries)
    {
      final name:String = normalizeEntryName(entry.fileName);

      if (isJunkEntry(name)) continue;

      if (name == metaFile || name.endsWith('/${metaFile}')) return entry;
    }

    return null;
  }

  /**
   * Gives the mod an ID based on the archive's name, if it didn't declare one itself.
   *
   * @param fileName The archive's name, without the folder or the extension.
   * @return The rewritten metadata, or null if it already had an ID.
   */
  static function buildPatchedMetadata(metadata:Entry, fileName:String):Null<Bytes>
  {
    final raw:Null<Bytes> = metadata.compressed ? haxe.zip.Reader.unzip(metadata) : metadata.data;
    if (raw == null) return null;

    var json:Dynamic = null;

    try
    {
      json = haxe.Json.parse(raw.toString());
    }
    catch (e:Dynamic)
    {
      // Not our problem to fix. Polymod reports it properly when it tries to load the mod.
      trace('Could not read the downloaded mod\'s metadata: ${e}');
      return null;
    }

    final existing:Null<String> = asString(Reflect.field(json, 'id'));
    if (existing != null && existing.trim() != '') return null;

    final id:String = sanitizeModId(fileName);

    Reflect.setField(json, 'id', id);

    trace('Giving the downloaded mod the ID "${id}", since it did not declare one.');

    return Bytes.ofString(haxe.Json.stringify(json, null, '  '));
  }
  #end

  /**
   * Whether a mod with this name is already sitting in the mods folder.
   */
  public static function isAlreadyInstalled(mod:OneClickMod):Bool
  {
    #if sys
    final baseName:String = sanitizeName(mod.name);
    final modFolder:String = getModFolder();

    return FileUtil.pathExists(Path.join([modFolder, '${baseName}.zip'])) || FileUtil.pathExists(Path.join([modFolder, baseName]));
    #else
    return false;
    #end
  }

  #if sys
  /**
   * Reads a response header without caring about its capitalisation.
   */
  static function getResponseHeader(http:haxe.Http, name:String):Null<String>
  {
    final headers:Null<Map<String, String>> = http.responseHeaders;
    if (headers == null) return null;

    for (key => value in headers)
    {
      if (key.toLowerCase() == name) return value;
    }

    return null;
  }

  /**
   * Turns a relative `Location` header into an absolute URL against the URL it came from.
   */
  static function resolveRelative(base:String, location:String):String
  {
    if (location.startsWith('//')) return 'https:${location}';

    final schemeEnd:Int = base.indexOf('://');
    if (schemeEnd == -1) return location;

    final rootEnd:Int = base.indexOf('/', schemeEnd + 3);
    final root:String = rootEnd == -1 ? base : base.substr(0, rootEnd);

    if (location.startsWith('/')) return '${root}${location}';

    final lastSlash:Int = base.lastIndexOf('/');

    return lastSlash <= schemeEnd + 2 ? '${root}/${location}' : '${base.substr(0, lastSlash + 1)}${location}';
  }
  #end

  /**
   * Whether a URL points at a host we're willing to download from.
   */
  public static function isHostAllowed(url:String):Bool
  {
    final host:Null<String> = getHost(url);
    if (host == null) return false;

    for (domain in Constants.ONE_CLICK_ALLOWED_DOMAINS)
    {
      // stop shit like 'evilgamebanana.com' from passing
      if (host == domain || host.endsWith('.${domain}')) return true;
    }

    return false;
  }

  /**
   * Pulls the host out of an absolute HTTPS URL.
   *
   * @return The lowercased host, or null if the URL isn't absolute HTTPS.
   */
  static function getHost(url:String):Null<String>
  {
    if (!url.toLowerCase().startsWith('https://')) return null;

    var rest:String = url.substr('https://'.length);

    for (terminator in ['/', '?', '#'])
    {
      final index:Int = rest.indexOf(terminator);
      if (index != -1) rest = rest.substr(0, index);
    }

    // Strip any userinfo, since the host is what comes after the `@` in `user:pass@host`.
    final at:Int = rest.lastIndexOf('@');
    if (at != -1) rest = rest.substr(at + 1);

    final colon:Int = rest.indexOf(':');
    if (colon != -1) rest = rest.substr(0, colon);

    rest = rest.toLowerCase();

    return rest == '' ? null : rest;
  }

  /**
   * The last path segment of a URL, when it's a plain number.
   * GameBanana `mmdl` links end in the id of the file to download.
   */
  static function extractTrailingId(url:String):Null<String>
  {
    var path:String = url;

    for (terminator in ['?', '#'])
    {
      final index:Int = path.indexOf(terminator);
      if (index != -1) path = path.substr(0, index);
    }

    final slash:Int = path.lastIndexOf('/');
    if (slash == -1) return null;

    final id:String = path.substr(slash + 1);

    return ~/^[0-9]+$/.match(id) ? id : null;
  }

  /**
   * Builds the URL of the submission's first preview image, to stand in for a mod icon.
   * The mod's real icon is inside the archive, which we haven't downloaded yet.
   */
  static function extractPreviewUrl(json:Dynamic):Null<String>
  {
    final media:Null<Dynamic> = Reflect.field(json, '_aPreviewMedia');
    if (media == null) return null;

    final images:Null<Array<Dynamic>> = cast Reflect.field(media, '_aImages');
    if (images == null || images.length == 0) return null;

    final base:Null<String> = asString(Reflect.field(images[0], '_sBaseUrl'));

    // The 220px crop is the closest match to the 96px icon slot.
    final file:Null<String> = asString(Reflect.field(images[0], '_sFile220')) ?? asString(Reflect.field(images[0], '_sFile'));

    if (base == null || file == null) return null;

    final url:String = '${base}/${file}';

    return isHostAllowed(url) ? url : null;
  }

  /**
   * Reads the submission's requirements.
   */
  static function parseRequirements(json:Dynamic):Array<OneClickRequirement>
  {
    final results:Array<OneClickRequirement> = [];

    final requirements:Null<Array<Dynamic>> = cast Reflect.field(json, '_aRequirements');
    if (requirements == null) return results;

    for (requirement in requirements)
    {
      final entry:Null<Array<Dynamic>> = cast requirement;
      if (entry == null || entry.length == 0) continue;

      final name:String = asString(entry[0]) ?? '';
      if (name == '') continue;

      final url:Null<String> = entry.length > 1 ? asString(entry[1]) : null;
      final target = parseSubmissionUrl(url);

      if (target.model == null || target.itemId == null)
      {
        trace('Ignoring the requirement "${name}", it does not link to a GameBanana submission.');
        continue;
      }

      results.push(
        {
          name: name,
          url: url,
          model: target.model,
          itemId: target.itemId
        });
    }

    return results;
  }

  /**
   * Pulls the model and submission ID out of a GameBanana profile URL.
   *
   * @return The parsed pair, both null if the URL isn't a GameBanana submission.
   */
  static function parseSubmissionUrl(url:Null<String>):{model:Null<String>, itemId:Null<String>}
  {
    if (url == null || url == '' || !isHostAllowed(url)) return {model: null, itemId: null};

    // The plural path segment in a profile URL maps onto the API's model name.
    final pattern:EReg = ~/gamebanana\.com\/([a-z]+)\/([0-9]+)/i;

    if (!pattern.match(url)) return {model: null, itemId: null};

    final model:Null<String> = Constants.ONE_CLICK_MODELS.get(pattern.matched(1).toLowerCase());
    if (model == null) return {model: null, itemId: null};

    return {model: model, itemId: pattern.matched(2)};
  }

  /**
   * Turns the GameBanana ProfilePage response into something we can act on.
   */
  static function interpretMetadata(fileId:Null<String>, json:Dynamic):Null<OneClickMod>
  {
    if (json == null) return null;

    final files:Null<Array<Dynamic>> = cast Reflect.field(json, '_aFiles');
    if (files == null || files.length == 0) return null;

    var match:Null<Dynamic> = null;

    if (fileId != null)
    {
      for (file in files)
      {
        if (Std.string(Reflect.field(file, '_idRow')) == fileId)
        {
          match = file;
          break;
        }
      }
    }

    if (match == null && (files.length == 1 || fileId == null)) match = files[0];

    if (match == null) return null;

    final submitter:Null<Dynamic> = Reflect.field(json, '_aSubmitter');
    final category:Null<Dynamic> = Reflect.field(json, '_aCategory');
    final superCategory:Null<Dynamic> = Reflect.field(json, '_aSuperCategory');

    return {
      categoryId: category == null ? 0 : asInt(Reflect.field(category, '_idRow')),
      superCategoryId: superCategory == null ? 0 : asInt(Reflect.field(superCategory, '_idRow')),
      categoryName: category == null ? 'Unknown' : (asString(Reflect.field(category, '_sName')) ?? 'Unknown'),
      name: asString(Reflect.field(json, '_sName')) ?? 'Unknown Mod',
      author: submitter == null ? 'Unknown' : (asString(Reflect.field(submitter, '_sName')) ?? 'Unknown'),
      filename: asString(Reflect.field(match, '_sFile')) ?? 'mod.zip',
      downloadUrl: asString(Reflect.field(match, '_sDownloadUrl')) ?? '',
      requirements: parseRequirements(json),
      filesize: asInt(Reflect.field(match, '_nFilesize')),
      md5: asString(Reflect.field(match, '_sMd5Checksum')),
      iconUrl: extractPreviewUrl(json),
      avResult: asString(Reflect.field(match, '_sAvResult')),
      analysisResult: asString(Reflect.field(match, '_sAnalysisResult'))
    };
  }

  /**
   * Rejects anything we shouldn't be downloading.
   *
   * @param mod The resolved metadata.
   * @param allowedCategories The categories that count as a base game mod folder, or null if we
   * couldn't look them up.
   * @return A human readable reason, or null if the file is fine.
   */
  static function validate(mod:OneClickMod, allowedCategories:Null<Array<Int>>):Null<String>
  {
    if (!isHostAllowed(mod.downloadUrl)) return 'The download link points somewhere untrusted.';

    if (allowedCategories != null
      && !allowedCategories.contains(mod.categoryId)
      && !allowedCategories.contains(mod.superCategoryId))
    {
      return 'That\'s a "${mod.categoryName}" upload, not a mod folder for this game.';
    }

    if (!mod.filename.toLowerCase().endsWith('.zip')) return 'Only ZIP archives can be installed this way.';

    if (mod.filesize > Constants.ONE_CLICK_MAX_FILESIZE)
    {
      return 'That mod is too large to install from a link.';
    }

    if (mod.avResult != null && mod.avResult != '' && mod.avResult.toLowerCase() != 'clean')
    {
      return 'GameBanana flagged that file as unsafe.';
    }

    if (mod.analysisResult != null && mod.analysisResult != '' && mod.analysisResult.toLowerCase() != 'ok')
    {
      return 'GameBanana couldn\'t verify that file.';
    }

    return null;
  }

  /**
   * Shared wrapper around URLLoader, so every request gets its listeners cleaned up.
   */
  static function loadUrl(url:String, format:URLLoaderDataFormat, onProgress:Null<Float->Void>, onSuccess:Dynamic->Void, onError:String->Void):Void
  {
    final loader:URLLoader = new URLLoader();
    loader.dataFormat = format;

    var finished:Bool = false;

    function cleanup():Void
    {
      finished = true;

      @:privateAccess
      loader.__removeAllListeners();
    }

    loader.addEventListener(Event.COMPLETE, function(_:Event):Void {
      if (finished) return;

      final data:Dynamic = loader.data;

      cleanup();
      onSuccess(data);
    });

    loader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):Void {
      if (finished) return;

      cleanup();
      onError(event.text);
    });

    loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):Void {
      if (finished) return;

      cleanup();
      onError(event.text);
    });

    if (onProgress != null)
    {
      loader.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):Void {
        if (finished || event.bytesTotal <= 0) return;

        onProgress(event.bytesLoaded / event.bytesTotal);
      });
    }

    try
    {
      loader.load(new URLRequest(url));
    }
    catch (e:Dynamic)
    {
      cleanup();
      onError(Std.string(e));
    }
  }

  /**
   * Whether an archive entry is packaging noise rather than part of the mod.
   */
  static function isJunkEntry(name:String):Bool
  {
    if (name.startsWith('__MACOSX/')) return true;

    return Path.withoutDirectory(name).startsWith('._');
  }

  #if sys
  /**
   * The mods folder as an absolute path.
   */
  static function getModFolder():String
  {
    try
    {
      return sys.FileSystem.fullPath(PolymodHandler.MOD_FOLDER);
    }
    catch (e:Dynamic)
    {
      trace('Could not resolve the mods folder to an absolute path: ${e}');
      return PolymodHandler.MOD_FOLDER;
    }
  }

  /**
   * Picks a path that doesn't already exist, so an install never clobbers a mod the player has.
   */
  static function uniquePath(path:String):String
  {
    if (!FileUtil.pathExists(path)) return path;

    final extension:String = Path.extension(path);
    final base:String = extension == '' ? path : path.substr(0, path.length - extension.length - 1);

    var index:Int = 2;

    while (index < 1000)
    {
      final candidate:String = extension == '' ? '${base}-${index}' : '${base}-${index}.${extension}';

      if (!FileUtil.pathExists(candidate)) return candidate;

      index++;
    }

    throw 'Could not find a free name in the mods folder.';
  }
  #end

  /**
   * Normalizes an archive entry name to forward slashes with no leading `./`.
   */
  static function normalizeEntryName(name:String):String
  {
    var result:String = name.replace('\\', '/');

    while (result.startsWith('./'))
      result = result.substr(2);

    return result;
  }

  /**
   * Strips anything from a mod name that can't safely become a file name.
   */
  static function sanitizeName(name:String):String
  {
    var result:String = ~/[^A-Za-z0-9 _.-]/g.replace(name, '');

    result = result.replace(' ', '-').trim();

    // Leading dots hide the folder on unix, and a name of only dots is a path traversal.
    while (result.startsWith('.'))
      result = result.substr(1);

    if (result.length > 64) result = result.substr(0, 64);

    return result == '' ? 'downloaded-mod' : result;
  }

  /**
   * Turns a name into something usable as a Polymod mod ID.
   */
  static function sanitizeModId(name:String):String
  {
    var result:String = ~/[^A-Za-z0-9._-]/g.replace(name.replace(' ', '-'), '');

    while (result.startsWith('.') || result.startsWith('-'))
      result = result.substr(1);

    if (result.length > 64) result = result.substr(0, 64);

    return result.toLowerCase();
  }

  static function asString(value:Dynamic):Null<String>
  {
    if (value == null) return null;

    return Std.string(value);
  }

  static function asInt(value:Dynamic):Int
  {
    if (value == null) return 0;

    final result:Null<Int> = Std.parseInt(Std.string(value));

    return result ?? 0;
  }
}

#if sys
/**
 * The state a running install shares between its thread and the main thread.
 */
private class InstallJob
{
  final mutex:sys.thread.Mutex;

  var finished:Bool = false;
  var destinations:Array<String> = [];
  var error:Null<String> = null;

  /**
   * How far through the archive the worker has read, from 0 to 1.
   */
  var progress:Float = 0;

  public function new()
  {
    this.mutex = new sys.thread.Mutex();
  }

  public function read():InstallSnapshot
  {
    mutex.acquire();

    final snapshot:InstallSnapshot = {finished: finished, destinations: destinations, error: error, progress: progress};

    mutex.release();

    return snapshot;
  }

  /**
   * Called from the worker thread as it walks the archive.
   */
  public function report(ratio:Float):Void
  {
    mutex.acquire();
    progress = Math.max(0, Math.min(1, ratio));
    mutex.release();
  }

  /**
   * @param paths Where the mods landed. Empty if the archive turned out not to hold any.
   */
  public function succeed(paths:Array<String>):Void
  {
    mutex.acquire();
    destinations = paths;
    finished = true;
    mutex.release();
  }

  public function fail(reason:String):Void
  {
    mutex.acquire();
    error = reason;
    finished = true;
    mutex.release();
  }
}

/**
 * An immutable view of an install's state, safe to read off the main thread.
 */
private typedef InstallSnapshot =
{
  var finished:Bool;
  var destinations:Array<String>;
  var error:Null<String>;
  var progress:Float;
}

/**
 * The state a running download shares between its thread and the main thread.
 */
private class DownloadJob
{
  public final url:String;
  public final md5:Null<String>;

  /**
   * The size GameBanana reported, used until the server tells us better.
   */
  public final expectedSize:Int;

  /**
   * Where the archive is streamed to.
   */
  public final tempPath:String;

  final mutex:sys.thread.Mutex;

  var bytesLoaded:Int = 0;
  var bytesTotal:Int = 0;
  var finished:Bool = false;
  var result:Null<String> = null;
  var error:Null<String> = null;

  public function new(url:String, md5:Null<String>, expectedSize:Int, tempPath:String)
  {
    this.url = url;
    this.md5 = md5;
    this.expectedSize = expectedSize;
    this.bytesTotal = expectedSize;
    this.tempPath = tempPath;
    this.mutex = new sys.thread.Mutex();
  }

  /**
   * Takes a consistent copy of the state for the main thread to act on.
   */
  public function read():DownloadSnapshot
  {
    mutex.acquire();

    final snapshot:DownloadSnapshot =
      {
        bytesLoaded: bytesLoaded,
        bytesTotal: bytesTotal,
        finished: finished,
        result: result,
        error: error
      };

    mutex.release();

    return snapshot;
  }

  public function setTotal(value:Int):Void
  {
    mutex.acquire();
    bytesTotal = value;
    mutex.release();
  }

  public function advance(amount:Int):Void
  {
    mutex.acquire();
    bytesLoaded += amount;
    mutex.release();
  }

  /**
   * Clears the counters before following a redirect, so the bar doesn't start part filled.
   */
  public function reset():Void
  {
    mutex.acquire();
    bytesLoaded = 0;
    bytesTotal = expectedSize;
    mutex.release();
  }

  public function succeed(path:String):Void
  {
    mutex.acquire();
    result = path;
    finished = true;
    mutex.release();
  }

  public function fail(reason:String):Void
  {
    mutex.acquire();
    error = reason;
    finished = true;
    mutex.release();
  }
}

/**
 * An immutable view of a download's state, safe to read off the main thread.
 */
private typedef DownloadSnapshot =
{
  var bytesLoaded:Int;
  var bytesTotal:Int;
  var finished:Bool;
  var result:Null<String>;
  var error:Null<String>;
}

/**
 * Buffers a download while keeping its job's progress counters up to date.
 */
private class DownloadOutput extends haxe.io.Output
{
  final file:sys.io.FileOutput;
  final job:DownloadJob;

  var written:Int = 0;
  var closed:Bool = false;

  public function new(job:DownloadJob, path:String)
  {
    this.job = job;

    final directory:String = haxe.io.Path.directory(path);
    if (directory != '' && !sys.FileSystem.exists(directory)) sys.FileSystem.createDirectory(directory);

    this.file = sys.io.File.write(path, true);
  }

  /**
   * Closes the file and reports how much landed in it.
   */
  public function close2():Int
  {
    if (!closed)
    {
      closed = true;

      try
      {
        file.close();
      }
      catch (e:Dynamic)
      {
        trace('Failed to close the download file: ${e}');
      }
    }

    return written;
  }

  public override function prepare(nbytes:Int):Void
  {
    job.setTotal(nbytes);
  }

  public override function writeByte(c:Int):Void
  {
    file.writeByte(c);

    written++;
    job.advance(1);
  }

  public override function writeBytes(s:haxe.io.Bytes, pos:Int, len:Int):Int
  {
    file.writeFullBytes(s, pos, len);

    written += len;
    job.advance(len);

    return len;
  }

  public override function close():Void
  {
    close2();
  }
}
#end

/**
 * Represents a single requirement listed on a GameBanana submission.
 */
typedef OneClickRequirement =
{
  /**
   * What the author called it. Free text, and sometimes not a mod at all.
   */
  var name:String;

  /**
   * The link the author gave, if any.
   */
  var url:Null<String>;

  /**
   * The GameBanana model and submission ID the link points at.
   */
  var model:Null<String>;

  var itemId:Null<String>;
}

/**
 * A one-click link, broken into its parts.
 */
typedef OneClickRequest =
{
  /**
   * The URL the link says to download from.
   */
  var downloadUrl:String;

  /**
   * The GameBanana model the submission belongs to, usually `Mod`.
   */
  var modelName:String;

  /**
   * The id of the submission.
   */
  var itemId:String;

  /**
   * The id of the specific file, taken off the end of the download URL.
   */
  var fileId:Null<String>;
}

/**
 * What GameBanana told us about the submission behind a one-click link.
 */
typedef OneClickMod =
{
  var name:String;
  var author:String;
  var filename:String;
  var downloadUrl:String;
  var filesize:Int;
  var md5:Null<String>;

  /**
   * The GameBanana category the submission sits in, and its parent.
   */
  var categoryId:Int;

  var superCategoryId:Int;

  var categoryName:String;

  /**
   * What GameBanana lists under the submission's requirements.
   */
  var requirements:Array<OneClickRequirement>;

  /**
   * A preview image to show in place of a mod icon, since the real one is inside the archive.
   */
  var iconUrl:Null<String>;

  var avResult:Null<String>;
  var analysisResult:Null<String>;
}
