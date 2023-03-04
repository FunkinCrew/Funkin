package flixel.addons.display;

import flixel.system.FlxAssets.FlxShader;
import lime.utils.Float32Array;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;

/**
 * An wrapper for Flixel/OpenFL's shaders, which takes fragment and vertex source
 * in the constructor instead of using macros, so it can be provided data
 * at runtime (for example, when using mods).
 * 
 * HOW TO USE:
 * 1. Create an instance of this class, passing the text of the `.frag` and `.vert` files.
 *    Note that you can set either of these to null (making them both null would make the shader do nothing???).
 * 2. Use `flxSprite.shader = runtimeShader` to apply the shader to the sprite.
 * 3. Use `runtimeShader.setFloat()`, `setBool()`, etc. to modify any uniforms.
 * 
 * @author MasterEric
 * @see https://github.com/openfl/openfl/blob/develop/src/openfl/utils/_internal/ShaderMacro.hx
 * @see https://dixonary.co.uk/blog/shadertoy
 */
class FlxRuntimeShader extends FlxShader
{
	#if FLX_DRAW_QUADS
	// We need to add stuff from FlxGraphicsShader too!
	#else
	// Only stuff from openfl.display.Shader is needed
	#end
	// These variables got copied from openfl.display.GraphicsShader
	// and from flixel.graphics.tile.FlxGraphicsShader,
	// and probably won't change ever.
	static final BASE_VERTEX_HEADER:String = "
		#pragma version

		#pragma precision

		attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;
		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;
		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
	";
	static final BASE_VERTEX_BODY:String = "
		openfl_Alphav = openfl_Alpha;
		openfl_TextureCoordv = openfl_TextureCoord;
		if (openfl_HasColorTransform) {
			openfl_ColorMultiplierv = openfl_ColorMultiplier;
			openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
		}
		gl_Position = openfl_Matrix * openfl_Position;
	";

	static final BASE_FRAGMENT_HEADER:String = "
		#pragma version

		#pragma precision

		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;
	"

