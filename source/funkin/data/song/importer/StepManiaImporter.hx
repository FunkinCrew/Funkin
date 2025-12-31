package funkin.data.song.importer;

import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongTimeChange;

import funkin.data.song.importer.StepManiaData.StepTimingPoint;
import funkin.data.song.importer.StepManiaData.StepDifficulty;
import funkin.data.song.importer.StepManiaData.StepManiaChartType;
import funkin.data.song.importer.StepManiaData.StepNote;
import funkin.data.song.importer.StepManiaData.StepStop;
import funkin.data.song.importer.StepManiaData.StepManiaNoteType;

enum StepStateEnum
{
  Metadata;
  TimingPoints;
  Stops;
  Notes;
}

class StepManiaImporter
{
  private static var readDiffMetadata:Map<String, String> = new Map<String, String>();

  static function parseMetadataLine(line:String, result:StepManiaData):StepManiaData
  {
    var parts:Array<String> = line.split(":");
    if (parts.length != 2) return result;

    var key:String = StringTools.trim(parts[0]);
    var value:String = StringTools.trim(parts[1]);

    // remove trailing ; on value
    if (StringTools.endsWith(value, ";")) value = value.substr(0, value.length - 1);

    switch (key)
    {
      case "TITLE":
        result.Metadata.Title = value;
      case "ARTIST":
        result.Metadata.Artist = value;
      case "GENRE":
        result.Metadata.Genre = value;
      case "CREDIT":
        if (result.Metadata.Credit == "") result.Metadata.Credit = value;
        else // .ssc
          readDiffMetadata.set("CREDIT", value);
      case "BANNER":
        result.Metadata.Banner = value;
      case "BACKGROUND":
        result.Metadata.Background = value;
      case "OFFSET":
        result.Metadata.Offset = Std.parseFloat(value);
      case "SAMPLESTART":
        result.Metadata.SampleStart = Std.parseFloat(value);
      // .ssc
      case "STEPSTYPE":
        readDiffMetadata.set("STEPSTYPE", value);
      case "DESCRIPTION":
        readDiffMetadata.set("DESCRIPTION", value);
      case "DIFFICULTY":
        readDiffMetadata.set("DIFFICULTY", value);
    }

    return result;
  }

  static function parseTimingPointLine(line:String):Array<StepTimingPoint>
  {
    // Remove #BPMS: prefix if present
    if (StringTools.startsWith(line, "#BPMS:")) line = line.substr(6);

    var parts:Array<String> = line.split(",");

    var stepTimingPoints:Array<StepTimingPoint> = [];
    for (i in 0...parts.length)
    {
      // Split the =
      var split = parts[i].split("=");
      if (split.length != 2) continue;

      var beat:Float = Std.parseFloat(StringTools.trim(split[0]));

      // Check if split[i + 1] has ; and remove it
      var bpmSplit = split[1];
      if (StringTools.endsWith(bpmSplit, ";")) bpmSplit = bpmSplit.substr(0, bpmSplit.length - 1);

      var tp:StepTimingPoint = new StepTimingPoint(Std.parseFloat(bpmSplit), beat);
      stepTimingPoints.push(tp);
    }

    return stepTimingPoints;
  }

  static function parseStopsLine(line:String):Array<StepStop>
  {
    // Remove #STOPS: prefix if present
    if (StringTools.startsWith(line, "#STOPS:")) line = line.substr(7);

    // Same as timing points
    var parts:Array<String> = line.split(",");
    var stepStopPoints:Array<StepStop> = [];
    for (i in 0...parts.length)
    {
      // Split the =
      var split = parts[i].split("=");
      if (split.length != 2) continue;

      var beat:Float = Std.parseFloat(StringTools.trim(split[0]));

      // Check if split[i + 1] has ; and remove it
      var durSplit = split[1];
      if (StringTools.endsWith(durSplit, ";")) durSplit = durSplit.substr(0, durSplit.length - 1);

      var tp:StepStop = new StepStop(beat, Std.parseFloat(durSplit));
      stepStopPoints.push(tp);
    }

    return stepStopPoints;
  }

