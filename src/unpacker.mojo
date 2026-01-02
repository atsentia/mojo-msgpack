"""
MessagePack Unpacker

Deserializes MessagePack binary format to MsgPackValue.

Supports all MessagePack types:
- nil
- bool (true/false)
- int (fixint, int8/16/32/64, uint8/16/32/64)
- float (float32, float64)
- str (fixstr, str8/16/32)
- bin (bin8/16/32)
- array (fixarray, array16/32)
- map (fixmap, map16/32)

Example:
    from mojo_msgpack import unpack

    var data = List[UInt8]()
    data.append(0xa5)  # fixstr of length 5
    data.append(0x68)  # 'h'
    data.append(0x65)  # 'e'
    data.append(0x6c)  # 'l'
    data.append(0x6c)  # 'l'
    data.append(0x6f)  # 'o'

    var value = unpack(data)
    print(value.as_str())  # "hello"
"""

from .types import (
    MsgPackValue,
    MsgPackType,
    MsgPackMapEntry,
    NIL, TRUE, FALSE, NEVER_USED,
    FIXINT_MAX, NEGATIVE_FIXINT_MIN,
    FIXSTR_PREFIX, FIXSTR_MASK,
    FIXARRAY_PREFIX, FIXARRAY_MASK,
    FIXMAP_PREFIX, FIXMAP_MASK,
    UINT8, UINT16, UINT32, UINT64,
    INT8, INT16, INT32, INT64,
    FLOAT32, FLOAT64,
    STR8, STR16, STR32,
    BIN8, BIN16, BIN32,
    ARRAY16, ARRAY32,
    MAP16, MAP32,
    EXT8, EXT16, EXT32,
    FIXEXT1, FIXEXT2, FIXEXT4, FIXEXT8, FIXEXT16,
)


# =============================================================================
# Unpacker Struct
# =============================================================================

