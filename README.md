# dynssh
[![Continuous integration](https://github.com/Skycoder42/dynssh/actions/workflows/ci.yaml/badge.svg)](https://github.com/Skycoder42/dynssh/actions/workflows/ci.yaml)
[![Weekly - Docker image update](https://github.com/Skycoder42/dynssh/actions/workflows/docker_weekly.yaml/badge.svg)](https://github.com/Skycoder42/dynssh/actions/workflows/docker_weekly.yaml)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/skycoder42/dynssh?label=Docker&color=blue)](https://hub.docker.com/r/skycoder42/dynssh)

A small server utility to dynamically update the SSH configuration for a remote host with dynamic IPs.

## Table of contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  * [Server Arguments](#server-arguments)
  * [API usage](#api-usage)
  * [Authentication](#authentication)

<small><i><a href='https://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Features
The primary goal of this tool is to make it possible to have a SSH configuration with a host alias for a remote server
that has a dynamic IP address, but no public name. That remote server can regularly notify the dynssh server with
it's changed IP address so the host configuration gets updated with the new IP.

The main features are:

- A minimal HTTP server that provides a DYNDNS-like endpoint, but for updating the SSH configuration.
- Updates the `HostName` parameter of a `Host` in the SSH config file
- This allows you to define an SSH host alias for a server with a dynamic IP address, without giving that server a
public name on the internet
- Uses API-Key Authentication plus SSH server key validation to ensure only authentic updates are accepted

## Installation
1. Via docker/podman:
    ```bash
    podman run \  # or docker run
      -v "$HOME/.config/dynssh:/etc/dynssh:ro" \
      -v "$HOME/.ssh:/etc/ssh" \
      -p 127.0.0.1:8080:80 \
      docker.io/skycoder42/dynssh [<options>]
    ```
2. From the releases page: https://github.com/Skycoder42/dynssh/releases/latest
3. Install as global dart tool: `dart pub global activate dynssh`
4. Compile it yourself:
    ```bash
    dart pub get
    dart run build_runner build
    dart compile exe bin/dynssh.dart -o bin/dynssh
    sudo install bin/dynssh /usr/local/bin/dynssh
    ```

## Usage
Simply start the server and use the provided HTTP endpoint to send update requests to it.

> **Important:** The server itself does not support HTTPS, but should never be run with just a HTTP connection. Instead,
> you should run it only on localhost (e.g `dynssh -H 127.0.0.1`) and use a reverse proxy like nginx or apache to
> provide a HTTPS gateway to expose the server to the internet.

### Server Arguments
```
Usage:
-H, --host=<host>             The host address to listen to.
                              (defaults to "0.0.0.0")
-p, --port=<port>             The port to listen to.
                              (defaults to "80")
-k, --api-key-path=<path>     The path to the API-Key json file.
                              (defaults to "$HOME/.config/dynssh/api-keys.json")
-d, --ssh-directory=<path>    The path to the ssh directory where configuration files are stored.
                              (defaults to "$HOME/.ssh")
-l, --log-level=<level>       Customize the logging level. Listed from most verbose (all) to least verbose (off)
                              [all, finest, finer, fine, config, info (default), warning, severe, shout, off]
-h, --help                    Prints usage information.
```

The API-Key JSON file has the following format:
```json
{
  "apiKeys": {
    "<hostname1>": "<api-key1>",
    "<hostname2>": "<api-key2>",
  }
}
```
With the `<hostnameX>` being the the domain name and `<api-keyX>` the API key for that domain. There are no formal
requirements for the API Keys themselves, but recommendation is to use a long, random, base64 key. You can, for example,
use `openssl` to generate such a key:

```bash
openssl rand -base64 48
```

### API usage
The server only provides a single endpoint:
```
POST <host>/dynssh/update?hostname=<hostname>&myip=<ipAddress>
```

This endpoint is modeled after the [DYNDNS Update API](https://help.dyn.com/remote-access-api/perform-update/) and thus
should be able to be used as drop in replacement in any dyndns client to instead report to dynssh.

The `hostname` and `myip` parameters are always required. `hostname` must be the alias of the host as defined in the SSH
config file to change the IP address for. The `myip` parameter is used to specify the new IP address for that host.

### Authentication
In addition to those parameters you must also authenticate against the server. This uses HTTP Basic auth with the
`hostname` as username and the API-Key as password, i. e. `base64UrlEncode(hostname ':' apiKey)`. Thus, for each
updatable hostname there must be an entry with the corresponding API Key in the API Key JSON file.

In addition to that, the server will verify that the SSH host keys will not have changed, meaning it will query the new
IP address for it's host keys and compare them with the currently verified host keys of the old IP address. The update
will only be accepted if those keys have not changed.
