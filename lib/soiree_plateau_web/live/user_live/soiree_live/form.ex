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
        <:subtitle>Use this form to manage soiree records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="soiree-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:date]} type="datetime-local" label="Date" />
        <.input field={@form[:home]} type="text" label="Home" />
        <.input field={@form[:capacity]} type="number" label="Capacity" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Soiree</.button>
          <.button navigate={return_path(@current_scope, @return_to, @soiree)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    soiree = Teuf.get_soiree!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Soiree")
    |> assign(:soiree, soiree)
    |> assign(:form, to_form(Teuf.change_soiree(socket.assigns.current_scope, soiree)))
  end

  defp apply_action(socket, :new, _params) do
    soiree = %Soiree{host: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Soiree")
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
    save_soiree(socket, socket.assigns.live_action, soiree_params)
  end

  defp save_soiree(socket, :edit, soiree_params) do
    case Teuf.update_soiree(socket.assigns.current_scope, socket.assigns.soiree, soiree_params) do
      {:ok, soiree} ->
        {:noreply,
         socket
         |> put_flash(:info, "Soiree updated successfully")
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
         |> put_flash(:info, "Soiree created successfully")
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
