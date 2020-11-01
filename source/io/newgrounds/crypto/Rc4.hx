package io.newgrounds.crypto;

import haxe.io.Bytes;

/**
 * The following was straight-up ganked from https://github.com/iskolbin/rc4hx
 * 
 * You da real MVP iskolbin...
 * 
 * The MIT License (MIT)
 * 
 * Copyright (c) 2015 iskolbin
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
**/
class Rc4 {
	var perm = Bytes.alloc( 256 );
	var index1: Int = 0;
	var index2: Int = 0;
	
	public function new( key: Bytes ) {
		for ( i in 0...256 ) {
			perm.set( i, i );
		}
		
		var j: Int = 0;
		for ( i in 0...256 ) {
			j = ( j + perm.get( i ) + key.get( i % key.length )) % 256; 
			swap( i, j );
		}
	}
	
	inline function swap( i: Int, j: Int ): Void {
		var temp = perm.get( i );
		perm.set( i, perm.get( j ));
		perm.set( j, temp );
	}
	
	public function crypt( input: Bytes ): Bytes {
		var output = Bytes.alloc( input.length );
		
		for ( i in 0...input.length ) {
			index1 = ( index1 + 1 ) % 256;
			index2 = ( index2 + perm.get( index1 )) % 256;
			swap( index1, index2 );
			var j = ( perm.get( index1 ) + perm.get( index2 )) % 256;
			output.set( i, input.get( i ) ^ perm.get( j ));
		}
		
		return output;
	}
}