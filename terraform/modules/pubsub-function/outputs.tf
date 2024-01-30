output "project" {
  value       = google_cloudfunctions2_function.default.project
  description = "The project where resources will be created."
}

output "name" {
  value       = google_cloudfunctions2_function.default.name
  description = "The name of the cloud function."
}

output "location" {
  value       = google_cloudfunctions2_function.default.location
  description = "The location of the cloud function."
}