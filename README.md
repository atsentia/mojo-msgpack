# mojo-msgpack

Pure Mojo MessagePack serialization library.

## Features

- **Full MessagePack Spec** - All types supported
- **MsgPackValue** - Variant type for any MessagePack value
- **Automatic Format Selection** - Smallest output size
- **Streaming Unpacker** - Handle multiple values
- **Type-safe Accessors** - Safe value extraction

## Installation

```bash
pixi add mojo-msgpack
```

## Quick Start

### Basic Usage

```mojo
from mojo_msgpack import MsgPackValue, pack, unpack

# Pack a value
var obj = MsgPackValue.from_int(42)
var data = pack(obj)

# Unpack
var value = unpack(data)
print(value.as_int())  # 42
```

### Complex Structures

```mojo
from mojo_msgpack import MsgPackValue, MsgPackMapEntry, pack, unpack

# Create a map
var entries = List[MsgPackMapEntry]()
entries.append(MsgPackMapEntry(
    MsgPackValue.from_string("name"),
    MsgPackValue.from_string("Alice")
))
entries.append(MsgPackMapEntry(
    MsgPackValue.from_string("age"),
    MsgPackValue.from_int(30)
))
var obj = MsgPackValue.from_map(entries)

var packed = pack(obj)
var unpacked = unpack(packed)
print(unpacked.get("name").as_str())  # "Alice"
```

### Convenience Functions

```mojo
from mojo_msgpack import pack_int, pack_str, pack_bool, try_unpack

var int_data = pack_int(42)
var str_data = pack_str("hello")
var bool_data = pack_bool(True)
```

## Supported Types

| Type | MessagePack Formats |
|------|---------------------|
| nil | nil |
| bool | true, false |
| int | fixint, int8-64, uint8-64 |
| float | float32, float64 |
| str | fixstr, str8/16/32 |
| bin | bin8/16/32 |
| array | fixarray, array16/32 |
| map | fixmap, map16/32 |

## Testing

```bash
mojo run tests/test_msgpack.mojo
```

## License

Apache 2.0

## Part of mojo-contrib

This library is part of [mojo-contrib](https://github.com/atsentia/mojo-contrib), a collection of pure Mojo libraries.
