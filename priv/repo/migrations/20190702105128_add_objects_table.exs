defmodule CommonsPub.Repo.Migrations.AddObjectsTable do
  use Ecto.Migration

  def change do
    create table("ap_object", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:data, :map)
      add(:local, :boolean)
      add(:public, :boolean)

      timestamps()
    end
  end
end
