# Use the official Superset image as a base
FROM apache/superset

# Switch to root user to perform the necessary operations
USER root

RUN pip install PyAthena

# Set the secret key as an environment variable
ENV SUPERSET_SECRET_KEY your_secret_key_here

# Copy a custom script to the container which will run the initialization commands
COPY entrypoint.sh /entrypoint.sh

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set the script to run when the container starts
ENTRYPOINT ["/entrypoint.sh"]
