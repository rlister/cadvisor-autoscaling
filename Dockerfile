FROM rlister/ruby:2.2.0

MAINTAINER Ric Lister <rlister@gmail.com>

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y \
    ca-certificates

WORKDIR /app

ADD ./Gemfile /app/
ADD ./Gemfile.lock /app/

RUN bundle install --without development test

ADD ./ /app

EXPOSE 3000

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "unicorn", "-c", "config/unicorn.rb", "-p", "3000"  ]
