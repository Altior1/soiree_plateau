defmodule SoireePlateau.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SoireePlateau.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    {:ok, game} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        complexity: 3,
        duration: 30,
        nb_players_max: 4,
        nb_players_min: 1
      })
      |> SoireePlateau.Games.create_game()

    game
  end
end