  static function parseMeasure(lines:Array<String>, measureIndex:Int):Array<StepNote>
  {
    var lengthInRows:Float = 192.0 / lines.length;
    var rowIndex:Int = 0;
    var beat:Float = 0;

    var stepNotes:Array<StepNote> = [];

    for (i in 0...lines.length)
    {
      var stepNoteRow:Float = measureIndex * 192 + (lengthInRows * rowIndex);
      beat = stepNoteRow / 48.0; // 48 rows per beat

      for (j in 0...lines[i].length)
      {
        var char:String = lines[i].charAt(j);
        if (char != "0")
        {
          var stepNote:StepNote = new StepNote(char, beat, j);
          stepNotes.push(stepNote);
        }
      }
      rowIndex++;
    }

    return stepNotes;
  }

  static function synchronizeStepTimingPoints(stepStopPoints:Array<StepStop>, stepTimingPoints:Array<StepTimingPoint>):Array<StepTimingPoint>
  {
    // Initialize startTimestamp/endTimestamp and endBeat for timing points
    for (tpIndex in 0...stepTimingPoints.length)
    {
      var tp = stepTimingPoints[tpIndex];
      // ensure fields exist
      if (tp.startTimestamp == Math.NEGATIVE_INFINITY) tp.startTimestamp = 0.0;
    }

    var tpIndex:Int = 1;
    var spIndex:Int = 0;

    // if we have more than one timing point or any StepStops, synchronize
    if (stepTimingPoints.length > 1 || stepStopPoints.length > 0)
    {
      if (stepStopPoints.length > 1)
      {
        while (tpIndex < stepTimingPoints.length || spIndex < stepStopPoints.length)
        {
          var prevTp:StepTimingPoint = stepTimingPoints[tpIndex - 1];

          if (tpIndex == stepTimingPoints.length)
          {
            var cts:Float = 0;
            while (spIndex < stepStopPoints.length)
            {
              var sp = stepStopPoints[spIndex];
              sp.startTimestamp = (prevTp.startTimestamp + (sp.startBeat - prevTp.startBeat) / (prevTp.bpm / 60)) + cts;
              cts += sp.duration;
              spIndex++;
            }
            continue;
          }

          if (spIndex == stepStopPoints.length)
          {
            while (tpIndex < stepTimingPoints.length)
            {
              var tp = stepTimingPoints[tpIndex];
              prevTp = stepTimingPoints[tpIndex - 1];
              prevTp.endBeat = tp.startBeat;
              prevTp.endTimestamp += (prevTp.endBeat - prevTp.startBeat) / (prevTp.bpm / 60);
              tp.startTimestamp = prevTp.endTimestamp;
              tp.endTimestamp = tp.startTimestamp;
              tpIndex++;
              if (tpIndex == stepTimingPoints.length)
              {
                tp.endTimestamp = Math.POSITIVE_INFINITY;
                tp.endBeat = Math.POSITIVE_INFINITY;
              }
            }
            continue;
          }

          var tp:StepTimingPoint = stepTimingPoints[tpIndex];
          var sp:StepStop = stepStopPoints[spIndex];

          prevTp.endBeat = tp.startBeat;

          if (sp.startBeat < prevTp.endBeat)
          {
            sp.startTimestamp = prevTp.endTimestamp + (sp.startBeat - prevTp.startBeat) / (prevTp.bpm / 60);
            prevTp.endTimestamp += sp.duration;
            spIndex++;
          }
          else
          {
            prevTp.endTimestamp += (prevTp.endBeat - prevTp.startBeat) / (prevTp.bpm / 60);
            tp.startTimestamp = prevTp.endTimestamp;
            tp.endTimestamp = tp.startTimestamp;
            tpIndex++;
          }

        }
      }
      else
      {
        while (tpIndex < stepTimingPoints.length)
        {
          var prevTp:StepTimingPoint = stepTimingPoints[tpIndex - 1];
          var tp:StepTimingPoint = stepTimingPoints[tpIndex];
          prevTp.endBeat = tp.startBeat;
          prevTp.endTimestamp = prevTp.startTimestamp + (prevTp.endBeat - prevTp.startBeat) / (prevTp.bpm / 60);
          tp.startTimestamp = prevTp.endTimestamp;
          tpIndex++;
          if (tpIndex == stepTimingPoints.length)
          {
            tp.endTimestamp = Math.POSITIVE_INFINITY;
            tp.endBeat = Math.POSITIVE_INFINITY;
          }
        }
      }
    }

    return stepTimingPoints;
  }

