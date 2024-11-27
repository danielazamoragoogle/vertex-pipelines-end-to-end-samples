## Create new components or pipelines 👷🏽‍♀️

In this file you will find the necessary instructions to create new components and build new pipelines using the structure provided in the repository.

### Create Components

> 🚨 It's important to previously test your code. **It's 100x easier to debug in an interactive environment like python notebook than directly in the components' containerized code. Suggestion:** adding a notebook within a `nbs` folder or trying out code in a Colab! The `base_image` in your component can be set to `us-docker.pkg.dev/vertex-ai/training/tf-cpu.2-14.py310:latest` ([docs](https://cloud.google.com/deep-learning-containers/docs/choosing-container)) if you want to have the exact same image as the ones used in Colab or Workbench - but make sure that if you `pip install` dependencies on the notebook, you specify them in the `packages_to_install` in the `@component` decorator, too.

1. Go to `components > src > components` and duplicate an existent component. 
2. Change the name of the file and replace the name of the function within the file with the same name (your new component's name).
3. Edit the code within the component:
    - Docs on the creation of components: [Create a component from a self-contained Python function](https://www.kubeflow.org/docs/components/pipelines/user-guides/components/lightweight-python-components/)
    - Docs on the use and passing of artifacts within components (E.g. Input, Output, Dataset, Model): [Create, use, pass, and track ML artifacts](https://www.kubeflow.org/docs/components/pipelines/user-guides/data-handling/artifacts/)
    - Docs on passing small sets of data (parameters): [Pass small amounts of data between components](https://www.kubeflow.org/docs/components/pipelines/user-guides/data-handling/parameters/)
4. Add your new component's name to the `__init__.py` file within `components > src > components`.
5. Run `make install` in the root directory (you only need to run it when adding a completely new component, not when making updates to an existent one).

### Build Pipelines

1. Go to `pipelines > src > pipelines` and duplicate an existent pipeline file.
1. Make sure to change the name of the file and add a unique identifiable name within the pipeline decorator (`@dsl.pipeline`).
1. Import your components in the beginning of the file and construct your pipeline:
    - Docs on creating pipelines: [Compose components into pipelines](https://www.kubeflow.org/docs/components/pipelines/user-guides/components/compose-components-into-pipelines/)
1. **[TIME TO RUN YOUR PIPELINE 🏃🏽🏃🏽]** Save your changes and run the following command in a terminal on the root directory of the repo:
    ```
    make run pipeline=your-pipeline-file-name
    ```
    
    > 🚨 For this command to run, the name of the function in the file needs to be "pipeline" i.e. `def pipeline(...`.
