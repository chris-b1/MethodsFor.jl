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


#const numcols = 2

"""
    methodsfor(type_or_val)

Pretty print list of exported methods that take a `type_or_val`
from currently available modules.  
"""
function methodsfor(::Type{T}) where {T}
    # todo - parametize/infer, use IOContext
    colwidth = 45

    methods = methodswith(T; supertypes=true)
    exported = Dict{MethodInfo, Int}()
    method_dct = DefaultDict(() -> DefaultDict(() -> 0))

    # not_exported = Dict{MethodInfo, Int}()

    for method in methods
        sig = Base.unwrap_unionall(method.sig)
        generic_fx_mod = sig.types[1].name.module

        mi = MethodInfo(method.name, method.module, generic_fx_mod)

        # typeof(n).name.module
        is_exported = mi.name in names(mi.def_mod) || mi.fx_mod == Base

        if is_exported
            method_dct[mi.fx_mod][mi.name] += 1
        end
    end


    group_lengths = Dict( (k, length(method_dct[k])) for k in keys(method_dct) )
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
    return

    return coltexts
    # return method_dct
end
methodsfor(val) = methodsfor(typeof(val))


end
