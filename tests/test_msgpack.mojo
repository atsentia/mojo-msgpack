"""
MessagePack Tests

Comprehensive tests for the mojo-msgpack library covering all MessagePack types
and edge cases.
"""

from mojo_msgpack import (
    MsgPackValue,
    MsgPackType,
    MsgPackMapEntry,
    MsgPackPacker,
    MsgPackUnpacker,
    pack,
    unpack,
    pack_nil,
    pack_bool,
    pack_int,
    pack_uint,
    pack_float,
    pack_str,
    pack_bin,
    try_unpack,
    unpack_all,
)


# =============================================================================
# Nil Tests
# =============================================================================

fn test_nil() raises:
    """Test nil value packing/unpacking."""
    var value = MsgPackValue.nil()

    # Check type
    if not value.is_nil():
        raise Error("Value should be nil")

    # Pack and check format
    var data = pack(value)
    if len(data) != 1 or data[0] != 0xc0:
        raise Error("Nil should pack to single byte 0xc0")

    # Unpack and verify
    var unpacked = unpack(data)
    if not unpacked.is_nil():
        raise Error("Unpacked value should be nil")

    print("test_nil passed")


# =============================================================================
# Boolean Tests
# =============================================================================

fn test_bool() raises:
    """Test boolean value packing/unpacking."""
    # Test true
    var true_val = MsgPackValue.from_bool(True)
    if not true_val.is_bool() or not true_val.as_bool():
        raise Error("True value mismatch")

    var true_data = pack(true_val)
    if len(true_data) != 1 or true_data[0] != 0xc3:
        raise Error("True should pack to 0xc3")

    var true_unpacked = unpack(true_data)
    if not true_unpacked.as_bool():
        raise Error("Unpacked true should be true")

    # Test false
    var false_val = MsgPackValue.from_bool(False)
    if false_val.as_bool():
        raise Error("False value mismatch")

    var false_data = pack(false_val)
    if len(false_data) != 1 or false_data[0] != 0xc2:
        raise Error("False should pack to 0xc2")

    var false_unpacked = unpack(false_data)
    if false_unpacked.as_bool():
        raise Error("Unpacked false should be false")

    print("test_bool passed")


# =============================================================================
# Integer Tests
# =============================================================================

fn test_positive_fixint() raises:
    """Test positive fixint (0-127)."""
    # Test 0
    var val0 = MsgPackValue.from_uint(0)
    var data0 = pack(val0)
    if len(data0) != 1 or data0[0] != 0:
        raise Error("0 should pack to single byte 0x00")

    var unpacked0 = unpack(data0)
    if unpacked0.as_uint() != 0:
        raise Error("Unpacked 0 mismatch")

    # Test 127
    var val127 = MsgPackValue.from_uint(127)
    var data127 = pack(val127)
    if len(data127) != 1 or data127[0] != 0x7f:
        raise Error("127 should pack to single byte 0x7f")

    var unpacked127 = unpack(data127)
    if unpacked127.as_uint() != 127:
        raise Error("Unpacked 127 mismatch")

    # Test 42
    var val42 = MsgPackValue.from_int(42)
    var data42 = pack(val42)
    var unpacked42 = unpack(data42)
    if unpacked42.as_int() != 42:
        raise Error("Unpacked 42 mismatch")

    print("test_positive_fixint passed")


fn test_negative_fixint() raises:
    """Test negative fixint (-32 to -1)."""
    # Test -1
    var val_neg1 = MsgPackValue.from_int(-1)
    var data_neg1 = pack(val_neg1)
    if len(data_neg1) != 1 or data_neg1[0] != 0xff:
        raise Error("-1 should pack to 0xff, got " + str(Int(data_neg1[0])))

    var unpacked_neg1 = unpack(data_neg1)
    if unpacked_neg1.as_int() != -1:
        raise Error("Unpacked -1 mismatch: got " + str(unpacked_neg1.as_int()))

    # Test -32
    var val_neg32 = MsgPackValue.from_int(-32)
    var data_neg32 = pack(val_neg32)
    if len(data_neg32) != 1 or data_neg32[0] != 0xe0:
        raise Error("-32 should pack to 0xe0")

    var unpacked_neg32 = unpack(data_neg32)
    if unpacked_neg32.as_int() != -32:
        raise Error("Unpacked -32 mismatch")

    print("test_negative_fixint passed")


