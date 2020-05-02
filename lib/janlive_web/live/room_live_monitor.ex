defmodule JanliveWeb.RoomLiveMonitor do
  use GenServer

  alias Phoenix.PubSub
  alias Janlive.GameServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :room_monitor)
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def monitor(pid, room, player) do
    GenServer.call(:room_monitor, {:monitor, pid, room, player})
  end

  def handle_call({:monitor, pid, room, player}, _, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {room, player})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    {{room, player}, new_views} = Map.pop(state.views, pid)
    GameServer.remove_player(room, player)
    PubSub.broadcast(Janlive.PubSub, "room:#{room}", "update-players")
    {:noreply, %{state | views: new_views}}
  end
end