  static function pushWorking(workingDiff:StepDifficulty, result:StepManiaData):StepManiaData
  {
    if (workingDiff != null && workingDiff.notes.length > 0)
    {
      // Apply .ssc metadata if any
      for (metaKey in readDiffMetadata.keys())
      {
        var metaValue = readDiffMetadata.get(metaKey);
        switch (metaKey)
        {
          case "STEPSTYPE":
            workingDiff.type = workingDiff.parseChartType(metaValue);
          case "DIFFICULTY":
            workingDiff.name = metaValue;
          case "CREDIT":
            workingDiff.charter = metaValue;
            // DESCRIPTION is ignored for now
        }
      }
      result.Difficulties.push(workingDiff);
    }
    readDiffMetadata.clear();
    return result;
  }

  static function parseBPMS(line:String, result:StepManiaData):StepManiaData
  {
    var tps = parseTimingPointLine(line);
    if (tps != null)
    {
      for (tp in tps)
        result.TimingPoints.push(tp);
    }
    return result;
  }

  static function parseStops(line:String, result:StepManiaData):StepManiaData
  {
    var sps = parseStopsLine(line);
    if (sps != null)
    {
      for (sp in sps)
        result.Stops.push(sp);
    }
    return result;
  }

  /**
   * Parses a StepMania file content into StepManiaData structure.
   * @param stepContent The content of the StepMania file as a string.
   * @return StepManiaData The parsed StepMania data.
   */
  public static function parseStepManiaFile(stepContent:String):StepManiaData
  {
    readDiffMetadata = new Map<String, String>();
    var lines:Array<String> = stepContent.split("\n");

    var currentMeasure:Int = 0;
    var measure:Array<String> = [];
    var workingDiff:StepDifficulty = null;

    var state:StepStateEnum = StepStateEnum.Metadata;
    var headerLines:Int = 0;

    var result:StepManiaData = {
      Metadata: {
        Title: "",
        Artist: "",
        Genre: "",
        Credit: "",
        Banner: "",
        Background: "",
        Offset: 0,
        SampleStart: 0
      },
      TimingPoints: [],
        Stops: [],
      Difficulties: []
    };

    // Parsing metadata

    for (line in lines)
    {
      line = StringTools.trim(line);
      if (line == "") continue;
      if (StringTools.startsWith(line, "//")) continue; // Comment line

      switch (state)
      {
        case StepStateEnum.Metadata:
          if (StringTools.startsWith(line, "#BPMS:"))
          {
            state = StepStateEnum.TimingPoints;
            result = parseBPMS(line, result);
            if (StringTools.endsWith(line, ";")) state = StepStateEnum.Metadata;
          }
          else if (StringTools.startsWith(line, "#STOPS:"))
          {
            state = StepStateEnum.Stops;
            result = parseStops(line, result);
            if (StringTools.endsWith(line, ";")) state = StepStateEnum.Metadata;
          }
          else if (StringTools.startsWith(line, "#NOTES:"))
          {
            if (workingDiff != null)
            {
              // Save previous difficulty
              result = pushWorking(workingDiff, result);
            }

            // Start new difficulty
            workingDiff = new StepDifficulty("", "", 0, "");
            workingDiff.notes = [];

            headerLines = 0;
            currentMeasure = 0;
            measure = [];
            state = StepStateEnum.Notes;
          }
          else if (StringTools.startsWith(line, "#")) result = parseMetadataLine(line.substr(1), result);
        case StepStateEnum.TimingPoints:
          if (line == ";") state = StepStateEnum.Metadata;
          else
          {
            result = parseBPMS(line, result);
            if (StringTools.endsWith(line, ";")) state = StepStateEnum.Metadata;
          }
        case StepStateEnum.Stops:
          if (line == ";") state = StepStateEnum.Metadata;
          else
          {
            result = parseStops(line, result);
            if (StringTools.endsWith(line, ";")) state = StepStateEnum.Metadata;
          }
        case StepStateEnum.Notes:
          if (line == "#NOTES:") continue;
          // remove comments in line (if any) ie, "0000 // some comment"
          var commentIndex = line.indexOf("//");
          if (commentIndex != -1) line = StringTools.trim(line.substr(0, commentIndex));

          if (StringTools.contains(line, ":")) // header
          {
            switch (headerLines)
            {
              case 0:
                // First line is chart type
                var chartTypeStr = StringTools.trim(line).replace(":", "");
                workingDiff.type = workingDiff.parseChartType(chartTypeStr);
              case 1:
                // Second line is charter
                workingDiff.charter = StringTools.trim(line).replace(":", "");
              case 2:
                // Third line is difficulty name
                workingDiff.name = StringTools.trim(line).replace(":", "");
              case 3:
                // Fourth line is difficulty rating
                workingDiff.difficultyRating = Std.parseInt(StringTools.trim(line).replace(":", ""));
                // we dont care about the rest lol
            }
            headerLines++;
            continue;
          }

          // we're reading StepNote data now
          // start gathering measures until we hit a ,
          if (line == "," || line == ";")
          {
            // end of measure
            var stepNotesInMeasure = parseMeasure(measure, currentMeasure);
            for (stepNote in stepNotesInMeasure)
              workingDiff.notes.push(stepNote);
            measure = [];
            currentMeasure++;
            // end of StepNotes section
            if (line == ";") state = StepStateEnum.Metadata;
          }
          else
          {
            measure.push(line);
          }
      }

    }

    if (workingDiff != null && workingDiff.notes.length > 0)
    {
      // Save last difficulty
      result = pushWorking(workingDiff, result);
    }

    // Syncronize timing points with StepStops
    result.TimingPoints = synchronizeStepTimingPoints(result.Stops, result.TimingPoints);

    return result;
  }

