defmodule MethodKnowWeb.UserLive.Registration do
  use MethodKnowWeb, :live_view

  alias MethodKnow.Accounts
  alias MethodKnow.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
            phx-blur="touch_field"
            phx-value-field="email"
          />

          <.input
            field={@form[:name]}
            type="text"
            label="Name"
            autocomplete="name"
            required
            phx-blur="touch_field"
            phx-value-field="name"
          />

          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="new-password"
            required
            phx-blur="touch_field"
            phx-value-field="password"
          />

          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm password"
            autocomplete="new-password"
            required
            phx-blur="touch_field"
            phx-value-field="password_confirmation"
          />

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
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
