--[[!
    File: language/ext_math.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features various extensions made to Lua's math module.

    Section: Math extensions
]]

--[[!
    Function: math.lsh
    Bit left shift function.

    Parameters:
        n1 - First integral number.
        n2 - Second integral number.

    Returns:
        The shifted value.
]]
math.lsh = CAPI.lsh

--[[!
    Function: math.rsh
    Bit right shift function.

    Parameters:
        n1 - First integral number.
        n2 - Second integral number.

    Returns:
        The shifted value.
]]
math.rsh = CAPI.rsh

--[[!
    Function: math.bor
    Bit OR function.

    Parameters:
        n1 - First integral number.
        n2 - Second integral number.
        n3 - ....
        n4 - ....
        nX - ....

    Returns:
        Bit OR result.
]]
math.bor = CAPI.bor

--[[!
    Function: math.band
    Bit AND function.

    Parameters:
        n1 - First integral number.
        n2 - Second integral number.
        n3 - ....
        n4 - ....
        nX - ....

    Returns:
        Bit AND result.
]]
math.band = CAPI.band

--[[!
    Function: math.bnot
    Bit negation function.

    Parameters:
        n - An integral value.

    Returns:
        Bit negated value.
]]
math.bnot = CAPI.bnot

--[[!
    Function: math.round
    Rounds a floating point value.
    If floating point is above or .5, the number
    gets rounded up, and down otherwise.

    Parameters:
        v - The number to round.

    Returns:
        A rounded (integral) value.
]]
function math.round(v)
    return (type(v) == "number"
        and math.floor(v + 0.5)
        or nil
    )
end

--[[!
    Function: math.clamp
    Clamps a number (limits its bounds)

    Parameters:
        v - The number to clamp.
        l - Lowest value the number can have.
        h - Highest value the number can have.

    Returns:
        A clamped number.
]]
function math.clamp(v, l, h)
    return math.max(l, math.min(v, h))
end

--[[!
    Function: math.sign
    Gets a sign of a number. That means if input
    is bigger than 0, sign is 1, if it's smaller
    than 0, sign is -1. If input is 0, sign is
    0 too.

    Parameters:
        v - The value to return sign of.

    Returns:
        A sign of the number.
]]
function math.sign(v)
    return (v < 0 and -1 or (v > 0 and 1 or 0))
end

--[[!
    Function: math.lerp
    Performs a lerp between two numbers.

    Parameters:
        first - The first number.
        other - The other number.
        weight - If it's 1, result equals other, if 0, first.

    Returns:
        Result of lerp between the numbers.
]]
function math.lerp(first, other, weight)
    return first + weight * (other - first)
end

--[[!
    Function: math.magnet
    If a value is inside certain radius from another value,
    it returns the other value, othrwise returns the
    first value.

    Parameters:
        value - The value to check for.
        other - From where to count the radius.
        radius - The radius.
]]
function math.magnet(value, other, radius)
    return (math.abs(value - other) <= radius) and other or value
end

--[[!
    Class: math.vec3
    A vec3 class (with x, y, z coordinates) for OctaForge's
    scripting system.
]]
math.vec3 = class.new()

--[[!
    Constructor: __init
    This initializes the vector. You can supply it
    with various arguments.

    Parameters:
        x - X coordinate of the vector.
        y - Y coordinate of the vector.
        z - Z coordinate of the vector.

    Alternatively:
        v - Array of 3 numbers or another vec3.

    Or simply omit arguments and let the vector
    initialize as 0, 0, 0.
]]
function math.vec3:__init(x, y, z)
    if type(x) == "table" and x.is_a and x:is_a(vec3) then
        self.x = tonumber(x.x)
        self.y = tonumber(x.y)
        self.z = tonumber(x.z)
    elseif type(x) == "table" and #x == 3 then
        self.x = tonumber(x[1])
        self.y = tonumber(x[2])
        self.z = tonumber(x[3])
    else
        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
    end
    self.length = 3
end

--[[!
    Function: __tostring
    Returns:
        string representation of the vector.
        The string representation contains value of the
        vector and has format

        (start code)
            vec3 <X, Y, Z>
        (end)
]]
function math.vec3:__tostring()
    return string.format("vec3 <%s, %s, %s>",
                         tostring(self.x),
                         tostring(self.y),
                         tostring(self.z))
end

