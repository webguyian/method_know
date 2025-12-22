defmodule MethodKnowWeb.ErrorHTML do
  use MethodKnowWeb, :html

  def render("404.html", assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div class="mb-8">
        <div class="inline-flex items-center justify-center size-32 rounded-full bg-primary/10 text-primary mb-6 transition-transform hover:rotate-12 duration-500">
          <Lucide.map_pin_off class="size-16" />
        </div>
        <h1 class="text-9xl font-black text-base-content/10 mb-[-3rem] select-none">404</h1>
        <h2 class="text-4xl font-bold text-base-content mb-2 pt-4 relative z-10">Lost in Space?</h2>
        <p class="text-xl text-base-content/60 font-medium pt-2">Page Not Found</p>
      </div>

      <p class="text-base-content/60 max-w-md mb-10 leading-relaxed">
        The resource you're looking for seems to have vanished or moved to a different coordinate.
        Don't worry, even the best explorers lose their way sometimes.
      </p>

      <div class="flex flex-col sm:flex-row gap-4 justify-center w-full max-w-sm">
        <.link
          navigate="/"
          class="btn btn-primary btn-lg grow shadow-lg shadow-primary/20"
        >
          <Lucide.home class="size-5 mr-2" /> Return Home
        </.link>
        <button
          onclick="history.back()"
          class="btn btn-outline btn-lg grow"
        >
          <Lucide.arrow_left class="size-5 mr-2" /> Go Back
        </button>
      </div>
    </div>
    """
  end

  def render("500.html", assigns) do
    ~H"""
    <Layouts.app
      flash={Map.get(assigns, :flash, %{})}
      current_scope={Map.get(assigns, :current_scope, nil)}
    >
      <div class="flex flex-col items-center justify-center py-12 px-4 text-center">
        <div class="mb-8">
          <div class="inline-flex items-center justify-center size-32 rounded-full bg-error/10 text-error mb-6 transition-transform hover:rotate-12 duration-500">
            <Lucide.alert_triangle class="size-16" />
          </div>
          <h1 class="text-9xl font-black text-base-content/10 mb-[-3rem] select-none">500</h1>
          <h2 class="text-4xl font-bold text-base-content mb-2 pt-4 relative z-10">
            Internal Server Error
          </h2>
          <p class="text-xl text-base-content/60 font-medium pt-2">
            Something went wrong on our end.
          </p>
        </div>

        <p class="text-base-content/60 max-w-md mb-10 leading-relaxed">
          We're experiencing technical difficulties. Please try again later or contact support if the issue persists.
        </p>

        <div class="flex flex-col sm:flex-row gap-4 justify-center w-full max-w-sm">
          <.link
            navigate="/"
            class="btn btn-error btn-lg grow shadow-lg shadow-error/20"
          >
            <Lucide.home class="size-5 mr-2" /> Return Home
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
