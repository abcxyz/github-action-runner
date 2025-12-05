#!/bin/bash
set -euo pipefail

printenv

echo "--- Checking for privileged access... ---"
# Create a temporary directory to use as a safe mountpoint for our test.
MOUNT_TEST_DIR="$(mktemp -d)"

# Create an isolated mount namespace (-m)
# and then attempt the 'mount' operation. This will only succeed if the
# container has the required capabilities (like CAP_SYS_ADMIN) AND is not
# blocked by a host security policy (like AppArmor/SELinux).
if unshare -m -- mount -t tmpfs tmpfs "${MOUNT_TEST_DIR}" &>/dev/null; then
    echo "SUCCESS: Container has sufficient privileges to run Docker-in-Docker."
    rm -rf -- "${MOUNT_TEST_DIR}"
else
    echo "ERROR: Container lacks the necessary mount permissions for DinD." >&2
    echo "Ensure the container is started with the --privileged flag." >&2
    exit 1
fi

# --- Opportunistic DinD Start ---
# Define a non-conflicting path for the DinD socket to avoid collision with the host's mount
INTERNAL_DOCKER_SOCKET="unix:///var/run/docker-internal.sock"

# Set the DOCKER_HOST variable so all docker commands talk to our new DinD daemon
export DOCKER_HOST="${INTERNAL_DOCKER_SOCKET}"

# Start the daemon in the background on the new socket
# Forcing --storage-driver=vfs is crucial for reliability in Cloud Build
dockerd-entrypoint.sh dockerd --host="${INTERNAL_DOCKER_SOCKET}" --storage-driver=vfs &

##########################################################################
# BEGIN - github actions container feature workaround
##########################################################################
# Normally, GitHub Actions Self Hosted does not support using the `container`
# workflow feature. See the following bug:
# https://github.com/actions/runner/blob/463496e4fb25773f9409c94ba8209f061a0aa612/src/Runner.Worker/ContainerOperationProvider.cs#L539-L557
# 
# We workaround this bug by utilizing the pre-mounted cloud build `/workspace`
# directory. This allows us to utilize a path that is the same on the host VM
# and current docker container filesystem.
cp -r /actions-runner/* /workspace
chown -R runner:docker /workspace

# In order to trick the GitHub Actions Runner binary into thinking that we are
# not already in a docker container we must create a fake cgroup file and then
# bind mount the fake file over the real one.
echo '0::/' > /tmp/cgroup_mask
mount --bind /tmp/cgroup_mask /proc/1/cgroup

##########################################################################
# END - github actions container feature workaround
##########################################################################

# Drop privileges and execute the runner startup script
# The DOCKER_HOST variable will be passed to the runner's environment
exec gosu runner /workspace/start_runner.sh "$@"
