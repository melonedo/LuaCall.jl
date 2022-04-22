module LibLua

using Lua_jll
export Lua_jll

const UINT_MAX = typemax(UInt)
const LLONG_MIN = typemin(Clonglong)
const LLONG_MAX = typemax(Clonglong)
const ULLONG_MAX = typemax(Culonglong)
const ptrdiff_t = Cptrdiff_t
const NULL = C_NULL

const lua_Number = Cdouble

const lua_Integer = Clonglong

mutable struct lua_State end

const lua_KContext = Cptrdiff_t

# typedef int ( * lua_KFunction ) ( lua_State * L , int status , lua_KContext ctx )
const lua_KFunction = Ptr{Cvoid}

function lua_callk(L, nargs, nresults, ctx, k)
    ccall((:lua_callk, liblua), Cvoid, (Ptr{lua_State}, Cint, Cint, lua_KContext, lua_KFunction), L, nargs, nresults, ctx, k)
end

function lua_pcallk(L, nargs, nresults, errfunc, ctx, k)
    ccall((:lua_pcallk, liblua), Cint, (Ptr{lua_State}, Cint, Cint, Cint, lua_KContext, lua_KFunction), L, nargs, nresults, errfunc, ctx, k)
end

function lua_yieldk(L, nresults, ctx, k)
    ccall((:lua_yieldk, liblua), Cint, (Ptr{lua_State}, Cint, lua_KContext, lua_KFunction), L, nresults, ctx, k)
end

function lua_tonumberx(L, idx, isnum)
    ccall((:lua_tonumberx, liblua), lua_Number, (Ptr{lua_State}, Cint, Ptr{Cint}), L, idx, isnum)
end

function lua_tointegerx(L, idx, isnum)
    ccall((:lua_tointegerx, liblua), lua_Integer, (Ptr{lua_State}, Cint, Ptr{Cint}), L, idx, isnum)
end

function lua_settop(L, idx)
    ccall((:lua_settop, liblua), Cvoid, (Ptr{lua_State}, Cint), L, idx)
end

function lua_createtable(L, narr, nrec)
    ccall((:lua_createtable, liblua), Cvoid, (Ptr{lua_State}, Cint, Cint), L, narr, nrec)
end

# typedef int ( * lua_CFunction ) ( lua_State * L )
const lua_CFunction = Ptr{Cvoid}

function lua_pushcclosure(L, fn, n)
    ccall((:lua_pushcclosure, liblua), Cvoid, (Ptr{lua_State}, lua_CFunction, Cint), L, fn, n)
end

function lua_setglobal(L, name)
    ccall((:lua_setglobal, liblua), Cvoid, (Ptr{lua_State}, Ptr{Cchar}), L, name)
end