fn test_uint8() raises:
    """Test uint8 (128-255)."""
    var val = MsgPackValue.from_uint(200)
    var data = pack(val)

    if len(data) != 2 or data[0] != 0xcc or data[1] != 200:
        raise Error("200 should pack as uint8: 0xcc 0xc8")

    var unpacked = unpack(data)
    if unpacked.as_uint() != 200:
        raise Error("Unpacked 200 mismatch")

    print("test_uint8 passed")


fn test_uint16() raises:
    """Test uint16 (256-65535)."""
    var val = MsgPackValue.from_uint(1000)
    var data = pack(val)

    if len(data) != 3 or data[0] != 0xcd:
        raise Error("1000 should pack as uint16: 0xcd ...")

    var unpacked = unpack(data)
    if unpacked.as_uint() != 1000:
        raise Error("Unpacked 1000 mismatch")

    print("test_uint16 passed")


fn test_uint32() raises:
    """Test uint32 (65536-4294967295)."""
    var val = MsgPackValue.from_uint(100000)
    var data = pack(val)

    if data[0] != 0xce:
        raise Error("100000 should pack as uint32: 0xce ...")

    var unpacked = unpack(data)
    if unpacked.as_uint() != 100000:
        raise Error("Unpacked 100000 mismatch")

    print("test_uint32 passed")


fn test_uint64() raises:
    """Test uint64 (large values)."""
    var val = MsgPackValue.from_uint(5000000000)  # 5 billion
    var data = pack(val)

    if data[0] != 0xcf:
        raise Error("5 billion should pack as uint64: 0xcf ...")

    var unpacked = unpack(data)
    if unpacked.as_uint() != 5000000000:
        raise Error("Unpacked 5 billion mismatch")

    print("test_uint64 passed")


fn test_int8() raises:
    """Test int8 (-128 to -33)."""
    var val = MsgPackValue.from_int(-100)
    var data = pack(val)

    if data[0] != 0xd0:
        raise Error("-100 should pack as int8: 0xd0 ...")

    var unpacked = unpack(data)
    if unpacked.as_int() != -100:
        raise Error("Unpacked -100 mismatch: got " + str(unpacked.as_int()))

    print("test_int8 passed")


fn test_int16() raises:
    """Test int16 (-32768 to -129)."""
    var val = MsgPackValue.from_int(-1000)
    var data = pack(val)

    if data[0] != 0xd1:
        raise Error("-1000 should pack as int16: 0xd1 ...")

    var unpacked = unpack(data)
    if unpacked.as_int() != -1000:
        raise Error("Unpacked -1000 mismatch")

    print("test_int16 passed")


fn test_int32() raises:
    """Test int32 (large negative values)."""
    var val = MsgPackValue.from_int(-100000)
    var data = pack(val)

    if data[0] != 0xd2:
        raise Error("-100000 should pack as int32: 0xd2 ...")

    var unpacked = unpack(data)
    if unpacked.as_int() != -100000:
        raise Error("Unpacked -100000 mismatch")

    print("test_int32 passed")


fn test_int64() raises:
    """Test int64 (very large negative values)."""
    var val = MsgPackValue.from_int(-5000000000)  # -5 billion
    var data = pack(val)

    if data[0] != 0xd3:
        raise Error("-5 billion should pack as int64: 0xd3 ...")

    var unpacked = unpack(data)
    if unpacked.as_int() != -5000000000:
        raise Error("Unpacked -5 billion mismatch")

    print("test_int64 passed")


