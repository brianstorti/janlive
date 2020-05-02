defmodule Janlive.GameSupervisor do
  use Supervisor

  @name Janlive.GameSupervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_game(room_id) do
    Supervisor.start_child(@name, [room_id])
  end

  def init(:ok) do
    children = [
      worker(Janlive.GameServer, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