function lua_type(L, idx)
    ccall((:lua_type, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_pushstring(L, s)
    ccall((:lua_pushstring, liblua), Ptr{Cchar}, (Ptr{lua_State}, Ptr{Cchar}), L, s)
end

function lua_rawgeti(L, idx, n)
    ccall((:lua_rawgeti, liblua), Cint, (Ptr{lua_State}, Cint, lua_Integer), L, idx, n)
end

function lua_tolstring(L, idx, len)
    ccall((:lua_tolstring, liblua), Ptr{Cchar}, (Ptr{lua_State}, Cint, Ptr{Csize_t}), L, idx, len)
end

function lua_rotate(L, idx, n)
    ccall((:lua_rotate, liblua), Cvoid, (Ptr{lua_State}, Cint, Cint), L, idx, n)
end

function lua_copy(L, fromidx, toidx)
    ccall((:lua_copy, liblua), Cvoid, (Ptr{lua_State}, Cint, Cint), L, fromidx, toidx)
end

function lua_newuserdatauv(L, sz, nuvalue)
    ccall((:lua_newuserdatauv, liblua), Ptr{Cvoid}, (Ptr{lua_State}, Csize_t, Cint), L, sz, nuvalue)
end

function lua_getiuservalue(L, idx, n)
    ccall((:lua_getiuservalue, liblua), Cint, (Ptr{lua_State}, Cint, Cint), L, idx, n)
end

function lua_setiuservalue(L, idx, n)
    ccall((:lua_setiuservalue, liblua), Cint, (Ptr{lua_State}, Cint, Cint), L, idx, n)
end

const lua_Unsigned = Culonglong

# typedef const char * ( * lua_Reader ) ( lua_State * L , void * ud , size_t * sz )
const lua_Reader = Ptr{Cvoid}

# typedef int ( * lua_Writer ) ( lua_State * L , const void * p , size_t sz , void * ud )
const lua_Writer = Ptr{Cvoid}

# typedef void * ( * lua_Alloc ) ( void * ud , void * ptr , size_t osize , size_t nsize )
const lua_Alloc = Ptr{Cvoid}

# typedef void ( * lua_WarnFunction ) ( void * ud , const char * msg , int tocont )
const lua_WarnFunction = Ptr{Cvoid}

function lua_newstate(f, ud)
    ccall((:lua_newstate, liblua), Ptr{lua_State}, (lua_Alloc, Ptr{Cvoid}), f, ud)
end

function lua_close(L)
    ccall((:lua_close, liblua), Cvoid, (Ptr{lua_State},), L)
end

function lua_newthread(L)
    ccall((:lua_newthread, liblua), Ptr{lua_State}, (Ptr{lua_State},), L)
end

function lua_resetthread(L)
    ccall((:lua_resetthread, liblua), Cint, (Ptr{lua_State},), L)
end

function lua_atpanic(L, panicf)
    ccall((:lua_atpanic, liblua), lua_CFunction, (Ptr{lua_State}, lua_CFunction), L, panicf)
end

function lua_version(L)
    ccall((:lua_version, liblua), lua_Number, (Ptr{lua_State},), L)
end

function lua_absindex(L, idx)
    ccall((:lua_absindex, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_gettop(L)
    ccall((:lua_gettop, liblua), Cint, (Ptr{lua_State},), L)
end

function lua_pushvalue(L, idx)
    ccall((:lua_pushvalue, liblua), Cvoid, (Ptr{lua_State}, Cint), L, idx)
end

function lua_checkstack(L, n)
    ccall((:lua_checkstack, liblua), Cint, (Ptr{lua_State}, Cint), L, n)
end

function lua_xmove(from, to, n)
    ccall((:lua_xmove, liblua), Cvoid, (Ptr{lua_State}, Ptr{lua_State}, Cint), from, to, n)
end

function lua_isnumber(L, idx)
    ccall((:lua_isnumber, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_isstring(L, idx)
    ccall((:lua_isstring, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_iscfunction(L, idx)
    ccall((:lua_iscfunction, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_isinteger(L, idx)
    ccall((:lua_isinteger, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_isuserdata(L, idx)
    ccall((:lua_isuserdata, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_typename(L, tp)
    ccall((:lua_typename, liblua), Ptr{Cchar}, (Ptr{lua_State}, Cint), L, tp)
end

function lua_toboolean(L, idx)
    ccall((:lua_toboolean, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_rawlen(L, idx)
    ccall((:lua_rawlen, liblua), lua_Unsigned, (Ptr{lua_State}, Cint), L, idx)
end

function lua_tocfunction(L, idx)
    ccall((:lua_tocfunction, liblua), lua_CFunction, (Ptr{lua_State}, Cint), L, idx)
end

function lua_touserdata(L, idx)
    ccall((:lua_touserdata, liblua), Ptr{Cvoid}, (Ptr{lua_State}, Cint), L, idx)
end

function lua_tothread(L, idx)
    ccall((:lua_tothread, liblua), Ptr{lua_State}, (Ptr{lua_State}, Cint), L, idx)
end

function lua_topointer(L, idx)
    ccall((:lua_topointer, liblua), Ptr{Cvoid}, (Ptr{lua_State}, Cint), L, idx)
end

function lua_arith(L, op)
    ccall((:lua_arith, liblua), Cvoid, (Ptr{lua_State}, Cint), L, op)
end

function lua_rawequal(L, idx1, idx2)
    ccall((:lua_rawequal, liblua), Cint, (Ptr{lua_State}, Cint, Cint), L, idx1, idx2)
end

function lua_compare(L, idx1, idx2, op)
    ccall((:lua_compare, liblua), Cint, (Ptr{lua_State}, Cint, Cint, Cint), L, idx1, idx2, op)
end

function lua_pushnil(L)
    ccall((:lua_pushnil, liblua), Cvoid, (Ptr{lua_State},), L)
end

function lua_pushnumber(L, n)
    ccall((:lua_pushnumber, liblua), Cvoid, (Ptr{lua_State}, lua_Number), L, n)
end

function lua_pushinteger(L, n)
    ccall((:lua_pushinteger, liblua), Cvoid, (Ptr{lua_State}, lua_Integer), L, n)
end

function lua_pushlstring(L, s, len)
    ccall((:lua_pushlstring, liblua), Ptr{Cchar}, (Ptr{lua_State}, Ptr{Cchar}, Csize_t), L, s, len)
end

function lua_pushboolean(L, b)
    ccall((:lua_pushboolean, liblua), Cvoid, (Ptr{lua_State}, Cint), L, b)
end

function lua_pushlightuserdata(L, p)
    ccall((:lua_pushlightuserdata, liblua), Cvoid, (Ptr{lua_State}, Ptr{Cvoid}), L, p)
end

function lua_pushthread(L)
    ccall((:lua_pushthread, liblua), Cint, (Ptr{lua_State},), L)
end

function lua_getglobal(L, name)
    ccall((:lua_getglobal, liblua), Cint, (Ptr{lua_State}, Ptr{Cchar}), L, name)
end

function lua_gettable(L, idx)
    ccall((:lua_gettable, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_getfield(L, idx, k)
    ccall((:lua_getfield, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, idx, k)
end

function lua_geti(L, idx, n)
    ccall((:lua_geti, liblua), Cint, (Ptr{lua_State}, Cint, lua_Integer), L, idx, n)
end

function lua_rawget(L, idx)
    ccall((:lua_rawget, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_rawgetp(L, idx, p)
    ccall((:lua_rawgetp, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cvoid}), L, idx, p)
end

function lua_getmetatable(L, objindex)
    ccall((:lua_getmetatable, liblua), Cint, (Ptr{lua_State}, Cint), L, objindex)
end

function lua_settable(L, idx)
    ccall((:lua_settable, liblua), Cvoid, (Ptr{lua_State}, Cint), L, idx)
end

function lua_setfield(L, idx, k)
    ccall((:lua_setfield, liblua), Cvoid, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, idx, k)
end

function lua_seti(L, idx, n)
    ccall((:lua_seti, liblua), Cvoid, (Ptr{lua_State}, Cint, lua_Integer), L, idx, n)
end

function lua_rawset(L, idx)
    ccall((:lua_rawset, liblua), Cvoid, (Ptr{lua_State}, Cint), L, idx)
end

function lua_rawseti(L, idx, n)
    ccall((:lua_rawseti, liblua), Cvoid, (Ptr{lua_State}, Cint, lua_Integer), L, idx, n)
end

function lua_rawsetp(L, idx, p)
    ccall((:lua_rawsetp, liblua), Cvoid, (Ptr{lua_State}, Cint, Ptr{Cvoid}), L, idx, p)
end

function lua_setmetatable(L, objindex)
    ccall((:lua_setmetatable, liblua), Cint, (Ptr{lua_State}, Cint), L, objindex)
end

function lua_load(L, reader, dt, chunkname, mode)
    ccall((:lua_load, liblua), Cint, (Ptr{lua_State}, lua_Reader, Ptr{Cvoid}, Ptr{Cchar}, Ptr{Cchar}), L, reader, dt, chunkname, mode)
end

function lua_dump(L, writer, data, strip)
    ccall((:lua_dump, liblua), Cint, (Ptr{lua_State}, lua_Writer, Ptr{Cvoid}, Cint), L, writer, data, strip)
end

function lua_resume(L, from, narg, nres)
    ccall((:lua_resume, liblua), Cint, (Ptr{lua_State}, Ptr{lua_State}, Cint, Ptr{Cint}), L, from, narg, nres)
end

function lua_status(L)
    ccall((:lua_status, liblua), Cint, (Ptr{lua_State},), L)
end

function lua_isyieldable(L)
    ccall((:lua_isyieldable, liblua), Cint, (Ptr{lua_State},), L)
end

function lua_setwarnf(L, f, ud)
    ccall((:lua_setwarnf, liblua), Cvoid, (Ptr{lua_State}, lua_WarnFunction, Ptr{Cvoid}), L, f, ud)
end

function lua_warning(L, msg, tocont)
    ccall((:lua_warning, liblua), Cvoid, (Ptr{lua_State}, Ptr{Cchar}, Cint), L, msg, tocont)
end

function lua_error(L)
    ccall((:lua_error, liblua), Union{}, (Ptr{lua_State},), L)
end

function lua_next(L, idx)
    ccall((:lua_next, liblua), Cint, (Ptr{lua_State}, Cint), L, idx)
end

function lua_concat(L, n)
    ccall((:lua_concat, liblua), Cvoid, (Ptr{lua_State}, Cint), L, n)
end

function lua_len(L, idx)
    ccall((:lua_len, liblua), Cvoid, (Ptr{lua_State}, Cint), L, idx)
end

function lua_stringtonumber(L, s)
    ccall((:lua_stringtonumber, liblua), Csize_t, (Ptr{lua_State}, Ptr{Cchar}), L, s)
end

function lua_getallocf(L, ud)
    ccall((:lua_getallocf, liblua), lua_Alloc, (Ptr{lua_State}, Ptr{Ptr{Cvoid}}), L, ud)
end

function lua_setallocf(L, f, ud)
    ccall((:lua_setallocf, liblua), Cvoid, (Ptr{lua_State}, lua_Alloc, Ptr{Cvoid}), L, f, ud)
end

function lua_toclose(L, idx)
    ccall((:lua_toclose, liblua), Cvoid, (Ptr{lua_State}, Cint), L, idx)
end

function lua_closeslot(L, idx)
    ccall((:lua_closeslot, liblua), Cvoid, (Ptr{lua_State}, Cint), L, idx)
end

mutable struct CallInfo end

struct lua_Debug
    event::Cint
    name::Ptr{Cchar}
    namewhat::Ptr{Cchar}
    what::Ptr{Cchar}
    source::Ptr{Cchar}
    srclen::Csize_t
    currentline::Cint
    linedefined::Cint
    lastlinedefined::Cint
    nups::Cuchar
    nparams::Cuchar
    isvararg::Cchar
    istailcall::Cchar
    ftransfer::Cushort
    ntransfer::Cushort
    short_src::NTuple{60, Cchar}
    i_ci::Ptr{CallInfo}
end

# typedef void ( * lua_Hook ) ( lua_State * L , lua_Debug * ar )
const lua_Hook = Ptr{Cvoid}

function lua_getstack(L, level, ar)
    ccall((:lua_getstack, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{lua_Debug}), L, level, ar)
end

function lua_getinfo(L, what, ar)
    ccall((:lua_getinfo, liblua), Cint, (Ptr{lua_State}, Ptr{Cchar}, Ptr{lua_Debug}), L, what, ar)
end

function lua_getlocal(L, ar, n)
    ccall((:lua_getlocal, liblua), Ptr{Cchar}, (Ptr{lua_State}, Ptr{lua_Debug}, Cint), L, ar, n)
end

function lua_setlocal(L, ar, n)
    ccall((:lua_setlocal, liblua), Ptr{Cchar}, (Ptr{lua_State}, Ptr{lua_Debug}, Cint), L, ar, n)
end

function lua_getupvalue(L, funcindex, n)
    ccall((:lua_getupvalue, liblua), Ptr{Cchar}, (Ptr{lua_State}, Cint, Cint), L, funcindex, n)
end

function lua_setupvalue(L, funcindex, n)
    ccall((:lua_setupvalue, liblua), Ptr{Cchar}, (Ptr{lua_State}, Cint, Cint), L, funcindex, n)
end

function lua_upvalueid(L, fidx, n)
    ccall((:lua_upvalueid, liblua), Ptr{Cvoid}, (Ptr{lua_State}, Cint, Cint), L, fidx, n)
end

function lua_upvaluejoin(L, fidx1, n1, fidx2, n2)
    ccall((:lua_upvaluejoin, liblua), Cvoid, (Ptr{lua_State}, Cint, Cint, Cint, Cint), L, fidx1, n1, fidx2, n2)
end

function lua_sethook(L, func, mask, count)
    ccall((:lua_sethook, liblua), Cvoid, (Ptr{lua_State}, lua_Hook, Cint, Cint), L, func, mask, count)
end

function lua_gethook(L)
    ccall((:lua_gethook, liblua), lua_Hook, (Ptr{lua_State},), L)
end

function lua_gethookmask(L)
    ccall((:lua_gethookmask, liblua), Cint, (Ptr{lua_State},), L)
end

function lua_gethookcount(L)
    ccall((:lua_gethookcount, liblua), Cint, (Ptr{lua_State},), L)
end

function lua_setcstacklimit(L, limit)
    ccall((:lua_setcstacklimit, liblua), Cint, (Ptr{lua_State}, Cuint), L, limit)
end

function luaL_checkversion_(L, ver, sz)
    ccall((:luaL_checkversion_, liblua), Cvoid, (Ptr{lua_State}, lua_Number, Csize_t), L, ver, sz)
end

function luaL_loadfilex(L, filename, mode)
    ccall((:luaL_loadfilex, liblua), Cint, (Ptr{lua_State}, Ptr{Cchar}, Ptr{Cchar}), L, filename, mode)
end

struct luaL_Reg
    name::Ptr{Cchar}
    func::lua_CFunction
end

function luaL_setfuncs(L, l, nup)
    ccall((:luaL_setfuncs, liblua), Cvoid, (Ptr{lua_State}, Ptr{luaL_Reg}, Cint), L, l, nup)
end

function luaL_argerror(L, arg, extramsg)
    ccall((:luaL_argerror, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, arg, extramsg)
end

function luaL_typeerror(L, arg, tname)
    ccall((:luaL_typeerror, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, arg, tname)
end

function luaL_checklstring(L, arg, l)
    ccall((:luaL_checklstring, liblua), Ptr{Cchar}, (Ptr{lua_State}, Cint, Ptr{Csize_t}), L, arg, l)
end

function luaL_optlstring(L, arg, def, l)
    ccall((:luaL_optlstring, liblua), Ptr{Cchar}, (Ptr{lua_State}, Cint, Ptr{Cchar}, Ptr{Csize_t}), L, arg, def, l)
end

function luaL_loadstring(L, s)
    ccall((:luaL_loadstring, liblua), Cint, (Ptr{lua_State}, Ptr{Cchar}), L, s)
end

function luaL_loadbufferx(L, buff, sz, name, mode)
    ccall((:luaL_loadbufferx, liblua), Cint, (Ptr{lua_State}, Ptr{Cchar}, Csize_t, Ptr{Cchar}, Ptr{Cchar}), L, buff, sz, name, mode)
end

struct var"##Ctag#294"
    data::NTuple{1024, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#294"}, f::Symbol)
    f === :n && return Ptr{lua_Number}(x + 0)
    f === :u && return Ptr{Cdouble}(x + 0)
    f === :s && return Ptr{Ptr{Cvoid}}(x + 0)
    f === :i && return Ptr{lua_Integer}(x + 0)
    f === :l && return Ptr{Clong}(x + 0)
    f === :b && return Ptr{NTuple{1024, Cchar}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#294", f::Symbol)
    r = Ref{var"##Ctag#294"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#294"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#294"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct luaL_Buffer
    data::NTuple{1056, UInt8}
end

function Base.getproperty(x::Ptr{luaL_Buffer}, f::Symbol)
    f === :b && return Ptr{Ptr{Cchar}}(x + 0)
    f === :size && return Ptr{Csize_t}(x + 8)
    f === :n && return Ptr{Csize_t}(x + 16)
    f === :L && return Ptr{Ptr{lua_State}}(x + 24)
    f === :init && return Ptr{var"##Ctag#294"}(x + 32)
    return getfield(x, f)
end

function Base.getproperty(x::luaL_Buffer, f::Symbol)
    r = Ref{luaL_Buffer}(x)
    ptr = Base.unsafe_convert(Ptr{luaL_Buffer}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{luaL_Buffer}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function luaL_prepbuffsize(B, sz)
    ccall((:luaL_prepbuffsize, liblua), Ptr{Cchar}, (Ptr{luaL_Buffer}, Csize_t), B, sz)
end

function luaL_getmetafield(L, obj, e)
    ccall((:luaL_getmetafield, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, obj, e)
end

function luaL_callmeta(L, obj, e)
    ccall((:luaL_callmeta, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, obj, e)
end

function luaL_tolstring(L, idx, len)
    ccall((:luaL_tolstring, liblua), Ptr{Cchar}, (Ptr{lua_State}, Cint, Ptr{Csize_t}), L, idx, len)
end

function luaL_checknumber(L, arg)
    ccall((:luaL_checknumber, liblua), lua_Number, (Ptr{lua_State}, Cint), L, arg)
end

function luaL_optnumber(L, arg, def)
    ccall((:luaL_optnumber, liblua), lua_Number, (Ptr{lua_State}, Cint, lua_Number), L, arg, def)
end

function luaL_checkinteger(L, arg)
    ccall((:luaL_checkinteger, liblua), lua_Integer, (Ptr{lua_State}, Cint), L, arg)
end

function luaL_optinteger(L, arg, def)
    ccall((:luaL_optinteger, liblua), lua_Integer, (Ptr{lua_State}, Cint, lua_Integer), L, arg, def)
end

function luaL_checkstack(L, sz, msg)
    ccall((:luaL_checkstack, liblua), Cvoid, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, sz, msg)
end

function luaL_checktype(L, arg, t)
    ccall((:luaL_checktype, liblua), Cvoid, (Ptr{lua_State}, Cint, Cint), L, arg, t)
end

function luaL_checkany(L, arg)
    ccall((:luaL_checkany, liblua), Cvoid, (Ptr{lua_State}, Cint), L, arg)
end

function luaL_newmetatable(L, tname)
    ccall((:luaL_newmetatable, liblua), Cint, (Ptr{lua_State}, Ptr{Cchar}), L, tname)
end

function luaL_setmetatable(L, tname)
    ccall((:luaL_setmetatable, liblua), Cvoid, (Ptr{lua_State}, Ptr{Cchar}), L, tname)
end

function luaL_testudata(L, ud, tname)
    ccall((:luaL_testudata, liblua), Ptr{Cvoid}, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, ud, tname)
end

function luaL_checkudata(L, ud, tname)
    ccall((:luaL_checkudata, liblua), Ptr{Cvoid}, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, ud, tname)
end

function luaL_where(L, lvl)
    ccall((:luaL_where, liblua), Cvoid, (Ptr{lua_State}, Cint), L, lvl)
end

function luaL_checkoption(L, arg, def, lst)
    ccall((:luaL_checkoption, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}, Ptr{Ptr{Cchar}}), L, arg, def, lst)
end

function luaL_fileresult(L, stat, fname)
    ccall((:luaL_fileresult, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, stat, fname)
end

function luaL_execresult(L, stat)
    ccall((:luaL_execresult, liblua), Cint, (Ptr{lua_State}, Cint), L, stat)
end

function luaL_ref(L, t)
    ccall((:luaL_ref, liblua), Cint, (Ptr{lua_State}, Cint), L, t)
end

function luaL_unref(L, t, ref)
    ccall((:luaL_unref, liblua), Cvoid, (Ptr{lua_State}, Cint, Cint), L, t, ref)
end

function luaL_newstate()
    ccall((:luaL_newstate, liblua), Ptr{lua_State}, ())
end

function luaL_len(L, idx)
    ccall((:luaL_len, liblua), lua_Integer, (Ptr{lua_State}, Cint), L, idx)
end

function luaL_addgsub(b, s, p, r)
    ccall((:luaL_addgsub, liblua), Cvoid, (Ptr{luaL_Buffer}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), b, s, p, r)
end

function luaL_gsub(L, s, p, r)
    ccall((:luaL_gsub, liblua), Ptr{Cchar}, (Ptr{lua_State}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), L, s, p, r)
end

function luaL_getsubtable(L, idx, fname)
    ccall((:luaL_getsubtable, liblua), Cint, (Ptr{lua_State}, Cint, Ptr{Cchar}), L, idx, fname)
end

function luaL_traceback(L, L1, msg, level)
    ccall((:luaL_traceback, liblua), Cvoid, (Ptr{lua_State}, Ptr{lua_State}, Ptr{Cchar}, Cint), L, L1, msg, level)
end

function luaL_requiref(L, modname, openf, glb)
    ccall((:luaL_requiref, liblua), Cvoid, (Ptr{lua_State}, Ptr{Cchar}, lua_CFunction, Cint), L, modname, openf, glb)
end

function luaL_buffinit(L, B)
    ccall((:luaL_buffinit, liblua), Cvoid, (Ptr{lua_State}, Ptr{luaL_Buffer}), L, B)
end

function luaL_addlstring(B, s, l)
    ccall((:luaL_addlstring, liblua), Cvoid, (Ptr{luaL_Buffer}, Ptr{Cchar}, Csize_t), B, s, l)
end

function luaL_addstring(B, s)
    ccall((:luaL_addstring, liblua), Cvoid, (Ptr{luaL_Buffer}, Ptr{Cchar}), B, s)
end

function luaL_addvalue(B)
    ccall((:luaL_addvalue, liblua), Cvoid, (Ptr{luaL_Buffer},), B)
end

function luaL_pushresult(B)
    ccall((:luaL_pushresult, liblua), Cvoid, (Ptr{luaL_Buffer},), B)
end

function luaL_pushresultsize(B, sz)
    ccall((:luaL_pushresultsize, liblua), Cvoid, (Ptr{luaL_Buffer}, Csize_t), B, sz)
end

function luaL_buffinitsize(L, B, sz)
    ccall((:luaL_buffinitsize, liblua), Ptr{Cchar}, (Ptr{lua_State}, Ptr{luaL_Buffer}, Csize_t), L, B, sz)
end

struct luaL_Stream
    f::Ptr{Libc.FILE}
    closef::lua_CFunction
end

function luaopen_base(L)
    ccall((:luaopen_base, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_coroutine(L)
    ccall((:luaopen_coroutine, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_table(L)
    ccall((:luaopen_table, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_io(L)
    ccall((:luaopen_io, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_os(L)
    ccall((:luaopen_os, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_string(L)
    ccall((:luaopen_string, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_utf8(L)
    ccall((:luaopen_utf8, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_math(L)
    ccall((:luaopen_math, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_debug(L)
    ccall((:luaopen_debug, liblua), Cint, (Ptr{lua_State},), L)
end

function luaopen_package(L)
    ccall((:luaopen_package, liblua), Cint, (Ptr{lua_State},), L)
end

function luaL_openlibs(L)
    ccall((:luaL_openlibs, liblua), Cvoid, (Ptr{lua_State},), L)
end

const LUAI_IS32INT = UINT_MAX >> 30 >= 3

const LUA_INT_INT = 1

const LUA_INT_LONG = 2

const LUA_INT_LONGLONG = 3

const LUA_FLOAT_FLOAT = 1

const LUA_FLOAT_DOUBLE = 2

const LUA_FLOAT_LONGDOUBLE = 3

const LUA_INT_DEFAULT = LUA_INT_LONGLONG

const LUA_FLOAT_DEFAULT = LUA_FLOAT_DOUBLE

const LUA_32BITS = 0

const LUA_C89_NUMBERS = 0

const LUA_INT_TYPE = LUA_INT_DEFAULT

const LUA_FLOAT_TYPE = LUA_FLOAT_DEFAULT

const LUA_PATH_SEP = ";"

const LUA_PATH_MARK = "?"

const LUA_EXEC_DIR = "!"

const LUA_VERSION_MAJOR = "5"

const LUA_VERSION_MINOR = "4"

const LUA_LDIR = "!\\lua\\"

const LUA_CDIR = "!\\"

# Skipping MacroDefinition: LUA_PATH_DEFAULT LUA_LDIR "?.lua;" LUA_LDIR "?\\init.lua;" LUA_CDIR "?.lua;" LUA_CDIR "?\\init.lua;" LUA_SHRDIR "?.lua;" LUA_SHRDIR "?\\init.lua;" ".\\?.lua;" ".\\?\\init.lua"

# Skipping MacroDefinition: LUA_CPATH_DEFAULT LUA_CDIR "?.dll;" LUA_CDIR "..\\lib\\lua\\" LUA_VDIR "\\?.dll;" LUA_CDIR "loadall.dll;" ".\\?.dll"

const LUA_DIRSEP = "\\"

# Skipping MacroDefinition: LUA_API extern

# Skipping MacroDefinition: LUAI_FUNC extern

LUAI_DDEC(dec) = LUAI_FUNC(dec)

l_mathop(op) = op

l_floor(x) = (l_mathop(floor))(x)

l_sprintf(s, sz, f, i) = (Cvoid(sz), sprintf(s, f, i))

const LUA_NUMBER_FMT = "%.14g"

const LUAI_UACNUMBER = Float64

lua_number2str(s, sz, n) = l_sprintf(s, sz, LUA_NUMBER_FMT, LUAI_UACNUMBER(n))

const LUA_NUMBER = Float64

const LUA_MININTEGER = LLONG_MIN

const LUA_INTEGER = Clonglong

const LUA_NUMBER_FRMLEN = ""

lua_str2number(s, p) = strtod(s, p)

const LUA_INTEGER_FRMLEN = "ll"

const LUAI_UACINT = LUA_INTEGER

lua_integer2str(s, sz, n) = l_sprintf(s, sz, LUA_INTEGER_FMT, LUAI_UACINT(n))

const LUA_UNSIGNED = unsigned(LUAI_UACINT)

# Skipping MacroDefinition: LUA_UNSIGNEDBITS ( sizeof ( LUA_UNSIGNED ) * CHAR_BIT )

const LUA_MAXINTEGER = LLONG_MAX

const LUA_MAXUNSIGNED = ULLONG_MAX

lua_pointer2str(buff, sz, p) = l_sprintf(buff, sz, "%p", p)

const LUA_KCONTEXT = ptrdiff_t

# Skipping MacroDefinition: lua_getlocaledecpoint ( ) ( localeconv ( ) -> decimal_point [ 0 ] )

luai_likely(x) = __builtin_expect(x != 0, 1)

luai_unlikely(x) = __builtin_expect(x != 0, 0)

const LUAI_MAXSTACK = 1000000

# Skipping MacroDefinition: LUA_EXTRASPACE ( sizeof ( void * ) )

const LUA_IDSIZE = 60

# Skipping MacroDefinition: LUAL_BUFFERSIZE ( ( int ) ( 16 * sizeof ( void * ) * sizeof ( lua_Number ) ) )

const LUA_VERSION_RELEASE = "3"

const LUA_VERSION_NUM = 504

const LUA_VERSION_RELEASE_NUM = LUA_VERSION_NUM * 100 + 0

const LUA_AUTHORS = "R. Ierusalimschy, L. H. de Figueiredo, W. Celes"

const LUA_SIGNATURE = "\eLua"

const LUA_MULTRET = -1

const LUA_REGISTRYINDEX = -LUAI_MAXSTACK - 1000

lua_upvalueindex(i) = LUA_REGISTRYINDEX - i

const LUA_OK = 0

const LUA_YIELD = 1

const LUA_ERRRUN = 2

const LUA_ERRSYNTAX = 3

const LUA_ERRMEM = 4

const LUA_ERRERR = 5

const LUA_TNONE = -1

const LUA_TNIL = 0

const LUA_TBOOLEAN = 1

const LUA_TLIGHTUSERDATA = 2

const LUA_TNUMBER = 3

const LUA_TSTRING = 4

const LUA_TTABLE = 5

const LUA_TFUNCTION = 6

const LUA_TUSERDATA = 7

const LUA_TTHREAD = 8

const LUA_NUMTYPES = 9

const LUA_MINSTACK = 20

const LUA_RIDX_MAINTHREAD = 1

const LUA_RIDX_GLOBALS = 2

const LUA_RIDX_LAST = LUA_RIDX_GLOBALS

const LUA_OPADD = 0

const LUA_OPSUB = 1

const LUA_OPMUL = 2

const LUA_OPMOD = 3

const LUA_OPPOW = 4

const LUA_OPDIV = 5

const LUA_OPIDIV = 6

const LUA_OPBAND = 7

const LUA_OPBOR = 8

const LUA_OPBXOR = 9

const LUA_OPSHL = 10

const LUA_OPSHR = 11

const LUA_OPUNM = 12

const LUA_OPBNOT = 13

const LUA_OPEQ = 0

const LUA_OPLT = 1

const LUA_OPLE = 2

lua_call(L, n, r) = lua_callk(L, n, r, 0, NULL)

lua_pcall(L, n, r, f) = lua_pcallk(L, n, r, f, 0, NULL)

lua_yield(L, n) = lua_yieldk(L, n, 0, NULL)

const LUA_GCSTOP = 0

const LUA_GCRESTART = 1

const LUA_GCCOLLECT = 2

const LUA_GCCOUNT = 3

const LUA_GCCOUNTB = 4

const LUA_GCSTEP = 5

const LUA_GCSETPAUSE = 6

const LUA_GCSETSTEPMUL = 7

const LUA_GCISRUNNING = 9

const LUA_GCGEN = 10

const LUA_GCINC = 11

# Skipping MacroDefinition: lua_getextraspace ( L ) ( ( void * ) ( ( char * ) ( L ) - LUA_EXTRASPACE ) )

lua_tonumber(L, i) = lua_tonumberx(L, i, NULL)

lua_tointeger(L, i) = lua_tointegerx(L, i, NULL)

lua_pop(L, n) = lua_settop(L, -n - 1)

lua_newtable(L) = lua_createtable(L, 0, 0)

lua_pushcfunction(L, f) = lua_pushcclosure(L, f, 0)

lua_register(L, n, f) = (lua_pushcfunction(L, f), lua_setglobal(L, n))

lua_isfunction(L, n) = lua_type(L, n) == LUA_TFUNCTION

lua_istable(L, n) = lua_type(L, n) == LUA_TTABLE

lua_islightuserdata(L, n) = lua_type(L, n) == LUA_TLIGHTUSERDATA

lua_isnil(L, n) = lua_type(L, n) == LUA_TNIL

lua_isboolean(L, n) = lua_type(L, n) == LUA_TBOOLEAN

lua_isthread(L, n) = lua_type(L, n) == LUA_TTHREAD

lua_isnone(L, n) = lua_type(L, n) == LUA_TNONE

lua_isnoneornil(L, n) = lua_type(L, n) <= 0

lua_pushliteral(L, s) = lua_pushstring(L, ("")(s))

lua_pushglobaltable(L) = (Cvoid(lua_rawgeti))(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS)

lua_tostring(L, i) = lua_tolstring(L, i, NULL)

lua_insert(L, idx) = lua_rotate(L, idx, 1)

lua_remove(L, idx) = (lua_rotate(L, idx, -1), lua_pop(L, 1))

lua_replace(L, idx) = (lua_copy(L, -1, idx), lua_pop(L, 1))

lua_newuserdata(L, s) = lua_newuserdatauv(L, s, 1)

lua_getuservalue(L, idx) = lua_getiuservalue(L, idx, 1)

lua_setuservalue(L, idx) = lua_setiuservalue(L, idx, 1)

const LUA_NUMTAGS = LUA_NUMTYPES

const LUA_HOOKCALL = 0

const LUA_HOOKRET = 1

const LUA_HOOKLINE = 2

const LUA_HOOKCOUNT = 3

const LUA_HOOKTAILCALL = 4

const LUA_MASKCALL = 1 << LUA_HOOKCALL

const LUA_MASKRET = 1 << LUA_HOOKRET

const LUA_MASKLINE = 1 << LUA_HOOKLINE

const LUA_MASKCOUNT = 1 << LUA_HOOKCOUNT

const LUA_GNAME = "_G"

const LUA_ERRFILE = LUA_ERRERR + 1

const LUA_LOADED_TABLE = "_LOADED"

const LUA_PRELOAD_TABLE = "_PRELOAD"

# Skipping MacroDefinition: LUAL_NUMSIZES ( sizeof ( lua_Integer ) * 16 + sizeof ( lua_Number ) )

luaL_checkversion(L) = luaL_checkversion_(L, LUA_VERSION_NUM, LUAL_NUMSIZES)

const LUA_NOREF = -2

const LUA_REFNIL = -1

luaL_loadfile(L, f) = luaL_loadfilex(L, f, NULL)

# Skipping MacroDefinition: luaL_newlibtable ( L , l ) lua_createtable ( L , 0 , sizeof ( l ) / sizeof ( ( l ) [ 0 ] ) - 1 )

luaL_newlib(L, l) = (luaL_checkversion(L), luaL_newlibtable(L, l), luaL_setfuncs(L, l, 0))

luaL_argcheck(L, cond, arg, extramsg) = Cvoid(luai_likely(cond) || luaL_argerror(L, arg, extramsg))

luaL_argexpected(L, cond, arg, tname) = Cvoid(luai_likely(cond) || luaL_typeerror(L, arg, tname))

luaL_checkstring(L, n) = luaL_checklstring(L, n, NULL)

luaL_optstring(L, n, d) = luaL_optlstring(L, n, d, NULL)

luaL_typename(L, i) = lua_typename(L, lua_type(L, i))

luaL_dofile(L, fn) = luaL_loadfile(L, fn) || lua_pcall(L, 0, LUA_MULTRET, 0)

luaL_getmetatable(L, n) = lua_getfield(L, LUA_REGISTRYINDEX, n)

luaL_opt(L, f, n, d) = if lua_isnoneornil(L, n)
        d
    else
        f(L, n)
    end

luaL_loadbuffer(L, s, sz, n) = luaL_loadbufferx(L, s, sz, n, NULL)

luaL_pushfail(L) = lua_pushnil(L)

lua_assert(c) = Cvoid(0)

luaL_bufflen(bf) = (bf->begin
            #= none:1 =#
            n
        end)

luaL_buffaddr(bf) = (bf->begin
            #= none:1 =#
            b
        end)

# Skipping MacroDefinition: luaL_addchar ( B , c ) ( ( void ) ( ( B ) -> n < ( B ) -> size || luaL_prepbuffsize ( ( B ) , 1 ) ) , ( ( B ) -> b [ ( B ) -> n ++ ] = ( c ) ) )

luaL_addsize(B, s) = (B->begin
            #= none:1 =#
            n += s
        end)

luaL_buffsub(B, s) = (B->begin
            #= none:1 =#
            n -= s
        end)

luaL_prepbuffer(B) = luaL_prepbuffsize(B, LUAL_BUFFERSIZE)

const LUA_FILEHANDLE = "FILE*"

lua_writestring(s, l) = fwrite(s, sizeof(Cchar), l, stdout)

lua_writeline() = (lua_writestring("\n", 1), fflush(stdout))

lua_writestringerror(s, p) = (fprintf(stderr, s, p), fflush(stderr))

const LUA_COLIBNAME = "coroutine"

const LUA_TABLIBNAME = "table"

const LUA_IOLIBNAME = "io"

const LUA_OSLIBNAME = "os"

const LUA_STRLIBNAME = "string"

const LUA_UTF8LIBNAME = "utf8"

const LUA_MATHLIBNAME = "math"

const LUA_DBLIBNAME = "debug"

const LUA_LOADLIBNAME = "package"

# exports
const PREFIXES = ["lua_", "luaL_", "LUA_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
