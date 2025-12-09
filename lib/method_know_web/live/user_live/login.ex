defmodule MethodKnowWeb.UserLive.Login do
  use MethodKnowWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-full flex-col justify-center py-6 sm:px-6 lg:px-8">
        <div class="sm:mx-auto sm:w-full sm:max-w-md text-center mb-8">
          <div class="mx-auto size-16 rounded-full bg-black text-white flex items-center justify-center mb-4">
            <Lucide.book_marked class="size-9" />
          </div>
          <h1 class="text-3xl font-semibold text-base-content leading-9">
            <%= if @current_scope do %>
              Verify your identity
            <% else %>
              Welcome Back
            <% end %>
          </h1>
          <p class="mt-2 text-xl text-base-content/70 leading-7">
            <%= if @current_scope do %>
              You need to reauthenticate to perform sensitive actions.
            <% else %>
              Share and discover valuable learning resources
            <% end %>
          </p>
        </div>

        <div class="sm:mx-auto sm:w-full sm:max-w-md">
          <div class="bg-base-100 p-4 shadow-xl shadow-base-content/5 rounded-2xl border border-base-300">
            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-3"
            >
              <h2 class="text-lg text-base-content leading-7">
                Log in
              </h2>

              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="email"
                required
                phx-mounted={JS.focus()}
                placeholder="Enter your email"
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                placeholder="Enter your password"
              />

              <div class="pt-2 space-y-2">
                <.button
                  class="btn btn-primary w-full text-sm"
                  name={@form[:remember_me].name}
                  value="false"
                >
                  Login
                </.button>
              </div>

              <%= if !@current_scope do %>
                <p class="text-sm text-base-content/70 text-center pt-2">
                  Don't have an account? <.link
                    navigate={~p"/users/register"}
                    class="text-primary underline underline-offset-3"
                    phx-no-format
                  >Sign up</.link>
                </p>
              <% end %>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
