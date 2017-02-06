defmodule Bundlex.Toolchain.VisualStudio do
  @moduledoc """
  Toolchain definition for Microsoft Visual Studio.

  It tries to determine Visual Studio root directory before compolation starts
  and set up appropriate environment variables that will cause using right
  compiler for given platform by calling vcvarsall.bat script shipped with
  Visual Studio.

  Visual Studio directory may be override by setting VISUAL_STUDIO_ROOT
  environment variable.
  """

  use Bundlex.Toolchain
  alias Bundlex.Helper.DirectoryHelper


  @directory_wildcard "c:\\Program Files (x86)\\Microsoft Visual Studio *"
  @directory_env "VISUAL_STUDIO_ROOT"


  def before_all!(:windows32) do
    [run_vcvarsall("amd64_x86")]
  end


  def before_all!(:windows64) do
    [run_vcvarsall("amd64")]
  end


  def compiler_commands(includes, libs, sources, output) do
    # FIXME escape quotes properly

    includes_part = includes |> Enum.map(fn(include) -> "/I \"#{include}\"" end) |> Enum.join(" ")
    sources_part = sources |> Enum.map(fn(source) -> "\"c_src\\#{source}\"" end) |> Enum.join(" ")
    libs_part = libs |> Enum.join(" ")

    ["cl /LD #{includes_part} #{sources_part} #{libs_part} /link /OUT:#{output}.dll"]
  end


  def post_copy_commands(output) do
    []
    # FIXME
    # first of all elixir returns wrong slashes
    #   https://github.com/elixir-lang/elixir/issues/1236
    # secondly we need to figure out the best directory for NIFs
    #
    # ["copy #{output}.dll #{Mix.Project.app_path()}"]
  end


  # Runs vcvarsall.bat script
  defp run_vcvarsall(vcvarsall_arg) do
    vcvarsall_path =
      determine_visual_studio_root()
      |> build_vcvarsall_path()

    case File.exists?(vcvarsall_path) do
      false ->
        Mix.raise "Unable to find vcvarsall.bat script within Visual Studio root directory. Is your Visual Studio installation valid?"

      true ->
        Bundlex.Output.info3 "Adding call to \"vcvarsall.bat #{vcvarsall_arg}\""

        "call \"#{vcvarsall_path}\" #{vcvarsall_arg}"
    end
  end


  # Determines root directory of the Visual Studio.
  defp determine_visual_studio_root() do
    determine_visual_studio_root(System.get_env(@directory_env))
  end

  # Determines root directory of the Visual Studio.
  # Case when we don't have a root path passed via an environment variable.
  defp determine_visual_studio_root(nil) do
    Bundlex.Output.info3 "Trying to find Visual Studio in \"#{@directory_wildcard}\"..."

    case DirectoryHelper.wildcard(@directory_wildcard) do
      nil ->
        Mix.raise "Unable to find Visual Studio root directory. Please ensure that it is either located in \"#{@directory_wildcard}\" or #{@directory_env} environment variable pointing to its root is set."

      directory ->
        Bundlex.Output.info3 "Found Visual Studio in #{directory}"

        directory
    end
  end

  # Determines root directory of the Visual Studio.
  # Case when we have a root path passed via an environment variable.
  defp determine_visual_studio_root(directory) do
    Bundlex.Output.info3 "Using #{directory} passed via #{@directory_env} environment variable as Visual Studio root."

    directory
  end


  # Builds path to the vcvarsall.bat script that can be used to set environment
  # variables necessary to use Visual Studio compilers.
  defp build_vcvarsall_path(root) do
    Path.join([root, "VC", "vcvarsall.bat"])
  end
end
