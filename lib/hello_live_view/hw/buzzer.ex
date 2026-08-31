defmodule HelloLiveView.HW.Buzzer do
  @moduledoc false

  @ev_snd 0x12
  @snd_bell 0x01

  # The buzzer GPIO is owned by the kernel's gpio-beeper driver, so it is
  # driven through its input device with EV_SND events, not Circuits.GPIO.
  def open do
    with {:ok, events} <- File.ls("/sys/class/input") do
      events
      |> Enum.filter(&String.starts_with?(&1, "event"))
      |> Enum.find_value({:error, :not_found}, fn event ->
        case File.read("/sys/class/input/#{event}/device/name") do
          {:ok, "beeper\n"} -> File.open("/dev/input/#{event}", [:binary, :write, :raw])
          _ -> nil
        end
      end)
    end
  end

  def bell(io, on?) do
    value = if on?, do: 1, else: 0
    IO.binwrite(io, <<0::128, @ev_snd::native-16, @snd_bell::native-16, value::native-32>>)
  end
end
