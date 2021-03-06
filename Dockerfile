FROM ruby:2.7.2
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y build-essential nodejs && apt-get clean
RUN gem install foreman

ENV DATABASE_URL mysql2://root:root@mysql/contacts-admin
ENV GOVUK_APP_NAME contacts-admin
ENV PORT 3051
ENV RAILS_ENV development

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* .ruby-version $APP_HOME/
RUN bundle install
ADD . $APP_HOME

RUN GOVUK_APP_DOMAIN=www.gov.uk GOVUK_WEBSITE_ROOT=www.gov.uk RAILS_ENV=production bundle exec rails assets:precompile

HEALTHCHECK CMD curl --silent --fail localhost:$PORT/healthcheck || exit 1

CMD foreman run web
