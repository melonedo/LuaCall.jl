
unwrap_popstack(x) = x
unwrap_popstack(x::PopStack) = x.data

function luareturn_impl(LS::LuaState, old_base, vars...)
    new_base = Ref(old_base)
    moved = map(vars) do x
        if x isa OnLuaStack
            new_base[] += 1
            typeof(x)(LS, new_base[])
        else
            x
        end
    end
    lua_rotate(LS, old_base + 1, new_base[] - old_base)
    new_base[], moved
end

function luascope_impl(LS_expr, code::Expr)
    @assert code.head == :block
    LS = gensym(:LS)
    base = gensym(:base)
    body = []
    for expr in code.args
        if expr isa Expr && expr.head == :(=)
            left, right = expr.args
            if left isa Expr && left.head == :(::)
                right = :($right::$PopStack{$(left.args[2])})
                left = left.args[1]
            end
            push!(body, :($left = $unwrap_popstack($right)))
        elseif expr isa Expr && expr.head == :macrocall &&
               expr.args[1] == Symbol("@luareturn")
            vars = expr.args[3:end]
            nvars = length(vars)
            ret = gensym(:ret)
            ret_expr = nvars == 1 ? :(only($ret)) : ret
            push!(body, quote
                $base, $ret = $luareturn_impl($LS, $base, $(vars...))
                $PopStack($ret_expr, $LS, $nvars)
            end)
        else
            push!(body, expr)
        end
    end
    quote
        $LS = $LS_expr
        $base = $top($LS)
        try
            $(body...)
        finally
            $lua_settop($LS, $base)
        end
    end |> esc
end

"""
    @luascope

Manage Lua stack for all top-level expressions in this block. Usage:

```julia
LS = LUA_STATE
@luascope LS begin
    t::LuaTable = new_table!(LS)
    t[1] = 2
    @luareturn t
end
```

In the above example, `getglobal` and `j["Base"]` both push value to the Lua stack and return `PopStack` values. 
To account for this, `@luascope` detects top-level assignment `var = expr`, where `expr` evaluates to a `PopStack` value
to unwrap the value. 

After control leaves the block, the Lua stack is reset, destroying all lua variables.
If you want to return Lua values, call `@luareturn` at the end of the block.

!!! warning
    This macro does not free Lua stack inside the block, so a loop that repetitively pushes Lua value may run out of stack space.
"""
macro luascope(LS, code::Expr)
    luascope_impl(LS, code)
end

"""
    @luareturn v1 v2...

Mark `v1, v2...` as Julia return value, they will be kept on the Lua stack.

Assume each value occupy one Lua stack slot. 
Manage Lua stack yourself if you want to use multiple return values.

!!! warning
    This macro will corrupt the current Lua stack, thus invalidating any existing values.
"""
macro luareturn(args...)
    error("`@luareturn` is only a placeholder, see `@luascope.`")
end
