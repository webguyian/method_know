defmodule MethodKnowWeb.UserLive.ResetPassword do
  use MethodKnowWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-full flex-col justify-center py-6 sm:px-6 lg:px-8">
        <div class="sm:mx-auto sm:w-full sm:max-w-lg text-center mb-8">
          <h1 class="text-3xl font-semibold text-base-content leading-9">Reset your password</h1>
          <p class="mt-2 text-xl text-base-content/70 leading-7">
            Enter your email to receive a password reset link.
          </p>
        </div>
        <div class="sm:mx-auto sm:w-full sm:max-w-lg">
          <div class="bg-base-100 p-4 shadow-xl shadow-base-content/5 rounded-2xl border border-base-300">
            <.form for={@form} id="reset-password-form" phx-submit="send_reset">
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="email"
                required
                placeholder="Enter your email"
              />
              <div class="pt-2">
                <.button class="btn btn-primary w-full text-sm">Send reset link</.button>
              </div>
            </.form>
            <%= if @sent do %>
              <div class="mt-4 text-success text-center">
                If your email is in our system, you will receive a reset link shortly.
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => ""}, as: "user")
    {:ok, assign(socket, form: form, sent: false)}
  end

  @impl true
  def handle_event("send_reset", %{"user" => %{"email" => email}}, socket) do
    if user = MethodKnow.Accounts.get_user_by_email(email) do
      MethodKnow.Accounts.deliver_user_reset_password_instructions(user, fn token ->
        Phoenix.VerifiedRoutes.url(
          MethodKnowWeb.Endpoint,
          MethodKnowWeb.Router,
          ~p"/users/reset-password/#{token}"
        )
      end)
    end

    # Always show success message, even if user not found, for privacy
    {:noreply, assign(socket, sent: true)}
  end
end
