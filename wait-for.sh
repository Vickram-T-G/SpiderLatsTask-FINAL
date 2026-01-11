set -e

host="$1"
port="$2"
timeout="${3:-30}"
shift 3 || true
cmd="$@"

if [ -z "$host" ] || [ -z "$port" ]; then
    echo "Usage: $0 host:port [timeout] [command]"
    exit 1
fi

echo "Waiting for $host:$port to be ready..."

# Try to connect to the host:port
for i in $(seq 1 $timeout); do
    if nc -z "$host" "$port" 2>/dev/null || \
       (command -v timeout >/dev/null 2>&1 && timeout 1 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null); then
        echo "$host:$port is ready!"
        if [ -n "$cmd" ]; then
            exec $cmd
        fi
        exit 0
    fi
    echo "Attempt $i/$timeout: $host:$port not ready, waiting..."
    sleep 1
done

echo "Timeout: $host:$port is not ready after $timeout seconds"
exit 1

