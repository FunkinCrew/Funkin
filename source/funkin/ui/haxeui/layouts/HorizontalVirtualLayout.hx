package funkin.ui.haxeui.layouts;

import haxe.ui.layouts.VirtualLayout;
import haxe.ui.containers.IVirtualContainer;
import haxe.ui.core.Component;
import haxe.ui.geom.Rectangle;
import haxe.ui.geom.Size;

/**
 * A bit of an accompanying class to HaxeUI's `VerticalVirtualLayout`
 * Can perhaps be upstreamed to HaxeUI at some point!
 */
class HorizontalVirtualLayout extends VirtualLayout
{
  override function repositionChildren():Void
  {
    super.repositionChildren();

    var comp:IVirtualContainer = cast(_component, IVirtualContainer);
    var itemWidth:Float = this.itemWidth;
    var contents:Component = this.contents;
    var horizontalSpacing = contents.layout.horizontalSpacing;
    if (comp.virtual)
    {
      var n:Int = _firstIndex;
      if (comp.variableItemSize)
      {
        var pos:Float = -comp.hscrollPos;
        for (i in 0..._lastIndex)
        {
          if (i >= _firstIndex)
          {
            var c:Component = contents.getComponentAt(i - _firstIndex);
            c.left = pos;
          }

          var size:Null<Float> = _sizeCache[i];
          pos += (size != null && size != 0 ? size : itemWidth) + horizontalSpacing;
        }
      }
      else
      {
        for (child in contents.childComponents)
        {
          child.left = (n * (itemWidth + horizontalSpacing)) - comp.hscrollPos;
          ++n;
        }
      }
    }
    // note: VerticalVirtualLayout has some commented out code in an else statement (an else to our if(comp.virtual))
    // but since it's all commented out, it might not be relavant
  }

  private function horizontalConstraintModifier():Float
    return 0;

  override function calculateRangeVisible():Void
  {
    var comp:IVirtualContainer = cast(_component, IVirtualContainer);
    var horizontalSpacing = contents.layout.horizontalSpacing;
    var itemWidth:Float = this.itemWidth;
    var visibleItemsCount:Int = 0;
    var contentsWidth:Float = 0;

    if (contents.autoWidth)
    {
      var itemCount:Int = this.itemCount;
      if (itemCount > 0 || _component.autoWidth) contentsWidth = itemCount * itemWidth - horizontalConstraintModifier();
      else
        contentsWidth = _component.width - horizontalConstraintModifier();
    }
    else
      contentsWidth = contents.width - horizontalConstraintModifier();

    if (contentsWidth > _component.width - horizontalConstraintModifier()) contentsWidth = _component.height - horizontalConstraintModifier();

    if (comp.variableItemSize)
    {
      var totalSize:Float = 0;
      var requireInvalidation:Bool = false;
      var newFirstIndex:Int = -1;
      for (i in 0...dataSource.size)
      {
        var size:Null<Float> = _sizeCache[i];

        // Extract the itemrenderer size from the cache or child component
        if (size == null || size == 0)
        {
          if (isIndexVisible(i))
          {
            var c:Component = contents.getComponentAt(i - _firstIndex);
            if (c != null && c.componentWidth > 0)
            {
              _sizeCache[i] = c.componentWidth;
              size = c.componentWidth;
            }
            else
            {
              requireInvalidation = true;
              size = itemWidth;
            }
          }
          else
          {
            requireInvalidation = true;
            size = itemWidth;
          }
        }

        size += horizontalSpacing;

        // Check limits
        if (newFirstIndex == -1) // Stage 1 - find the first index
        {
          if (totalSize + size > comp.hscrollPos)
          {
            newFirstIndex = i;
            totalSize += size - comp.hscrollPos;
            ++visibleItemsCount;
          }
          else
            totalSize += size;
        }
        else // Stage 2 - find the visible items count
        {
          if (totalSize + size > contentsWidth)
          {
            break;
          }
          else
          {
            ++visibleItemsCount;
            totalSize += size;
          }
        }
      }

      if (requireInvalidation) _component.invalidateComponentLayout();

      _firstIndex = newFirstIndex;
    }
    else
    {
      visibleItemsCount = Math.ceil(contentsWidth / (itemWidth + horizontalSpacing));
      _firstIndex = Std.int(comp.hscrollPos / (itemWidth + horizontalSpacing));
    }

    if (_firstIndex < 0) _firstIndex = 0;

    var rc:Rectangle = new Rectangle(0, 0, contentsWidth - (paddingLeft + paddingRight) - (borderSize * 2), contents.height);
    contents.componentClipRect = rc;

    _lastIndex = _firstIndex + visibleItemsCount + 1;
    if (_lastIndex > dataSource.size) _lastIndex = dataSource.size;
  }

  override function updateScroll():Void
  {
    var comp:IVirtualContainer = cast(_component, IVirtualContainer);
    var usableSize = this.usableSize;
    var dataSize:Int = dataSource.size;
    var horizontalSpacing = contents.layout.horizontalSpacing;
    var scrollMax:Float = 0;
    var itemWidth:Float = this.itemWidth;
    if (comp.variableItemSize)
    {
      scrollMax = -usableSize.width;
      for (i in 0...dataSource.size)
      {
        var size:Null<Float> = _sizeCache[i];
        if (size == null || size == 0) size = itemWidth;

        scrollMax += size + horizontalSpacing + horizontalConstraintModifier();
      }
    }
    else
    {
      scrollMax = (dataSize * itemWidth + ((dataSize - 1) * horizontalSpacing)) - usableSize.width + horizontalConstraintModifier();
    }

    if (scrollMax < 0) scrollMax = 0;

    comp.hscrollMax = scrollMax;
    comp.hscrollPageSize = (usableSize.width / (scrollMax + usableSize.width)) * scrollMax;
  }

  override public function calcAutoSize(?exclusions:Array<Component>):Size
  {
    var size:Size = super.calcAutoSize(exclusions);
    var comp:IVirtualContainer = cast(_component, IVirtualContainer);
    if (comp.itemCount > 0 && _component.autoWidth)
    {
      var contents:Component = _component.findComponent("scrollview-contents", false);
      var contentsPadding:Float = 0;
      var horizontalSpacing = this.horizontalSpacing;
      if (contents != null)
      {
        var layout = contents.layout;
        if (layout != null)
        {
          contentsPadding = layout.paddingLeft + layout.paddingRight;
          horizontalSpacing = layout.horizontalSpacing;
        }
      }

      size.width = (itemWidth * comp.itemCount)
        + paddingLeft
        + paddingRight
        + contentsPadding
        + (borderSize * 2)
        + ((comp.itemCount - 1) * horizontalSpacing);
    }

    return size;
  }
}
