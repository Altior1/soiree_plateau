# Use the official Elixir image as the base
FROM elixir:latest

# Set the working directory
WORKDIR /app

# Copy the application files
COPY . .

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies
RUN mix deps.get

# Compile the application
RUN MIX_ENV=prod mix compile

# Database setup will run at container startup via the entrypoint script
# (avoid running stateful DB commands during image build)

# Expose the application port
EXPOSE 4000

# Copy and install the container entrypoint that runs migrations/seeds at startup
COPY entrypoint.sh .
RUN chmod +x ./entrypoint.sh

# Start the application (entrypoint will run migrations/seeds before exec)
ENTRYPOINT ["./entrypoint.sh"]
CMD ["mix", "phx.server"]