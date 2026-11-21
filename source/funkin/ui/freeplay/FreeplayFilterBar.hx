package funkin.ui.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxInputText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.assets.ValidatedPaths as Paths;
import funkin.graphics.FunkinSprite;
import funkin.input.Controls;

typedef SongFilter =
{
  var favorite:FavoriteFilter;
  var sortOrder:SongSortOrder;
  var search:String;
}

enum abstract FavoriteFilter(String) from String to String
{
  public var ALL = 'all';
  public var FAVORITES = 'favorites';
  public var UNFAVORITES = 'unfavorites';
}

enum abstract SongSortOrder(String) from String to String
{
  public var WEEK_ORDER = 'week';
  public var ALPHABETICAL_ASC = 'alphabetical-asc';
  public var ALPHABETICAL_DESC = 'alphabetical-desc';
  public var DIFFICULTY_ASC = 'difficulty-asc';
  public var DIFFICULTY_DESC = 'difficulty-desc';
  public var RANK_ASC = 'rank-asc';
  public var RANK_DESC = 'rank-desc';
}

class FreeplayFilterBar extends FlxSpriteGroup
{
  static final FAVORITE_OPTIONS:Array<FavoriteFilter> = [FavoriteFilter.ALL, FavoriteFilter.FAVORITES, FavoriteFilter.UNFAVORITES];
  static final SORT_OPTIONS:Array<SongSortOrder> = [
    SongSortOrder.WEEK_ORDER,
    SongSortOrder.ALPHABETICAL_ASC,
    SongSortOrder.ALPHABETICAL_DESC,
    SongSortOrder.DIFFICULTY_ASC,
    SongSortOrder.DIFFICULTY_DESC,
    SongSortOrder.RANK_DESC,
    SongSortOrder.RANK_ASC
  ];

  public var changeSelectionCallback:SongFilter->Bool->Void;
  public var filter(default, null):SongFilter = {
    favorite: FavoriteFilter.ALL,
    sortOrder: SongSortOrder.WEEK_ORDER,
    search: ''
  };
  public var isSearchFocused(default, null):Bool = false;

  var instance:FreeplayState;
  var favoriteHitbox:FlxSprite;
  var sortHitbox:FlxSprite;
  var searchHitbox:FlxSprite;
  var favoriteIcon:FunkinSprite;
  var searchTitleGroup:FlxSpriteGroup;
  var searchQueryGroup:FlxSpriteGroup;
  var searchInput:FlxInputText;
  var searchCaret:FlxSprite;
  var searchQueryScale:Float = 0.3;
  var customSortIcon:FlxSpriteGroup;
  var sortLabelGroup:FlxSpriteGroup;
  var displayedFavoriteSymbol:String = '';
  var leftArrow:FlxSprite;
  var rightArrow:FlxSprite;
  var favoriteIndex:Int = 0;
  var sortIndex:Int = 0;
  var suppressAcceptInput:Bool = false;
  var controls(get, never):Controls;

  inline function get_controls():Controls return PlayerSettings.player1.controls;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    favoriteHitbox = makeHitbox(24, 0, 88, 72);
    sortHitbox = makeHitbox(118, 0, 98, 72);
    searchHitbox = makeHitbox(236, 0, 174, 56);

    leftArrow = new FlxSprite(-12, 12).loadGraphic(funkin.assets.Paths.image('ui/freeplay/interface/mini-arrow').toFlxGraphicAsset());
    leftArrow.flipX = true;
    rightArrow = new FlxSprite(414, 12).loadGraphic(funkin.assets.Paths.image('ui/freeplay/interface/mini-arrow').toFlxGraphicAsset());
    add(leftArrow);
    add(rightArrow);

    favoriteIcon = new FunkinSprite(32, -12);
    favoriteIcon.loadTextureAtlas('ui/freeplay/interface/sorted-letters');
    favoriteIcon.anim.addBySymbol('ALL', 'ALL', 24, false);
    favoriteIcon.anim.addBySymbol('ALL move', 'ALL move', 24, false);
    favoriteIcon.anim.addBySymbol('fav', 'fav', 24, false);
    favoriteIcon.anim.addBySymbol('fav move', 'fav move', 24, false);
    favoriteIcon.animation.onFinish.add(function(_)
    {
      favoriteIcon.animation.play(favoriteAnimationName(), true);
    });
    add(favoriteIcon);

    addSeparator(112);
    addSeparator(224);

    searchTitleGroup = makeBoldText('TYPE SONG:', 236, 0, 174, 27, 0.39);
    add(searchTitleGroup);
    searchQueryGroup = new FlxSpriteGroup();
    add(searchQueryGroup);

