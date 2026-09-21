# break-fix

Log real errors here. One honest entry beats tutorial copy.

## Example

- Symptom: `kubectl get nodes` hangs from laptop.
- Cause: OCI security list blocked 6443. `ufw` was open, OCI was not.
- Fix: VCN -> Security List -> add ingress 6443/80/443.
