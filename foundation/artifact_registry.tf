# Pull-through cache of Docker Hub: VMs pull container images without internet access
# and without being subject to Docker Hub rate limits.
resource "google_artifact_registry_repository" "dockerhub" {
  location      = var.region
  repository_id = "dockerhub"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  description   = "Remote repository proxying Docker Hub for the web VMs."

  remote_repository_config {
    description = "Docker Hub"

    docker_repository {
      public_repository = "DOCKER_HUB"
    }
  }

  depends_on = [google_project_service.required]
}
