defmodule HelloLiveView.Buzzer do
  @moduledoc """
  Guards the reComputer R22xx buzzer.
  """
  use GenServer

  alias HelloLiveView.HW

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def beep(server \\ __MODULE__, duration_ms \\ 150) do
    GenServer.cast(server, {:beep, duration_ms})
  end

  def on(server \\ __MODULE__), do: GenServer.cast(server, {:set, true})

  def off(server \\ __MODULE__), do: GenServer.cast(server, {:set, false})

  @impl GenServer
  def init(_opts) do
    case HW.Buzzer.open() do
      {:ok, io} -> {:ok, %{io: io, timer: nil}}
      {:error, _} -> {:ok, %{io: nil, timer: nil}}
    end
  end

  @impl GenServer
  def handle_cast(_msg, %{io: nil} = state), do: {:noreply, state}

  def handle_cast({:beep, duration_ms}, state) do
    HW.Buzzer.bell(state.io, true)
    if state.timer, do: Process.cancel_timer(state.timer)
    {:noreply, %{state | timer: Process.send_after(self(), :off, duration_ms)}}
  end

  def handle_cast({:set, on?}, state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    HW.Buzzer.bell(state.io, on?)
    {:noreply, %{state | timer: nil}}
  end

  @impl GenServer
  def handle_info(:off, state) do
    HW.Buzzer.bell(state.io, false)
    {:noreply, %{state | timer: nil}}
  end
end
