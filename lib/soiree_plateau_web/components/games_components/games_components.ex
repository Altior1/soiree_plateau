defmodule SoireePlateauWeb.GamesComponents.GamesComponents do
  @moduledoc """
  Ce module sert à regrouper tous les composants liés aux jeux de société.
  On va y trouver le composant pour la liste des jeux (sous forme de petite card)
  et le composant pour les détails d'un jeu (avec une description, les règles, etc)
  """
  use Phoenix.Component

  attr :game, :map, required: true, doc: "La carte de jeu à afficher"
  def game_card(assigns) do
    ~H"""
    <div class="game-card bg-white rounded-lg shadow-md p-4 ">
      <div :if={@game.image_url != ""} class="game-card-image-container mb-4">
        <img src ={@game.image_url} alt={"Image de #{@game.title}"} class="game-card-image mb-4 rounded" />
      </div>
      <h3 class="game-card-title">{@game.title}</h3>
      <p class="game-card-description">{@game.description}</p>
    </div>
    """
  end
end