# =============================================================================
# Float Tests
# =============================================================================

fn test_float64() raises:
    """Test float64."""
    var val = MsgPackValue.from_float(3.14159265358979)
    var data = pack(val)

    if data[0] != 0xcb:
        raise Error("Float should pack as float64: 0xcb ...")

    if len(data) != 9:
        raise Error("Float64 should be 9 bytes")

    var unpacked = unpack(data)
    if not unpacked.is_float():
        raise Error("Unpacked should be float")

    # Check approximate equality (floating point)
    var diff = unpacked.as_float() - 3.14159265358979
    if diff < -0.0000001 or diff > 0.0000001:
        raise Error("Unpacked float mismatch")

    print("test_float64 passed")


fn test_float_zero() raises:
    """Test float zero."""
    var val = MsgPackValue.from_float(0.0)
    var data = pack(val)
    var unpacked = unpack(data)

    if unpacked.as_float() != 0.0:
        raise Error("Unpacked float zero mismatch")

    print("test_float_zero passed")


fn test_float_negative() raises:
    """Test negative float."""
    var val = MsgPackValue.from_float(-123.456)
    var data = pack(val)
    var unpacked = unpack(data)

    var diff = unpacked.as_float() - (-123.456)
    if diff < -0.001 or diff > 0.001:
        raise Error("Unpacked negative float mismatch")

    print("test_float_negative passed")


# =============================================================================
# String Tests
# =============================================================================

fn test_fixstr() raises:
    """Test fixstr (up to 31 bytes)."""
    var val = MsgPackValue.from_string("hello")
    var data = pack(val)

    # fixstr for 5 bytes: 0xa5
    if data[0] != 0xa5:
        raise Error("'hello' should pack with fixstr: 0xa5, got " + str(Int(data[0])))

    if len(data) != 6:  # 1 byte header + 5 bytes string
        raise Error("'hello' should be 6 bytes total")

    var unpacked = unpack(data)
    if unpacked.as_str() != "hello":
        raise Error("Unpacked string mismatch: got '" + unpacked.as_str() + "'")

    print("test_fixstr passed")


fn test_empty_string() raises:
    """Test empty string."""
    var val = MsgPackValue.from_string("")
    var data = pack(val)

    if data[0] != 0xa0:
        raise Error("Empty string should pack as 0xa0")

    var unpacked = unpack(data)
    if unpacked.as_str() != "":
        raise Error("Unpacked empty string mismatch")

    print("test_empty_string passed")


fn test_str8() raises:
    """Test str8 (32-255 bytes)."""
    # Create a string with 50 characters
    var long_str = String()
    for _ in range(50):
        long_str += "x"

    var val = MsgPackValue.from_string(long_str)
    var data = pack(val)

    if data[0] != 0xd9:
        raise Error("50-char string should pack as str8: 0xd9")

    var unpacked = unpack(data)
    if len(unpacked.as_str()) != 50:
        raise Error("Unpacked str8 length mismatch")

    print("test_str8 passed")


# =============================================================================
# Binary Tests
# =============================================================================

fn test_bin8() raises:
    """Test bin8."""
    var bin_data = List[UInt8]()
    for i in range(10):
        bin_data.append(UInt8(i))

    var val = MsgPackValue.from_bin(bin_data)
    var data = pack(val)

    if data[0] != 0xc4:
        raise Error("10-byte binary should pack as bin8: 0xc4")

    var unpacked = unpack(data)
    if not unpacked.is_bin():
        raise Error("Unpacked should be binary")

    var unpacked_bin = unpacked.as_bin()
    if len(unpacked_bin) != 10:
        raise Error("Unpacked binary length mismatch")

    for i in range(10):
        if unpacked_bin[i] != UInt8(i):
            raise Error("Unpacked binary content mismatch")

    print("test_bin8 passed")


