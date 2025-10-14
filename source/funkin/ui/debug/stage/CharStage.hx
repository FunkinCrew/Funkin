package funkin.ui.debug.stage;

#if FEATURE_STAGE_EDITOR
class CharStage extends SprStage
{
  public function new(x:Float, y:Float, dragShitFunc:SprStage->Void)
  {
    super(x, y, dragShitFunc);
  }
}
#end
