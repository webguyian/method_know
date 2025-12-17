defmodule MethodKnowWeb.ResourceLive.FormDrawerTest do
  use MethodKnowWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias MethodKnow.Resources
  alias MethodKnow.Resources.Resource
  alias MethodKnowWeb.ResourceLive.FormDrawer

  defmodule TestLive do
    use MethodKnowWeb, :live_view

    def render(assigns) do
      ~H"""
      <.live_component
        module={FormDrawer}
        id="form-drawer"
        all_tags={@all_tags}
        current_user={@current_user}
        current_scope={@current_scope}
        title={@title}
        form_action={@form_action}
        resource={@resource}
        tags={@tags}
        form={@form}
        on_close="hide_form"
        from_drawer={@from_drawer}
      />
      """
    end

    def mount(_params, session, socket) do
      current_scope = session["current_scope"]
      resource = session["resource"] || %Resource{}
      changeset = Resources.change_resource(current_scope, resource, %{})

      {:ok,
       assign(socket,
         parent_pid: session["parent_pid"],
         all_tags: session["all_tags"] || [],
         current_user: session["current_user"],
         current_scope: current_scope,
         title: session["title"] || "Test Drawer",
         form_action: session["form_action"] || :show,
         resource: resource,
         tags: session["tags"] || [],
         form: to_form(changeset),
         from_drawer: session["from_drawer"] || false
       )}
    end

    def handle_info(msg, socket) do
      if pid = socket.assigns[:parent_pid] do
        send(pid, {:received, msg})
      end

      {:noreply, socket}
    end
  end

  setup do
    user = MethodKnow.AccountsFixtures.user_fixture()
    scope = MethodKnow.Accounts.Scope.for_user(user)
    # Ensure the resource has some tags for "show" mode tests
    resource =
      MethodKnow.ResourcesFixtures.resource_fixture(scope, %{user_id: user.id, tags: ["elixir"]})

    {:ok, user: user, scope: scope, resource: resource}
  end

  describe "rendering" do
    test "renders show mode with resource content", %{
      conn: conn,
      user: user,
      scope: scope,
      resource: resource
    } do
      {:ok, _view, html} =
        live_isolated(conn, TestLive,
          session: %{
            "parent_pid" => self(),
            "resource" => resource,
            "current_user" => user,
            "current_scope" => scope,
            "form_action" => :show,
            "title" => "Resource Details",
            "tags" => ["elixir"]
          }
        )

      assert html =~ "Resource Details"
      assert html =~ resource.description
      assert html =~ "elixir"
      # Edit and Delete buttons
      assert html =~ "title=\"Edit\""
      assert html =~ "title=\"Delete\""
    end

    test "renders edit mode with form and tags", %{
      conn: conn,
      user: user,
      scope: scope,
      resource: resource
    } do
      {:ok, _view, html} =
        live_isolated(conn, TestLive,
          session: %{
            "parent_pid" => self(),
            "resource" => resource,
            "current_user" => user,
            "current_scope" => scope,
            "form_action" => :edit,
            "title" => "Edit Resource",
            "all_tags" => ["elixir", "phoenix"],
            "tags" => ["elixir"]
          }
        )

      assert html =~ "Edit Resource"
      assert html =~ "id=\"resource-form\""
      assert html =~ "Tags"
      assert html =~ "Save Changes"
      assert html =~ "Cancel"
    end

    test "renders new mode with share button", %{conn: conn, user: user, scope: scope} do
      {:ok, _view, html} =
        live_isolated(conn, TestLive,
          session: %{
            "parent_pid" => self(),
            "current_user" => user,
            "current_scope" => scope,
            "form_action" => :new,
            "title" => "Share Resource"
          }
        )

      assert html =~ "Share Resource"
      assert html =~ "Share"
      assert html =~ "Cancel"
    end
  end

  describe "interactions" do
    test "closes drawer on close button click", %{
      conn: conn,
      user: user,
      scope: scope,
      resource: resource
    } do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "parent_pid" => self(),
            "resource" => resource,
            "current_user" => user,
            "current_scope" => scope,
            "form_action" => :show
          }
        )

      view |> element("button[aria-label='Close']") |> render_click()
      assert_received {:received, :close_drawer}
    end

    test "closes drawer on Escape keyup", %{
      conn: conn,
      user: user,
      scope: scope,
      resource: resource
    } do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "parent_pid" => self(),
            "resource" => resource,
            "current_user" => user,
            "current_scope" => scope,
            "form_action" => :show
          }
        )

      view |> element("div[phx-window-keyup='esc_close']") |> render_keyup(%{key: "Escape"})
      assert_received {:received, :close_drawer}
    end

    test "notifies parent on form validation", %{
      conn: conn,
      user: user,
      scope: scope,
      resource: resource
    } do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "parent_pid" => self(),
            "resource" => resource,
            "current_user" => user,
            "current_scope" => scope,
            "form_action" => :edit
          }
        )

      view
      |> form("#resource-form", %{resource: %{title: "New Title"}})
      |> render_change()

      assert_received {:received, {:form_params_updated, _params}}
    end

    test "saves resource and notifies parent", %{
      conn: conn,
      user: user,
      scope: scope,
      resource: resource
    } do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "parent_pid" => self(),
            "resource" => resource,
            "current_user" => user,
            "current_scope" => scope,
            "form_action" => :edit
          }
        )

      view
      |> form("#resource-form", %{resource: %{title: "Updated Title"}})
      |> render_submit()

      assert_received {:received, {:resource_saved, :updated}}
      assert_received {:received, :close_drawer}
    end
  end
end
