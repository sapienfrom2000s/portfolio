# Kubernetes Storage

## Storage in Docker

When a container writes a file, it writes to a **writable layer** on top of the image. This layer is tied to the container's lifecycle — when the container is removed, so is the data.

Docker introduced **volumes** to solve this: a directory on the host that gets mounted into the container. The data lives outside the container and survives restarts.

Docker volumes also define an **access mode** — essentially, who can read and write:

- **Read-Write (`rw`)** — the container can read and modify files. Default.
- **Read-Only (`ro`)** — the container can only read. Useful for config files or secrets you don't want the app to accidentally overwrite.

```bash
# rw (default)
docker run -v /host/data:/app/data my-image

# ro — container cannot modify the mounted files
docker run -v /host/config:/app/config:ro my-image
```

This works fine for a single container on a single host. But Kubernetes runs containers across many nodes — and that changes everything.

---

## Kubernetes Volumes — Start Simple

In Kubernetes, a **Pod** is the unit that runs your containers. Pods are ephemeral — they get killed, rescheduled, replaced. When that happens, any data written inside the container is gone.

The first and simplest solution Kubernetes gives you is `emptyDir`.

```yaml
volumes:
  - name: scratch
    emptyDir: {}
```

Kubernetes creates an empty directory on the node when the Pod starts and mounts it into your containers. Two containers inside the same Pod can share it — useful for a sidecar writing logs that the main app reads.

One variant worth knowing: `medium: Memory` backs the directory with RAM instead of disk (tmpfs). Faster reads and writes, but counts against the container's memory limit and is gone on node restart.

```yaml
volumes:
  - name: fast-scratch
    emptyDir:
      medium: Memory    # RAM-backed — faster but ephemeral and memory-limited
```

The catch: `emptyDir` lives and dies with the **Pod**. If the Pod is deleted and rescheduled, you start with a fresh empty directory. It's scratch space, not persistence.

---

## The Real Problem — Data That Must Survive Pods

Databases, message queues, uploaded files — these can't be lost when a Pod restarts. You need storage that exists **independent of any Pod**.

Kubernetes models this as two separate concerns, intentionally separated:

**PersistentVolume (PV)** — the actual storage. Created by the platform/infra team. Could be an EBS volume, an NFS share, a GCP disk. It's a cluster-level resource that represents real storage.

**PersistentVolumeClaim (PVC)** — a request for storage, written by the developer. It says "I need 10Gi, read-write." Kubernetes finds a PV that satisfies those requirements and binds them together.

```yaml
# Infra team writes this — represents actual storage on the cluster
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce              # Must match what the PVC requests
  persistentVolumeReclaimPolicy: Retain   # Keep the disk even if PVC is deleted
  storageClassName: ""           # Empty string = static (manual) provisioning
  hostPath:
    path: /mnt/data              # On cloud, this would be an EBS/GCP disk reference
```

```yaml
# Developer writes this — Kubernetes matches it to the PV above
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce              # Must match the PV's accessModes
  resources:
    requests:
      storage: 10Gi              # Must be <= PV's capacity
  storageClassName: ""           # Empty string = only match manually created PVs
```

Kubernetes binds them when **capacity, accessModes, and storageClassName all match**. If nothing matches, the PVC stays in `Pending` — one of the most common issues you'll debug.

The access modes here mirror what Docker introduced but at the cluster level:

| Mode | Abbreviation | Meaning |
|---|---|---|
| ReadWriteOnce | RWO | One node can mount it read-write. Standard for databases. |
| ReadOnlyMany | ROX | Many nodes can mount it, read-only. Good for shared config. |
| ReadWriteMany | RWX | Many nodes can mount it read-write. Needs special backends like NFS. |

> PV is supply. PVC is demand. Kubernetes does the matching.

### PVC Lifecycle States

A PVC moves through these states — knowing this helps you debug:

| State | Meaning |
|---|---|
| `Pending` | No matching PV found yet. Check capacity, accessModes, and storageClassName. |
| `Bound` | Matched to a PV. Ready to use. |
| `Released` | The PVC was deleted but the PV still holds the old data. Not yet available for a new claim. |
| `Failed` | Automatic reclaim failed. Manual intervention needed. |

The most common interview question here: *"Your PVC is stuck in Pending — what do you check?"* Answer: does a PV exist with matching accessModes, enough capacity, and the same storageClassName?

### Reclaim Policies

When a PVC is deleted, what happens to the underlying disk? That's controlled by `persistentVolumeReclaimPolicy`:

- **Retain** — the disk is kept, data intact. A human must manually clean up and re-provision. Safe for production databases.
- **Delete** — the disk is deleted automatically. Convenient but destructive. Default for dynamically provisioned volumes.
- **Recycle** *(deprecated)* — runs `rm -rf` on the volume and makes it available again. Replaced by dynamic provisioning.

For production, always use `Retain` on anything stateful. Losing a database because someone deleted a PVC is a bad day.

---

## The Problem With Manual PVs

This model works, but it has an operational bottleneck: **someone has to manually create PVs in advance.**

