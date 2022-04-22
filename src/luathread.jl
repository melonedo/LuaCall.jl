
struct LuaThread <: OnLuaStack
    LS::LuaState
    idx::Cint
    LuaThread(LS::LuaState, idx) = new(LS, lua_absindex(LS, idx))
end

