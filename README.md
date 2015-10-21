A few simple functions for doing the basic wire encoding and decoding for protocol buffers. Caveat, I'm not good at coding SQL function and haven't run a whole lot of tests. I only intend to use these functions as a quick hack for ad-hoc command-line access to data. Any production code would be better written in a real language.

These function don't parse an actual protobuf definition, validate or provide helper functions, They just let you manipulate the data directly provided that you know what types you are expecting. Floats, doubles and field ids > 15 cannot be handled.

zigzag(n bigint) RETURNS bigint - takes an integer value and zigzag-encodes it. Can be used for any size of int up to bigint.

dezigzag(n bigint unsigned) RETURNS bigint - takes an integer value and zigzag-encodes it. Can be used for any size of int up to bigint.

get_varint(proto_in blob) RETURNS bigint - gets a varint from the start of the message

get_varint__wire_size(varint_in bigint) - calculates the space taken by a varint (so it can be removed from the start of the message)

proto_decode(id_in INT, proto_in BLOB) - get an integer value from field number id_in from the message contained in proto_in

proto_decode_string(id_in INT, proto_in BLOB) - get a text value from the field number id_in in from the message contained in proto_in