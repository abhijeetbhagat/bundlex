defmodule Bundlex.Toolchain.Common.Compilers do
    defstruct [:c, :cpp]

    def resolve_lang(lang) do
        cond do
            lang in ["cpp", "c++", "C++", "CPP", "cplusplus", "CPLUSPLUS"] ->
                :cpp
            lang in ["c", "C"] ->
                :c
            true ->
                :c
        end
    end

    def resolve_compiler(lang, compilers) when is_atom(lang) do
        with :cpp <- lang do
            compilers.cpp
        else
            l -> compilers.c
        end
    end

    def resolve_compiler(lang, compilers) do
        lang |> resolve_lang |> resolve_compiler(compilers)
    end

    def get_std_flag(:cpp) do
        "-std=c++17"
    end

    def get_std_flag(:c) do
        "-std=c11"
    end
end