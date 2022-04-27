
function LuaStateWrapper(L::Ptr, debug=true)
    return LuaStateWrapper(LuaThread(L), debug, [])
end

"""
    LuaState(julia_module=Main, debug=true)

Create a new Lua state, with `julia_module` set to Lua global varaible `julia`
or not set if `nothing` is passed.

If `debug` is true, stacktrace will be stored for every exception.
You can also set debug on a per-call basis.
"""
function LuaStateWrapper(julia_module::Union{Nothing,Module}, debug=true)
    LS = LuaStateWrapper(LuaThread(C_NULL), debug, [])
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
    return_on_lua_stack(LS, -1)
end

function set_global!(LS::LuaState, f, v)
    push!(LS, v)
    lua_setglobal(LS, f)
end

function get_globaltable(LS::LuaState)
    registry(LS)[LUA_RIDX_GLOBALS]
end

function mainthread(LS::LuaState)
    @luascope LS begin
        t::LuaThread = registry(LS)[LUA_RIDX_MAINTHREAD]
        t
    end
end

mainthread(LS::LuaStateWrapper) = getfield(LS, :L)

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

function lua_getextraspace(L::LuaState)
    L = Base.unsafe_convert(Ptr{lua_State}, L)
    Ptr{Cvoid}(L - sizeof(Ptr{Cvoid}))
end

function set_julia_wrapper!(LS::LuaStateWrapper)
    space = lua_getextraspace(LS)
    unsafe_store!(Ptr{Any}(space), LS)
end

function get_julia_wrapper(L::Ptr{lua_State})
    space = lua_getextraspace(L)
    unsafe_load(Ptr{Any}(space))::LuaStateWrapper
end

get_julia_wrapper(LS::LuaThread) = get_julia_wrapper(Base.unsafe_convert(Ptr{lua_State}, LS))

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
    @eval $func(L::LuaState, args...) = $func(get_julia_wrapper(L), args...)
end

function Base.close(LS::LuaStateWrapper)
    lua_close(LS)
    setfield!(LS, :L, LuaThread(C_NULL))
end

function init(LS::LuaStateWrapper; julia_module=Main)
    L = luaL_newstate()
    L == C_NULL && error("Failed to initialize Lua")
    setfield!(LS, :L, LuaThread(L))
    set_julia_wrapper!(LS)
    finalizer(close, LS)

    luaL_openlibs(LS)
    init_julia_value_metatable(LS)
    init_julia_module_metatable(LS)
    @luascope LS begin
        set_global!(LS, "julia", julia_module)
    end
end
