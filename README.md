<!-- 
Copyright 2023 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 -->

# Vertex Pipelines End-to-End

_AKA "Vertex AI Turbo Templates (remastered by googlers)"_

The repository contains a ready-to-run example to train a regression model that predicts the price of a Taxi Ride in the city of Chicago, using publicly available BigQuery data and an xgboost model. 

## Setup

There are four different Google Cloud projects in use:

* `dev` - a shared sandbox environment for use during development
* `test` - environment for testing new changes before they are promoted to production. This environment should be treated as much as possible like a production environment.
* `prod` - production environment
* `admin` - separate Google Cloud project for setting up CI/CD in Cloud Build (since the CI/CD pipelines operate across the different environments)

To start working with the repository, you only need the `dev` environmet.

**Deploy infrastructure:**

Docs file with detailed instructions: [Infrastructure Setup with Terraform](documentation/Infrastructure.md).

After running the attached instructions, you will have a ready-to-use GCP environment (services, resources, and permissions), including a Vertex AI workbench instance (a Jupyter-like environment with Data Science and Google cloud packages pre-installed) for each of the future users of the repo.

> **Note:** Once inside a Vertex Workbench you can clone the repository and leverage from the Git Integration using:
>  
>   ```bash
>   git clone [repository_url] my-pipelines-repo
>   cd my-pipelines-repo
>   ```
>  
> ![Workbench](https://screenshot.googleplex.com/9gnufquDHAHVW9P.png)

**Install dependencies & authenticate to Google Cloud:**

To run this example you will need to follow these three steps (when running from a Vertex AI Workbench):

1. **[Python env]** Ensure you have installed Pyenv (for managing Python versions) and Poetry (for managing Python dependencies). You can run the following commands to install pyenv and add it to the shell's PATH environment variable:

    ```bash
    curl https://pyenv.run | bash
    nano ~/.bashrc
    ```
    
    Add the following lines to the end of the file: 
    
    ```bash
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    ```
    
    Reload the .bashrc:
    
    ```bash
    source ~/.bashrc
    ```
    
    And for Poetry (the repository contains a script for Poetry installation):
    
    ```bash
    bash scripts/install_poetry.sh
    ```
    
    Then, install poetry and pyenv dependencies by running:
    
    ```bash
    pyenv install -skip-existing
    poetry config virtualenvs.prefer-active-python true
    ```

1. **[GCP env]** Now, rename your env.sh.example file to env.sh and edit the VERTEX_PROJECT_ID, VERTEX_LOCATION, VERTEX_ZONE, RESOURCE_SUFFIX, and GOOGLE_ACCOUNT (termination) variables. Once that’s done, you can authenticate to your Google account by running the following the target (which sets the Google Project and Account, and then prompts you to authenticate with your credentials):

    ```bash
    make auth
    ```


1. **[Vertex Pipelines & Components env]** Finally, install the code dependencies to run pipelines by using:

    ```bash
    make install
    ```
    
Once done, you’re ready to run the training and prediction pipelines.

## Run pipelines 🚀
### Simply explained

```bash
make training wait=true
```
    
The training target first compiles the “training” and “prediction” Docker images under the `model` folder, containing the “training code” that will be used on the pipeline as a container component and the “prediction” FastAPI code that will be provided to Vertex AI as a serving container image when registering the model to Model Registry on the last step of the pipeline (we basically tell Vertex AI, I’ll give you a model and this is how to make predictions to it). Once the images are containerized and pushed to Artifact Registry (using Cloud Build), the target compiles the training pipeline by using the KubeFlow SDK (as a YAML file under  pipelines/training). Finally it runs the pipeline in Vertex AI by using the Vertex AI Python SDK and the pipeline YAML file (you can watch the pipeline execute in your terminal or on the Vertex AI console [see the following image]).

![Training](https://screenshot.googleplex.com/9jVGYGTNEDy63dC.png)

After the training pipeline is completed, you can run the prediction pipeline [see the attached image] using:

```bash
make prediction
```
![Prediction](https://screenshot.googleplex.com/5GtgJcGqwe6ot7C.png)

The prediction target will run a batch prediction job and outputs the results to BigQuery [see the next image]. 

![Predictions](https://screenshot.googleplex.com/7qMwESwkPte3YH3.png)

And just like that you’ve run a production-ready end-to-end ML workflow to train a model and generate predictions with it!

### Full explanation

**Build containers:** The [model/](/model/) directory contains the code for custom training and prediction container images, including the model training script at [model/training/train.py](model/training/train.py). 
You can modify this to suit your own use case.
Build the training and prediction container images and push them to Artifact Registry with:

```bash
make build [ images="training prediction" ]
```

Optionally specify the `images` variable to only build one of the images.

**Execute pipelines:** Vertex AI Pipelines uses KubeFlow to orchestrate your training steps, as such you'll need to:

1. Compile the pipeline
1. Build dependent Docker containers
1. Run the pipeline in Vertex AI

Execute the following command to run through steps 1-3:

```bash
make run pipeline=training [ build=<true|false> ] [ compile=<true|false> ] [ cache=<true|false> ] [ wait=<true|false> ] 
```

The command has the following true/false flags:

- `build` - re-build containers for training & prediction code (limit by setting images=training to build only one of the containers)
- `compile` - re-compile the pipeline to YAML
- `cache` - cache pipeline steps
- `wait` - run the pipeline (a-)sync

**Shortcuts:** Use these commands which support the same options as `run` to run the training or prediction pipeline:

```bash
make training
make prediction
```

## Create components or pipeline

1. Go to `components > src > components` and duplicate an existent component. 
2. Change the name of the file and replace the name of the function within the file with the same name (your new component's name).
3. Edit the code within the component:
    - Docs on the creation of components: [Create a component from a self-contained Python function](https://www.kubeflow.org/docs/components/pipelines/user-guides/components/lightweight-python-components/)
    - Docs on the use and passing of artifacts within components (E.g. Input, Output, Dataset, Model): [Create, use, pass, and track ML artifacts](https://www.kubeflow.org/docs/components/pipelines/user-guides/data-handling/artifacts/)
    - Docs on passing small sets of data (parameters): [Pass small amounts of data between components](https://www.kubeflow.org/docs/components/pipelines/user-guides/data-handling/parameters/)
4. Add your new component's name to the `__init__.py` file within `components > src > components`.
5. Run `make install` in the root directory (you only need to run it when adding a completely new component, not when making updates to an existent one).
6. Go to `pipelines > src > pipelines` and duplicate the existent pipeline file.
7. Make sure to change the name of the file and add a unique identifiable name within the pipeline decorator (`@dsl.pipeline`).
8. Import your components in the beginning of the file and construct your pipeline:
    - Docs on creating pipelines: [Compose components into pipelines](https://www.kubeflow.org/docs/components/pipelines/user-guides/components/compose-components-into-pipelines/)
9. Save your changes and run `make run pipeline=your-pipeline-file-name`.
10. Done! You can go to the Vertex AI console and watch you pipeline run.
    ![alt text](assets/images/pipeline.png)

> It's important to previously test your code adding a notebook within the `nbs` folder (the "Tensorflow" image is the same image as the `BASE_IMAGE` in your component, but make sure that if you `pip install` dependencies on your notebook, you specify them in the `packages_to_install` in the `@component` decorator).

## Branching strategy

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