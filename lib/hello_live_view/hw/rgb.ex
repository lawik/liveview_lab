defmodule HelloLiveView.HW.Rgb do
  @moduledoc false

  @leds %{red: "led-red", green: "led-green", blue: "led-blue"}

  def present? do
    Enum.all?(@leds, fn {_, name} -> File.dir?("/sys/class/leds/#{name}") end)
  end

  def set(color, on?) do
    File.write("/sys/class/leds/#{@leds[color]}/brightness", if(on?, do: "1", else: "0"))
  end
end