--[[!
    Function: magnitude
    Gets a magnitude (length) of vec3.

    Returns:
        Magnitude (length, that is square root of sum of powers of two of x, y, z)
        of the vector, that is a number value.

    (start code)
        sqrt(x^2 + y^2 + z^2)
    (end)
]]
function math.vec3:magnitude()
    return math.sqrt(self.x * self.x
                   + self.y * self.y
                   + self.z * self.z)
end

--[[!
    Function: normalize
    Normalizes a vector, that means, divides each component with its length.

    Returns:
        Itself.

    See Also:
        <magnitude>
]]
function math.vec3:normalize()
    local mag = self:magnitude()
    if mag ~= 0 then self:mul(1 / mag)
    else logging.log(logging.ERROR, "Can't normalize vec of null length.") end
    return self
end

--[[!
    Function: cap
    Caps a vector, that means, multiplies every component with division of
    entered size and length.

    Parameters:
        s - Size to cap the vector with.

    Returns:
        Itself.

    See Also:
        <magnitude>
]]
function math.vec3:cap(s)
    local mag = self:magnitude()
    if mag > s then self:mul(size / mag) end
    return self
end

--[[!
    Function: subnew
    Subtracts a vector with another one and returns as a new vector.

    Parameters:
        v - The other vector to subtract with.

    Returns:
        A new vector as result of subtraction.

    See Also:
        <sub>
]]
function math.vec3:subnew(v)
    return math.vec3(self.x - v.x,
                     self.y - v.y,
                     self.z - v.z)
end

--[[!
    Function: addnew
    Sums a vector with another one and returns as a new vector.

    Parameters:
        v - The other vector to sum with.

    Returns:
        A new vector as result of summary.

    See Also:
        <add>
]]
function math.vec3:addnew(v)
    return math.vec3(self.x + v.x,
                     self.y + v.y,
                     self.z + v.z)
end

--[[!
    Function: mulnew
    Multiplies each vector component with a number and returns as a new vector.

    Parameters:
        v - The number to multiply each component with.

    Returns:
        A new vector as result of multiplication.

    See Also:
        <mul>
]]
function math.vec3:mulnew(v)
    return math.vec3(self.x * v,
                     self.y * v,
                     self.z * v)
end

