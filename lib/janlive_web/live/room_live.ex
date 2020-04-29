defmodule JanliveWeb.RoomLive do
  use JanliveWeb, :live_view

  def mount(%{"name" => name}, _session, socket) do
    {:ok, assign(socket, query: "", results: %{})}
  end

  def handle_params(%{"name" => name}, _uri, socket) do
    IO.puts "*****************************"
    IO.puts name
    {:noreply, socket}
  end
end