    searchInput = new FlxInputText(247, 24, 152, '', 12, FlxColor.WHITE, FlxColor.TRANSPARENT);
    searchInput.setFormat(Paths.font('ui/fonts/VCR OSD Mono'), 12, FlxColor.WHITE, FlxTextAlign.LEFT);
    searchInput.maxChars = 64;
    searchInput.alpha = 0;
    searchInput.caretColor = FlxColor.TRANSPARENT;
    searchInput.onTextChange.add((text, _) ->
    {
      filter.search = text;
      refreshIndicators();
      notifyChange();
    });
    searchInput.onEnter.add((_) ->
    {
      suppressAcceptInput = true;
      deactivateSearch();
    });
    add(searchInput);

    refreshIndicators();
  }

  function makeHitbox(x:Float, y:Float, width:Int, height:Int):FlxSprite
  {
    return new FlxSprite(x, y).makeGraphic(width, height, 0x00000000);
  }

  function addSeparator(x:Float):Void
  {
    var separator = new FlxSprite(x, 13).loadGraphic(funkin.assets.Paths.image('ui/freeplay/interface/separator').toFlxGraphicAsset());
    add(separator);
  }

  public function setInstance(value:FreeplayState):Void
  {
    instance = value;
    favoriteHitbox.cameras = [value.funnyCam];
    sortHitbox.cameras = [value.funnyCam];
    searchHitbox.cameras = [value.funnyCam];
    for (member in members)
    {
      if (member == null) continue;
      member.cameras = [value.funnyCam];
      if (Std.isOfType(member, FlxSpriteGroup))
      {
        var group:FlxSpriteGroup = cast member;
        for (child in group.members)
        {
          if (child != null) child.cameras = [value.funnyCam];
        }
      }
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (searchCaret != null)
    {
      if (isSearchFocused)
      {
        positionSearchCaret(filter.search.toUpperCase(), searchQueryScale);
        searchCaret.visible = true;
      }
    }
    syncHitboxes();

    if (!visible)
    {
      deactivateSearch();
      return;
    }

    if (instance == null || !instance.uiStateMachine.canInteract()) return;

    if (FlxG.keys.justPressed.CONTROL)
    {
      if (isSearchFocused) deactivateSearch();
      else activateSearch();
      return;
    }

    if (isSearchFocused)
    {
      if (FlxG.keys.justPressed.ESCAPE) deactivateSearch();
      if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(searchHitbox, instance.funnyCam)) deactivateSearch();
      return;
    }

    if (controls.FREEPLAY_LEFT)
    {
      if (FlxG.keys.pressed.SHIFT) changeFavorite(-1);
      else
        changeSort(-1);
    }
    else if (controls.FREEPLAY_RIGHT)
    {
      if (FlxG.keys.pressed.SHIFT) changeFavorite(1);
      else
        changeSort(1);
    }

    if (!FlxG.mouse.justPressed) return;

    if (FlxG.mouse.overlaps(favoriteHitbox, instance.funnyCam))
    {
      deactivateSearch();
      changeFavorite(1);
    }
    else if (FlxG.mouse.overlaps(sortHitbox, instance.funnyCam))
    {
      deactivateSearch();
      changeSort(1);
    }
    else if (isSearchFocused)
    {
      deactivateSearch();
    }
  }

  function syncHitboxes():Void
  {
    favoriteHitbox.setPosition(x + 24, y);
    sortHitbox.setPosition(x + 118, y);
    searchHitbox.setPosition(x + 236, y);
  }

  public function consumeAcceptInput():Bool
  {
    var suppress:Bool = suppressAcceptInput;
    suppressAcceptInput = false;
    return suppress;
  }

  function changeFavorite(amount:Int):Void
  {
    favoriteIndex = (favoriteIndex + amount + FAVORITE_OPTIONS.length) % FAVORITE_OPTIONS.length;
    filter.favorite = FAVORITE_OPTIONS[favoriteIndex];
    refreshIndicators();
    notifyChange();
  }

  function changeSort(amount:Int):Void
  {
    sortIndex = (sortIndex + amount + SORT_OPTIONS.length) % SORT_OPTIONS.length;
    filter.sortOrder = SORT_OPTIONS[sortIndex];
    refreshIndicators();
    animateSortLetters(sortLabelGroup != null ? sortLabelGroup : customSortIcon);
    notifyChange(true);
  }

  function refreshIndicators():Void
  {
    var favoriteSymbol:String = favoriteAnimationName();
    if (displayedFavoriteSymbol != favoriteSymbol)
    {
      displayedFavoriteSymbol = favoriteSymbol;
      favoriteIcon.animation.play(favoriteSymbol, true);
    }
    favoriteIcon.color = filter.favorite == FavoriteFilter.UNFAVORITES ? 0xFF858585 : 0xFFFFFFFF;

    if (customSortIcon != null)
    {
      cancelSortLetterTweens(customSortIcon);
      remove(customSortIcon, true);
      customSortIcon = null;
    }
    if (sortLabelGroup != null)
    {
      cancelSortLetterTweens(sortLabelGroup);
      remove(sortLabelGroup, true);
      sortLabelGroup = null;
    }

    var sortText:String = '';
    switch (filter.sortOrder)
    {
      case ALPHABETICAL_ASC:
        customSortIcon = makeAlphabetIcon('A', 'Z');
      case ALPHABETICAL_DESC:
        customSortIcon = makeAlphabetIcon('Z', 'A');
      case DIFFICULTY_ASC:
        sortText = 'LOW\nSTARS';
      case DIFFICULTY_DESC:
        sortText = 'HIGH\nSTARS';
      case RANK_DESC:
        sortText = 'BEST\nRANK';
      case RANK_ASC:
        sortText = 'WORST\nRANK';
      default:
        sortText = 'WEEK\nORDER';
    }

    if (sortText != '')
    {
      sortLabelGroup = makeBoldText(sortText, 128, -4, 98, 56, 0.44);
      add(sortLabelGroup);
      setGroupCamera(sortLabelGroup);
    }

    if (customSortIcon != null)
    {
      add(customSortIcon);
      setGroupCamera(customSortIcon);
    }

    searchInput.visible = false;
    if (isSearchFocused && searchInput.text != filter.search) searchInput.text = filter.search;
    refreshSearchQuery();
  }

  function animateSortLetters(indicator:FlxSpriteGroup):Void
  {
    if (indicator == null) return;

    var letterIndex:Int = 0;
    for (letter in indicator.members)
    {
      if (letter == null) continue;

      var originalY:Float = letter.y;
      letter.y += 5;
      FlxTween.tween(letter, {y: originalY}, 0.18, {
        ease: FlxEase.quadOut,
        startDelay: letterIndex * 0.012
      });
      letterIndex++;
    }
  }

  function cancelSortLetterTweens(indicator:FlxSpriteGroup):Void
  {
    for (letter in indicator.members)
    {
      if (letter != null) FlxTween.cancelTweensOf(letter);
    }
  }

  function refreshSearchQuery():Void
  {
    if (searchQueryGroup != null)
    {
      remove(searchQueryGroup, true);
    }

    var query:String = filter.search.toUpperCase();
    searchQueryScale = query.length > 0 ? Math.min(0.36, 150 / (query.length * 48)) : 0.36;
    searchQueryGroup = makeBoldText(query, 247, 24, 152, 25, searchQueryScale, 0xFFFFFF00);

    if (isSearchFocused)
    {
      searchCaret = new FlxSprite();
      searchCaret.frames = Paths.getSparrowAtlas('ui/fonts/default');
      searchCaret.frame = searchCaret.frames.getByName('_0000');
      searchCaret.scale.set(0.24, 0.24);
      searchCaret.color = 0xFFFFE8C8;
      searchCaret.updateHitbox();
      searchCaret.visible = true;
      searchQueryGroup.add(searchCaret);
      positionSearchCaret(query, searchQueryScale);
    }
    else
    {
      searchCaret = null;
    }

    add(searchQueryGroup);
    setGroupCamera(searchQueryGroup);
  }

  function positionSearchCaret(query:String, scale:Float):Void
  {
    var glyphs:Array<FlxSprite> = [];
    for (member in searchQueryGroup.members)
    {
      if (member != null && member != searchCaret) glyphs.push(cast member);
    }

    var spacing:Float = -1.5 * scale / 0.4;
    var lineWidth:Float = 0;
    var glyphIndex:Int = 0;
    for (i in 0...query.length)
    {
      var character:String = query.charAt(i);
      lineWidth += character == ' ' ? 12 * scale : glyphs[glyphIndex++].width;
    }
    lineWidth += Math.max(0, query.length - 1) * spacing;

    var caretIndex:Int = Std.int(Math.max(0, Math.min(searchInput.caretIndex, query.length)));
    var caretX:Float = (152 - lineWidth) / 2;
    glyphIndex = 0;
    for (i in 0...caretIndex)
    {
      var character:String = query.charAt(i);
      caretX += character == ' ' ? 12 * scale : glyphs[glyphIndex++].width;
    }
    if (caretIndex < query.length) caretX += spacing;

    var lineHeight:Float = 0;
    for (glyph in glyphs)
    {
      lineHeight = Math.max(lineHeight, glyph.height);
    }
    if (lineHeight == 0) lineHeight = 70 * scale;
    searchCaret.x = searchQueryGroup.x + caretX;
    searchCaret.y = searchQueryGroup.y + (25 - lineHeight) / 2 + lineHeight + 0.5;
  }

  function makeAlphabetIcon(firstLetter:String, secondLetter:String):FlxSpriteGroup
  {
    var letters = new FlxSpriteGroup(135, -15);
    var firstGlyph = addBoldLetter(letters, firstLetter, 9, 0, 0.7);
    addBoldLetter(letters, secondLetter, 9 + firstGlyph.width - 1.5, 20, 0.7);
    return letters;
  }

  function addBoldLetter(group:FlxSpriteGroup, letter:String, x:Float, y:Float, scale:Float):FlxSprite
  {
    var glyph = new FlxSprite(x, y);
    glyph.frames = Paths.getSparrowAtlas('ui/fonts/bold');
    glyph.animation.addByPrefix('letter', '${letter}0000', 24, false);
    glyph.animation.play('letter');
    glyph.scale.set(scale, scale);
    glyph.updateHitbox();
    group.add(glyph);
    return glyph;
  }

  function makeBoldText(text:String, x:Float, y:Float, width:Float, height:Float, scale:Float, color:FlxColor = FlxColor.WHITE):FlxSpriteGroup
  {
    var group = new FlxSpriteGroup(x, y);
    var lines = text.split('\n');
    var lineGlyphs:Array<Array<FlxSprite>> = [];
    var lineWidths:Array<Float> = [];
    var lineHeights:Array<Float> = [];
    var spacing:Float = -1.5 * scale / 0.4;
    var totalHeight:Float = 0;

    for (lineIndex in 0...lines.length)
    {
      var glyphs:Array<FlxSprite> = [];
      var lineWidth:Float = 0;
      var line:String = lines[lineIndex];
      for (characterIndex in 0...line.length)
      {
        var character:String = line.charAt(characterIndex);
        if (character == ' ')
        {
          glyphs.push(null);
          lineWidth += 12 * scale;
          continue;
        }

        var glyph = new FlxSprite();
        glyph.frames = Paths.getSparrowAtlas('ui/fonts/bold');
        glyph.animation.addByPrefix('letter', '${character}0000', 24, false);
        glyph.animation.play('letter');
        glyph.color = color;
        glyph.scale.set(scale, scale);
        glyph.updateHitbox();
        glyphs.push(glyph);
        lineWidth += glyph.width;
      }

      lineWidth += Math.max(0, glyphs.length - 1) * spacing;
      var lineHeight:Float = 0;
      for (glyph in glyphs)
      {
        if (glyph == null) continue;
        lineHeight = Math.max(lineHeight, glyph.height);
      }

      lineGlyphs.push(glyphs);
      lineWidths.push(lineWidth);
      lineHeights.push(lineHeight);
      totalHeight += lineHeight;
    }

    var lineGap:Float = -2 * scale / 0.4;
    totalHeight += Math.max(0, lines.length - 1) * lineGap;
    var glyphY:Float = (height - totalHeight) / 2;
    for (lineIndex in 0...lineGlyphs.length)
    {
      var glyphX:Float = (width - lineWidths[lineIndex]) / 2;
      for (glyph in lineGlyphs[lineIndex])
      {
        if (glyph == null)
        {
          glyphX += 12 * scale;
          continue;
        }
        glyph.x = glyphX;
        glyph.y = glyphY;
        group.add(glyph);
        glyphX += glyph.width + spacing;
      }
      glyphY += lineHeights[lineIndex] + lineGap;
    }
    return group;
  }

  function favoriteAnimationName():String
  {
    return filter.favorite == FavoriteFilter.ALL ? 'ALL move' : 'fav move';
  }

  function setGroupCamera(group:FlxSpriteGroup):Void
  {
    if (instance == null) return;
    group.cameras = [instance.funnyCam];
    for (member in group.members)
    {
      if (member != null) member.cameras = [instance.funnyCam];
    }
  }

  function activateSearch():Void
  {
    if (isSearchFocused) return;

    isSearchFocused = true;
    searchInput.text = filter.search;
    searchInput.visible = false;
    searchInput.startFocus();
    refreshIndicators();
  }

  function deactivateSearch():Void
  {
    if (!isSearchFocused) return;

    filter.search = searchInput.text;
    isSearchFocused = false;
    searchInput.endFocus();
    searchInput.visible = false;
    refreshIndicators();
  }

  function notifyChange(resetSelection:Bool = false):Void
  {
    if (changeSelectionCallback != null)
    {
      changeSelectionCallback({
        favorite: filter.favorite,
        sortOrder: filter.sortOrder,
        search: filter.search
      }, resetSelection);
    }
  }

  override function destroy():Void
  {
    deactivateSearch();
    super.destroy();
  }
}
