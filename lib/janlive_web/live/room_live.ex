defmodule JanliveWeb.RoomLive do
  use JanliveWeb, :live_view

  def mount(_params, _session, socket) do
    state = %{
      room_name: nil,
      player_name: nil,
    }

    {:ok, assign(socket, state)}
  end

  def handle_params(%{"room_name" => room_name}, _uri, socket) do
    socket = assign(socket, room_name: room_name)
    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("submit-room", %{"room_name" => room_name}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, __MODULE__, room_name))}
  end

  def handle_event("submit-player-name", %{"player_name" => player_name}, socket) do
    {:noreply, assign(socket, player_name: player_name)}
  end
end
