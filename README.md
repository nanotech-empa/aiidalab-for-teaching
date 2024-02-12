# aiidalab-for-teaching
## Local deployment
[Install docker](https://docs.docker.com/get-docker/) desktop on your pc.

Make sure you have [git installed](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) on your pc

for windows:
open power shell and execute:
```bash
wsl --install
```
open the WSL terminal from the start menu then execute:

```bash
sudo apt update && sudo apt install python3-pip
pip install aiidalab-launch start
```
close the WSL terminal and re-open it
make sure you have [WSL 2 running](https://docs.docker.com/desktop/wsl/):

oepn a terminal in your mac/linux (or WSL for windows) and execute in a appropriate directory (e.g. your home folder or the home in the WSL terminal)
```bash
git clone https://github.com/nanotech-empa/aiidalab-for-teaching.git
```
enter the aiidalab-for-teaching folder:
```bash
cd aiidalab-for-teaching
```

Install aiidalab-launch on your pc

execute:
```bash
pip install aiidalab-launch
```


### Make sure Docker desktop is running

### To use a pre-compiled docker image:
....

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

### To start aiidalab execute
```bash
aiidalab-launch start --profile teaching
```
### To stop execute
```bash
aiidalab-launch stop --profile teaching
```

### Clean-up (will delete everything):
First, remove the container:
```bash
docker rm aiidalab_teaching
```
Also, remove the mounted volume:
```bash
docker volume rm aiidalab_teaching_home
```