struct MsgPackUnpacker:
    """
    MessagePack deserializer.

    Converts MessagePack binary data to MsgPackValue.

    Example:
        var unpacker = MsgPackUnpacker(data)
        var value = unpacker.unpack()
    """
    var data: List[UInt8]
    var offset: Int

    fn __init__(out self, data: List[UInt8]):
        """Create unpacker with input data."""
        self.data = data
        self.offset = 0

    fn reset(mut self, data: List[UInt8]):
        """Reset with new data."""
        self.data = data
        self.offset = 0

    fn remaining(self) -> Int:
        """Get number of remaining bytes."""
        return len(self.data) - self.offset

    fn is_complete(self) -> Bool:
        """Check if all data has been consumed."""
        return self.offset >= len(self.data)

    fn unpack(mut self) raises -> MsgPackValue:
        """
        Unpack the next value from the data.

        Raises if data is incomplete or invalid.
        """
        if self.offset >= len(self.data):
            raise Error("Unexpected end of data")

        var format_byte = self.data[self.offset]
        self.offset += 1

        # Check format byte ranges

        # Positive fixint: 0x00 - 0x7f
        if format_byte <= FIXINT_MAX:
            return MsgPackValue.from_uint(UInt64(format_byte))

        # Fixmap: 0x80 - 0x8f
        if format_byte >= FIXMAP_PREFIX and format_byte <= 0x8f:
            var length = Int(format_byte & FIXMAP_MASK)
            return self._unpack_map(length)

        # Fixarray: 0x90 - 0x9f
        if format_byte >= FIXARRAY_PREFIX and format_byte <= 0x9f:
            var length = Int(format_byte & FIXARRAY_MASK)
            return self._unpack_array(length)

        # Fixstr: 0xa0 - 0xbf
        if format_byte >= FIXSTR_PREFIX and format_byte <= 0xbf:
            var length = Int(format_byte & FIXSTR_MASK)
            return self._unpack_str(length)

        # Negative fixint: 0xe0 - 0xff
        if format_byte >= NEGATIVE_FIXINT_MIN:
            # Interpret as signed 8-bit value
            var signed_val = Int8(bitcast[DType.int8](SIMD[DType.uint8, 1](format_byte)))
            return MsgPackValue.from_int(Int64(signed_val))

        # Individual format bytes
        if format_byte == NIL:
            return MsgPackValue.nil()

        if format_byte == NEVER_USED:
            raise Error("Invalid format byte: 0xc1 (never used)")

        if format_byte == FALSE:
            return MsgPackValue.from_bool(False)

        if format_byte == TRUE:
            return MsgPackValue.from_bool(True)

        # Binary
        if format_byte == BIN8:
            var length = Int(self._read_u8())
            return self._unpack_bin(length)

        if format_byte == BIN16:
            var length = Int(self._read_be16())
            return self._unpack_bin(length)

        if format_byte == BIN32:
            var length = Int(self._read_be32())
            return self._unpack_bin(length)

        # Extension types (skip for now, read and discard)
        if format_byte == EXT8:
            var length = Int(self._read_u8())
            _ = self._read_u8()  # type
            self.offset += length
            return MsgPackValue.nil()  # Return nil for unsupported ext

        if format_byte == EXT16:
            var length = Int(self._read_be16())
            _ = self._read_u8()  # type
            self.offset += length
            return MsgPackValue.nil()

        if format_byte == EXT32:
            var length = Int(self._read_be32())
            _ = self._read_u8()  # type
            self.offset += length
            return MsgPackValue.nil()

        # Float
        if format_byte == FLOAT32:
            return MsgPackValue.from_float(Float64(self._read_float32()))

        if format_byte == FLOAT64:
            return MsgPackValue.from_float(self._read_float64())

        # Unsigned integers
        if format_byte == UINT8:
            return MsgPackValue.from_uint(UInt64(self._read_u8()))

        if format_byte == UINT16:
            return MsgPackValue.from_uint(UInt64(self._read_be16()))

        if format_byte == UINT32:
            return MsgPackValue.from_uint(UInt64(self._read_be32()))

        if format_byte == UINT64:
            return MsgPackValue.from_uint(self._read_be64())

        # Signed integers
        if format_byte == INT8:
            var val = self._read_u8()
            var signed = Int8(bitcast[DType.int8](SIMD[DType.uint8, 1](val)))
            return MsgPackValue.from_int(Int64(signed))

        if format_byte == INT16:
            var val = self._read_be16()
            var signed = Int16(bitcast[DType.int16](SIMD[DType.uint16, 1](val)))
            return MsgPackValue.from_int(Int64(signed))

        if format_byte == INT32:
            var val = self._read_be32()
            var signed = Int32(bitcast[DType.int32](SIMD[DType.uint32, 1](val)))
            return MsgPackValue.from_int(Int64(signed))

        if format_byte == INT64:
            var val = self._read_be64()
            var signed = Int64(bitcast[DType.int64](SIMD[DType.uint64, 1](val)))
            return MsgPackValue.from_int(signed)

        # Fixed extension types (skip)
        if format_byte == FIXEXT1:
            _ = self._read_u8()  # type
            self.offset += 1
            return MsgPackValue.nil()

        if format_byte == FIXEXT2:
            _ = self._read_u8()
            self.offset += 2
            return MsgPackValue.nil()

        if format_byte == FIXEXT4:
            _ = self._read_u8()
            self.offset += 4
            return MsgPackValue.nil()

        if format_byte == FIXEXT8:
            _ = self._read_u8()
            self.offset += 8
            return MsgPackValue.nil()

        if format_byte == FIXEXT16:
            _ = self._read_u8()
            self.offset += 16
            return MsgPackValue.nil()

        # String
        if format_byte == STR8:
            var length = Int(self._read_u8())
            return self._unpack_str(length)

        if format_byte == STR16:
            var length = Int(self._read_be16())
            return self._unpack_str(length)

        if format_byte == STR32:
            var length = Int(self._read_be32())
            return self._unpack_str(length)

        # Array
        if format_byte == ARRAY16:
            var length = Int(self._read_be16())
            return self._unpack_array(length)

        if format_byte == ARRAY32:
            var length = Int(self._read_be32())
            return self._unpack_array(length)

        # Map
        if format_byte == MAP16:
            var length = Int(self._read_be16())
            return self._unpack_map(length)

        if format_byte == MAP32:
            var length = Int(self._read_be32())
            return self._unpack_map(length)

        raise Error("Unknown format byte: " + str(Int(format_byte)))

    # =========================================================================
    # Internal Unpacking Methods
    # =========================================================================

    fn _unpack_str(mut self, length: Int) raises -> MsgPackValue:
        """Unpack string of given length."""
        if self.offset + length > len(self.data):
            raise Error("Unexpected end of data reading string")

        var result = String()
        for i in range(length):
            result += chr(Int(self.data[self.offset + i]))
        self.offset += length

        return MsgPackValue.from_string(result)

    fn _unpack_bin(mut self, length: Int) raises -> MsgPackValue:
        """Unpack binary data of given length."""
        if self.offset + length > len(self.data):
            raise Error("Unexpected end of data reading binary")

        var result = List[UInt8]()
        for i in range(length):
            result.append(self.data[self.offset + i])
        self.offset += length

        return MsgPackValue.from_bin(result)

    fn _unpack_array(mut self, length: Int) raises -> MsgPackValue:
        """Unpack array of given length."""
        var result = List[MsgPackValue]()
        for _ in range(length):
            result.append(self.unpack())
        return MsgPackValue.from_array(result)

    fn _unpack_map(mut self, length: Int) raises -> MsgPackValue:
        """Unpack map of given length (number of key-value pairs)."""
        var result = List[MsgPackMapEntry]()
        for _ in range(length):
            var key = self.unpack()
            var val = self.unpack()
            result.append(MsgPackMapEntry(key, val))
        return MsgPackValue.from_map(result)

    # =========================================================================
    # Binary Reading Helpers
    # =========================================================================

    fn _read_u8(mut self) raises -> UInt8:
        """Read 8-bit unsigned value."""
        if self.offset >= len(self.data):
            raise Error("Unexpected end of data")
        var val = self.data[self.offset]
        self.offset += 1
        return val

    fn _read_be16(mut self) raises -> UInt16:
        """Read 16-bit value in big-endian order."""
        if self.offset + 2 > len(self.data):
            raise Error("Unexpected end of data")

        var val = (UInt16(self.data[self.offset]) << 8) | UInt16(self.data[self.offset + 1])
        self.offset += 2
        return val

    fn _read_be32(mut self) raises -> UInt32:
        """Read 32-bit value in big-endian order."""
        if self.offset + 4 > len(self.data):
            raise Error("Unexpected end of data")

        var val = (
            (UInt32(self.data[self.offset]) << 24) |
            (UInt32(self.data[self.offset + 1]) << 16) |
            (UInt32(self.data[self.offset + 2]) << 8) |
            UInt32(self.data[self.offset + 3])
        )
        self.offset += 4
        return val

    fn _read_be64(mut self) raises -> UInt64:
        """Read 64-bit value in big-endian order."""
        if self.offset + 8 > len(self.data):
            raise Error("Unexpected end of data")

        var val: UInt64 = 0
        for i in range(8):
            val = (val << 8) | UInt64(self.data[self.offset + i])
        self.offset += 8
        return val

    fn _read_float32(mut self) raises -> Float32:
        """Read float32 in IEEE 754 format (big-endian)."""
        var bits = self._read_be32()
        return Float32(bitcast[DType.float32](SIMD[DType.uint32, 1](bits)))

    fn _read_float64(mut self) raises -> Float64:
        """Read float64 in IEEE 754 format (big-endian)."""
        var bits = self._read_be64()
        return Float64(bitcast[DType.float64](SIMD[DType.uint64, 1](bits)))


# =============================================================================
# Convenience Functions
# =============================================================================

fn unpack(data: List[UInt8]) raises -> MsgPackValue:
    """
    Unpack MessagePack binary data to MsgPackValue.

    Example:
        var data = pack_int(42)
        var value = unpack(data)
        print(value.as_int())  # 42
    """
    var unpacker = MsgPackUnpacker(data)
    return unpacker.unpack()


fn unpack_all(data: List[UInt8]) raises -> List[MsgPackValue]:
    """
    Unpack all values from MessagePack binary data.

    Use when data contains multiple concatenated values.

    Example:
        var data = List[UInt8]()
        # ... add multiple packed values ...
        var values = unpack_all(data)
    """
    var unpacker = MsgPackUnpacker(data)
    var result = List[MsgPackValue]()

    while not unpacker.is_complete():
        result.append(unpacker.unpack())

    return result


fn try_unpack(data: List[UInt8]) -> MsgPackValue:
    """
    Try to unpack data, returning nil on failure.

    Example:
        var value = try_unpack(data)
        if not value.is_nil():
            # use value
    """
    try:
        return unpack(data)
    except:
        return MsgPackValue.nil()