# =============================================================================
# Array Tests
# =============================================================================

fn test_fixarray() raises:
    """Test fixarray (up to 15 elements)."""
    var arr = List[MsgPackValue]()
    arr.append(MsgPackValue.from_int(1))
    arr.append(MsgPackValue.from_int(2))
    arr.append(MsgPackValue.from_int(3))

    var val = MsgPackValue.from_array(arr)
    var data = pack(val)

    # fixarray for 3 elements: 0x93
    if data[0] != 0x93:
        raise Error("3-element array should pack with fixarray: 0x93")

    var unpacked = unpack(data)
    if not unpacked.is_array():
        raise Error("Unpacked should be array")

    var unpacked_arr = unpacked.as_array()
    if len(unpacked_arr) != 3:
        raise Error("Unpacked array length mismatch")

    if unpacked_arr[0].as_int() != 1:
        raise Error("Array element 0 mismatch")
    if unpacked_arr[1].as_int() != 2:
        raise Error("Array element 1 mismatch")
    if unpacked_arr[2].as_int() != 3:
        raise Error("Array element 2 mismatch")

    print("test_fixarray passed")


fn test_empty_array() raises:
    """Test empty array."""
    var arr = List[MsgPackValue]()
    var val = MsgPackValue.from_array(arr)
    var data = pack(val)

    if data[0] != 0x90:
        raise Error("Empty array should pack as 0x90")

    var unpacked = unpack(data)
    if len(unpacked.as_array()) != 0:
        raise Error("Unpacked empty array should have 0 elements")

    print("test_empty_array passed")


fn test_nested_array() raises:
    """Test nested arrays."""
    var inner = List[MsgPackValue]()
    inner.append(MsgPackValue.from_int(1))
    inner.append(MsgPackValue.from_int(2))

    var outer = List[MsgPackValue]()
    outer.append(MsgPackValue.from_array(inner))
    outer.append(MsgPackValue.from_string("end"))

    var val = MsgPackValue.from_array(outer)
    var data = pack(val)
    var unpacked = unpack(data)

    var outer_arr = unpacked.as_array()
    if len(outer_arr) != 2:
        raise Error("Outer array should have 2 elements")

    var inner_arr = outer_arr[0].as_array()
    if len(inner_arr) != 2:
        raise Error("Inner array should have 2 elements")

    if inner_arr[0].as_int() != 1 or inner_arr[1].as_int() != 2:
        raise Error("Inner array elements mismatch")

    if outer_arr[1].as_str() != "end":
        raise Error("Outer array string element mismatch")

    print("test_nested_array passed")


# =============================================================================
# Map Tests
# =============================================================================

fn test_fixmap() raises:
    """Test fixmap (up to 15 pairs)."""
    var entries = List[MsgPackMapEntry]()
    entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("name"),
        MsgPackValue.from_string("Alice")
    ))
    entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("age"),
        MsgPackValue.from_int(30)
    ))

    var val = MsgPackValue.from_map(entries)
    var data = pack(val)

    # fixmap for 2 pairs: 0x82
    if data[0] != 0x82:
        raise Error("2-pair map should pack with fixmap: 0x82")

    var unpacked = unpack(data)
    if not unpacked.is_map():
        raise Error("Unpacked should be map")

    # Test get accessor
    if unpacked.get("name").as_str() != "Alice":
        raise Error("Map 'name' mismatch")

    if unpacked.get("age").as_int() != 30:
        raise Error("Map 'age' mismatch")

    print("test_fixmap passed")


fn test_empty_map() raises:
    """Test empty map."""
    var entries = List[MsgPackMapEntry]()
    var val = MsgPackValue.from_map(entries)
    var data = pack(val)

    if data[0] != 0x80:
        raise Error("Empty map should pack as 0x80")

    var unpacked = unpack(data)
    if len(unpacked.as_map()) != 0:
        raise Error("Unpacked empty map should have 0 entries")

    print("test_empty_map passed")


