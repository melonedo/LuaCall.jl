
const GC_ROOT = []
const GC_ROOT_FREE_LIST = Ref(0)

function add_object(@nospecialize x)
    if GC_ROOT_FREE_LIST[] == 0
        push!(GC_ROOT, x)
        return length(GC_ROOT)
    else
        i = GC_ROOT_FREE_LIST[]
        GC_ROOT_FREE_LIST[] = GC_ROOT[i]
        GC_ROOT[i] = x
        return i
    end
end

function get_object(i)
    GC_ROOT[i]
end

function del_object(i)
    GC_ROOT[i] = GC_ROOT_FREE_LIST[]
    GC_ROOT_FREE_LIST[] = i
end

function lua_gc(L::Ptr{lua_State})::Cint
    ptr = lua_touserdata(L, -1)
    idx = unsafe_load_gc_index(ptr)
    del_object(idx)
    return 0
end


"""
    const JULIA_IDENTITY = "__julia"

This field identifies a Julia object from other Lua userdata. 

Implementation detail:
LuaCall place all Julia objects that are passed to Lua in a global
array, and Lua userdata store an index into the array. The index 
is freed by `__gc` callback when Lua frees the userdata.
"""
const JULIA_IDENTITY = "__julia"


# 0 is error from `lua_tointeger`
const JULIA_IDENTITY_OBJECT = 1
const JULIA_IDENTITY_MODULE = 2

#=
Lua `for key, other1, other2 in exp do ...body... end` is implemented as:
```lua
iterate_func, iterable, key, to_be_closed = exp
while true
    key, other1, other2 = iterate_func(iterable, key)
    if key == nil then
        break
    end
    ...body...
end
```
=#

function lua_next(LS::LuaState)::Cint
    try
        iter, state_key = getjulia.((LS[-2], LS[-1]))
        if isnothing(state_key)
            # initial call
            it = iterate(iter)
        else
            # subsequent call
            it = iterate(iter, state_key.state)
        end
        if isnothing(it)
            push!(LS, 0)
            return 1
        else
            (key, value), state = it
            push!(LS, 0, StateKey(state, key), value)
            return 3
        end
    catch e
        @debug "Error occurred when Lua calls Julia function `julia_next`" exception = (e, catch_backtrace())
        push!(LS, 1, sprint(showerror, e))
        return 2
    end
end

struct StateKey{S,K}
    state::S
    key::K
end

lua_index(iter, sk::StateKey) = iter[sk.key]
lua_index(iter, key) = iter[key]

lua_newindex(table, sk::StateKey, value) = setindex!(table, value, sk.key)
lua_newindex(table, key, value) = setindex!(table, value, key)

lua_call(f, args...) = f(args...)

lua_length(x) = length(x)

lua_tostring(x) = string(x)

lua_idiv(x, y) = x // y

lua_concat(x, y) = error("Lua concat operator `..` is not defined for $(typeof(x)) and $(typeof(y))")


# @luacall does not work behind macros
macro mirror_method(lua_name, julia_name, nargs=1)
    esc(quote
        f = push_cfunction!(LS, @lua_CFunction LuaFunctionWrapper($julia_name, $nargs)) |> unwrap_popstack
        t[$(string(lua_name))] = wrapper(f) |> unwrap_popstack
    end)
end

const JULIA_METATABLE_OBJECT = "julia_metatable_object"

