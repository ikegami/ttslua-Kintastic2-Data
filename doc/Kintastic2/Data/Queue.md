<a name="name-and-description"></a>
Kintastic2.Data.Queue - Queue class
===================================

A simple queue implementation.

`nil` can't be stored in these sets.

# TABLE OF CONTENTS

1. [NAME AND DESCRIPTION](#name-and-description)
2. [TABLE OF CONTENTS](#tableofcontents)
3. [SYNOPSIS](#synopsis)
4. [CONSTRUCTOR](#constructor)
    1. [Queue:new](#queuenew)
5. [INSTANCE METHODS](#instancemethods)
    1. [queue:dequeue](#queuedequeue)
    2. [queue:enqueue](#queueenqueue)
    3. [queue:is_empty](#queueisempty)

# SYNOPSIS

```lua
local Queue = require( "Kintastic2.Data.Queue" )

local q = Queue:new()
a:enqueue( "a" )
a:enqueue( "b" )
a:enqueue( "c" )

while not q:is_empty() do
   print( q:dequeue() )   -- a b c
end
```

# CONSTRUCTOR

## Queue:new

```lua
local q = Queue:new()
```

# INSTANCE METHODS

## queue:dequeue

```lua
local value = q:dequeue()
```

Removes the value at the head of the queue and returns it.
Returns nothing if the queue is empty.

## queue:enqueue

```lua
q:enqueue( value )
```

Adds a value to the tail of the queue.

## queue:is_empty

```lua
local boolean q:is_empty()
```
