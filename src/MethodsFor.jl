module MethodsFor

export methodsfor

using DataStructures: DefaultDict
using InteractiveUtils: methodswith
using Crayons: Crayon

struct MethodInfo
    name::Symbol
    def_mod::Module
    fx_mod::Module
end

const method_color = Crayon(foreground=:light_yellow)
const module_color = Crayon(foreground=:light_cyan)

function _groupmethods(methods::Array{Method}, q)
    exported = Dict{MethodInfo, Int}()
    method_dct = DefaultDict(() -> DefaultDict(() -> 0))

    for method in methods
        if !isnothing(q) && !occursin(q, string(method.name))
            continue
        end

        sig = Base.unwrap_unionall(method.sig)
        generic_fx_mod = sig.types[1].name.module

        mi = MethodInfo(method.name, method.module, generic_fx_mod)

        # typeof(n).name.module
        is_exported = mi.name in names(mi.def_mod) || mi.fx_mod == Base

        if is_exported
            method_dct[mi.fx_mod][mi.name] += 1
        end
    end

    return method_dct
end

function _printmethods(method_dct)
    colwidth = 45

    group_lengths = Dict((k, length(method_dct[k])) for k in keys(method_dct))
    ordered_keys = sort(collect(keys(group_lengths)), by=x->group_lengths[x]; rev=true)

    cols = [[], []]
    col_len(i) = isempty(cols[i]) ? 0 : sum(group_lengths[x] for x in cols[i])

    for k in ordered_keys
        next_length = group_lengths[k]
        if col_len(1) > col_len(2) + next_length + 2
            push!(cols[2], k)
        else
            push!(cols[1], k)
        end
    end
    coltexts = [[], []]
    for i in 1:2
        for k in cols[i]
            push!(coltexts[i], string(module_color(string(k))) * ":")
            for f in sort(collect(keys(method_dct[k])))
                count = method_dct[k][f]
                push!(coltexts[i], "  " * string(method_color(string(f))) * " with $count methods")
            end
        end
    end

    col_text(i, row) = row > length(coltexts[i]) ? "" : coltexts[i][row]

    for row in 1:max(length(coltexts[1]), length(coltexts[2]))
        one = rpad(col_text(1, row), colwidth)
        two = col_text(2, row)
        println(one, two)
    end
end


"""
    methodsfor(type_or_val[, module]; q=nothing, supertypes=true)

Pretty print list of exported methods that take a `type_or_val`
from currently available modules
"""
function methodsfor(::Type{T}; q=nothing, supertypes=true) where {T}
    methods = methodswith(T; supertypes=supertypes)
    method_dct = _groupmethods(methods, q)
    _printmethods(method_dct)
    return nothing
end
methodsfor(val; kwargs...) = methodsfor(typeof(val); kwargs...)

end
