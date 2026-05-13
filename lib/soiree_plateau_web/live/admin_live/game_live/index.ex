defmodule SoireePlateauWeb.GameLive.Index do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Games

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Liste des jeux
        <:actions>
          <.button variant="primary" navigate={~p"/admin/games/new"}>
            <.icon name="hero-plus" /> Nouveau jeu
          </.button>
        </:actions>
      </.header>

      <.table
        id="games"
        rows={@streams.games}
        row_click={fn {_id, game} -> JS.navigate(~p"/admin/games/#{game}") end}
      >
        <:col :let={{_id, game}} label="Nom">{game.name}</:col>
        <:col :let={{_id, game}} label="Description">{game.description}</:col>
        <:action :let={{_id, game}}>
          <div class="sr-only">
            <.link navigate={~p"/admin/games/#{game}"}>Voir</.link>
          </div>
          <.link navigate={~p"/admin/games/#{game}/edit"}>Modifier</.link>
        </:action>
        <:action :let={{id, game}}>
          <.link
            phx-click={JS.push("delete", value: %{id: game.id}) |> hide("##{id}")}
            data-confirm="Confirmer la suppression ?"
          >
            Supprimer
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Liste des jeux")
     |> stream(:games, list_games())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    game = Games.get_game!(id)
    {:ok, _} = Games.delete_game(game)

    {:noreply, stream_delete(socket, :games, game)}
  end

  defp list_games() do
    Games.list_games()
  end
end
