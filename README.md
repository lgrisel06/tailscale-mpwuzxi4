# Run Tailscale on Render

![image](https://github.com/render-examples/tailscale/assets/168030/2513267e-6503-45c6-b596-3713160ae4ec)

[Tailscale](https://tailscale.com) is a zero-config VPN service built on top of [Wireguard](https://www.wireguard.com/). It's great for accessing devices and applications behind firewalls, and you can use it to connect to all your private services on Render with this repo.

A Tailscale [subnet router](https://tailscale.com/kb/1019/subnets/) acts as a gateway to your Render private network, enabling connections to any and all internal IPs (of the form `10.x.x.x`) in your Render network.

## Deployment

### One Click Deploy

Use the button below to deploy a Tailscale subnet router on Render. [Generate a Tailscale auth key](https://login.tailscale.com/admin/settings/authkeys) and provide that as the `TAILSCALE_AUTHKEY` environment variable in Render. Use a one-off key for maximum security.

The build downloads a static Linux binary from the Tailscale [stable track](https://pkgs.tailscale.com/stable/). Pin the release with `TAILSCALE_VERSION` (set in `render.yaml` for Blueprint deploys, or override in the Render dashboard). Bump it when you want to pick up a newer stable client.

<a href="https://render.com/deploy?repo=https://github.com/render-examples/tailscale/tree/main">
  <img src="https://render.com/images/deploy-to-render-button.svg" alt="Deploy to Render">
</a>

## Usage
Deploying this repo will create a subnet router in your Tailscale network. The first time you deploy, you'll need to [enable the subnet routes](https://tailscale.com/kb/1019/subnets/#step-3-enable-subnet-routes-from-the-admin-panel) you want access to from the Tailscale admin panel. Once the subnet router is up and running, you can connect to other private services in your Render network. To find the internal IP address for a Render private service, go to the web shell for your subnet router service and run `dig` with the [private service's host name](https://render.com/docs/private-services#connecting-to-a-private-service) as the only argument.

## Résolution DNS des hostnames Render depuis le tailnet (CoreDNS + Split DNS)

Le subnet router ci-dessus donne l'accès **par IP** (`10.x`), mais ces IPs changent à
chaque déploiement. Pour utiliser des noms **stables** depuis n'importe quelle machine
du tailnet, ce fork embarque un resolver **CoreDNS** qui relaie vers le DNS interne
Render, exposé au tailnet via le **Split DNS** Tailscale.

En mode `--tun=userspace-networking`, `tailscaled` forwarde les connexions entrantes
vers `localhost`. CoreDNS écoute donc sur `:53` dans le container et reçoit les requêtes
arrivant sur l'IP tailnet du subnet router.

### 1. Variables d'environnement (Render)

| Variable | Obligatoire | Exemple / défaut | Rôle |
|---|---|---|---|
| `RENDER_INTERNAL_DOMAIN` | ✅ | `own-xxxxxxxx.svc.cluster.local` | domaine interne Render réel |
| `TS_DNS_DOMAIN` | — | `feelia.internal` | domaine "joli" exposé dans le tailnet |
| `RENDER_UPSTREAM_DNS` | — | `169.254.20.10` | resolver interne Render |
| `COREDNS_VERSION` | — | `1.12.0` | version de CoreDNS |

> Récupère `RENDER_INTERNAL_DOMAIN` (et vérifie `RENDER_UPSTREAM_DNS`) via le web shell
> du subnet router : `cat /etc/resolv.conf`. Le domaine est la valeur de `search` qui se
> termine par `svc.cluster.local`.

### 2. Split DNS dans la console Tailscale

DNS → **Add nameserver** → **Custom** :

- **Nameserver** : l'IP tailnet du subnet router (ex. `100.91.42.54`)
- **Restrict to domain** activé, et ajoute **deux** domaines pointant vers ce même nameserver :
  - `feelia.internal` (= `TS_DNS_DOMAIN`)
  - `svc.cluster.local` (pour adresser aussi les FQDN Render bruts)

MagicDNS doit être activé.

### 3. Utilisation

Depuis n'importe quelle machine du tailnet :

```bash
curl http://feelia-admin-prod.feelia.internal:8080/login
# ou le FQDN Render natif (stable lui aussi) :
curl http://feelia-admin-prod.<RENDER_INTERNAL_DOMAIN>:8080/login
```

L'IP est résolue à chaque requête : elle suit automatiquement les redéploiements,
sans IP statique ni fichier `hosts`.

