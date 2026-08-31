defmodule HelloLiveView.Rgb do
  @moduledoc """
  Guards the reComputer R22xx RGB status LED.
  """
  use GenServer

  alias HelloLiveView.HW

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def set(server \\ __MODULE__, red?, green?, blue?) do
    GenServer.cast(server, {:set, red?, green?, blue?})
  end

  def off(server \\ __MODULE__), do: GenServer.cast(server, {:set, false, false, false})

  def get(server \\ __MODULE__), do: GenServer.call(server, :get)

  @impl GenServer
  def init(_opts) do
    {:ok, %{color: {false, false, false}}}
  end

  @impl GenServer
  def handle_cast({:set, red?, green?, blue?}, state) do
    HW.Rgb.set(:red, red?)
    HW.Rgb.set(:green, green?)
    HW.Rgb.set(:blue, blue?)
    {:noreply, %{state | color: {red?, green?, blue?}}}
  end

  @impl GenServer
  def handle_call(:get, _from, state), do: {:reply, state.color, state}
end
