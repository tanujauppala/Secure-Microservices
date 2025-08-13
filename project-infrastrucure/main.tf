# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = ">= 6.46.0"
#     }
#   }
#   required_version = ">= 1.3.0"
# }
# provider "google" {

#   project     = "sharp-harbor-466005-p5"
#   region      = "us-central1"
# }
# locals {
#   data = yamldecode(file("projects.yaml"))

# }

# # projects creation
# resource "google_project" "projects" {
#   for_each = { for project in local.data.projects : project.projectId => project }

#   name       = each.value.name
#   project_id = each.value.projectId
#   labels     = each.value.labels
#   deletion_policy = var.delete_policy # Controls deletion behavior. Set variable 'delete_policy' to delete to allow deletion, or by default it will be prevent.

# }
#  resource "google_project_iam_member" "projects_viewer" {
#   for_each = { for project in local.data.projects : project.projectId => project }

#   project = each.value.projectId
#   role    =  "roles/resourcemanager.projectIamAdmin"                    #"roles/resourcemanager.projectIamAdmin"
#   member  = "user:tanujagcp@gmail.com"
# }

# # single role for multiple members
# #   resource "google_project_iam_binding" "team_roles" {
# #    for_each = {
# #     for team in local.team_data.teams : team.name => team }

# #   project = each.value.project
# #   role    = each.value.roles

# #   members = [
# #     for member in each.value.members : "user:${member.user}"
# #   ]
# # }


# locals {

#   team_data = yamldecode(file("roles.yaml"))

#   team_roles = flatten([
#     for team in local.team_data.teams : [
#       for member in team.members : [
#         for role in member.roles : {
#           project = team.project
#           user    = member.user
#           role    = role
#         }
#       ]
#     ]
#   ])
# }
# # assign team roles
# resource "google_project_iam_member" "team_roles" {
#   for_each = {
#     for role_assign in local.team_roles :
#     "${role_assign.project}-${role_assign.user}-${role_assign.role}" => role_assign
#   }

#   project = each.value.project
#   role    = each.value.role
#   member  = "user:${each.value.user}"
# }