	#if FLX_DRAW_QUADS
	// Add on more stuff!
	+ "
		uniform bool hasTransform;
		uniform bool hasColorTransform;
		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);
			if (!hasTransform)
			{
				return color;
			}
			if (color.a == 0.0)
			{
				return vec4(0.0, 0.0, 0.0, 0.0);
			}
			if (!hasColorTransform)
			{
				return color * openfl_Alphav;
			}
			color = vec4(color.rgb / color.a, color.a);
			mat4 colorMultiplier = mat4(0);
			colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
			colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
			colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
			colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
			color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
			if (color.a > 0.0)
			{
				return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}
	";
	#else
	// No additional data.
	;
	#end
	static final BASE_FRAGMENT_BODY:String = "
		vec4 color = texture2D (bitmap, openfl_TextureCoordv);
		if (color.a == 0.0) {
			gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);
		} else if (openfl_HasColorTransform) {
			color = vec4 (color.rgb / color.a, color.a);
			mat4 colorMultiplier = mat4 (0);
			colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
			colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
			colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
			colorMultiplier[3][3] = 1.0; // openfl_ColorMultiplierv.w;
			color = clamp (openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
			if (color.a > 0.0) {
				gl_FragColor = vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			} else {
				gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);
			}
		} else {
			gl_FragColor = color * openfl_Alphav;
		}
	";

	#if FLX_DRAW_QUADS
	static final DEFAULT_FRAGMENT_SOURCE:String = "
		#pragma header
		
		void main(void)
		{
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		}
	";
	#else
	static final DEFAULT_FRAGMENT_SOURCE:String = "
		#pragma header
		void main(void) {
			#pragma body
		}
	";
	#end

	#if FLX_DRAW_QUADS
	static final DEFAULT_VERTEX_SOURCE:String = "
		#pragma header
		
		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
		
		void main(void)
		{
			#pragma body
			
			openfl_Alphav = openfl_Alpha * alpha;
			
			if (hasColorTransform)
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
	";
	#else
	static final DEFAULT_VERTEX_SOURCE:String = "
		#pragma header
		void main(void) {
			#pragma body
		}
	";
	#end

	static final PRAGMA_HEADER:String = "#pragma header";
	static final PRAGMA_BODY:String = "#pragma body";
	static final PRAGMA_PRECISION:String = "#pragma precision";
	static final PRAGMA_VERSION:String = "#pragma version";

	private var _glslVersion:Int;

	/**
	 * Constructs a GLSL shader.
	 * @param fragmentSource The fragment shader source.
	 * @param vertexSource The vertex shader source.
	 * Note you also need to `initialize()` the shader MANUALLY! It can't be done automatically.
	 */
	public function new(fragmentSource:String = null, vertexSource:String = null, glslVersion:Int = 120):Void
	{
		_glslVersion = glslVersion;

		if (fragmentSource == null)
		{
			trace('Loading default fragment source...');
			glFragmentSource = processFragmentSource(DEFAULT_FRAGMENT_SOURCE);
		}
		else
		{
			trace('Loading fragment source from argument...');
			glFragmentSource = processFragmentSource(fragmentSource);
		}

		if (vertexSource == null)
		{
			var s = processVertexSource(DEFAULT_VERTEX_SOURCE);
			glVertexSource = s;
		}
		else
		{
			var s = processVertexSource(vertexSource);
			glVertexSource = s;
		}

		@:privateAccess {
			// This tells the shader that the glVertexSource/glFragmentSource have been updated.
			__glSourceDirty = true;
			// This tells the shader that the shader properties are NOT reflected on this class automatically.
			__isGenerated = false;
		}

		super();
	}
	
	/**
	 * Replace the `#pragma header` and `#pragma body` with the fragment shader header and body.
	 */
	function processFragmentSource(input:String):String
	{
		var result = StringTools.replace(input, PRAGMA_HEADER, BASE_FRAGMENT_HEADER);
		result = StringTools.replace(result, PRAGMA_BODY, BASE_FRAGMENT_BODY);
		return result;
	}

	/**
	 * Replace the `#pragma header` and `#pragma body` with the vertex shader header and body.
	 */
	function processVertexSource(input:String):String
	{
		var result = StringTools.replace(input, PRAGMA_HEADER, BASE_VERTEX_HEADER);
		result = StringTools.replace(result, PRAGMA_BODY, BASE_VERTEX_BODY);
		return result;
	}

	function buildPrecisionHeaders():String {
		return "#ifdef GL_ES
				" + (precisionHint == FULL ? "#ifdef GL_FRAGMENT_PRECISION_HIGH
					precision highp float;
				#else
					precision mediump float;
				#endif" : "precision lowp float;")
				+ "
				#endif
				";
	}

	/**
	 * The parent function that initializes the shader.
	 * This is done to add the `#version` shader directive.
	 */
	private override function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
		{
			__glSourceDirty = false;
			program = null;

			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();

			__processGLData(glVertexSource, "attribute");
			__processGLData(glVertexSource, "uniform");
			__processGLData(glFragmentSource, "uniform");
		}

		@:privateAccess
		if (__context != null && program == null)
		{
			var gl = __context.gl;

			var precisionHeaders = buildPrecisionHeaders();
			var versionHeader = '#version ${_glslVersion}\n';

			var vertex = StringTools.replace(glVertexSource, PRAGMA_PRECISION, precisionHeaders);
			vertex = StringTools.replace(vertex, PRAGMA_VERSION, versionHeader);
			var fragment = StringTools.replace(glFragmentSource, PRAGMA_PRECISION, precisionHeaders);
			fragment = StringTools.replace(fragment, PRAGMA_VERSION, versionHeader);
			
			var id = vertex + fragment;

			if (__context.__programs.exists(id)) {
				// Use the existing program if it has been compiled.
				program = __context.__programs.get(id);
			} else {
				// Build the program.
				program = __context.createProgram(GLSL);
				program.__glProgram = __createGLProgram(vertex, fragment);
				__context.__programs.set(id, program);
			}

			if (program != null) {
				glProgram = program.__glProgram;

				// Map attributes for each type.

				for (input in __inputBitmapData) {
					if (input.__isUniform) {
						input.index = gl.getUniformLocation(glProgram, input.name);
					} else {
						input.index = gl.getAttribLocation(glProgram, input.name);
					}
				}

				for (parameter in __paramBool) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramFloat) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramInt) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}
			}
		}
	}

	private var __fieldList:Array<String> = null;
	private function thisHasField(name:String) {
		// Reflect.hasField(this, name) is REALLY expensive so we use a cache.
		if (__fieldList == null) {
			__fieldList = Reflect.fields(this)
				.concat(Type.getInstanceFields(Type.getClass(this)));
		}
		return __fieldList.indexOf(name) != -1;
	}

	/**
	 * The parent function that initializes the shader.
	 * This is done because some shader fields (such as `bitmap`) have to automatically propagate from the shader,
	 * but others may not exist or be properties rather than fields.
	 */
	private override function __processGLData(source:String, storageType:String):Void
	{
		var position;
		var name;
		var type;

		var regex = (storageType == "uniform")
			? ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/
			: ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;

		var lastMatch = 0;

		@:privateAccess
		while (regex.matchSub(source, lastMatch)) {
			type = regex.matched(1);
			name = regex.matched(2);

			if (StringTools.startsWith(name, "gl_")) {
				continue;
			}

			var isUniform = (storageType == "uniform");

			if (StringTools.startsWith(type, "sampler")) {
				var input = new ShaderInput<BitmapData>();
				input.name = name;
				input.__isUniform = isUniform;
				__inputBitmapData.push(input);

				switch (name) {
					case "openfl_Texture":
						__texture = input;
					case "bitmap":
						__bitmap = input;
					default:
				}

				Reflect.setField(__data, name, input);
				if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, input);
			} else if (!Reflect.hasField(__data, name) || Reflect.field(__data, name) == null) {
				var parameterType:ShaderParameterType = switch (type)
				{
					case "bool": BOOL;
					case "double", "float": FLOAT;
					case "int", "uint": INT;
					case "bvec2": BOOL2;
					case "bvec3": BOOL3;
					case "bvec4": BOOL4;
					case "ivec2", "uvec2": INT2;
					case "ivec3", "uvec3": INT3;
					case "ivec4", "uvec4": INT4;
					case "vec2", "dvec2": FLOAT2;
					case "vec3", "dvec3": FLOAT3;
					case "vec4", "dvec4": FLOAT4;
					case "mat2", "mat2x2": MATRIX2X2;
					case "mat2x3": MATRIX2X3;
					case "mat2x4": MATRIX2X4;
					case "mat3x2": MATRIX3X2;
					case "mat3", "mat3x3": MATRIX3X3;
					case "mat3x4": MATRIX3X4;
					case "mat4x2": MATRIX4X2;
					case "mat4x3": MATRIX4X3;
					case "mat4", "mat4x4": MATRIX4X4;
					default: null;
				}

				var length = switch (parameterType)
				{
					case BOOL2, INT2, FLOAT2: 2;
					case BOOL3, INT3, FLOAT3: 3;
					case BOOL4, INT4, FLOAT4, MATRIX2X2: 4;
					case MATRIX3X3: 9;
					case MATRIX4X4: 16;
					default: 1;
				}

				var arrayLength = switch (parameterType)
				{
					case MATRIX2X2: 2;
					case MATRIX3X3: 3;
					case MATRIX4X4: 4;
					default: 1;
				}

				switch (parameterType)
				{
					case BOOL, BOOL2, BOOL3, BOOL4:
						var parameter = new ShaderParameter<Bool>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isBool = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramBool.push(parameter);

						if (name == "openfl_HasColorTransform")
						{
							__hasColorTransform = parameter;
						}

						Reflect.setField(__data, name, parameter);
						if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, parameter);

					case INT, INT2, INT3, INT4:
						var parameter = new ShaderParameter<Int>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isInt = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramInt.push(parameter);
						Reflect.setField(__data, name, parameter);
						if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, parameter);

					default:
						var parameter = new ShaderParameter<Float>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						#if lime
						if (arrayLength > 0) parameter.__uniformMatrix = new Float32Array(arrayLength * arrayLength);
						#end
						parameter.__isFloat = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramFloat.push(parameter);

						if (StringTools.startsWith(name, "openfl_"))
						{
							switch (name)
							{
								case "openfl_Alpha": __alpha = parameter;
								case "openfl_ColorMultiplier": __colorMultiplier = parameter;
								case "openfl_ColorOffset": __colorOffset = parameter;
								case "openfl_Matrix": __matrix = parameter;
								case "openfl_Position": __position = parameter;
								case "openfl_TextureCoord": __textureCoord = parameter;
								case "openfl_TextureSize": __textureSize = parameter;
								default:
							}
						}

						Reflect.setField(__data, name, parameter);
						if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, parameter);
				}
			}

			position = regex.matchedPos();
			lastMatch = position.pos + position.len;
		}
	}
	/**
	 * Modify a float parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloat(name:String, value:Float):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		@:privateAccess
		if (prop == null)
		{
			trace('[WARN] Shader float property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify a float array parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader float[] property ${name} not found.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify an integer parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader int property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify an integer array parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader int[] property ${name} not found.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify a boolean parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader bool property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify a boolean array parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader bool[] property ${name} not found.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Set or modify a sampler2D input of the shader.
	 * @param name The name of the shader input to modify.
	 * @param value The texture to use as the sampler2D input.
	 */
	public function setSampler2D(name:String, value:BitmapData)
	{
		var prop:ShaderInput<BitmapData> = Reflect.field(this.data, name);
		if(prop == null)
		{
			trace('[WARNING] Shader sampler2D property ${name} not found.');
			return;
		}
		prop.input = value;
	}

	/**
	 * Retrieve a float parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloat(name:String):Null<Float>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('[WARN] Shader float property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader float[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 */
	public function getInt(name:String):Null<Int>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('[WARN] Shader int property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader int[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve a boolean parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBool(name:String):Null<Bool>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('[WARN] Shader bool property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a boolean array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader bool[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	public function toString():String
	{
		return 'FlxRuntimeShader';
	}
}