  static function getStepStopAtBeat(beat:Float, stepStops:Array<StepStop>):StepStop
  {
    var stepStop:StepStop = null;

    for (s in stepStops)
    {
      if (s.startBeat < beat) stepStop = s;
    }

    return stepStop;
  }

  static function beatToTime(beat:Float, offset:Float, stepTimingPoints:Array<StepTimingPoint>, stepStops:Array<StepStop>):Float
  {
    var time:Float = 0;
    for (tp in stepTimingPoints)
    {
      if (tp.startBeat <= beat && tp.endBeat > beat)
      {
        var stepStop:StepStop = getStepStopAtBeat(beat, stepStops);
        var b:Float = tp.startBeat;
        var startTime:Float = tp.startTimestamp;
        if (stepStop != null)
        {
          if (stepStop.startBeat > tp.startBeat)
          {
            b = stepStop.startBeat;
            startTime = stepStop.startTimestamp + stepStop.duration;
          }
        }

        var nb:Float = (beat - b) / (tp.bpm / 60);
        time = startTime + nb;
      }
    }

    return (time * 1000) - (offset * 1000); // convert to ms
  }

  static function convertStepNotes(offset:Float, type:StepManiaChartType, stepNotes:Array<StepNote>,
    stepTimingPoints:Array<StepTimingPoint>, stepStops:Array<StepStop>):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = [];
    var holdArray:Array<Float> = [];
    if (type == StepManiaChartType.DanceSingle)
    {
      holdArray = [-1, -1, -1, -1];
    }
    else if (type == StepManiaChartType.DanceDouble)
    {
      holdArray = [-1, -1, -1, -1, -1, -1, -1, -1];
    }
    else
    {
      trace("[WARN] Unknown StepMania chart type when converting notes.");
      return result;
    }

