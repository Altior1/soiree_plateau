defmodule SoireePlateauWeb.SoireeLive.Form do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Teuf
  alias SoireePlateau.Teuf.Soiree

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Utilisez ce formulaire pour gérer les soirées dans la base de données.</:subtitle>
      </.header>

      <.form for={@form} id="soiree-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Titre" />
        <.input field={@form[:date]} type="datetime-local" label="Date" />
        <.input field={@form[:home]} type="text" label="Lieu" />
        <.input field={@form[:capacity]} type="number" label="Capacité" />
        <.input field={@form[:game_id]} type="select" label="Jeu" options={@options_games} />
        <footer>
          <.button phx-disable-with="Enregistrement..." variant="primary">Enregistrer la soirée</.button>
          <.button navigate={return_path(@current_scope, @return_to, @soiree)}>Annuler</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    options_games = SoireePlateau.Games.list_games_for_form()

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:options_games, options_games)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    soiree = Teuf.get_soiree!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Modifier la soirée")
    |> assign(:soiree, soiree)
    |> assign(:form, to_form(Teuf.change_soiree(socket.assigns.current_scope, soiree)))
  end

  defp apply_action(socket, :new, _params) do
    soiree = %Soiree{host: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "Nouvelle soirée")
    |> assign(:soiree, soiree)
    |> assign(:form, to_form(Teuf.change_soiree(socket.assigns.current_scope, soiree)))
  end

  @impl true
  def handle_event("validate", %{"soiree" => soiree_params}, socket) do
    changeset =
      Teuf.change_soiree(socket.assigns.current_scope, socket.assigns.soiree, soiree_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"soiree" => soiree_params}, socket) do
    # on force ici le cast en int de game_id, pour ne pas le catch après ( le changeset sert à la validation aussi )
    soiree_params =
      Map.update(soiree_params, "game_id", nil, fn
        "" ->
          nil

        game_id when is_binary(game_id) ->
          case Integer.parse(game_id) do
            {int, _} -> int
            :error -> nil
          end

        game_id ->
          game_id
      end)

    save_soiree(socket, socket.assigns.live_action, soiree_params)
  end

  defp save_soiree(socket, :edit, soiree_params) do
    case Teuf.update_soiree(socket.assigns.current_scope, socket.assigns.soiree, soiree_params) do
      {:ok, soiree} ->
        {:noreply,
         socket
         |> put_flash(:info, "Soirée mise à jour avec succès")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, soiree)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_soiree(socket, :new, soiree_params) do
    case Teuf.create_soiree(socket.assigns.current_scope, soiree_params) do
      {:ok, soiree} ->
        {:noreply,
         socket
         |> put_flash(:info, "Soirée créée avec succès")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, soiree)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _soiree), do: ~p"/users/soirees"
  defp return_path(_scope, "show", soiree), do: ~p"/users/soirees/#{soiree}"
end
