"""
MessagePack Packer

Serializes MsgPackValue to MessagePack binary format.

Supports all MessagePack types with automatic format selection:
- nil
- bool (true/false)
- int (fixint, int8/16/32/64, uint8/16/32/64)
- float (float32, float64)
- str (fixstr, str8/16/32)
- bin (bin8/16/32)
- array (fixarray, array16/32)
- map (fixmap, map16/32)

Example:
    from mojo_msgpack import MsgPackValue, pack

    var value = MsgPackValue.from_string("hello")
    var packed = pack(value)  # Returns List[UInt8]
"""

from .types import (
    MsgPackValue,
    MsgPackType,
    MsgPackMapEntry,
    NIL, TRUE, FALSE,
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
)


# =============================================================================
# Packer Struct
# =============================================================================

struct MsgPackPacker:
    """
    MessagePack serializer.

    Converts MsgPackValue to binary MessagePack format.

    Example:
        var packer = MsgPackPacker()
        var data = packer.pack(value)
    """
    var buffer: List[UInt8]

    fn __init__(out self):
        """Create a new packer."""
        self.buffer = List[UInt8]()

    fn clear(mut self):
        """Clear the internal buffer."""
        self.buffer = List[UInt8]()

    fn pack(mut self, value: MsgPackValue) -> List[UInt8]:
        """
        Pack a value to MessagePack format.

        Returns the packed binary data.
        """
        self.clear()
        self._pack_value(value)
        return self.buffer

    # =========================================================================
    # Internal Packing Methods
    # =========================================================================

    fn _pack_value(mut self, value: MsgPackValue):
        """Pack any MsgPackValue."""
        var vtype = value.type()

        if vtype == MsgPackType.NIL:
            self._pack_nil()
        elif vtype == MsgPackType.BOOL:
            self._pack_bool(value.as_bool())
        elif vtype == MsgPackType.INT:
            self._pack_int(value.as_int())
        elif vtype == MsgPackType.UINT:
            self._pack_uint(value.as_uint())
        elif vtype == MsgPackType.FLOAT:
            self._pack_float(value.as_float())
        elif vtype == MsgPackType.STR:
            self._pack_str(value.as_str())
        elif vtype == MsgPackType.BIN:
            self._pack_bin(value.as_bin())
        elif vtype == MsgPackType.ARRAY:
            self._pack_array(value.as_array())
        elif vtype == MsgPackType.MAP:
            self._pack_map(value.as_map())

    fn _pack_nil(mut self):
        """Pack nil."""
        self.buffer.append(NIL)

    fn _pack_bool(mut self, value: Bool):
        """Pack boolean."""
        if value:
            self.buffer.append(TRUE)
        else:
            self.buffer.append(FALSE)

    fn _pack_int(mut self, value: Int64):
        """Pack signed integer with smallest possible format."""
        if value >= 0:
            # Use unsigned format for non-negative values
            self._pack_uint(UInt64(value))
        elif value >= -32:
            # Negative fixint: 0xe0 - 0xff
            self.buffer.append(UInt8(value & 0xFF))
        elif value >= -128:
            # int8
            self.buffer.append(INT8)
            self.buffer.append(UInt8(value & 0xFF))
        elif value >= -32768:
            # int16
            self.buffer.append(INT16)
            self._write_be16(UInt16(value & 0xFFFF))
        elif value >= -2147483648:
            # int32
            self.buffer.append(INT32)
            self._write_be32(UInt32(value & 0xFFFFFFFF))
        else:
            # int64
            self.buffer.append(INT64)
            self._write_be64(UInt64(value))

    fn _pack_uint(mut self, value: UInt64):
        """Pack unsigned integer with smallest possible format."""
        if value <= 127:
            # Positive fixint: 0x00 - 0x7f
            self.buffer.append(UInt8(value))
        elif value <= 255:
            # uint8
            self.buffer.append(UINT8)
            self.buffer.append(UInt8(value))
        elif value <= 65535:
            # uint16
            self.buffer.append(UINT16)
            self._write_be16(UInt16(value))
        elif value <= 4294967295:
            # uint32
            self.buffer.append(UINT32)
            self._write_be32(UInt32(value))
        else:
            # uint64
            self.buffer.append(UINT64)
            self._write_be64(value)

    fn _pack_float(mut self, value: Float64):
        """Pack float64 (always uses double precision)."""
        self.buffer.append(FLOAT64)
        self._write_float64(value)

    fn _pack_str(mut self, value: String):
        """Pack string with smallest possible format."""
        var length = len(value)

        if length <= 31:
            # Fixstr: 0xa0 - 0xbf
            self.buffer.append(FIXSTR_PREFIX | UInt8(length))
        elif length <= 255:
            # str8
            self.buffer.append(STR8)
            self.buffer.append(UInt8(length))
        elif length <= 65535:
            # str16
            self.buffer.append(STR16)
            self._write_be16(UInt16(length))
        else:
            # str32
            self.buffer.append(STR32)
            self._write_be32(UInt32(length))

        # Write string bytes
        self._write_string(value)

    fn _pack_bin(mut self, value: List[UInt8]):
        """Pack binary data with smallest possible format."""
        var length = len(value)

        if length <= 255:
            # bin8
            self.buffer.append(BIN8)
            self.buffer.append(UInt8(length))
        elif length <= 65535:
            # bin16
            self.buffer.append(BIN16)
            self._write_be16(UInt16(length))
        else:
            # bin32
            self.buffer.append(BIN32)
            self._write_be32(UInt32(length))

        # Write binary data
        for i in range(length):
            self.buffer.append(value[i])

    fn _pack_array(mut self, value: List[MsgPackValue]):
        """Pack array with smallest possible format."""
        var length = len(value)

        if length <= 15:
            # Fixarray: 0x90 - 0x9f
            self.buffer.append(FIXARRAY_PREFIX | UInt8(length))
        elif length <= 65535:
            # array16
            self.buffer.append(ARRAY16)
            self._write_be16(UInt16(length))
        else:
            # array32
            self.buffer.append(ARRAY32)
            self._write_be32(UInt32(length))

        # Pack each element
        for i in range(length):
            self._pack_value(value[i])

    fn _pack_map(mut self, value: List[MsgPackMapEntry]):
        """Pack map with smallest possible format."""
        var length = len(value)

        if length <= 15:
            # Fixmap: 0x80 - 0x8f
            self.buffer.append(FIXMAP_PREFIX | UInt8(length))
        elif length <= 65535:
            # map16
            self.buffer.append(MAP16)
            self._write_be16(UInt16(length))
        else:
            # map32
            self.buffer.append(MAP32)
            self._write_be32(UInt32(length))

        # Pack each key-value pair
        for i in range(length):
            var entry = value[i]
            self._pack_value(entry.key)
            self._pack_value(entry.val)

    # =========================================================================
    # Binary Writing Helpers
    # =========================================================================

    fn _write_be16(mut self, value: UInt16):
        """Write 16-bit value in big-endian order."""
        self.buffer.append(UInt8((value >> 8) & 0xFF))
        self.buffer.append(UInt8(value & 0xFF))

    fn _write_be32(mut self, value: UInt32):
        """Write 32-bit value in big-endian order."""
        self.buffer.append(UInt8((value >> 24) & 0xFF))
        self.buffer.append(UInt8((value >> 16) & 0xFF))
        self.buffer.append(UInt8((value >> 8) & 0xFF))
        self.buffer.append(UInt8(value & 0xFF))

    fn _write_be64(mut self, value: UInt64):
        """Write 64-bit value in big-endian order."""
        self.buffer.append(UInt8((value >> 56) & 0xFF))
        self.buffer.append(UInt8((value >> 48) & 0xFF))
        self.buffer.append(UInt8((value >> 40) & 0xFF))
        self.buffer.append(UInt8((value >> 32) & 0xFF))
        self.buffer.append(UInt8((value >> 24) & 0xFF))
        self.buffer.append(UInt8((value >> 16) & 0xFF))
        self.buffer.append(UInt8((value >> 8) & 0xFF))
        self.buffer.append(UInt8(value & 0xFF))

    fn _write_float64(mut self, value: Float64):
        """Write float64 in IEEE 754 format (big-endian)."""
        # Reinterpret float bits as uint64
        var bits = bitcast[DType.uint64](SIMD[DType.float64, 1](value))
        self._write_be64(UInt64(bits))

    fn _write_string(mut self, value: String):
        """Write string bytes to buffer."""
        var bytes = value.as_bytes()
        for i in range(len(bytes)):
            self.buffer.append(bytes[i])


