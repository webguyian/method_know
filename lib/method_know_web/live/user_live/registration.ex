defmodule MethodKnowWeb.UserLive.Registration do
  use MethodKnowWeb, :live_view

  alias MethodKnow.Accounts
  alias MethodKnow.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-full flex-col justify-center py-6 sm:px-6 lg:px-8">
        <div class="sm:mx-auto sm:w-full sm:max-w-lg text-center mb-8">
          <div class="mx-auto size-16 rounded-full bg-black text-white flex items-center justify-center mb-4">
            <Lucide.book_marked class="size-9" />
          </div>
          <h1 class="text-3xl font-semibold text-base-content leading-9">
            Join Method Know
          </h1>
          <p class="mt-2 text-xl text-base-content/70 leading-7">
            Share and discover valuable learning resources
          </p>
        </div>

        <div class="sm:mx-auto sm:w-full sm:max-w-lg">
          <div class="bg-base-100 p-4 shadow-xl shadow-base-content/5 rounded-2xl border border-base-300">
            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              class="space-y-3"
            >
              <h2 class="text-lg text-base-content leading-7">
                Create Account
              </h2>

              <.input
                field={@form[:name]}
                type="text"
                label="Full Name"
                autocomplete="name"
                required
                phx-blur="touch_field"
                phx-mounted={JS.focus()}
                phx-value-field="name"
                placeholder="Enter your full name"
              />

              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
                phx-blur="touch_field"
                phx-value-field="email"
                placeholder="Enter your email"
              />

              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="new-password"
                required
                phx-blur="touch_field"
                phx-value-field="password"
                placeholder="Create a password (min. 8 characters)"
              />

              <.input
                field={@form[:password_confirmation]}
                type="password"
                label="Confirm Password"
                autocomplete="new-password"
                required
                phx-blur="touch_field"
                phx-value-field="password_confirmation"
                placeholder="Confirm your password"
              />

              <div class="pt-2">
                <.button
                  phx-disable-with="Signing Up..."
                  class="btn btn-primary w-full text-sm"
                >
                  Sign Up
                </.button>
              </div>

              <p class="text-sm text-base-content/70 text-center">
                Already have an account?
                <.link navigate={~p"/users/log-in"} class="text-primary underline underline-offset-3">
                  Log in
                </.link>
              </p>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: MethodKnowWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:ok,
     socket
     |> assign(touched_fields: MapSet.new())
     |> assign(hide_navbar: true)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    # Mark all fields as touched on submit
    touched_fields = MapSet.new([:email, :name, :password, :password_confirmation])

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Generate a short-lived, one-time registration token for auto-login
        # This is more secure than passing a session token in the URL
        {:ok, token} = Accounts.generate_registration_login_token(user)

        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully!")
         |> push_navigate(to: ~p"/users/confirm-registration/#{token}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(touched_fields: touched_fields)
         |> assign_form(changeset)}
    end
  end

  def handle_event("touch_field", %{"field" => field}, socket) do
    field_atom = String.to_existing_atom(field)
    touched_fields = MapSet.put(socket.assigns.touched_fields, field_atom)

    {:noreply, assign(socket, touched_fields: touched_fields)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params, validate_unique: false)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    # Only show errors for fields that have been touched
    touched = socket.assigns.touched_fields

    # Filter errors to only include touched fields
    filtered_errors =
      changeset.errors
      |> Enum.filter(fn {field, _} -> MapSet.member?(touched, field) end)

    filtered_changeset = %{changeset | errors: filtered_errors}
    form = to_form(filtered_changeset, as: "user")

    assign(socket, form: form)
  end
end
