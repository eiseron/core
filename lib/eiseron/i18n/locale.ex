defmodule Eiseron.I18n.Locale do
  @doc """
  Returns the list of supported locales from the configured Gettext backend.
  Configure via:
      config :eiseron_core, Eiseron.I18n.Locale,
        gettext_backend: MyAppWeb.Gettext,
        default_locale: "pt_BR"
  """
  def supported do
    config() |> Keyword.fetch!(:gettext_backend) |> Gettext.known_locales()
  end

  def default do
    config() |> Keyword.fetch!(:default_locale)
  end

  def valid?(value) when is_binary(value), do: value in supported()
  def valid?(_), do: false

  def parse_accept_language(header) when is_binary(header) do
    header
    |> String.split(",")
    |> Enum.map(&parse_entry/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn {_locale, q} -> q end, :desc)
    |> Enum.find_value(fn {locale, _q} -> if valid?(locale), do: locale end)
  end

  def parse_accept_language(_), do: nil

  defp config do
    Application.get_env(:eiseron_core, __MODULE__, [])
  end

  defp parse_entry(raw) do
    case String.split(raw, ";", parts: 2) |> Enum.map(&String.trim/1) do
      [tag] -> build_entry(tag, 1.0)
      [tag, params] -> build_entry(tag, extract_quality(params))
      _ -> nil
    end
  end

  defp build_entry("", _q), do: nil
  defp build_entry(tag, q), do: {normalize_tag(tag), q}

  defp normalize_tag(tag) do
    case String.split(tag, ["-", "_"], parts: 2) do
      [lang] -> String.downcase(lang)
      [lang, region] -> String.downcase(lang) <> "_" <> String.upcase(region)
    end
  end

  defp extract_quality(params) do
    params
    |> String.split(";")
    |> Enum.find_value(1.0, &quality_from_param/1)
  end

  defp quality_from_param(param) do
    case param |> String.trim() |> String.split("=", parts: 2) do
      ["q", value] ->
        case value |> String.trim() |> Float.parse() do
          {q, _} -> q
          :error -> 1.0
        end

      _ ->
        nil
    end
  end
end
