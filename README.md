# Python Lambda Project Boilerplate

This repository contains the most up-to-date boilerplate for a new Python project that will help you get set up and deployed to a Lambda quickly.

Generally speaking, we use Python projects like this and [`parsons`](https://github.com/move-coop/parsons) for data engineering or general scripting, and not web applications (see our [Web App Framework](https://github.com/MoveOnOrg/web-app-framework)).

## Get your project set up

1. Name your project

### _Keep everything in your README below here:_

---

# <PROJECT_NAME>

## Set up your local dev environment

1. [Install pyenv](https://github.com/pyenv/pyenv?tab=readme-ov-file#a-getting-pyenv) if you haven't.

1. Install Python (uses `.python-version`)

   ```bash
   pyenv install
   ```

1. Create your virtualenv:

   ```bash
   python -m venv venv
   ```

1. Activate the virtualenv and install / update dependencies:

   ```bash
   source venv/bin/activate
   venv/bin/pip install --upgrade pip
   venv/bin/pip install -r requirements.txt --upgrade
   venv/bin/pip install -r requirements-dev.txt --upgrade
   ```

   **Note:** you'll want to do this every time you come back to develop locally!

1. If you're using VSCode, you should not need to set your interpreter path and your IDE should resolve import references automatically if you didn't change the `venv` name. Otherwise, you may need to [manually set the interpreter path](https://code.visualstudio.com/docs/python/environments#_working-with-python-interpreters).

## Deploy to AWS Lambda with Zappa

## Deployment

> [!IMPORTANT]
> Always use the Docker container and shell script to deploy to ensure all steps are run and that the appropriate Lambda env dependencies will be installed!

1. Disable Docker CLI spam and build the image if you haven't:

   ```bash
   export DOCKER_CLI_HINTS=false
   docker compose build
   ```

1. Start the container:

   ```bash
   docker compose up -d
   ```

   **Note**: this will need to be run again if you ever shut down the container and come back.

1. The Docker Zappa shell script will handle collecting and uploading static assets to S3, clean installing non-dev dependencies, deployment to Lambda, running migrations, and loading test data for the selected environment. Call with either `staging`, `prod`, or other deployment env names as you add them.

   ```bash
   docker compose exec -ti <PROJECT_NAME> bash -ic "./zappa-deploy.sh {staging|prod}"
   ```
