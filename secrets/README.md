# secrets/

Nothing in this directory is encrypted yet. Keep the repository private.

| File | Contents | Used by |
|---|---|---|
| `fantomtchi7.hash` | yescrypt password hash for the main user | `users.users.fantomtchi7.hashedPasswordFile` (`modules/nixos/core/users.nix`) |

Generate the hash before installing (the build fails with an assertion while the placeholder is in place):

```bash
mkpasswd -m yescrypt > secrets/fantomtchi7.hash
```

Not stored here, but back these up yourself:

- `/var/lib/sbctl` (Secure Boot keys, once lanzaboote is set up)

## Migration to sops-nix (planned)

1. Add the `sops-nix` input and import `sops-nix.nixosModules.sops`.
2. Derive an age key from the host SSH key (`ssh-to-age`) and list it in `.sops.yaml`.
3. Move the hash into `secrets/secrets.yaml` and declare
   `sops.secrets."fantomtchi7-password".neededForUsers = true;`.
4. Point `hashedPasswordFile` at `config.sops.secrets."fantomtchi7-password".path`
   and delete `fantomtchi7.hash`.

Modules only ever read secrets through `*File` options, so nothing else has to change.
