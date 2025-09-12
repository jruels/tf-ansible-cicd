# cri_dockerd (Ubuntu 24.04)

Installs the latest stable (non-prerelease) `cri-dockerd` from GitHub Releases, places the binary in `/usr/local/bin`, installs upstream systemd unit/socket, adjusts ExecStart, reloads systemd, enables and starts the socket.

## Variables

- `cri_dockerd_version`: `"latest"` or a specific tag like `"v0.3.20"`.
- `cri_dockerd_bin_dir`: Install path (default `/usr/local/bin`).
- `cri_dockerd_manage_service`: Manage systemd units (default `true`).

## Example Playbook

```yaml
- hosts: ubuntu_nodes
  become: true
  gather_facts: yes
  roles:
    - role: cri_dockerd
      vars:
        # Optional: pin a version
        # cri_dockerd_version: "v0.3.20"
```
