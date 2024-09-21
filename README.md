# Terraform completely stack for GCP microservices

The collection of the terraform modules that used for provision the infrastructure support Kubernetes GCP-native.

## Project strucutres

1. **modules:** Store the freezed modules to provision resources as GCP including Network service and Container services.
2. **stack:** Represent the actually project's infrastructure that reference from the module reusable. The stack should be isolate environment cause it contain the state to managed real resources.
3. **example:** Provided example to used this project and test some feature before append the resource to `stack`

## Requirement

1. Terraform 1.3 and up
2. Provider google (including beta) 5 to 7

## How to use

1. Define your folder under `stack` to represent your environment like *dev*, *sit*, and other.
2. Create the Terraform files provisioned your resources.
3. Apply with the Terraform

## How to contributes

1. You can **fork** or **new branch** this repo for adjustment and re-create the source code.
2. After you need to merge your code into the mainline branch, you could open the PR to review and required the **Maintainer** to review your change.
3. After **Maintainer** approved, you can merge your code into main branch.

> Note! Please ensure every your commit was pass the terraform linter and security scan before pushed to remote repository.
