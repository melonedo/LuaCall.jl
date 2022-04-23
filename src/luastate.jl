

function LuaStateWraper()
    LS = LuaStateWraper(C_NULL)
    init(LS)
    LS
end


"Push values to the stack. This function also calls `lua_checkstack` as `@boundscheck`."
@inline function Base.push!(LS::LuaState, xs...)
    @boundscheck checkstack(LS, length(xs))
    for x in xs
        pushstack!(LS, x)
    end
end

Base.pop!(LS::LuaState, n) = lua_pop(LS, n)

top(LS::LuaState) = lua_gettop(LS)


Base.getproperty(LS::LuaState, f::Symbol) = pushglobal!(LS, f)

Base.setproperty!(LS::LuaState, f::Symbol, x) = setglobal!(LS, f, x)

Base.getindex(LS::LuaState, i=-1) = getstack(LS, i)


function pushglobal!(LS::LuaState, f)
    checkstack(LS, 1)
    lua_getglobal(LS, f)
    PopStack(LS[], LS, 1)
end

function setglobal!(LS::LuaState, f, v)
    push!(LS, v)
    lua_setglobal(LS, f)
end

function pushglobaltable!(LS::LuaState)
    lua_pushglobaltable(LS)
    PopStack(LuaTable(LS, -1), LS, 1)
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
        setglobal!(LUA_STATE, "julia", mod)
    end
end
