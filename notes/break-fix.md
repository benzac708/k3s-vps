# Break → diagnose → fix

Real incidents from the Oracle/K3s build. These are more useful than a tutorial
because they show how evidence changed the decision.

## Kubernetes API blocked

- **Symptom:** `kubectl get nodes` hung from the laptop.

- **Diagnosis:** `ufw` was open, but the OCI Security List blocked 6443.

- **Fix:** open the API only to the private admin CIDR; public access stays on
  80/443.

## Ollama RWO and rolling update

- **Symptom:** a rolling Deployment could not schedule a second pod while the
  models PVC was mounted.

- **Diagnosis:** the PVC is `ReadWriteOnce` and the namespace quota had no
  headroom for a surge pod.

- **Fix:** use `strategy: Recreate`, one replica, a 10 Gi PVC, explicit requests
  and limits, and a namespace quota.

## Argo CD ApplicationSet restart loop

- **Symptom:** `argocd-applicationset-controller` restarted hundreds of times.

- **Diagnosis:** the controller existed, but the `ApplicationSet` CRD did not;
  the Argo CD v3.5.3 `install.yaml` did not include that CRD.

- **Fix:** apply the pinned `manifests/crds/applicationset-crd.yaml` immediately
  after the pinned Argo CD install, and verify stable restart counts.

## Monitoring Helm timeouts

- **Symptom:** `mon` release history showed failed install/upgrade attempts even
  though most monitoring pods were running.

- **Diagnosis:** Helm timed out waiting for admission/operator readiness on the
  small 4 OCPU node.

- **Fix:** make the monitoring release declarative through Argo CD, pin the
  chart version, and require `helm status` to report `deployed` before calling
  the platform healthy.

## Mutable image delivery

- **Symptom:** Argo CD was `Synced` while the live pod digest differed from the
  digest produced by the latest build.

- **Diagnosis:** the Deployment used `latest` with `imagePullPolicy:
  IfNotPresent`; a Git sync did not necessarily roll the pod.

- **Fix:** deploy an immutable digest, use commit-based promotion, and verify the
  live `imageID` against the CI-produced digest.

## Private corpus access

- **Symptom:** an unauthenticated clone of the corpus repository failed outside
  the developer's credential environment.

- **Diagnosis:** the sample corpus is private and the CronJob had no documented
  read-only credential path.

- **Fix:** make the fictional sample corpus public, or provide a least-privilege
  read-only deploy key in a Kubernetes Secret. Never embed a personal token in a
  manifest.