# =============================================================================
# Convenience Functions
# =============================================================================

fn pack(value: MsgPackValue) -> List[UInt8]:
    """
    Pack a MsgPackValue to MessagePack binary format.

    Example:
        var value = MsgPackValue.from_int(42)
        var data = pack(value)
    """
    var packer = MsgPackPacker()
    return packer.pack(value)


fn pack_nil() -> List[UInt8]:
    """Pack nil value."""
    return pack(MsgPackValue.nil())


fn pack_bool(value: Bool) -> List[UInt8]:
    """Pack boolean value."""
    return pack(MsgPackValue.from_bool(value))


fn pack_int(value: Int64) -> List[UInt8]:
    """Pack signed integer value."""
    return pack(MsgPackValue.from_int(value))


fn pack_uint(value: UInt64) -> List[UInt8]:
    """Pack unsigned integer value."""
    return pack(MsgPackValue.from_uint(value))


fn pack_float(value: Float64) -> List[UInt8]:
    """Pack float value."""
    return pack(MsgPackValue.from_float(value))


fn pack_str(value: String) -> List[UInt8]:
    """Pack string value."""
    return pack(MsgPackValue.from_string(value))


fn pack_bin(value: List[UInt8]) -> List[UInt8]:
    """Pack binary value."""
    return pack(MsgPackValue.from_bin(value))
