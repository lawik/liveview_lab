defmodule HelloLiveView.Ups do
  @moduledoc """
  Guards the SuperCAP UPS module's LTC3350 charger monitor. Subscribers
  receive `{:ups, %{vin_mv: _, caps_mv: _}}` once a second.
  """
  use GenServer

  alias HelloLiveView.HW

  @poll_ms 1_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def subscribe(server \\ __MODULE__), do: GenServer.call(server, {:subscribe, self()})

  def unsubscribe(server \\ __MODULE__), do: GenServer.call(server, {:unsubscribe, self()})

  def latest(server \\ __MODULE__), do: GenServer.call(server, :latest)

  @impl GenServer
  def init(_opts) do
    state = %{i2c: nil, latest: nil, subs: %{}}

    case HW.Ups.open() do
      {:ok, i2c} ->
        Process.send_after(self(), :poll, @poll_ms)
        {:ok, %{state | i2c: i2c}}

      {:error, _} ->
        {:ok, state}
    end
  end

  @impl GenServer
  def handle_call({:subscribe, pid}, _from, state) do
    ref = Process.monitor(pid)
    {:reply, :ok, put_in(state.subs[pid], ref)}
  end

  def handle_call({:unsubscribe, pid}, _from, state) do
    {ref, subs} = Map.pop(state.subs, pid)
    if ref, do: Process.demonitor(ref, [:flush])
    {:reply, :ok, %{state | subs: subs}}
  end

  def handle_call(:latest, _from, state), do: {:reply, state.latest, state}

  @impl GenServer
  def handle_info(:poll, state) do
    state =
      case HW.Ups.read(state.i2c) do
        {:ok, sample} ->
          Enum.each(state.subs, fn {pid, _ref} -> send(pid, {:ups, sample}) end)
          %{state | latest: sample}

        {:error, _} ->
          state
      end

    Process.send_after(self(), :poll, @poll_ms)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | subs: Map.delete(state.subs, pid)}}
  end
end