function init_julia_value_metatable(LS::LuaState)
    @luascope LS begin
        t = push_table!(LS)
        registry(LS)[JULIA_METATABLE_OBJECT] = t
        t[JULIA_IDENTITY] = JULIA_IDENTITY_OBJECT
        # Not wrapped
        f = push_cfunction!(LS, @lua_CFunction lua_gc)
        t["__gc"] = f

        wrapper = luaeval(LS, get_julia_function_wrapper(1))
        @mirror_method __add (+)
        @mirror_method __sub (-)
        @mirror_method __mol (*)
        @mirror_method __div (/)
        @mirror_method __mod (%)
        @mirror_method __unm (-) 1
        @mirror_method __idiv lua_idiv
        @mirror_method __band (&)
        @mirror_method __bor (|)
        @mirror_method __bxor (⊻)
        @mirror_method __bnot (~) 1
        @mirror_method __shl (<<)
        @mirror_method __shr (>>)
        @mirror_method __concat lua_concat
        @mirror_method __len lua_length 1
        @mirror_method __eq (==)
        @mirror_method __lt (<)
        @mirror_method __le (<=)
        @mirror_method __index lua_index
        @mirror_method __newindex lua_newindex 3
        @mirror_method __call lua_call -1
        @mirror_method __tostring lua_tostring 1

        pairs_wrapper_code = """
            local iter, state = ...
            return function (self)
                return iter, state(self) --, nil, nil
            end
            """
        pairs_wrapper = luaeval(LS, pairs_wrapper_code)
        wrapper2 = luaeval(LS, get_julia_function_wrapper(2))
        f = push_cfunction!(LS, @lua_CFunction LuaFunctionWrapper(pairs, 1))
        julia_pairs = wrapper(f)
        
        f = push_cfunction!(LS, @lua_CFunction lua_next)
        julia_next = wrapper2(f)
        
        pairs_wrapped = pairs_wrapper(julia_next, julia_pairs)
        t["__pairs"] = pairs_wrapped
    end
end

const JULIA_METATABLE_MODULE = "julia_metatable_module"

julia_getproperty(x, f) = getproperty(x, Symbol(f))
julia_setproperty(x, f, v) = setproperty!(x, Symbol(f), v)


# I don't like so many mapped methods for modules
function init_julia_module_metatable(LS::LuaState)
    @luascope LS begin
        t = push_table!(LS; ndict=4)
        registry(LS)[JULIA_METATABLE_MODULE] = t

        t[JULIA_IDENTITY] = JULIA_IDENTITY_MODULE
        t["__gc"] = push_cfunction!(LS, @lua_CFunction lua_gc)

        wrapper = luaeval(LS, get_julia_function_wrapper(1))

        f = push_cfunction!(LS, @lua_CFunction LuaFunctionWrapper(julia_getproperty, 2))
        t.__index = wrapper(f)

        f = push_cfunction!(LS, @lua_CFunction LuaFunctionWrapper(julia_setproperty, 3))
        t.__newindex = wrapper(f)

        f = push_cfunction!(LS, @lua_CFunction LuaFunctionWrapper(string, 1))
        t.__str = wrapper(f)
    end
end


unsafe_store_gc_index!(ptr, idx) = unsafe_store!(Ptr{Int}(ptr), idx)

unsafe_load_gc_index(ptr) = unsafe_load(Ptr{Int}(ptr))


function push_julia_object!(LS::LuaState, obj)
    idx = add_object(obj)
    ptr = lua_newuserdatauv(LS, sizeof(Int), 0)
    unsafe_store_gc_index!(ptr, idx)
    luaL_setmetatable(LS, JULIA_METATABLE_OBJECT)
    PopStack(LS[], LS, 1)
end

function pushstack!(LS::LuaState, mod::Module)
    push_julia_object!(LS, mod)
    luaL_setmetatable(LS, JULIA_METATABLE_MODULE)
    PopStack(LuaUserData(LS, -1), LS, 1)
end

function pushstack!(LS::LuaState, obj)
    push_julia_object!(LS, obj)
end

getjulia(x) = x

function getjulia(ud::LuaUserData)
    t = luaL_getmetafield(LS(ud), idx(ud), JULIA_IDENTITY)
    t == LUA_TNIL && return ud
    pop!(LS(ud), 1)
    i = unsafe_load_gc_index(get_userdata(ud))
    get_object(i)
end

