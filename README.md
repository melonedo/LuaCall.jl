# LuaCall.jl

A Julia package for interoperability with [Lua](https://www.lua.org/).

Functionality:

- Calling any Julia function from Lua
- Sharing any Julia object with Lua
- Accessing any Lua data from Julia
- Resuming Lua coroutines from Julia

## Showcase

### Call Julia from Lua

When LuaCall initializes a Lua state, a global variables `julia` represents the Julia module `Main`,
where you can access any Julia functions. Any Julia value involved is shared with Lua as opaque userdata.

For example, you can do linear algebra from Lua

```julia
using LuaCall
LS = LuaState()
# Guard whatever Lua scope with @luascope
@luascope LS begin
    lua_inv = lualoadstring(LS, """
        a = ...
        return julia.inv(a)
        """)
    inv = lua_inv([1 2; 3 4])
    get_julia(inv)  # => [-2 -1; 1.5 -0.5]
end
```

### Calling Lua from Julia

```julia
using LuaCall
LS = LuaState()
@luascope LS begin
    code = lualoadstring(LS, """
        return {a=1, [2]="hello"}, coroutine.create(function (a)
            b = coroutine.yield(a + 1)
            return a + b
        end)""")
    table, thread = code(; multiret=true)
    a = table["a"]
    b = table[2]
    c = resume(LS, thread, 3)
    d = resume(LS, thread, 4)
    a, b, c, d # => (1, "hello", 4, 7)
end
```

## Lua API overview

Each Lua session is contained in a Lua state, `lua_State` in C or `LuaState` in Julia. While Lua sessions do not
share data among each other, any access to a Lua state may affect its internal state. Of most concern is the 
**stack** of one state, where the Lua state stores its execution context. To hide implimentation details for Lua
users, we can not use pointers to access Lua objects. Instead, we must reference it as one specific index into the
stack, which has substantial impact on the design of this package:

- The Lua API itself uses the stack to transfer data, may reference the data on the stack, or pop/push any object.
- LuaCall duplicates the poped elements so that no objects will be removed.
- However, new objects must be located on the stack, potentially leaking memory.
- `@luascope` resets the top of the stack to remove all elements pushed in the block.
- `@luareturn` can be used to return elements on the Lua stack, that is, remove any other elements but leave the returned
  object.
- Any object on the Lua stack is wrapped in `PopStack`, which is automatically unwrapped if appear on the right-hand-side
  of assignment in a `@luascope` block. You can manually unwrap it with `[]`, e.g. `table[key][]` returns the value unwrapped.
- You can also manage stack manually with `push!` and `pop!`.

Example:

```julia
@luascope LUA_STATE begin
  array = [1,2,3]
  array2 = @luascope LUA_STATE begin
      table = new_table!(LUA_STATE)
      # stack: [table1]
      table[1] = array
      # stack: [table] (unmodified)
      userdata = table[1]
      # stack: [table userdata(array)]
      @luareturn userdata
  end
  # stack: [userdata(array)]
  get_julia(array2[]) == array
end
# stack: []
```

## Type mapping

| Lua type       | To Julia type         | From Julia type  | On Lua stack  |
| -------------- | --------------------- | ---------------- | ------------- |
| `nil`          | `nothing`(value)      | `nothing`        | ❌            |
| integer        | `LuaInt`(`Int64`)     | `AbstractInt`    | ❌            |
| floating point | `LuaFloat`(`Float64`) | `AbstractFloat`  | ❌            |
| string         | `String`              | `AbstractString` | ❌            |
| table          | `LuaTable`            | *                | ✔             |
| function       | `LuaFunction`         | *                | ✔             |
| userdata       | `LuaUserData`, `Any`  | `Any`            | ✔             |
| thread         | `LuaThread`           | *                | ✔             |


You can retrive any value on the Lua stack with `LUA_STATE[index]` or `getstack(LUA_STATE, index)`.
To retrive the Julia value contained in a Lua userdata, use `get_julia`.

To push value to the stack with default conversion, use `push!(LUA_STATE, values...)`.
To construct mutable object from Julia, check `new_table!`, `new_cfunction!`, `new_userdata` and `new_thread!`.
