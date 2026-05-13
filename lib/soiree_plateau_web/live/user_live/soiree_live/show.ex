defmodule SoireePlateauWeb.SoireeLive.Show do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Teuf

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Soirée #{@soiree.id}
        <:subtitle>Fiche de la soirée depuis la base de données.</:subtitle>
        <:actions>
          <.button navigate={~p"/users/soirees"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/users/soirees/#{@soiree}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Modifier la soirée
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Titre">{@soiree.title}</:item>
        <:item title="Date">{@soiree.date}</:item>
        <:item title="Lieu">{@soiree.home}</:item>
        <:item title="Capacité">{@soiree.capacity}</:item>
      </.list>

      <section class="mt-10">
        <h2 class="text-lg font-semibold mb-3">Invités &amp; réponses</h2>
        <%= if @invitations == [] do %>
          <p class="text-sm text-base-content/70">
            Aucun invité pour le moment. Modifie la soirée pour en ajouter.
          </p>
        <% else %>
          <table id="rsvp-table" class="w-full text-sm">
            <thead class="text-left text-base-content/70">
              <tr>
                <th class="py-2">Invité</th>
                <th class="py-2">Statut</th>
                <th class="py-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={inv <- @invitations} id={"rsvp-#{inv.id}"} class="border-t">
                <td class="py-2">
                  {inv.user.email}
                  <span :if={inv.user_id == @soiree.host} class="ml-1 text-xs text-base-content/60">
                    (hôte)
                  </span>
                </td>
                <td class="py-2">
                  <span class={[
                    "inline-block rounded-full px-2 py-0.5 text-xs",
                    status_badge(inv.status)
                  ]}>
                    {status_label(inv.status)}
                  </span>
                </td>
                <td class="py-2 text-right">
                  <.link
                    :if={inv.user_id != @soiree.host}
                    phx-click="remove_invitation"
                    phx-value-id={inv.id}
                    data-confirm="Retirer cet invité ?"
                    class="text-error hover:underline"
                  >
                    Retirer
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
        <% end %>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    soiree = Teuf.get_soiree!(socket.assigns.current_scope, id)

    if connected?(socket) do
      Teuf.subscribe_soirees(socket.assigns.current_scope)
      Teuf.subscribe_soiree_invitations(soiree.id)
    end

    {:ok,
     socket
     |> assign(:page_title, "Détails de la soirée")
     |> assign(:soiree, soiree)
     |> assign(
       :invitations,
       Teuf.list_invitations_for_soiree(socket.assigns.current_scope, soiree)
     )}
  end

  @impl true
  def handle_event("remove_invitation", %{"id" => invitation_id}, socket) do
    soiree = socket.assigns.soiree

    invitation =
      Enum.find(socket.assigns.invitations, fn inv ->
        to_string(inv.id) == to_string(invitation_id)
      end)

    cond do
      is_nil(invitation) ->
        {:noreply, put_flash(socket, :error, "Invitation introuvable.")}

      invitation.user_id == soiree.host ->
        {:noreply, put_flash(socket, :error, "L'hôte ne peut pas être retiré.")}

      true ->
        {:ok, _} = Teuf.remove_invitation(socket.assigns.current_scope, invitation)

        {:noreply,
         socket
         |> put_flash(:info, "Invité retiré.")
         |> assign(
           :invitations,
           Teuf.list_invitations_for_soiree(socket.assigns.current_scope, soiree)
         )}
    end
  end

  @impl true
  def handle_info(
        {:updated, %SoireePlateau.Teuf.Soiree{id: id} = soiree},
        %{assigns: %{soiree: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :soiree, soiree)}
  end

  def handle_info(
        {:deleted, %SoireePlateau.Teuf.Soiree{id: id}},
        %{assigns: %{soiree: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "La soirée a été supprimée.")
     |> push_navigate(to: ~p"/users/soirees")}
  end

  def handle_info({type, %SoireePlateau.Teuf.Soiree{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  def handle_info({invitation_event, %SoireePlateau.Teuf.Invitation{}}, socket)
      when invitation_event in [:invitation_created, :invitation_updated, :invitation_deleted] do
    soiree = socket.assigns.soiree

    {:noreply,
     assign(
       socket,
       :invitations,
       Teuf.list_invitations_for_soiree(socket.assigns.current_scope, soiree)
     )}
  end

  defp status_label(:pending), do: "En attente"
  defp status_label(:yes), do: "Oui"
  defp status_label(:no), do: "Non"
  defp status_label(:maybe), do: "Peut-être"

  defp status_badge(:pending), do: "bg-gray-200 text-gray-800"
  defp status_badge(:yes), do: "bg-green-200 text-green-800"
  defp status_badge(:no), do: "bg-red-200 text-red-800"
  defp status_badge(:maybe), do: "bg-yellow-200 text-yellow-800"
end
