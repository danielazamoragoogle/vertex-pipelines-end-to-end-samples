## Edit Python Custom Package 📚

This repository contains a custom Python Package that can be used in the components (example in the `components/src/components/read_data.py` component) or in the notebooks under the `nbs` folder.

>ℹ️ The example Python Package contains a module to handle BQ queries.

### Store Package in Artifact Registry

> ℹ️ If you don't have an Artifact Registry repository to store the package, you can create one by running `make create-ar-repository TYPE=python`.

To store the package (as is) in Google Artifact Registry (without any changes), run: 
```bash
make publish-package add_user=false increment=false
```

You can validate which version of the package you've just deployed to AR (e.g. `package 2.0.0`) by:

- Observing the `package_name` in the message "Publish Custom Package 'package_name' to Artifact Registry ..."  

- Looking in the file `pyproject.toml` under `package`.    

- Directly opening the Artifact Registry repository used for python in your environment (found in the variavle `AR_PYTHON` in the `env.sh` file) and looking for the most recently uploaded version of the package `package`. 

### Use the Package from Artifact Registry

To use the package you've stored in Artifact Registry, you can use `pip`. Either in a notebook or in your terminal run `gcloud auth login` to authenticate  with your credentials, and then use: 

> ℹ️ The name of the repository in AR should look like `us-central1-python.pkg.dev/your-project-id/your-ar-repo-mame`, it contains the location of the repository, the project, and name.

```
pip install plantillas-y-enriquecimiento=={THE VERSION YOU'VE UPLOADED TO ARTIFACT REGISTRY} --index-url https://oauth2accesstoken:$(gcloud auth print-access-token)@{YOUR AR REPO NAME}/simple --no-deps
```

### Make Changes to the Package

To edit the Python package by adding other modules follow the next instructions:

1. Add the new file to the source code.
1. If the package has dependencies, add them with `poetry add {DEPENDENCY}` in the `package`'s root folder (where you see the packages `toml` and `lock` files).
1. Add the corresponding tests in the `tests` folder.
1. Run `make install` in the root directory (to install build and publish dependencies).
1. Build the package using the command: 
    ```shell
    make build-package
    ```
   If you want to increment the version of the package use the `increment` variable (`part` can be `mayor`,`minor`,`patch`):
    ```shell
    make build-package increment=true part=minor
    ```
   You can also use this package in the notebooks by installing the editable (`!pip3 install -e {PATH TO}package/package`).

1. If you're ready to publish your Python Package to artifact registry, run the following `make` command (in the parent directory): 
    ```shell
    make publish-package increment=false
    ```
    This command will add a user tag by default, remove it adding the argument `add_user=false`.