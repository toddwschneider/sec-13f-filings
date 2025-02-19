FROM ruby:3.0.2-slim

ENV NODE_VERSION=14
ENV LANG=C.UTF-8
ENV BUNDLE_PATH=/bundle
ENV RAILS_ENV=development
ENV PATH="/app/bin:${PATH}"

# Install essential packages
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libpq-dev \
    postgresql-client \
    python2 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

WORKDIR /app
COPY . /app/

# Install dependencies
RUN bundle install \
    && yarn install

# Add script to fix permissions
RUN echo '#!/bin/bash\n\
chown -R $USER:$USER /app/tmp/cache\n\
chown -R $USER:$USER /app/tmp/pids\n\
chown -R $USER:$USER /app/log\n\
rm -f /app/tmp/pids/server.pid\n\
exec "$@"' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]