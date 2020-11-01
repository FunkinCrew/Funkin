package io.newgrounds.crypto;

@:enum
abstract EncryptionFormat(String) to String {
	var BASE_64 = "base64";
	var HEX     = "hex";
}