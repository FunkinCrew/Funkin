package funkin.ui.transition.preload;

import openfl.display.GraphicsShader;

class VFDOverlay extends GraphicsShader
{
  public var elapsedTime(default, set):Float = 0;

  function set_elapsedTime(value:Float):Float
  {
    u_time.value = [value];
    return value;
  }

  @:glFragmentSource('#pragma header
    const vec2 s = vec2(1, 1.7320508);

    uniform float u_time;

    float rand(float co) { return fract(sin(co*(91.3458)) * 47453.5453); }
    float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }

    void main(void) {
      vec4 col = texture2D (bitmap, openfl_TextureCoordv);
      vec2 game_res = vec2(1280.0, 720.0);
      const float tileAmount = 10.;

      vec2 uv = (2. * openfl_TextureCoordv.xy * -1.);
      uv *= 50.;

      vec4 hexCenter = floor(vec4(uv, uv - vec2(0.5, 1.0)) / s.xyxy) + 0.5;
      vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + 0.5) * s) + 0.0;
      vec4 hexInfo = dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? vec4(offset.xy, hexCenter.xy) : vec4(offset.zw, hexCenter.zw);

      // Distance to the nearest edge of a hexagon
      vec2 p = abs(hexInfo.xy) ;
      float edgeDist = max(dot(p, normalize(vec2(1.0, sqrt(3.0)))), p.x);
      float edgeWidth = 0.05 * tileAmount; // Adjust edge width based on tile amount
      float edgeSharpness = 0.011 * tileAmount;

      float outline = smoothstep(edgeWidth - edgeSharpness, edgeWidth, edgeDist);
      float color_mix = mix(0.0, 0.3, outline); // Mix black outline with white fill

      float flicker = (sin(u_time) * 0.05) + 1.0;
      float sinshit = smoothstep(-3.0, 1.0, sin(uv.y * 3.));

      col = vec4(vec3(0.0), color_mix);
      col = mix(col, vec4(0., 0., 0., sinshit), 0.5 * flicker);

      float specs = rand(uv.xy);
      vec4 noise = vec4(0., 0., 0., specs);
      col = mix(col, noise, 0.1);

      gl_FragColor = col;
		}
  ')
  public function new()
  {
    super();

    this.elapsedTime = 0;
  }

  public function update(elapsed:Float):Void
  {
    this.elapsedTime += elapsed;
  }
}