fn test_nested_map() raises:
    """Test nested maps."""
    # Inner map
    var inner_entries = List[MsgPackMapEntry]()
    inner_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("x"),
        MsgPackValue.from_int(10)
    ))

    # Outer map
    var outer_entries = List[MsgPackMapEntry]()
    outer_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("point"),
        MsgPackValue.from_map(inner_entries)
    ))

    var val = MsgPackValue.from_map(outer_entries)
    var data = pack(val)
    var unpacked = unpack(data)

    var point = unpacked.get("point")
    if not point.is_map():
        raise Error("'point' should be a map")

    if point.get("x").as_int() != 10:
        raise Error("Nested map value mismatch")

    print("test_nested_map passed")


fn test_int_keys() raises:
    """Test map with integer keys."""
    var entries = List[MsgPackMapEntry]()
    entries.append(MsgPackMapEntry(
        MsgPackValue.from_int(1),
        MsgPackValue.from_string("one")
    ))
    entries.append(MsgPackMapEntry(
        MsgPackValue.from_int(2),
        MsgPackValue.from_string("two")
    ))

    var val = MsgPackValue.from_map(entries)
    var data = pack(val)
    var unpacked = unpack(data)

    var map_entries = unpacked.as_map()
    if len(map_entries) != 2:
        raise Error("Map should have 2 entries")

    if map_entries[0].key.as_int() != 1:
        raise Error("First key should be 1")
    if map_entries[0].val.as_str() != "one":
        raise Error("First value should be 'one'")

    print("test_int_keys passed")


# =============================================================================
# Round-Trip Tests
# =============================================================================

fn test_roundtrip_complex() raises:
    """Test complex nested structure round-trip."""
    # Build: {"users": [{"name": "Bob", "active": true}], "count": 1}
    var user_entries = List[MsgPackMapEntry]()
    user_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("name"),
        MsgPackValue.from_string("Bob")
    ))
    user_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("active"),
        MsgPackValue.from_bool(True)
    ))
    var user = MsgPackValue.from_map(user_entries)

    var users = List[MsgPackValue]()
    users.append(user)

    var root_entries = List[MsgPackMapEntry]()
    root_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("users"),
        MsgPackValue.from_array(users)
    ))
    root_entries.append(MsgPackMapEntry(
        MsgPackValue.from_string("count"),
        MsgPackValue.from_int(1)
    ))
    var root = MsgPackValue.from_map(root_entries)

    # Pack and unpack
    var data = pack(root)
    var unpacked = unpack(data)

    # Verify
    if unpacked.get("count").as_int() != 1:
        raise Error("Root 'count' mismatch")

    var unpacked_users = unpacked.get("users").as_array()
    if len(unpacked_users) != 1:
        raise Error("Should have 1 user")

    var unpacked_user = unpacked_users[0]
    if unpacked_user.get("name").as_str() != "Bob":
        raise Error("User name mismatch")

    if not unpacked_user.get("active").as_bool():
        raise Error("User active mismatch")

    print("test_roundtrip_complex passed")


# =============================================================================
# Edge Cases
# =============================================================================

fn test_try_unpack() raises:
    """Test try_unpack with invalid data."""
    var empty = List[UInt8]()
    var result = try_unpack(empty)

    if not result.is_nil():
        raise Error("try_unpack on empty should return nil")

    # Valid data should work
    var valid = pack_int(42)
    var valid_result = try_unpack(valid)
    if valid_result.as_int() != 42:
        raise Error("try_unpack on valid data failed")

    print("test_try_unpack passed")


