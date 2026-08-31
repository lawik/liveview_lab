defmodule HelloLiveView.HW.Ups do
  @moduledoc false

  @bus "i2c-2"
  @addr 0x09
  @vin_reg 0x1B
  @cap_regs [0x20, 0x21, 0x22, 0x23]
  @vin_uv_per_lsb 2210
  @cap_uv_per_lsb 184

  def open, do: Circuits.I2C.open(@bus)

  def read(i2c) do
    with {:ok, vin} <- word(i2c, @vin_reg),
         {:ok, caps} <- cap_words(i2c) do
      {:ok,
       %{
         vin_mv: div(vin * @vin_uv_per_lsb, 1000),
         caps_mv: Enum.map(caps, &div(&1 * @cap_uv_per_lsb, 1000))
       }}
    end
  end

  defp cap_words(i2c) do
    Enum.reduce_while(@cap_regs, {:ok, []}, fn reg, {:ok, acc} ->
      case word(i2c, reg) do
        {:ok, value} -> {:cont, {:ok, acc ++ [value]}}
        error -> {:halt, error}
      end
    end)
  end

  defp word(i2c, reg) do
    case Circuits.I2C.write_read(i2c, @addr, <<reg>>, 2) do
      {:ok, <<lo, hi>>} -> {:ok, hi * 256 + lo}
      {:error, reason} -> {:error, reason}
    end
  end
end