The platform team needs to pre-provision a pool of volumes in various sizes. Developers open tickets and wait. If you need a 7Gi volume and the smallest available PV is 20Gi, that 20Gi PV gets consumed entirely — wasted capacity. And in multi-zone clusters, a PV created in `us-east-1a` can't be used by a Pod scheduled in `us-east-1b`.

---

## StorageClass — Dynamic Provisioning

A **StorageClass** is a blueprint that tells Kubernetes *how* to create storage automatically when a PVC is submitted. No pre-created PVs needed.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com      # which driver creates the volume
parameters:
  type: gp3                        # what kind of disk (SSD, HDD, etc.)
reclaimPolicy: Retain              # when PVC is deleted: keep or delete the underlying disk?
allowVolumeExpansion: true         # can you grow the volume later?
volumeBindingMode: WaitForFirstConsumer  # don't create the disk until a Pod is actually scheduled
```

`WaitForFirstConsumer` is the fix for the zone mismatch problem — Kubernetes waits until it knows *which node* the Pod lands on, then creates the volume in that same zone.

Now your PVC just references the StorageClass by name, and the disk is created automatically:

```yaml
spec:
  storageClassName: fast-ssd
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

---

## CSI — How Kubernetes Actually Talks to Storage

StorageClass says *what* to provision. **CSI (Container Storage Interface)** is *how* that happens.

Before CSI, every storage plugin (AWS EBS, GCP PD, NFS...) had its code baked into Kubernetes itself. That meant Kubernetes had to be updated every time a storage vendor added a feature or fixed a bug.

CSI moved storage drivers **out of Kubernetes core** into separate plugins that vendors ship and maintain independently. Kubernetes just calls a standard interface — `CreateVolume`, `AttachVolume`, `MountVolume` — and the CSI driver handles the rest. This is why you see `ebs.csi.aws.com` as the provisioner — that's the AWS-maintained EBS CSI driver, not Kubernetes itself.

---

## Projected Volumes — Cleaning Up Config Injection

One last common pattern: your app needs a config file, a secret (DB password), and some Pod metadata all available at the same path.

Without projected volumes, you'd define three separate volumes and three separate `volumeMounts`. A **Projected Volume** collapses multiple sources into a single directory:

```yaml
volumes:
  - name: app-config
    projected:
      sources:
        - configMap:
            name: app-settings
        - secret:
            name: db-credentials
```

One mount point, cleaner Pod spec, and your app just reads files from a single directory without knowing where each file came from.

---

## StatefulSets — Where Storage Meets Production

Everything so far has been about how storage works in isolation. **StatefulSets** is where it comes together for real workloads like databases.

A regular `Deployment` treats all Pod replicas as identical and interchangeable — any Pod can die and be replaced. That breaks for databases, where each replica needs its own dedicated, stable storage.

A **StatefulSet** gives each Pod:
- A stable, predictable name (`postgres-0`, `postgres-1`, `postgres-2`)
- Its own PVC, automatically created via `volumeClaimTemplates`
- The same PVC reattached if the Pod is rescheduled

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 3
  serviceName: postgres
  template:
    spec:
      containers:
        - name: postgres
          image: postgres:15
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:              # Kubernetes creates one PVC per replica
    - metadata:
        name: data
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 20Gi
```

This creates three PVCs automatically: `data-postgres-0`, `data-postgres-1`, `data-postgres-2`. If `postgres-1` crashes and restarts, it gets `data-postgres-1` back — not a fresh volume, not someone else's volume.

> If an interviewer asks "how would you run a database in Kubernetes?" — this is the answer.

---

## RWO and Node Failures — A Practical Gotcha

RWO (ReadWriteOnce) means only **one node** can mount the volume at a time. In normal operation this is fine. But when a node fails, it creates a problem.

Say `postgres-0` is running on `node-A` with an EBS volume attached. `node-A` goes down. Kubernetes reschedules `postgres-0` to `node-B` — but the EBS volume is still attached to `node-A` from Kubernetes' perspective.

Before `node-B` can mount it, Kubernetes must detach it from `node-A`. If the node is truly dead (not just slow), Kubernetes waits for a timeout before force-detaching. This means your Pod can be stuck in `ContainerCreating` for several minutes even though the node is already gone.

This is not a bug — it's a safety mechanism to prevent two nodes writing to the same disk simultaneously (split-brain). But it's something you need to know exists when designing for high availability.

RWX volumes (NFS, EFS) don't have this problem since multiple nodes can mount them simultaneously — but they come with their own performance and consistency tradeoffs.

---

| Type | Survives Pod? | Who manages it? | Use case |
|---|---|---|---|
| `emptyDir` | ❌ No | Kubernetes | Scratch space, shared workspace |
| PV / PVC | ✅ Yes | Infra team (manual) | Persistent storage |
| StorageClass | ✅ Yes | Kubernetes (dynamic) | Persistent storage, automated |
| Projected Volume | Same as source | Developer | Clean config + secret injection |

Each layer exists because the previous one had a gap. That's the thread.
