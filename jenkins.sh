#!/bin/bash
set -x
export DISPLAY=:99
export GOVUK_ASSET_ROOT=http://static.test.gov.uk
env

function github_status {
  STATUS="$1"
  MESSAGE="$2"
  if [ "$GIT_BRANCH" != "origin/master" ]; then
    gh-status alphagov/whitehall "$GIT_COMMIT" "$STATUS" -d "Build #${BUILD_NUMBER} ${MESSAGE}" -u "$BUILD_URL" >/dev/null
  fi
}

function error_handler {
  trap - ERR # disable error trap to avoid recursion
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  github_status failure "failed on Jenkins"
  exit "${code}"
}

trap "error_handler ${LINENO}" ERR
github_status pending "is running on Jenkins"

time bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment

time bundle exec rake db:drop db:create db:schema:load --trace
time bundle exec rake db:test:prepare --trace
RAILS_ENV=production time bundle exec rake assets:clean --trace
RAILS_ENV=test time bundle exec rake ci:setup:rspec spec --trace
RAILS_ENV=production time bundle exec rake assets:precompile --trace

EXIT_STATUS=$?
echo "EXIT STATUS: $EXIT_STATUS"

if [ "$EXIT_STATUS" == "0" ]; then
  github_status success "succeeded on Jenkins"
else
  github_status failure "failed on Jenkins"
fi

exit $EXIT_STATUS