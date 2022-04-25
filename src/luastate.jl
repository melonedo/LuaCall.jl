
function LuaStateWrapper(L::Ptr, debug=true)
    return LuaStateWrapper(L, debug, [])
end

"""
    LuaState(julia_module=Main, debug=true)

Create a new Lua state, with `julia_module` set to Lua global varaible `julia`
or not set if `nothing` is passed.

If `debug` is true, stacktrace will be stored for every exception.
You can also set debug on a per-call basis.
"""
function LuaStateWrapper(julia_module::Union{Nothing,Module}, debug=true)
    LS = LuaStateWrapper(C_NULL, debug, [])
    init(LS; julia_module)
    LS
end



LuaState(julia_module::Union{Nothing,Module}=Main, debug=true) = LuaStateWrapper(julia_module, debug)


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

const LUA_STATE_JULIA_WRAPPER = "lua_state_julia_wrapper"

function get_julia_wrapper(L::Ptr{lua_State})
    @luascope L begin
        LS = registry(L)[LUA_STATE_JULIA_WRAPPER]
        @assert !isnothing(LS)
        get_julia(LS)
    end
end

get_julia_wrapper(LS::LuaStateWrapper) = LS

get_debug(LS::LuaStateWrapper) = getfield(LS, :debug)

function set_debug!(LS::LuaStateWrapper, enable::Bool)
    old_debug = get_debug(LS)
    setfield!(LS, :debug, enable)
    old_debug
end

get_stacktrace(LS::LuaStateWrapper) = getfield(LS, :stacktrace)

set_stacktrace!(LS::LuaStateWrapper, stacktrace) = setfield!(LS, :stacktrace, stacktrace)

for func in [:get_debug, :set_debug!, :get_stacktrace, :set_stacktrace!]
    @eval $func(L::Ptr{lua_State}, args...) = $func(get_julia_wrapper(L), args...)
end

function init(LS::LuaStateWrapper; julia_module=Main)
    L = luaL_newstate()
    L == C_NULL && error("Failed to initialize Lua")
    setfield!(LS, :L, L)
    luaL_openlibs(LS)
    finalizer(lua_close, LS)

    init_julia_value_metatable(LS)
    init_julia_module_metatable(LS)
    @luascope LS begin
        set_global!(LS, "julia", julia_module)
        registry(LS)[LUA_STATE_JULIA_WRAPPER] = LS
    end
end
