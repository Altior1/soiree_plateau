defmodule SoireePlateauWeb.UserLive.Confirmation do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>Bienvenue {@user.email}</.header>
        </div>

        <.form
          :if={!@user.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/users/log-in?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirmation..."
            class="btn btn-primary w-full"
          >
            Confirmer et rester connecté
          </.button>
          <.button phx-disable-with="Confirmation..." class="btn btn-primary btn-soft w-full mt-2">
            Confirmer et se connecter uniquement cette fois
          </.button>
        </.form>

        <.form
          :if={@user.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/users/log-in"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope do %>
            <.button phx-disable-with="Connexion..." class="btn btn-primary w-full">
              Se connecter
            </.button>
          <% else %>
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Connexion..."
              class="btn btn-primary w-full"
            >
              Rester connecté sur cet appareil
            </.button>
            <.button phx-disable-with="Connexion..." class="btn btn-primary btn-soft w-full mt-2">
              Se connecter uniquement cette fois
            </.button>
          <% end %>
        </.form>

        <p :if={!@user.confirmed_at} class="alert alert-outline mt-8">
          Astuce : si vous préférez les mots de passe, vous pouvez les activer dans les paramètres utilisateur.
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Le lien magique est invalide ou a expiré.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
