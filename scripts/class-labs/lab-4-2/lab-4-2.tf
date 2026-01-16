# ---------------------------------------------------------------------------------------------------
# Copyright Notice
# All Rights Reserved.
# All course materials (the “Materials”) are protected by copyright under U.S. Copyright laws 
# and are the property of 2nd Sight Lab. They are provided pursuant to a royalty free, 
# perpetual license to the course attendee (the "Attendee") to whom they were presented by 
# 2nd Sight Lab and are solely for the training and education of the Attendee. The Materials 
# may not be copied, reproduced, distributed, offered for sale, published, displayed, performed, 
# modified, used to create derivative works, transmitted to others, or used or exploited in any way, 
# including, in whole or in part, as training materials by or for any third party.
# 
# The above copyright notice and this permission notice shall be included in all copies or 
# substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES 
# OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# ---------------------------------------------------------------------------------------------------
# Provider Setup
# ---------------------------------------------------------------------------------------------------
provider "aws" {
  region = "us-west-2"
}

provider "azurerm" {
  version         = ">= 2.0"
  features {}
}

# ---------------------------------------------------------------------------------------------------
# Create AWS Group, Policy & User
# ---------------------------------------------------------------------------------------------------
resource "aws_iam_group" "users_developers_group" {
  name = "developers"
  path = "/users/developers/"
}

data "template_file" "user_developers_policy" {
  template = "${file("${path.module}/scripts/packer-policy.tpl.json")}"

  vars {
    tag_name  = "${var.tag_name}"
    tag_value = "${var.tag_value}"
  }
}

resource "aws_iam_policy" "users_developers_policy" {
  name        = "developers-policy"
  description = "Developers Policy Object"
  policy      = "${data.template_file.user_developers_policy.rendered}"

  depends_on = [
    "aws_iam_group.users_developers_group",
    "data.template_file.user_developers_policy",
  ]
}

resource "aws_iam_group_policy_attachment" "users_developers_policy_attachment" {
  group      = "${aws_iam_group.users_developers_group.name}"
  policy_arn = "${aws_iam_policy.users_developers_policy.arn}"
}

resource "aws_iam_user" "new_user_setup" {
  count = "${length(var.users_to_create)}"

  name = "${element(var.users_to_create, count.index)}"
  path = "/users/developers/"
}

resource "aws_iam_access_key" "new_user_access_keys" {
  count = "${length(var.users_to_create)}"

  user = "${element(aws_iam_user.new_user_setup.*.name, count.index)}"
}

resource "aws_iam_group_membership" "new_development_users_to_group" {
  name = "developers-group-membership"

  users = [
    "${aws_iam_user.new_user_setup.*.name}",
  ]

  group = "${aws_iam_group.users_developers_group.name}"
}

# ---------------------------------------------------------------------------------------------------
# Create Azure Role & Assign to self
# ---------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "lab_resourcegroup" {
  name     = "testRGForLab4"
  location = "West US"
}

data "azurerm_subscription" "primary" {}

resource "random_string" "password" {
  length = 32
}

resource "random_id" "name" {
  byte_length = 16
  prefix      = "terraform"
}

resource "azuread_application" "service_principal" {
  name = "tf-${random_id.name.hex}"
}

resource "azuread_service_principal" "service_principal" {
  application_id = "${azuread_application.service_principal.application_id}"
}

resource "azuread_service_principal_password" "service_principal" {
  service_principal_id = "${azuread_service_principal.service_principal.id}"
  value                = "${random_string.password.result}"
  end_date             = "${timeadd(timestamp(), "${10 * (24 * 365)}h")}"
}

resource "azurerm_role_assignment" "service_principal" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.lab_resourcegroup.name}"
  role_definition_name = "Contributor"
  principal_id         = "${azuread_service_principal.service_principal.id}"
}
