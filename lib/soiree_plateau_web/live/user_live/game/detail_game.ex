defmodule SoireePlateauWeb.UserLive.Game.DetailGame do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Games
  alias SoireePlateauWeb.GamesComponents.GamesComponents

  def mount(%{"id" => id}, _session, socket) do
    case Games.get_game(id) do
      nil ->
        {:ok, assign(socket, game: nil, error: "Jeu non trouvé")}

      game ->
        {:ok, assign(socket, game: game, error: nil)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <GamesComponents.game_details game={@game} />
    </Layouts.app>
    """
  end
end
