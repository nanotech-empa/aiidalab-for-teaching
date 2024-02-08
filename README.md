# aiidalab-for-teaching
## Local deployment
To build the container locally run the following command:

```bash
docker build -t aiidalab/teaching .
```

Once the container is built, you can create a new profile with aiidalab-launch:
```bash
aiidalab-launch profile add teaching
```
with the following content:
```
port = 8891
default_apps = [ "mfa-cscs", "quantum-espresso",]
system_user = "jovyan"
image = "aiidalab/teaching"
home_mount = "aiidalab_teaching_home"
extra_mounts = []
```

### Clean-up:
First, remove the container:
```bash
docker rm <container_id>
```
Also, remove the mounted volume:
```bash
docker volume rm aiidalab_teaching_home
```