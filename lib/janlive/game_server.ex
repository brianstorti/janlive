defmodule Janlive.GameServer do
  @moduledoc """
  This module is responsible for managing a single game room.

  Its state is the list of players in this single game, with their scores and weapons.
  """

  use GenServer

  def start_link(room_id) do
    GenServer.start_link(__MODULE__,
                         [],
                         name: via_tuple(room_id))
  end


  defp via_tuple(room_id) do
    {:via, Registry, {Janlive.GameRegistry, room_id}}
  end

  @doc """
  Adds a player to the game with the given `player_name`.
  Players start with a `score` of 0 and an empty `weapon`

  Returns `:ok` or `{:error, message}`
  """
  def add_player(room_id, player_name) do
    case GenServer.call(via_tuple(room_id), {:add_player, player_name}) do
      :ok -> :ok
      :duplicate -> {:error, "There is already a '#{player_name}' in this room"}
      :empty -> {:error, "The name must be filled in"}
      :game_already_started -> {:error, "There's a game being played in this room already"}
    end
  end

  def remove_player(room_id, player_name) do
    GenServer.cast(via_tuple(room_id), {:remove_player, player_name})
  end

  @doc """
  Finds the user with the given `player_name` and sets its `weapon`.
  If all the users have played already, it will try to find the winner,
  and can return `{:winner, player_name}` or simply `:draw`.
  """
  def choose_weapon(room_id, player_name, weapon) do
    case GenServer.call(via_tuple(room_id), {:choose_weapon, player_name, weapon}) do
      {:winner, winner} ->
        GenServer.cast(via_tuple(room_id), {:increment_winner_score, winner})
        {:winner, winner}
      other_result -> other_result
    end
  end

  @doc """
  Resets the game by settings all the users' weapons to empty String.
  """
  def reset_game(room_id) do
    GenServer.cast(via_tuple(room_id), :reset_game)
  end

  @doc """
  Returns the list of all the players that are in this game, with their
  score and weapon.
  """
  def get_players_list(room_id) do
    GenServer.call(via_tuple(room_id), :players_list)
  end

  ## SERVER

  def init(_) do
    {:ok, []}
  end

  def handle_cast({:remove_player, player_name}, state) do
    new_state = Enum.filter(state, &(&1.name != player_name))

    if Enum.empty?(new_state) do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end

  def handle_cast(:reset_game, state) do
    {:noreply, Enum.map(state, &(%{&1 | weapon: ""}))}
  end

  def handle_cast({:increment_winner_score, winner}, state) do
    new_state = Enum.map(state, fn player ->
      if player.name == winner.name do
        %{player | score: player.score + 1}
      else
        player
      end
    end)

    {:noreply, new_state}
  end

  def handle_call({:add_player, player_name}, _from, state) do
    cond do
      Enum.any?(state, &(String.downcase(&1.name) == String.downcase(player_name))) ->
        {:reply, :duplicate, state}

      String.trim(player_name) == "" ->
        {:reply, :empty, state}

      Enum.any?(state, &(&1.weapon != "")) ->
        {:reply, :game_already_started, state}

      true ->
        {:reply, :ok, [%{name: player_name, weapon: "", score: 0} | state]}
    end
  end

  def handle_call(:players_list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:choose_weapon, player_name, weapon}, _from, state) do
    new_state = Enum.map(state, fn player ->
      if player.name == player_name do
        %{player | weapon: weapon}
      else
        player
      end
    end)

    {:reply, answer_for(new_state), new_state}
  end

  defp answer_for(players) do
    all_players_moved = players |> Enum.map(&(&1.weapon)) |> Enum.all?(&(&1 != ""))
    if all_players_moved, do: find_winner(players)
  end

  defp find_winner(players) do
    is_winner = fn current -> beat_all?(current.weapon, List.delete(players, current)) end
    winner = Enum.find(players, is_winner)

    if winner, do: {:winner, winner}, else: :draw
  end

  # Returns `true` if given `weapon` beats the weapons of all the other `players`.
  # This is useful when we want to support more than 2 players, meaning that for
  # any number of player, one is the winner if its weapon beats all the others'.
  defp beat_all?(weapon, players) do
    this_beat_that = %{"rock" => "scissors",
                       "paper" => "rock",
                       "scissors" => "paper"}

    weapon_that_i_beat = Map.get(this_beat_that, weapon)

    Enum.all?(players, &(&1.weapon == weapon_that_i_beat))
  end
end