--[[!
    Function: sub
    Subtracts a vector with another one.

    Parameters:
        v - The other vector to subtract with.

    Returns:
        Itself.

    See Also:
        <subnew>
]]
function math.vec3:sub(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
    return self
end

--[[!
    Function: add
    Sums a vector with another one.

    Parameters:
        v - The other vector to sum with.

    Returns:
        Itself.

    See Also:
        <addnew>
]]
function math.vec3:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
    return self
end

--[[!
    Function: mul
    Multiplies each component of a vector with a number.

    Parameters:
        v - The number to multiply each component with.

    Returns:
        Itself.

    See Also:
        <mulnew>
]]
function math.vec3:mul(v)
    self.x = self.x * v
    self.y = self.y * v
    self.z = self.z * v
    return self
end

--[[!
    Function: copy
    Copies a vector.

    Returns:
        Copy of self.
]]
function math.vec3:copy()
    return math.vec3(self.x, self.y, self.z)
end

--[[!
    Function: as_array
    Gets an array of vector components.

    Returns:
        An array of vector components.
]]
function math.vec3:as_array()
    return { self.x, self.y, self.z }
end

--[[!
    Function: fromyawpitch
    Sets components of the vector from given yaw and pitch.

    Parameters:
        yaw - Yaw to calculate x, y from.
        pitch - Pitch to calculate x, y, z from.

    Returns:
        Itself.
]]
function math.vec3:fromyawpitch(yaw, pitch)
    self.x = -(math.sin(math.rad(yaw)))
    self.y =   math.cos(math.rad(yaw))

    if pitch ~= 0 then
        self.x = self.x * math.cos(math.rad(pitch))
        self.y = self.y * math.cos(math.rad(pitch))
        self.z = math.sin(math.rad(pitch))
    else
        self.z = 0
    end

    return self
end

--[[!
    Function: toyawpitch
    Calculates yaw and pitch from vector components.

    Returns:
        Table containing yaw and pitch -

        (start code)
            { yaw = yaw_value, pitch = pitch_value }
        (end)
]]
function math.vec3:toyawpitch()
    local mag = self:magnitude()
    if mag < 0.001 then
        return { yaw = 0, pitch = 0 }
    end
    return {
        yaw = math.deg(-(math.atan2(self.x, self.y))),
        pitch = math.deg(math.asin(self.z / mag))
    }
end

--[[!
    Function: iscloseto
    Calculates if vector is close to another vector, knowing
    their maximal distance to assume it's not close.

    Parameters:
        v - The other vector.
        d - Maximal distance to assume the other vector is close.

    Returns:
        Boolean value, true if the distance is lower than
        given maximal distance, false otherwise.
]]
function math.vec3:iscloseto(v, d)
    d = d * d
    local temp, sum

    -- note order: we expect z to be less important, as most maps are 'flat'
    temp = self.x - v.x
    sum = temp * temp
    if sum > d then return false end

    temp = self.y - v.y
    sum = sum + temp * temp
    if sum > d then return false end

    temp = self.z - v.z
    sum = sum + temp * temp
    return (sum <= d)
end

--[[!
    Function: dotproduct
    Calculates dot product of two vectors.

    Parameters:
        v - The other vector.

    Returns:
        Dot product of two vectors.
]]
function math.vec3:dotproduct(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

--[[!
    Function: cos_angle_with
    Returns the cosine angle with other vector.

    Parameters:
        v - The other vector.
]]
function math.vec3:cos_angle_with(v)
    return (self:dotproduct(v) / (self:magnitude() * v:magnitude()))
end

--[[!
    Function: cross_product
    Calculates cross product of two vectors.

    Parameters:
        v - The other vector.

    Returns:
        Cross product of two vectors (a new vector)
]]
function math.vec3:cross_product(v)
    return math.vec3(
        (self.y * v.z) - (self.z * v.y),
        (self.z * v.x) - (self.x * v.z),
        (self.x * v.y) - (self.y * v.x)
    )
end

--[[!
    Function: project_along_surface
    Projects the vector along a surface (defined by a normal).

    Parameters:
        surf - The surface normal.

    Returns:
        Modified self.
]]
function math.vec3:project_along_surface(surf)
    local normal_proj = self:dotproduct (surf)
    return self:sub (surf:mulnew(normal_proj))
end

--[[!
    Function: toyawpitchroll
    Calculates yaw, pitch and roll from vector components.

    Parameters:
        up - Given this vector, uses self as forward vector to find the
        yaw, pitch and roll.
        yaw_hint - If the yaw isn't clear enough, we use this yaw hint vector.

    Returns:
        Table containing yaw, pitch and roll:

        (start code)
            { yaw = yaw_value, pitch = pitch_value, roll = roll_value }
        (end)
]]
function math.vec3:toyawpitchroll(up, yaw_hint)
    local left = self:cross_product(up)

    local yaw
    local pitch
    local roll

    if math.abs(self.z) < 0.975 or not yaw_hint then
        yaw = math.deg(math.atan2(self.y,         self.x)) + 90
    else
        yaw = math.deg(math.atan2(yaw_hint.y, yaw_hint.x)) + 90
    end

    local pitch = math.deg(math.atan2(-(self.z), math.sqrt(up.z * up.z + left.z * left.z)))
    local roll  = math.deg(math.atan2(up.z, left.z)) - 90

    return { yaw = yaw, pitch = pitch, roll = roll }
end

--[[!
    Function: lerp
    Performs a lerp between two vectors.

    Parameters:
        other - The other vector.
        weight - If it's 1, result has x, y, z of "other", if 0,
        of "self".

    Returns:
        Result of lerp, a new vector.
]]
function math.vec3:lerp(other, weight)
    return self:addnew(other:subnew(self):mul(weight))
end

--[[!
    Function: is_zero
    Returns true if all components of the vector are zero.
]]
function math.vec3:is_zero()
    return (self.x == 0 and self.y == 0 and self.z == 0)
end

--[[!
    Class: math.vec4
    A vec4 class (with x, y, z, w coordinates) for OctaForge's
    scripting system.

    This vector inherits from vec3, so it has all of its methods.
]]
math.vec4 = class.new(math.vec3)

--[[!
    Constructor: __init
    This initializes the vector. You can supply it
    with various arguments.

    Parameters:
        x - X coordinate of the vector.
        y - Y coordinate of the vector.
        z - Z coordinate of the vector.
        w - W coordinate of the vector.

    Alternatively:
        v - Array of 4 numbers or another vec4.

    Or simply omit arguments and let the vector
    initialize as 0, 0, 0, 0.
]]
function math.vec4:__init(x, y, z, w)
    if type(x) == "table" and x.is_a and x:is_a(vec4) then
        self.x = tonumber(x.x)
        self.y = tonumber(x.y)
        self.z = tonumber(x.z)
        self.w = tonumber(x.w)
    elseif type(x) == "table" and #x == 4 then
        self.x = tonumber(x[1])
        self.y = tonumber(x[2])
        self.z = tonumber(x[3])
        self.z = tonumber(x[4])
    else
        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
        self.w = w or 0
    end
    self.length = 4
end

--[[!
    Function: __tostring
    Returns:
        string representation of the vector.
        The string representation contains value of the
        vector and has format

        (start code)
            vec4 <X, Y, Z, W>
        (end)
]]
function math.vec4:__tostring()
    return string.format("vec4 <%s, %s, %s, %s>",
                         tostring(self.x),
                         tostring(self.y),
                         tostring(self.z),
                         tostring(self.w))
end

--[[!
    Function: magnitude
    Gets a magnitude (length) of vec4.

    Returns:
        Magnitude (length, that is square root of sum of powers of two of x, y, z, w)
        of the vector, that is a number value.

    (start code)
        sqrt(x^2 + y^2 + z^2 + w^2)
    (end)
]]
function math.vec4:magnitude()
    return math.sqrt(self.x * self.x
                   + self.y * self.y
                   + self.z * self.z
                   + self.w * self.w)
end

function math.vec4:subnew(v)
    return math.vec4(self.x - v.x,
                     self.y - v.y,
                     self.z - v.z,
                     self.w - v.w)
end

function math.vec4:addnew(v)
    return math.vec4(self.x + v.x,
                     self.y + v.y,
                     self.z + v.z,
                     self.w + v.w)
end

function math.vec4:mulnew(v)
    return math.vec4(self.x * v,
                     self.y * v,
                     self.z * v,
                     self.w * v)
end

function math.vec4:sub(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
    self.w = self.w - v.w
    return self
end

function math.vec4:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
    self.w = self.w + v.w
    return self
end

function math.vec4:mul(v)
    self.x = self.x * v
    self.y = self.y * v
    self.z = self.z * v
    self.w = self.w * v
    return self
end

function math.vec4:copy()
    return math.vec4(self.x, self.y, self.z, self.w)
end

function math.vec4:as_array()
    return { self.x, self.y, self.z, self.w }
end

--[[!
    Function: quatfromaxisangle
    Sets components of the vector from given axis
    (which is vec3) and angle (which is an integral
    number in degrees)

    Parameters:
        ax - The axis (vec3)
        an - The angle (integral number)

    Returns:
        Itself.
]]
function math.vec4:quatfromaxisangle(ax, an)
    an = math.rad(an)
    self.w = math.cos(an / 2)
    local s = math.sin(an / 2)

    self.x = s * ax.x
    self.y = s * ax.y
    self.z = s * ax.z

    return self
end

--[[!
    Function: toyawpitchroll
    Calculates yaw, pitch and roll from vector components.

    Returns:
        Table containing yaw, pitch and roll:

        (start code)
            { yaw = yaw_value, pitch = pitch_value, roll = roll_value }
        (end)
]]
function math.vec4:toyawpitchroll()
    --local r = self:toyawpitch()
    --r.roll = 0
    --return r

    if math.abs(self.z) < 0.99 then
        local r = self:toyawpitch()
        r.roll = math.deg(self.w)
        return r
    else
        return {
            yaw = math.deg(self.w) * (self.z < 0 and 1 or -1),
            pitch = self.z > 0 and -90 or 90,
            roll = 0
        }
    end
end

--[[!
    Function: is_zero
    Returns true if all components of the vector are zero.
]]
function math.vec4:is_zero()
    return (self.x == 0 and self.y == 0 and self.z == 0 and self.w == 0)
end

--[[!
    Function: math.frandom
    Returns floating point pseudo-random number using range
    specified from arguments.

    Parameters:
        _min - Minimal value of the returned number.
        _max - Maximal value of the returned number.
]]
function math.frandom(_min, _max)
    return math.random() * (_max - _min) + _min
end

--[[!
    Function: math.vec3_norm
    Returns a normalized vec3 of non-zero length with
    x, y, z components being random floating point numbers
    ranging from -1 to 1.
]]
function math.vec3_norm()
    local ret = nil
    while not ret or ret:magnitude() == 0 do
        ret = math.vec3(math.frandom(-1, 1), math.frandom(-1, 1), math.frandom(-1, 1))
    end
    return ret:normalize()
end