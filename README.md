# Vertex Pipelines Repo

## Introduction

This repository is structured to facilitate the development and deployment of ML(Ops) pipelines ([Vertex Pipelines](https://cloud.google.com/vertex-ai/docs/pipelines/)). It provides a reference implementation for creating a production-ready MLOps solution on Google Cloud. You can take this repository as a starting point you own ML use cases. 
The implementation includes:

* **ML training and prediction pipelines** using the Kubeflow Pipelines
* **Reusable Kubeflow components** that can be used in common ML pipelines
* **Developer scripts** (Makefile, Python scripts etc.)
* **Package** Structure for custom Python Package.
* **Cloud Function & Triggering** Cloud Function files for pipeline deployment + utilities to create scheduled and event-based triggers.
* **CI/CD** [WIP]

## ⚙️ Setup Environment [to use the repository]
This repository includes a [Makefile](Makefile) to easily run shell commands but make sure you first:
1. Rename the `env.sh.example` file to `env.sh`
1. Update the variables to your project variables and resources (project ID, gcs bucket name, resource suffix, service account name, pipeline root gcs bucket to one existent).

> Run `make help` for documentation on the commands available in the Makefile.

> It's **highly recommended** to run the code within this repository using a Vertex AI Workbench Instance with the base image suggested in the `env.sh` file.
 
Additionally, you will need: 

- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/quickstart) - (already installed in Vertex Workbench Instance or Cloud Shell environment).
- The cloned repo.
- [Poetry](https://python-poetry.org/) for managing Python dependencies:
    1. `python3 -m venv env`
    1. `source env/bin/activate`
    1. `pip install poetry` or `bash docs/scripts/install_poetry.sh`.

## 🚀 Documentation

This project includes documentation to help you get started. You can find the files in the [docs](./docs) folder.

- [📃 Running a pipeline](./docs/01_run_pipeline.md): Instructions to run pipelines in the repository.
- [📃 Create new components or pipelines](./docs/02_create_component_or_pipeline.md): Learn how to create new components and build new pipelines.
- [📃 Edit Python Custom Package](./docs/03_custom_python_package.md): Learn how to edit and use the custom Python package. 
- **Pipeline Deployment**: Registering pipelines in Artifact Registry and scheduling or creating event triggers (using the repository's Cloud Function and Pub/Sub) [WIP].
- **CI/CD** [WIP].

## 🗺️🗂️ Structure

The repo is organized into several key folders:

```
├── env.sh		  # Environment variables (GCP Project IDs, service account, buckets, etc.) 
├── Makefile		  # File containing pre-written commands that go from running pipelines to registering them, deploying our cloud function, and creating triggers.
├── docs		  # Folder containing documentation to run pipelines, create components and pipelines, deploy them, and more.
├── nbs # Notebooks to test code before making it operational (in components and pipelines) 
├── components			  # Component code as packages; for usability in pipelines
│   └── src            
│   	└── components	
│   	       ├── file.py # One file per component (Python-based or container components).
│   	       └── __init__.py # (components as modules)  
├── model # Folder containing the folders that can become Docker images (in AR)
│   ├── prediction
│   └── training  
├── pipelines
│   └── src   
│   	└── pipelines
│   	       ├── file.py # One file per pipeline.
│   	       └── … # (add more pipelines here)  	
├── package # Folder containing code for Python Custom Package
│   └── src
├── cloudfunction
│   └── src 
│   	└── main.py # File with code to run pipelines from their AR-registered templates.
└── utils # code containing scripts used in the repo's backend (e.g. package building).
```

## 🧑‍🧑‍🧒‍🧒🤝 Branching Strategy

We use a Git branching strategy that promotes a structured and collaborative development workflow. Here's how it works:


1. **Feature Branches:**
  - When developing new capabilities or fixing bugs, create a new branch based on the `development` branch.
  - Use a consistent naming convention for your branches:
    - **`feature/`**: For new features.
    - **`fix/`**: For bug fixes.
  - Include a ticket number or identifier, and a human-readable description. For example:
    - `feature/123456-config-files`
    - `fix/LDAP-notification-issues`
  - Example:
    ```shell
    git checkout -b feature/123456-config-files development
    ```

2. **Pull Requests:**
  - Once you've completed the work in your feature branch, open a pull request (PR) targeting the `development` branch.
  - This allows for code review and discussion before merging changes into the main development line.

## ☁️ Cloud Architecture

The diagram below shows the cloud architecture for this repository.

![Cloud Architecture diagram](./docs/images/architecture.png)

There are four different Google Cloud projects in use

* `dev` - a shared sandbox environment for use during development
* `test` - environment for testing new changes before they are promoted to production. This environment should be treated as much as possible like a production environment.
* `prod` - production environment
* `admin` - separate Google Cloud project for setting up CI/CD in Cloud Build (since the CI/CD pipelines operate across the different environments)

Vertex Pipelines are scheduled using Google Cloud Scheduler. Cloud Scheduler emits a Pub/Sub message that triggers a Cloud Function, which in turn triggers the Vertex Pipeline to run.