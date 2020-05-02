defmodule JanliveWeb.RoomLive do
  use JanliveWeb, :live_view

  alias Phoenix.PubSub
  alias Janlive.GameServer
  alias JanliveWeb.RoomLiveMonitor

  def mount(_params, _session, socket) do
    state = %{
      room: nil,
      player: nil,
      result: nil,
      players: []
    }

    {:ok, assign(socket, state)}
  end

  def handle_params(%{"room" => room}, _uri, socket) do
    pid = GameServer.start_link(room)

    # PubSub.subscribe(Janlive.PubSub, topic(socket))
    # GameServer.add_player(room, "Brian")
    # GameServer.add_player(room, "Storti")
    # GameServer.choose_weapon(room, "Storti", "scissors")
    # GameServer.choose_weapon(room, "Brian", "scissors")
    # socket = assign(socket, player: "Brian", result: "Brian won!")
    # PubSub.broadcast(Janlive.PubSub, topic(socket), "update-players")

    {:noreply, assign(socket, room: room, pid: pid)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("submit-room", %{"room" => room}, socket) do
    if String.trim(room) == "" do
      {:noreply, put_flash(socket, :error, "Please enter a room name")}
    else
      {:noreply, push_redirect(socket, to: Routes.live_path(socket, __MODULE__, room))}
    end
  end

  def handle_event("submit-player-name", %{"player" => player}, socket) do
    room = socket.assigns.room
    case GameServer.add_player(room, player) do
      :ok ->
        RoomLiveMonitor.monitor(self(), room, player)
        PubSub.subscribe(Janlive.PubSub, topic(socket))
        PubSub.broadcast(Janlive.PubSub, topic(socket), "update-players")
        {:noreply, assign(socket, player: player)}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, reason)}
    end
  end

  def handle_event("choose-weapon", %{"weapon" => weapon}, socket) do
    room = socket.assigns.room
    player = socket.assigns.player

    result = case GameServer.choose_weapon(room, player, weapon) do
      {:winner, player} -> "#{player.name} won!"
      :draw -> "It's a draw."
      _ -> nil
    end

    PubSub.broadcast(Janlive.PubSub, topic(socket), "update-players")
    PubSub.broadcast(Janlive.PubSub, topic(socket), %{"new-result" => result})

    {:noreply, socket}
  end

  def handle_event("reset-game", _params, socket) do
    GameServer.reset_game(socket.assigns.room)
    PubSub.broadcast(Janlive.PubSub, topic(socket), "update-players")
    PubSub.broadcast(Janlive.PubSub, topic(socket), %{"new-result" => nil})
    {:noreply, socket}
  end

  def handle_info("update-players", socket) do
    {:noreply, assign(socket, players: GameServer.get_players_list(socket.assigns.room))}
  end

  def handle_info(%{"new-result" => result}, socket) do
    {:noreply, assign(socket, result: result)}
  end

  defp topic(socket) do
    "room:#{socket.assigns.room}"
  end
end
