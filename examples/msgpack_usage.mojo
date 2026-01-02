"""MessagePack serialization examples."""
from mojo_msgpack import MsgPackValue, MsgPackMapEntry, pack, unpack

fn main() raises:
    # Pack simple values
    var int_val = MsgPackValue.from_int(42)
    var packed_int = pack(int_val)
    print("Packed int size:", len(packed_int), "bytes")
    
    # Unpack
    var unpacked = unpack(packed_int)
    print("Unpacked:", unpacked.as_int())
    
    # Pack a map (like JSON object)
    var entries = List[MsgPackMapEntry]()
    entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("name"),
        MsgPackValue.from_string("Alice")
    ))
    entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("score"),
        MsgPackValue.from_int(100)
    ))
    var map_val = MsgPackValue.from_map(entries)
    
    var packed_map = pack(map_val)
    print("Packed map size:", len(packed_map), "bytes")
    
    var unpacked_map = unpack(packed_map)
    print("Name:", unpacked_map.get("name").as_str())
