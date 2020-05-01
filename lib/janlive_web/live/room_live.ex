defmodule JanliveWeb.RoomLive do
  use JanliveWeb, :live_view
  alias Phoenix.PubSub
  alias Janlive.GameServer

  def mount(_params, _session, socket) do
    state = %{
      room_name: nil,
      player_name: nil,
      result: "foo",
      players: []
    }

    {:ok, assign(socket, state)}
  end

  def handle_params(%{"room_name" => room_name}, _uri, socket) do
    GameServer.start_link(room_name)
    {:noreply, assign(socket, room_name: room_name)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("submit-room", %{"room_name" => room_name}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, __MODULE__, room_name))}
  end

  def handle_event("submit-player-name", %{"player_name" => player_name}, socket) do
    case GameServer.add_player(socket.assigns.room_name, player_name) do
      :ok ->
        PubSub.subscribe(Janlive.PubSub, topic(socket))
        PubSub.broadcast(Janlive.PubSub, topic(socket), "update-players")
        {:noreply, assign(socket, player_name: player_name)}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, reason)}
    end
  end

  def handle_event("choose-weapon", %{"weapon" => weapon}, socket) do
    room_name = socket.assigns.room_name
    player_name = socket.assigns.player_name
    result = case GameServer.choose_weapon(room_name, player_name, weapon) do
      {:winner, player} -> "#{player.name} won!"
      :draw -> "It's a draw."
      _ -> nil
    end

    PubSub.broadcast(Janlive.PubSub, topic(socket), "update-players")
    PubSub.broadcast(Janlive.PubSub, topic(socket), %{"new-result" => result})

    {:noreply, socket}
  end

  def handle_info("update-players", socket) do
    {:noreply, assign(socket, players: GameServer.get_players_list(socket.assigns.room_name))}
  end

  def handle_info(%{"new-result" => result}, socket) do
    {:noreply, assign(socket, result: result)}
  end

  def topic(socket) do
    "room:#{socket.assigns.room_name}"
  end
end
