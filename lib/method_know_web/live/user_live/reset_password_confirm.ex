defmodule MethodKnowWeb.UserLive.ResetPasswordConfirm do
  use MethodKnowWeb, :live_view
  alias MethodKnow.Accounts

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      assign(socket,
        token: token,
        form: to_form(%{"password" => ""}, as: "user"),
        error: nil,
        success: false
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-full flex-col justify-center py-6 sm:px-6 lg:px-8">
        <div class="sm:mx-auto sm:w-full sm:max-w-md text-center mb-8">
          <h1 class="text-3xl font-semibold text-base-content leading-9">Set a new password</h1>
        </div>
        <div class="sm:mx-auto sm:w-full sm:max-w-md">
          <div class="bg-base-100 p-4 shadow-xl shadow-base-content/5 rounded-2xl border border-base-300">
            <%= if @success do %>
              <div class="text-success text-center">
                Your password has been reset. You may now <.link
                  navigate={~p"/users/log-in"}
                  class="text-primary underline"
                >log in</.link>.
              </div>
            <% else %>
              <%= if @error do %>
                <div class="text-error text-center mb-2">{@error}</div>
              <% end %>
              <.form for={@form} id="reset-password-confirm-form" phx-submit="reset_password">
                <.input
                  field={@form[:password]}
                  type="password"
                  label="New password"
                  autocomplete="new-password"
                  required
                  placeholder="Enter new password"
                />
                <div class="pt-2">
                  <.button class="btn btn-primary w-full text-sm">Reset password</.button>
                </div>
              </.form>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("reset_password", %{"user" => %{"password" => password}}, socket) do
    case Accounts.reset_user_password_by_token(socket.assigns.token, %{password: password}) do
      {:ok, _user} ->
        {:noreply, assign(socket, success: true, error: nil)}

      {:error, :invalid_token} ->
        {:noreply, assign(socket, error: "Invalid or expired token.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        error =
          changeset.errors
          |> Keyword.get(:password, {"Invalid password", []})
          |> elem(0)

        {:noreply, assign(socket, error: error)}
    end
  end
end
