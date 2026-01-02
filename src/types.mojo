"""
MessagePack Value Types

Defines the MsgPackValue variant type for representing all MessagePack types:
- nil
- bool
- int (signed/unsigned, 8/16/32/64 bit)
- float (32/64 bit)
- str (fixstr, str8/16/32)
- bin (bin8/16/32)
- array (fixarray, array16/32)
- map (fixmap, map16/32)
"""


# =============================================================================
# MessagePack Format Constants
# =============================================================================

# Positive fixint: 0x00 - 0x7f (0 - 127)
alias FIXINT_MAX: UInt8 = 0x7f

# Negative fixint: 0xe0 - 0xff (-32 to -1)
alias NEGATIVE_FIXINT_MIN: UInt8 = 0xe0

# Fixmap: 0x80 - 0x8f (up to 15 elements)
alias FIXMAP_PREFIX: UInt8 = 0x80
alias FIXMAP_MASK: UInt8 = 0x0f

# Fixarray: 0x90 - 0x9f (up to 15 elements)
alias FIXARRAY_PREFIX: UInt8 = 0x90
alias FIXARRAY_MASK: UInt8 = 0x0f

# Fixstr: 0xa0 - 0xbf (up to 31 bytes)
alias FIXSTR_PREFIX: UInt8 = 0xa0
alias FIXSTR_MASK: UInt8 = 0x1f

# Nil
alias NIL: UInt8 = 0xc0

# Unused (never used)
alias NEVER_USED: UInt8 = 0xc1

# Bool
alias FALSE: UInt8 = 0xc2
alias TRUE: UInt8 = 0xc3

# Binary
alias BIN8: UInt8 = 0xc4
alias BIN16: UInt8 = 0xc5
alias BIN32: UInt8 = 0xc6

# Extension (not fully implemented)
alias EXT8: UInt8 = 0xc7
alias EXT16: UInt8 = 0xc8
alias EXT32: UInt8 = 0xc9

# Float
alias FLOAT32: UInt8 = 0xca
alias FLOAT64: UInt8 = 0xcb

# Unsigned integers
alias UINT8: UInt8 = 0xcc
alias UINT16: UInt8 = 0xcd
alias UINT32: UInt8 = 0xce
alias UINT64: UInt8 = 0xcf

# Signed integers
alias INT8: UInt8 = 0xd0
alias INT16: UInt8 = 0xd1
alias INT32: UInt8 = 0xd2
alias INT64: UInt8 = 0xd3

# Fixed extension (not fully implemented)
alias FIXEXT1: UInt8 = 0xd4
alias FIXEXT2: UInt8 = 0xd5
alias FIXEXT4: UInt8 = 0xd6
alias FIXEXT8: UInt8 = 0xd7
alias FIXEXT16: UInt8 = 0xd8

# String
alias STR8: UInt8 = 0xd9
alias STR16: UInt8 = 0xda
alias STR32: UInt8 = 0xdb

# Array
alias ARRAY16: UInt8 = 0xdc
alias ARRAY32: UInt8 = 0xdd

# Map
alias MAP16: UInt8 = 0xde
alias MAP32: UInt8 = 0xdf


# =============================================================================
# Value Type Enum
# =============================================================================

@value
struct MsgPackType:
    """Enum-like struct for MessagePack value types."""
    var value: Int

    alias NIL = MsgPackType(0)
    alias BOOL = MsgPackType(1)
    alias INT = MsgPackType(2)
    alias UINT = MsgPackType(3)
    alias FLOAT = MsgPackType(4)
    alias STR = MsgPackType(5)
    alias BIN = MsgPackType(6)
    alias ARRAY = MsgPackType(7)
    alias MAP = MsgPackType(8)
    alias EXT = MsgPackType(9)

    fn __eq__(self, other: MsgPackType) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: MsgPackType) -> Bool:
        return self.value != other.value

    fn __str__(self) -> String:
        if self == MsgPackType.NIL:
            return "nil"
        elif self == MsgPackType.BOOL:
            return "bool"
        elif self == MsgPackType.INT:
            return "int"
        elif self == MsgPackType.UINT:
            return "uint"
        elif self == MsgPackType.FLOAT:
            return "float"
        elif self == MsgPackType.STR:
            return "str"
        elif self == MsgPackType.BIN:
            return "bin"
        elif self == MsgPackType.ARRAY:
            return "array"
        elif self == MsgPackType.MAP:
            return "map"
        elif self == MsgPackType.EXT:
            return "ext"
        else:
            return "unknown"


