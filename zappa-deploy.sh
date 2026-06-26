#!/bin/bash
set -e

# Refuse to run outside the Lambda Docker container
if [[ ! -f "/.dockerenv" && -z "$LAMBDA_TASK_ROOT" ]]; then
  echo "Error: zappa-deploy.sh must be run inside the Lambda Docker container." >&2
  echo "Start the container with \`docker compose up -d\` and run this script from there." >&2
  exit 1
fi

# Require a deploy environment argument (must match in zappa_settings.json)
DEPLOY_ENV="${1:-}"
if [[ "$DEPLOY_ENV" != "prod" && "$DEPLOY_ENV" != "staging" ]]; then
  echo "Usage: $0 <prod|staging>" >&2
  exit 1
fi

# Define colors.
COLOR_BLACK=$'\033[0;30m'
COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_BROWN=$'\033[0;33m'
COLOR_BLUE=$'\033[0;34m'
COLOR_PURPLE=$'\033[0;35m'
COLOR_CYAN=$'\033[0;36m'
COLOR_DARK_GRAY=$'\033[1;30m'
COLOR_LIGHT_RED=$'\033[1;31m'
COLOR_YELLOW=$'\033[1;33m'
COLOR_WHITE=$'\033[1;37m'
COLOR_NONE=$'\033[0m'


# Exit with an error message.
exit_with_error_message() {
  echo -e "\n${COLOR_LIGHT_RED}Error: ${1} Exiting.${COLOR_NONE}\n"
  exit 1
}

# Display the separator (used between steps).
echo_separator() {
  echo -e "${COLOR_DARK_GRAY}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${COLOR_NONE}\n"
}

# Display the step's question.
echo_question() {
  echo -en "${COLOR_CYAN}${1}${COLOR_NONE} "
}

update_pip() {
    echo_question "Upgrading pip..."
    if ( venv/bin/pip install -q --upgrade pip ) ; then
        echo -e "${messages["DONE"]}"
    else
       exit_with_error_message "Could not upgrade pip."
    fi
}

install_dev_deps() {
    echo_question "Reinstalling dev requirements..."
    if ( venv/bin/pip install -q -r requirements-dev.txt ) ; then
        echo -e "${messages["DONE"]}"
    else
        exit_with_error_message "Could not install dev requirements."
    fi
}

checks_and_tests() {
    echo_question "Linting..."
    if ( venv/bin/flake8 . ) ; then
        echo -e "${messages["DONE"]}"
    else
        exit_with_error_message "Linting failed."
    fi

    echo_question "Type-checking..."
    if ( venv/bin/pyright ) ; then
        echo -e "${messages["DONE"]}"
    else
        exit_with_error_message "Type-checking failed."
    fi

    echo_question "Running tests..."
    if ( venv/bin/python manage.py test ) ; then
        echo -e "${messages["DONE"]}"
    else
        exit_with_error_message "Tests failed."
    fi
}

clean_install_prod_deps() {
    echo_question "Clean installing non-dev dependencies..."
    if ( 
      # uninstall @ git installed libraries first
      venv/bin/pip uninstall python_controlshift -q -y || true &&
      venv/bin/pip freeze | xargs venv/bin/pip uninstall -q -y &&
      venv/bin/pip cache purge -q &&
      venv/bin/pip install -r requirements.txt
    ) ; then
        echo -e "${messages["DONE"]}"
    else
        exit_with_error_message "Could not install requirements."
    fi
}

zappa_deploy() {
    echo_question "Deploying with Zappa to ${DEPLOY_ENV}...\n"

    # Try to deploy first
    if ( venv/bin/zappa deploy "$DEPLOY_ENV" ); then
        echo -e "${messages["DONE"]}"
    else     
        # Run update instead
        if ! ( venv/bin/zappa update "$DEPLOY_ENV" ); then
            exit_with_error_message "Could not deploy or update with Zappa."
        fi
    fi

    echo -e "${messages["DONE"]}"
}

update_pip
install_dev_deps
checks_and_tests
clean_install_prod_deps
zappa_deploy
