#!/bin/bash
set -euo pipefail

# default args "n" and "main"
proceed="${1:-n}"
basebranch="${2-main}"

function changed_project_files {

  # default args "n" and "main"
  basebranch="${1-main}"

  if git status >>/dev/null; then
    echo "" >>/dev/null
  else
    echo "Git not installed"
    exit 1
  fi

  GLOB_PATTERN="'*.sql' "
  GLOB_PATTERN+="'redshift_queries/**' "

  DIFF_FILTER="d" # exclude deleted

  FILES_TO_LINT=$({
    # committed changes
    c_command=$(echo -e "git diff $basebranch \
      --diff-filter $DIFF_FILTER \
      --merge-base \
      --name-only \
      -- $GLOB_PATTERN")
    eval $c_command

    # staged changes
    s_command=$(echo -e "git diff \
      --staged \
      --name-only \
      --diff-filter $DIFF_FILTER \
      -- $GLOB_PATTERN")
    eval $s_command

    # unstaged changes
    u_command=$(echo -e "git diff \
      --name-only \
      --diff-filter $DIFF_FILTER \
      -- $GLOB_PATTERN")
    eval $u_command

  } | sort | uniq)

  echo "$FILES_TO_LINT"
}

echo -e "\nSetting up Python venv and installing/updating dependencies...\n"

if ! command -v pyenv &>/dev/null; then
  echo -e "\n❌ Please install pyenv:"
  echo -e "https://github.com/pyenv/pyenv?tab=readme-ov-file#a-getting-pyenv\n"
  exit 1
fi

pyenv install --skip-existing 3.13

if [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
else
  python3.13 -m venv venv
  source venv/bin/activate
fi

venv/bin/pip install --upgrade pip -q
venv/bin/pip install -r requirements.txt -q --upgrade

echo "Checking for changed files based on the $basebranch branch..."
echo ""

FILES_TO_LINT=$(changed_project_files $basebranch)

if [[ -z "$FILES_TO_LINT" ]]; then
  echo "No files changed"
  exit 0
fi


echo "🔍 Checking if SQL files can be parsed:"
set +e # don't raise any errors
parse_statuses=()
for file in $FILES_TO_LINT; do
  sqlfluff parse --nocolor $file >/dev/null
  if [ $? -eq 0 ]; then
    echo "✅ $file"
  else
    parse_statuses+=(1)
    echo "Unparseable ❌ $file"
  fi
done

# error if any are unparsable
if [[ ${#parse_statuses[@]} -gt 0 ]]; then
  echo ""
  echo "Exiting, unable to continue: some files unparsable!"
  echo "Try running 'sqlfluff parse {file}' for more details"
  exit 1
fi


# Auto Format
echo ""
echo "🔍 Applying sqlfluff auto-format"
for file in $FILES_TO_LINT; do
  sqlfluff format --nocolor --disable-progress-bar $file >>/dev/null
  if [ $? -eq 0 ]; then
    echo "✅ $file"
  else
    echo "Auto format ❌ $file"
  fi
done

# Auto Lint
echo ""
echo "🔍 Sqlfluff applying lint auto-fix"
for file in $FILES_TO_LINT; do
  sqlfluff fix --quiet --nocolor --disable-progress-bar $file >>/dev/null
  if [ $? -eq 0 ]; then
    echo "✅ $file"
  else
    echo "Linting failed ❌ $file"
  fi
done

# Lint
echo ""
echo "🔍 Sqlfluff lint?"
for file in $FILES_TO_LINT; do
  sqlfluff lint \
    --disable-progress-bar \
    $file
  if [ $? -eq 0 ]; then
    echo "✅ $file"
  else
    echo "Linting failed ❌ $file"
  fi
done

# Print auto Lint errors
echo ""
echo "🔍 Sqlfluff applying lint auto-fix again"
for file in $FILES_TO_LINT; do
  sqlfluff fix --show-lint-violations --disable-progress-bar $file
  if [ $? -eq 0 ]; then
    echo "✅ $file"
  else
    echo "Linting failed ❌ $file"
  fi
done