# =============================================================================
# Type Aliases
# =============================================================================

alias MsgPackArray = List[MsgPackValue]
alias MsgPackMap = List[MsgPackMapEntry]


# =============================================================================
# Map Entry (Key-Value Pair)
# =============================================================================

struct MsgPackMapEntry:
    """A key-value pair in a MessagePack map."""
    var key: MsgPackValue
    var val: MsgPackValue

    fn __init__(out self, key: MsgPackValue, val: MsgPackValue):
        self.key = key
        self.val = val

    fn __init__(out self, other: MsgPackMapEntry):
        self.key = other.key
        self.val = other.val

    fn __copyinit__(out self, other: MsgPackMapEntry):
        self.key = other.key
        self.val = other.val

    fn __moveinit__(out self, owned other: MsgPackMapEntry):
        self.key = other.key^
        self.val = other.val^


# =============================================================================
# MsgPackValue - Variant Type
# =============================================================================

struct MsgPackValue:
    """
    A MessagePack value that can hold any MessagePack type.

    This is a discriminated union (variant) type that stores the type tag
    and the value data.

    Example:
        var nil_val = MsgPackValue.nil()
        var int_val = MsgPackValue.from_int(42)
        var str_val = MsgPackValue.from_string("hello")
        var arr_val = MsgPackValue.from_array(my_array)
    """
    var _type: MsgPackType
    var _int_val: Int64
    var _uint_val: UInt64
    var _float_val: Float64
    var _bool_val: Bool
    var _str_val: String
    var _bin_val: List[UInt8]
    var _array_val: List[MsgPackValue]
    var _map_val: List[MsgPackMapEntry]

    # =========================================================================
    # Constructors
    # =========================================================================

    fn __init__(out self):
        """Create a nil value."""
        self._type = MsgPackType.NIL
        self._int_val = 0
        self._uint_val = 0
        self._float_val = 0.0
        self._bool_val = False
        self._str_val = String()
        self._bin_val = List[UInt8]()
        self._array_val = List[MsgPackValue]()
        self._map_val = List[MsgPackMapEntry]()

    fn __init__(out self, other: MsgPackValue):
        """Copy constructor."""
        self._type = other._type
        self._int_val = other._int_val
        self._uint_val = other._uint_val
        self._float_val = other._float_val
        self._bool_val = other._bool_val
        self._str_val = other._str_val
        self._bin_val = other._bin_val
        self._array_val = other._array_val
        self._map_val = other._map_val

    fn __copyinit__(out self, other: MsgPackValue):
        """Copy initializer."""
        self._type = other._type
        self._int_val = other._int_val
        self._uint_val = other._uint_val
        self._float_val = other._float_val
        self._bool_val = other._bool_val
        self._str_val = other._str_val
        self._bin_val = other._bin_val
        self._array_val = other._array_val
        self._map_val = other._map_val

    fn __moveinit__(out self, owned other: MsgPackValue):
        """Move initializer."""
        self._type = other._type
        self._int_val = other._int_val
        self._uint_val = other._uint_val
        self._float_val = other._float_val
        self._bool_val = other._bool_val
        self._str_val = other._str_val^
        self._bin_val = other._bin_val^
        self._array_val = other._array_val^
        self._map_val = other._map_val^

    # =========================================================================
    # Factory Methods
    # =========================================================================

    @staticmethod
    fn nil() -> MsgPackValue:
        """Create a nil value."""
        return MsgPackValue()

    @staticmethod
    fn from_bool(value: Bool) -> MsgPackValue:
        """Create a boolean value."""
        var v = MsgPackValue()
        v._type = MsgPackType.BOOL
        v._bool_val = value
        return v

    @staticmethod
    fn from_int(value: Int64) -> MsgPackValue:
        """Create a signed integer value."""
        var v = MsgPackValue()
        v._type = MsgPackType.INT
        v._int_val = value
        return v

    @staticmethod
    fn from_uint(value: UInt64) -> MsgPackValue:
        """Create an unsigned integer value."""
        var v = MsgPackValue()
        v._type = MsgPackType.UINT
        v._uint_val = value
        return v

    @staticmethod
    fn from_float(value: Float64) -> MsgPackValue:
        """Create a float value."""
        var v = MsgPackValue()
        v._type = MsgPackType.FLOAT
        v._float_val = value
        return v

    @staticmethod
    fn from_float32(value: Float32) -> MsgPackValue:
        """Create a float value from Float32."""
        var v = MsgPackValue()
        v._type = MsgPackType.FLOAT
        v._float_val = Float64(value)
        return v

    @staticmethod
    fn from_string(value: String) -> MsgPackValue:
        """Create a string value."""
        var v = MsgPackValue()
        v._type = MsgPackType.STR
        v._str_val = value
        return v

    @staticmethod
    fn from_bin(value: List[UInt8]) -> MsgPackValue:
        """Create a binary value."""
        var v = MsgPackValue()
        v._type = MsgPackType.BIN
        v._bin_val = value
        return v

    @staticmethod
    fn from_array(value: List[MsgPackValue]) -> MsgPackValue:
        """Create an array value."""
        var v = MsgPackValue()
        v._type = MsgPackType.ARRAY
        v._array_val = value
        return v

    @staticmethod
    fn from_map(value: List[MsgPackMapEntry]) -> MsgPackValue:
        """Create a map value."""
        var v = MsgPackValue()
        v._type = MsgPackType.MAP
        v._map_val = value
        return v

    # =========================================================================
    # Type Checking
    # =========================================================================

    fn type(self) -> MsgPackType:
        """Get the type of this value."""
        return self._type

    fn is_nil(self) -> Bool:
        """Check if this is a nil value."""
        return self._type == MsgPackType.NIL

    fn is_bool(self) -> Bool:
        """Check if this is a boolean value."""
        return self._type == MsgPackType.BOOL

    fn is_int(self) -> Bool:
        """Check if this is a signed integer value."""
        return self._type == MsgPackType.INT

    fn is_uint(self) -> Bool:
        """Check if this is an unsigned integer value."""
        return self._type == MsgPackType.UINT

    fn is_integer(self) -> Bool:
        """Check if this is any integer value (signed or unsigned)."""
        return self._type == MsgPackType.INT or self._type == MsgPackType.UINT

    fn is_float(self) -> Bool:
        """Check if this is a float value."""
        return self._type == MsgPackType.FLOAT

    fn is_number(self) -> Bool:
        """Check if this is any number (int, uint, or float)."""
        return self.is_integer() or self.is_float()

    fn is_str(self) -> Bool:
        """Check if this is a string value."""
        return self._type == MsgPackType.STR

    fn is_bin(self) -> Bool:
        """Check if this is a binary value."""
        return self._type == MsgPackType.BIN

    fn is_array(self) -> Bool:
        """Check if this is an array value."""
        return self._type == MsgPackType.ARRAY

    fn is_map(self) -> Bool:
        """Check if this is a map value."""
        return self._type == MsgPackType.MAP

    # =========================================================================
    # Value Accessors
    # =========================================================================

    fn as_bool(self) -> Bool:
        """Get the boolean value. Returns False if not a bool."""
        if self._type == MsgPackType.BOOL:
            return self._bool_val
        return False

    fn as_int(self) -> Int64:
        """Get the signed integer value. Returns 0 if not an int."""
        if self._type == MsgPackType.INT:
            return self._int_val
        elif self._type == MsgPackType.UINT:
            return Int64(self._uint_val)
        return 0

    fn as_uint(self) -> UInt64:
        """Get the unsigned integer value. Returns 0 if not a uint."""
        if self._type == MsgPackType.UINT:
            return self._uint_val
        elif self._type == MsgPackType.INT:
            if self._int_val >= 0:
                return UInt64(self._int_val)
        return 0

    fn as_float(self) -> Float64:
        """Get the float value. Returns 0.0 if not a float."""
        if self._type == MsgPackType.FLOAT:
            return self._float_val
        elif self._type == MsgPackType.INT:
            return Float64(self._int_val)
        elif self._type == MsgPackType.UINT:
            return Float64(self._uint_val)
        return 0.0

    fn as_str(self) -> String:
        """Get the string value. Returns empty string if not a string."""
        if self._type == MsgPackType.STR:
            return self._str_val
        return String()

    fn as_bin(self) -> List[UInt8]:
        """Get the binary value. Returns empty list if not binary."""
        if self._type == MsgPackType.BIN:
            return self._bin_val
        return List[UInt8]()

    fn as_array(self) -> List[MsgPackValue]:
        """Get the array value. Returns empty list if not an array."""
        if self._type == MsgPackType.ARRAY:
            return self._array_val
        return List[MsgPackValue]()

    fn as_map(self) -> List[MsgPackMapEntry]:
        """Get the map value. Returns empty list if not a map."""
        if self._type == MsgPackType.MAP:
            return self._map_val
        return List[MsgPackMapEntry]()

    # =========================================================================
    # Array/Map Operations
    # =========================================================================

    fn len(self) -> Int:
        """Get the length of array, map, string, or binary."""
        if self._type == MsgPackType.ARRAY:
            return len(self._array_val)
        elif self._type == MsgPackType.MAP:
            return len(self._map_val)
        elif self._type == MsgPackType.STR:
            return len(self._str_val)
        elif self._type == MsgPackType.BIN:
            return len(self._bin_val)
        return 0

    fn __getitem__(self, index: Int) -> MsgPackValue:
        """Get array element by index."""
        if self._type == MsgPackType.ARRAY:
            if index >= 0 and index < len(self._array_val):
                return self._array_val[index]
        return MsgPackValue.nil()

    fn get(self, key: String) -> MsgPackValue:
        """Get map value by string key."""
        if self._type == MsgPackType.MAP:
            for i in range(len(self._map_val)):
                var entry = self._map_val[i]
                if entry.key.is_str() and entry.key.as_str() == key:
                    return entry.val
        return MsgPackValue.nil()

    # =========================================================================
    # String Representation
    # =========================================================================

    fn __str__(self) -> String:
        """Get string representation of the value."""
        if self._type == MsgPackType.NIL:
            return "nil"
        elif self._type == MsgPackType.BOOL:
            if self._bool_val:
                return "true"
            else:
                return "false"
        elif self._type == MsgPackType.INT:
            return str(self._int_val)
        elif self._type == MsgPackType.UINT:
            return str(self._uint_val)
        elif self._type == MsgPackType.FLOAT:
            return str(self._float_val)
        elif self._type == MsgPackType.STR:
            return '"' + self._str_val + '"'
        elif self._type == MsgPackType.BIN:
            return "<binary:" + str(len(self._bin_val)) + " bytes>"
        elif self._type == MsgPackType.ARRAY:
            var result = String("[")
            for i in range(len(self._array_val)):
                if i > 0:
                    result += ", "
                result += str(self._array_val[i])
            result += "]"
            return result
        elif self._type == MsgPackType.MAP:
            var result = String("{")
            for i in range(len(self._map_val)):
                if i > 0:
                    result += ", "
                var entry = self._map_val[i]
                result += str(entry.key) + ": " + str(entry.val)
            result += "}"
            return result
        return "unknown"

    # =========================================================================
    # Comparison
    # =========================================================================

    fn __eq__(self, other: MsgPackValue) -> Bool:
        """Check equality."""
        if self._type != other._type:
            return False

        if self._type == MsgPackType.NIL:
            return True
        elif self._type == MsgPackType.BOOL:
            return self._bool_val == other._bool_val
        elif self._type == MsgPackType.INT:
            return self._int_val == other._int_val
        elif self._type == MsgPackType.UINT:
            return self._uint_val == other._uint_val
        elif self._type == MsgPackType.FLOAT:
            return self._float_val == other._float_val
        elif self._type == MsgPackType.STR:
            return self._str_val == other._str_val
        elif self._type == MsgPackType.BIN:
            if len(self._bin_val) != len(other._bin_val):
                return False
            for i in range(len(self._bin_val)):
                if self._bin_val[i] != other._bin_val[i]:
                    return False
            return True
        elif self._type == MsgPackType.ARRAY:
            if len(self._array_val) != len(other._array_val):
                return False
            for i in range(len(self._array_val)):
                if self._array_val[i] != other._array_val[i]:
                    return False
            return True
        elif self._type == MsgPackType.MAP:
            if len(self._map_val) != len(other._map_val):
                return False
            # Note: Map comparison is order-dependent
            for i in range(len(self._map_val)):
                var e1 = self._map_val[i]
                var e2 = other._map_val[i]
                if e1.key != e2.key or e1.val != e2.val:
                    return False
            return True
        return False

    fn __ne__(self, other: MsgPackValue) -> Bool:
        """Check inequality."""
        return not (self == other)
