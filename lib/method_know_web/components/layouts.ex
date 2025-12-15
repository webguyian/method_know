defmodule MethodKnowWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MethodKnowWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main class="px-4 py-8 sm:px-6 lg:px-8">
      <div class="container mx-auto">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash kind={:success} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  attr :current_scope, :map, default: nil
  attr :hide_navbar, :boolean, default: false
  attr :hide_navbar_action, :boolean, default: false
  slot :inner_block

  def navbar(assigns) do
    ~H"""
    <%= unless @hide_navbar do %>
      <nav class="navbar bg-base-100 px-4 sm:px-6 lg:px-8 shadow-sm border-b border-base-200 sticky top-0 z-40">
        <div class="container mx-auto flex justify-between items-center">
          <div class="flex-1">
            <.link
              navigate="/"
              class="inline-flex items-center text-xl gap-2 text-base-content"
            >
              <div class="size-9 rounded-full bg-black text-white flex items-center justify-center">
                <Lucide.book_marked class="size-5" />
              </div>
              <span class="font-semibold tracking-tight hidden sm:inline">Method Know</span>
            </.link>
          </div>
          <div class="flex gap-4 items-center">
            <%= if @current_scope && @current_scope.user do %>
              <%= unless @hide_navbar_action do %>
                <.button class="lg:px-10 lg:py-2" variant="primary" phx-click="show_drawer">
                  Share Resource
                </.button>
              <% else %>
                <Layouts.theme_toggle />
              <% end %>
              <div class="dropdown dropdown-end">
                <button type="button" class="btn btn-ghost gap-2 font-normal p-2">
                  <.avatar user={@current_scope.user} />
                </button>
                <ul class="mt-3 z-[1] p-2 shadow-lg shadow-base-content/5 menu menu-sm dropdown-content bg-base-100 rounded-box w-52 border border-base-200">
                  <li class="menu-title text-base-content/60 px-4 py-2 border-b border-base-content/10 mb-1">
                    My Account
                  </li>
                  <li>
                    <.link href="/my/resources" class="py-2 gap-2">
                      <Lucide.bookmark class="size-4" /> Your Shared Resources
                    </.link>
                  </li>
                  <li>
                    <.link href="/users/settings" class="py-2 gap-2">
                      <Lucide.settings_2 class="size-4" /> Settings
                    </.link>
                  </li>
                  <li class="border-t border-base-content/10 mt-1 pt-1">
                    <.link href="/users/log-out" method="delete" class="py-2 gap-2">
                      <Lucide.log_out class="size-4" /> Log out
                    </.link>
                  </li>
                </ul>
              </div>
            <% else %>
              <ul class="menu menu-horizontal px-1">
                <li><.link navigate="/users/register">Register</.link></li>
                <li><.link navigate="/users/log-in">Log in</.link></li>
              </ul>
            <% end %>
          </div>
        </div>
      </nav>
    <% end %>
    """
  end
end
