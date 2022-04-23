

function LuaStateWraper()
    LS = LuaStateWraper(C_NULL)
    init(LS)
    LS
end

LuaState() = LuaStateWraper()


"Push values to the stack. This function also calls `lua_checkstack` as `@boundscheck`."
@inline function Base.push!(LS::LuaState, xs...)
    @boundscheck checkstack(LS, length(xs))
    for x in xs
        pushstack!(LS, x)
    end
end

Base.pop!(LS::LuaState, n) = lua_pop(LS, n)

top(LS::LuaState) = lua_gettop(LS)


Base.getproperty(LS::LuaState, f::Symbol) = get_global(LS, f)

Base.setproperty!(LS::LuaState, f::Symbol, x) = set_global!(LS, f, x)

Base.getindex(LS::LuaState, i=-1) = getstack(LS, i)


function get_global(LS::LuaState, f)
    checkstack(LS, 1)
    lua_getglobal(LS, f)
    PopStack(LS[], LS, 1)
end

function set_global!(LS::LuaState, f, v)
    push!(LS, v)
    lua_setglobal(LS, f)
end

function get_globaltable(LS::LuaState)
    registry(LS)[LUA_RIDX_GLOBALS]
end

function get_mainthread(LS::LuaState)
    registry(LS)[LUA_RIDX_MAINTHREAD]
end

"""
    registry(LS::LuaState)

Get the Lua registry.
"""
registry(LS::LuaState) = LuaTable(LS, LUA_REGISTRYINDEX)

function get_metatable(obj::Union{LuaTable,LuaUserData})
    @assert lua_getmetatable(LS(obj), idx(obj)) == 1
    PopStack(LuaTable(LS(obj), -1), LS(obj), 1)
end

"""
    set_metatable!(obj::Union{LuaTable,LuaUserData}, table)

Set metatable for `obj`, if `table` is `nothing`, unset the metatable.
"""
function set_metatable!(obj::Union{LuaTable,LuaUserData}, table::LuaTable)
    push!(LS(obj), table)
    lua_setmetatable(LS(obj), idx(obj))
end

function init(LS::LuaStateWraper; init_julia=true)
    L = luaL_newstate()
    L == C_NULL && error("Failed to initialize Lua")
    setfield!(LS, :L, L)
    luaL_openlibs(LS)
    finalizer(lua_close, LS)

    init_julia_value_metatable(LUA_STATE)
    init_julia_module_metatable(LUA_STATE)
    @luascope LUA_STATE begin
        mod = pushstack!(LUA_STATE, Main)
        set_global!(LUA_STATE, "julia", mod)
    end
end
