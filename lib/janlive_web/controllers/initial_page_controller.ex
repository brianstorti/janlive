defmodule InitialPageController do
  use JanliveWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end
end