    for (stepNote in stepNotes)
    {
      var time = beatToTime(stepNote.beat, offset, stepTimingPoints, stepStops);

      if (stepNote.type == StepManiaNoteType.Head || stepNote.type == StepManiaNoteType.Roll)
      {
        holdArray[stepNote.column] = time;
        continue;
      }

      var snd:SongNoteData = new SongNoteData(time, stepNote.column, 0);
      if (stepNote.type == StepManiaNoteType.Mine) snd.kind = "mine";
      else if (stepNote.type == StepManiaNoteType.Fake) snd.kind = "fake";
      if (stepNote.type == StepManiaNoteType.Tail)
      {
        var length:Float = 0;
        if (holdArray[stepNote.column] != -1) length = time - holdArray[stepNote.column];
        snd.time = holdArray[stepNote.column];
        snd.length = length;
        holdArray[stepNote.column] = -1;
      }

      if (type != StepManiaChartType.DanceSingle)
      {
        if (stepNote.column < 4) snd.data = stepNote.column + 4;
        else
          snd.data = stepNote.column - 4;
      }
      else
      {
        if (snd.data >= 4) snd.data -= 4;
      }

      result.push(snd);
    }
    return result;

  }

  /**
   * Migrates StepManiaData to SongMetadata.
   * @param songData The StepManiaData to migrate.
   * @return SongMetadata The migrated SongMetadata.
   */
  public static function migrateChartMetadata(songData:StepManiaData):SongMetadata
  {
    var metadata:SongMetadata = new SongMetadata(songData.Metadata.Title, songData.Metadata.Artist);

    metadata.playData.stage = 'mainStage';
    metadata.playData.characters = new SongCharacterData('bf', 'gf', 'dad');

    metadata.generatedBy = 'Chart Editor Import (StepMania)';

    metadata.playData.songVariations = [];

    // Difficulties
    var difficulties:Array<String> = [];
    for (diff in songData.Difficulties)
    {
      if (diff.type == StepManiaChartType.Unknown)
      {
        trace("[WARN] Skipping unknown StepMania chart type. Name: " + diff.name);
        continue; // skip unknown chart types
      }
      difficulties.push(diff.name);
      metadata.playData.ratings.set(diff.name, diff.difficultyRating);
    }

    metadata.playData.difficulties = difficulties;

    metadata.charter = songData.Metadata.Credit != "" ? songData.Metadata.Credit : null;

    // TimeChanges
    metadata.timeChanges = [];
    for (tp in songData.TimingPoints)
    {
      var timeChange = new SongTimeChange(tp.startTimestamp * 1000, tp.bpm);
      timeChange.beatTime = tp.startBeat;
      metadata.timeChanges.push(timeChange);
    }

    return metadata;
  }

  /**
   * Migrates StepManiaData to SongChartData.
   * @param songData The StepManiaData to migrate.
   * @return SongChartData The migrated SongChartData.
   */
  public static function migrateChartData(songData:StepManiaData):SongChartData {
    var scrollsMap:Map<String, Float> = new Map<String, Float>();
    var stepNoteMap:Map<String, Array<SongNoteData>> = new Map<String, Array<SongNoteData>>();

    for (diff in songData.Difficulties)
    {
      if (diff.type == StepManiaChartType.Unknown)
      {
        trace("[WARN] Skipping unknown StepMania chart type. Name: " + diff.name);
        continue; // skip unknown chart types
      }
      scrollsMap.set(diff.name, Constants.DEFAULT_SCROLLSPEED);
      stepNoteMap.set(diff.name, convertStepNotes(songData.Metadata.Offset, diff.type, diff.notes, songData.TimingPoints, songData.Stops));
    }

    var songChartData:SongChartData = new SongChartData(scrollsMap, [], stepNoteMap);
    return songChartData;
  }
}
