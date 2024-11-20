#pragma header

void main()
{
  vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
  color.r = color.a;
  color.g = color.a;
  color.b = color.a;
  gl_FragColor = color;
}
