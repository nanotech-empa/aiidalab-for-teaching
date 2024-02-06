# aiidalab-for-teaching
## Local deployment
To build the container locally run teh following command:

```bash
docker build -t aiidalab/teaching .
```

Once the container is built you can create a new profile with aiidalab-launch:
```bash
aiidalab-lauche profile add teaching
```
with the following content:
```
port = 8891
default_apps = []
system_user = "jovyan"
image = "aiidalab/teaching"
home_mount = "aiidalab_teaching_home"
extra_mounts = []
```

### Clean-up:
first remove the container:
```bash
docker rm <container_id>
```
also remove the mounted volume
```bash
docker volume rm aiidalab_teaching_home
```