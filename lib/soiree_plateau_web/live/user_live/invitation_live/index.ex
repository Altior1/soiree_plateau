defmodule SoireePlateauWeb.InvitationLive.Index do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Teuf

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Mes invitations
        <:subtitle>Réponds aux soirées auxquelles tu es invité.</:subtitle>
      </.header>

      <div id="invitations" class="space-y-4">
        <%= if @invitations == [] do %>
          <p class="text-sm text-base-content/70">
            Aucune invitation pour le moment.
          </p>
        <% else %>
          <article
            :for={inv <- @invitations}
            id={"invitation-#{inv.id}"}
            class="rounded-lg border bg-white/60 p-4 shadow-sm"
          >
            <header class="flex items-start justify-between gap-4">
              <div>
                <h3 class="text-base font-semibold">{inv.soiree.title}</h3>
                <p class="text-sm text-base-content/70">
                  {format_date(inv.soiree.date)} · {inv.soiree.home}
                </p>
                <p class="text-xs text-base-content/60 mt-1">
                  Hôte : {inv.soiree.user.email}
                </p>
              </div>
              <span class={[
                "inline-block self-start rounded-full px-2 py-0.5 text-xs",
                status_badge(inv.status)
              ]}>
                {status_label(inv.status)}
              </span>
            </header>

            <footer class="mt-4 flex flex-wrap gap-2">
              <button
                type="button"
                phx-click="respond"
                phx-value-id={inv.id}
                phx-value-status="yes"
                class={[
                  "btn",
                  if(inv.status == :yes, do: "btn-primary", else: "btn-primary btn-soft")
                ]}
              >
                Oui
              </button>
              <button
                type="button"
                phx-click="respond"
                phx-value-id={inv.id}
                phx-value-status="maybe"
                class={[
                  "btn",
                  if(inv.status == :maybe, do: "btn-primary", else: "btn-primary btn-soft")
                ]}
              >
                Peut-être
              </button>
              <button
                type="button"
                phx-click="respond"
                phx-value-id={inv.id}
                phx-value-status="no"
                class={["btn", if(inv.status == :no, do: "btn-primary", else: "btn-primary btn-soft")]}
              >
                Non
              </button>
            </footer>
          </article>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Teuf.subscribe_user_invitations(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Mes invitations")
     |> assign(:invitations, Teuf.list_invitations_for_user(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("respond", %{"id" => id, "status" => status}, socket) do
    invitation = Teuf.get_user_invitation!(socket.assigns.current_scope, id)
    status_atom = String.to_existing_atom(status)

    case Teuf.respond_to_invitation(socket.assigns.current_scope, invitation, status_atom) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Réponse enregistrée.")
         |> assign(:invitations, Teuf.list_invitations_for_user(socket.assigns.current_scope))}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Impossible d'enregistrer la réponse.")}
    end
  end

  @impl true
  def handle_info({event, %SoireePlateau.Teuf.Invitation{}}, socket)
      when event in [:invitation_created, :invitation_updated, :invitation_deleted] do
    {:noreply,
     assign(socket, :invitations, Teuf.list_invitations_for_user(socket.assigns.current_scope))}
  end

  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d/%m/%Y %H:%M")
  defp format_date(other), do: to_string(other)

  defp status_label(:pending), do: "En attente"
  defp status_label(:yes), do: "Oui"
  defp status_label(:no), do: "Non"
  defp status_label(:maybe), do: "Peut-être"

  defp status_badge(:pending), do: "bg-gray-200 text-gray-800"
  defp status_badge(:yes), do: "bg-green-200 text-green-800"
  defp status_badge(:no), do: "bg-red-200 text-red-800"
  defp status_badge(:maybe), do: "bg-yellow-200 text-yellow-800"
end