fn test_convenience_functions() raises:
    """Test convenience pack functions."""
    # pack_nil
    var nil_data = pack_nil()
    if nil_data[0] != 0xc0:
        raise Error("pack_nil failed")

    # pack_bool
    var true_data = pack_bool(True)
    if true_data[0] != 0xc3:
        raise Error("pack_bool(True) failed")

    # pack_int
    var int_data = pack_int(42)
    var int_val = unpack(int_data)
    if int_val.as_int() != 42:
        raise Error("pack_int failed")

    # pack_uint
    var uint_data = pack_uint(200)
    var uint_val = unpack(uint_data)
    if uint_val.as_uint() != 200:
        raise Error("pack_uint failed")

    # pack_float
    var float_data = pack_float(1.5)
    var float_val = unpack(float_data)
    var diff = float_val.as_float() - 1.5
    if diff < -0.001 or diff > 0.001:
        raise Error("pack_float failed")

    # pack_str
    var str_data = pack_str("test")
    var str_val = unpack(str_data)
    if str_val.as_str() != "test":
        raise Error("pack_str failed")

    print("test_convenience_functions passed")


fn test_value_string_repr() raises:
    """Test string representation of values."""
    var nil_str = str(MsgPackValue.nil())
    if nil_str != "nil":
        raise Error("nil string repr mismatch")

    var bool_str = str(MsgPackValue.from_bool(True))
    if bool_str != "true":
        raise Error("true string repr mismatch")

    var int_str = str(MsgPackValue.from_int(-5))
    if int_str != "-5":
        raise Error("int string repr mismatch")

    var str_str = str(MsgPackValue.from_string("hi"))
    if str_str != '"hi"':
        raise Error("string repr mismatch")

    print("test_value_string_repr passed")


fn test_type_checking() raises:
    """Test type checking methods."""
    var nil = MsgPackValue.nil()
    if not nil.is_nil():
        raise Error("is_nil failed")

    var int_val = MsgPackValue.from_int(1)
    if not int_val.is_int():
        raise Error("is_int failed")
    if not int_val.is_integer():
        raise Error("is_integer failed for int")
    if not int_val.is_number():
        raise Error("is_number failed for int")

    var uint_val = MsgPackValue.from_uint(1)
    if not uint_val.is_uint():
        raise Error("is_uint failed")
    if not uint_val.is_integer():
        raise Error("is_integer failed for uint")

    var float_val = MsgPackValue.from_float(1.0)
    if not float_val.is_float():
        raise Error("is_float failed")
    if not float_val.is_number():
        raise Error("is_number failed for float")

    print("test_type_checking passed")


fn test_equality() raises:
    """Test value equality."""
    var a = MsgPackValue.from_int(42)
    var b = MsgPackValue.from_int(42)
    var c = MsgPackValue.from_int(43)

    if a != b:
        raise Error("Equal values should be equal")

    if a == c:
        raise Error("Different values should not be equal")

    # Different types
    var d = MsgPackValue.from_string("42")
    if a == d:
        raise Error("Different types should not be equal")

    print("test_equality passed")


# =============================================================================
# Main
# =============================================================================

fn main() raises:
    print("Running MessagePack tests...\n")

    # Nil
    test_nil()

    # Boolean
    test_bool()

    # Integer
    test_positive_fixint()
    test_negative_fixint()
    test_uint8()
    test_uint16()
    test_uint32()
    test_uint64()
    test_int8()
    test_int16()
    test_int32()
    test_int64()

    # Float
    test_float64()
    test_float_zero()
    test_float_negative()

    # String
    test_fixstr()
    test_empty_string()
    test_str8()

    # Binary
    test_bin8()

    # Array
    test_fixarray()
    test_empty_array()
    test_nested_array()

    # Map
    test_fixmap()
    test_empty_map()
    test_nested_map()
    test_int_keys()

    # Round-trip
    test_roundtrip_complex()

    # Edge cases
    test_try_unpack()
    test_convenience_functions()
    test_value_string_repr()
    test_type_checking()
    test_equality()

    print("\nAll MessagePack tests passed!")
