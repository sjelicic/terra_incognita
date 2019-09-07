/*The second option for handling secrets is to manage them completely outside of Terraform 
(e.g., in a password manager such as 1Password, LastPass, or OS X Keychain) 
and to pass the secret into Terraform via an environment variable*/

/*variable "db_password" {
  description = "database password"
  type = string
}
*/