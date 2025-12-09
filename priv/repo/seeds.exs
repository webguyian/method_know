# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MethodKnow.Repo.insert!(%MethodKnow.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MethodKnow.Accounts

users = [
  {"John Smith", "john.smith@example.com"},
  {"Jane Doe", "jane.doe@example.com"},
  {"Michael Brown", "michael.brown@example.com"},
  {"Emily Davis", "emily.davis@example.com"},
  {"David Wilson", "david.wilson@example.com"},
  {"Sarah Miller", "sarah.miller@example.com"},
  {"Robert Taylor", "robert.taylor@example.com"},
  {"Jessica Anderson", "jessica.anderson@example.com"},
  {"William Thomas", "william.thomas@example.com"},
  {"Jennifer Jackson", "jennifer.jackson@example.com"}
]

password = "letmein!"

IO.puts("Seeding users...")

for {name, email} <- users do
  case Accounts.get_user_by_email(email) do
    nil ->
      case Accounts.register_user(%{
             name: name,
             email: email,
             password: password,
             password_confirmation: password
           }) do
        {:ok, _user} ->
          IO.puts("Created user: #{name} (#{email})")

        {:error, changeset} ->
          IO.puts("Failed to create user #{name}: #{inspect(changeset.errors)}")
      end

    _user ->
      IO.puts("User already exists: #{name} (#{email})")
  end
end

alias MethodKnow.Resources
alias MethodKnow.Accounts.Scope

IO.puts("Seeding resources...")

# Query all users with @example.com email addresses
import Ecto.Query
user_query = from u in MethodKnow.Accounts.User, where: like(u.email, "%@example.com")
user_list = MethodKnow.Repo.all(user_query)

json_file = Path.join(:code.priv_dir(:method_know), "repo/seeds/resources.json")

if File.exists?(json_file) do
  resources =
    json_file
    |> File.read!()
    |> Jason.decode!(keys: :atoms)

  # Shuffle users for pseudo-random assignment
  shuffled_users = Enum.shuffle(user_list)

  for {resource_attrs, idx} <- Enum.with_index(resources) do
    # Cycle through shuffled users if there are fewer users than resources
    user = Enum.at(shuffled_users, rem(idx, length(shuffled_users)))
    scope = Scope.for_user(user)

    # Check if resource already exists for this user by title to avoid duplicates
    existing_resource =
      Resources.list_resources(scope)
      |> Enum.find(fn r -> r.title == resource_attrs.title end)

    if existing_resource do
      IO.puts("Resource already exists: #{resource_attrs.title}")
    else
      case Resources.create_resource(scope, resource_attrs) do
        {:ok, _resource} ->
          IO.puts(
            "Created resource: #{resource_attrs.title} (assigned to #{user.name} <#{user.email}>)"
          )

        {:error, changeset} ->
          IO.puts(
            "Failed to create resource #{resource_attrs.title}: #{inspect(changeset.errors)}"
          )
      end
    end
  end
else
  IO.puts("Error: Resources seed file not found at #{json_file}")
end

IO.puts("Done!")

# ==============================================================================
# ROLLBACK / CLEANUP
# ==============================================================================
# To easily delete the users created by this script (and any other users with
# @example.com email addresses), you can uncomment and run the following lines,
# or run them in IEx:
#
# import Ecto.Query
#
# # Delete resources created by example users
# resource_query = from r in MethodKnow.Resources.Resource,
#   where: r.user_id in subquery(from u in MethodKnow.Accounts.User, where: like(u.email, "%@example.com"), select: u.id)
# {resource_count, _} = MethodKnow.Repo.delete_all(resource_query)
# IO.puts("Deleted #{resource_count} resources.")
#
# # Delete example users
# user_query = from u in MethodKnow.Accounts.User, where: like(u.email, "%@example.com")
# {user_count, _} = MethodKnow.Repo.delete_all(user_query)
# IO.puts("Deleted #{user_count} example users.")
# ==============================================================================
