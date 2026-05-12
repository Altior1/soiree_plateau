defmodule SoireePlateauWeb.UserLive.Game.ListGames do
  use SoireePlateauWeb, :live_view

  alias SoireePlateauWeb.GamesComponents.GamesComponents

  def mount(_params, _session, socket) do
    list_games = SoireePlateau.Games.list_games()

    {:ok, assign(socket, list_games: list_games)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-2xl font-bold mb-4">Liste des jeux de société</h1>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for game <- @list_games do %>
          <GamesComponents.game_card game={game} navigate={~p"/users/games/#{game.id}"} />
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
