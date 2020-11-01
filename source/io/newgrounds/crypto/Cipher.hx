package io.newgrounds.crypto;

@:enum
abstract Cipher(String) to String{
	var NONE    = "none";
	var AES_128 = "aes128";
	var RC4     = "rc4";
}