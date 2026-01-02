"""
Mojo MessagePack Library

A pure Mojo library for MessagePack serialization and deserialization.
No external dependencies, maximum performance.

MessagePack is an efficient binary serialization format. It lets you exchange
data among multiple languages like JSON, but it's faster and smaller.

Features:
- Full MessagePack spec compliance
- MsgPackValue variant type for all MessagePack types
- Automatic format selection for smallest output
- Streaming unpacker for multiple values
- Type-safe accessors

Supported Types:
- nil
- bool (true/false)
- int (positive fixint, negative fixint, int8/16/32/64, uint8/16/32/64)
- float (float32, float64)
- str (fixstr, str8/16/32)
- bin (bin8/16/32)
- array (fixarray, array16/32)
- map (fixmap, map16/32)

Basic Usage:
    from mojo_msgpack import MsgPackValue, pack, unpack

    # Create and pack values
    var obj = MsgPackValue.from_int(42)
    var data = pack(obj)  # List[UInt8]

    # Unpack values
    var value = unpack(data)
    print(value.as_int())  # 42

    # Complex nested structures
    var map_entries = List[MsgPackMapEntry]()
    map_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("name"),
        MsgPackValue.from_string("Alice")
    ))
    map_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("age"),
        MsgPackValue.from_int(30)
    ))
    var obj = MsgPackValue.from_map(map_entries)

    var packed = pack(obj)
    var unpacked = unpack(packed)
    print(unpacked.get("name").as_str())  # "Alice"

Convenience Functions:
    # Pack primitives directly
    var int_data = pack_int(42)
    var str_data = pack_str("hello")
    var bool_data = pack_bool(True)

    # Try unpack (returns nil on error)
    var value = try_unpack(maybe_invalid_data)
    if not value.is_nil():
        # use value

    # Unpack multiple values
    var values = unpack_all(concatenated_data)

Format Specification:
    MessagePack uses a type-length-value encoding where the first byte(s)
    indicate the type and sometimes the length:

    - Positive fixint: 0x00 - 0x7f (value encoded in byte)
    - Fixmap: 0x80 - 0x8f (length in low 4 bits)
    - Fixarray: 0x90 - 0x9f (length in low 4 bits)
    - Fixstr: 0xa0 - 0xbf (length in low 5 bits)
    - Nil: 0xc0
    - False: 0xc2
    - True: 0xc3
    - Bin8/16/32: 0xc4 - 0xc6
    - Float32/64: 0xca - 0xcb
    - Uint8/16/32/64: 0xcc - 0xcf
    - Int8/16/32/64: 0xd0 - 0xd3
    - Str8/16/32: 0xd9 - 0xdb
    - Array16/32: 0xdc - 0xdd
    - Map16/32: 0xde - 0xdf
    - Negative fixint: 0xe0 - 0xff (value encoded in byte)
"""

# Value types
from .types import (
    MsgPackValue,
    MsgPackType,
    MsgPackMapEntry,
    MsgPackArray,
    MsgPackMap,
)

# Format constants (for advanced use)
from .types import (
    NIL, TRUE, FALSE,
    FIXINT_MAX, NEGATIVE_FIXINT_MIN,
    FIXSTR_PREFIX, FIXARRAY_PREFIX, FIXMAP_PREFIX,
    UINT8, UINT16, UINT32, UINT64,
    INT8, INT16, INT32, INT64,
    FLOAT32, FLOAT64,
    STR8, STR16, STR32,
    BIN8, BIN16, BIN32,
    ARRAY16, ARRAY32,
    MAP16, MAP32,
)

# Packer
from .packer import (
    MsgPackPacker,
    pack,
    pack_nil,
    pack_bool,
    pack_int,
    pack_uint,
    pack_float,
    pack_str,
    pack_bin,
)

# Unpacker
from .unpacker import (
    MsgPackUnpacker,
    unpack,
    unpack_all,
    try_unpack,
)
