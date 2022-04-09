<a name="name-and-description"></a>
Kintastic2.Data.Set - Set class
===============================

A set is an unordered collection of unique values.

`nil` can't be stored in these sets.

# TABLE OF CONTENTS

1. [NAME AND DESCRIPTION](#name-and-description)
2. [TABLE OF CONTENTS](#tableofcontents)
3. [SYNOPSIS](#synopsis)
4. [CONSTRUCTOR](#constructor)
    1. [Set:new](#setnew)
5. [CLASS METHODS](#classmethods)
    1. [Set:union](#setunion)
    2. [set + set](#setset)
    3. [Set:difference](#setdifference)
    4. [set - set](#setset)
    5. [Set:intersection](#setintersection)
    6. [set * set](#setset)
6. [INSTANCE METHODS](#instancemethods)
    1. [set:add](#setadd)
    2. [set:delete](#setdelete)
    3. [set:del](#setdel)
    4. [set:has](#sethas)
    5. [set:size](#setsize)
    6. [set:get_values](#setgetvalues)
    7. [set:values](#setvalues)

# SYNOPSIS

```lua
local Set = require( "Kintastic2.Data.Set" )

local set = Set:new({ "a", "b" })
set:delete( "b" ):add( "c" ):add( "d" )
for value in set:values() do
   print( value )   -- a c d, in any order.
end

print( set:has( "e" ) )   -- false
print( set:size( )        -- 3

local values = set:get_values()  -- a c d, in any order.


local set1 = Set:new({ "a", "b", "c", "d"           })
local set2 = Set:new({           "c", "d", "e", "f" })

local union        = set1 + set2   -- a b c d e f
local difference   = set1 - set2   -- a b
local intersection = set1 * set2   --     c d
```

# CONSTRUCTOR

## Set:new

```lua
local set = Set:new()
local set = Set:new( array )
```

Create an empty set, or one that contains the values
provided by an array.

# CLASS METHODS

## Set:union
## set + set

```lua
local set = Set:union( set1, set2 )
local set = set1 + set2
```

## Set:difference
## set - set

```lua
local set = Set:difference( set1, set2 )
local set = set1 - set2
```

## Set:intersection
## set * set

```lua
local set = Set:intersection( set1, set2 )
local set = set1 * set2
```

# INSTANCE METHODS

## set:add

```lua
set = set:add( value )
```

Adds a value to a set. Has no effect if the value is already
part of the set.

Returns the set as a convenience.

## set:delete
## set:del

```lua
set = set:delete( value )
set = set:del( value )
```

Removes a value from a set. Has no effect if the value is
already absent.

Returns the set as a convenience.

`set:del` is an alias for `set:delete`.

## set:has

```lua
local boolean = set:has( value )
```

Returns true if the value is part of the set.

## set:size

```lua
local size = set:size()
```

Returns the number of values which are part of the set.
(This currently requires iterating over the entire set.)

## set:get_values

```lua
local values = set:get_values()
```

Returns an array of the values which are part of the set.

## set:values

```lua
for value in set:values() do … end
```

Produces an iterator suitable for `for in` which visits each
value which is part of the set.
