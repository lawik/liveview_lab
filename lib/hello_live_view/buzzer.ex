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
    {:ok, %{io: nil, timer: nil}, {:continue, :open}}
  end

  @impl GenServer
  def handle_continue(:open, state), do: {:noreply, try_open(state)}

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

  def handle_info(:open, state), do: {:noreply, try_open(state)}

  # The beeper input device appears ~10s into boot, after this process
  # starts, so keep retrying until it shows up.
  defp try_open(state) do
    case HW.Buzzer.open() do
      {:ok, io} ->
        %{state | io: io}

      {:error, _} ->
        Process.send_after(self(), :open, 2_000)
        state
    end
  end
end
