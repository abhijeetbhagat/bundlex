defmodule Bundlex.Platform do

  @type platform_name_t :: atom

  @callback extra_otp_configure_options() :: [] | [String.t]
  @callback required_env_vars() :: [] | [String.t]
  @callback patches_to_apply() :: [] | [String.t]
  @callback toolchain_module() :: module


  @doc """
  Converts platform passed as options into platform atom valid for further use
  and module that contains platform-specific callbacks.

  First argument are keyword list, as returned from `OptionParser.parse/2` or
  `OptionParse.parse!/2`.

  It expects that `platform` option was passed to options.

  In case of success returns tuple `{platform, platform_module}`.

  Otherwise raises Mix error.
  """
  @spec get_platform_from_opts!(OptionParser.parsed) :: {platform_name_t, module}
  def get_platform_from_opts!(opts) do
    cond do
      platform = opts[:platform] ->
        platform_name = String.to_atom(platform)
        {platform_name, get_module!(platform_name)}

      true ->
        get_current_platform!()
    end
  end


  @doc """
  Detects current platform.

  In case of success returns tuple `{platform, platform_module}`.

  Otherwise raises Mix error.
  """
  @spec get_current_platform! :: {platform_name_t, module}
  def get_current_platform! do
    case :os.type do
      {:win32, _} ->
        {:ok, reg} = :win32reg.open([:read])
        :ok = :win32reg.change_key(reg, '\\hklm\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion')
        {:ok, build} = :win32reg.value(reg, 'BuildLabEx')

        platform_name = if build |> to_string |> String.contains?("amd64") do
          :windows64
        else
          :windows32
        end
        :ok = :win32reg.close(reg)

        {platform_name, get_module!(platform_name)}

      # TODO add detection for more platforms
    end
  end


  defp get_module!(platform_name) do
    case platform_name do
      :windows32 ->
        Bundlex.Platform.Windows32

      :windows64 ->
        Bundlex.Platform.Windows64

      :android_armv7 ->
        Bundlex.Platform.AndroidARMv7

      :unix64 ->
        Bundlex.Platform.Unix64

      _ ->
        Mix.raise "Cannot create bundle for unknown platform. Given #{platform_name} which is not known platform."
    end
  end
end
