# aiidalab-for-teaching
## Local deployment

### Prerequisites

To run the AiiDAlab for teaching on your local machine, we recommend to have Docker and Python installed.
Since the instructions depend on the operating system, please select the appropriate section below.

#### Linux/Mac

* **Docker**.
To install Docker, please follow the instructions available on the Docker website for [Linux](https://docs.docker.com/desktop/install/linux-install/) or [Mac](https://docs.docker.com/desktop/install/mac-install/).


* **Git**.
Usually, Git is already installed on Linux and Mac.
If not, please install it using the package manager of your operating system.
For instance, on Ubuntu, you can install Git by running the following command:
```bash
sudo apt update && sudo apt install git
```

On Mac, you can install Git using [Homebrew](https://brew.sh/):
```bash
brew install git
```

* **Python**.
Python is also quite often pre-installed on Linux and Mac.
If this is not the case, we recommend installing Python through Conda the minimal installed named Miniconda.
The installation instructions are available on the [Conda website](https://docs.conda.io/en/latest/miniconda.html).


#### Windows

* **Docker**.
The Docker Desktop for Windows can be installed from the [Docker website](https://docs.docker.com/desktop/install/windows-install/).

There is an important step when working on **Windows**: after downloading and installing Docker (note: Docker Desktop may prompt you to turn on WSL 2 during installation. Read the information displayed on the screen and turn on the WSL 2 feature to continue), open Docker.app, select "without login", answer a couple of survey questions and then move to the settings, Resources, Advanced, check that "You are using the WSL2 backend" is there, then in "Resources --> WSL integration" activate the "Ubuntu" flag (note: if the flag is still not there, repeat this check after the next step).

* **Git** and **Python**.
Instead of installing Git and Python separately, we recommend installing the Windows Subsystem for Linux (WSL) and using the Ubuntu distribution.
First, you should make sure that you have [WSL 2 running](https://docs.docker.com/desktop/wsl/).
Once this is set, open PowerShell as an administrator and run the following commands:
```bash
wsl --set-default-version 2
wsl --install -d ubuntu
```
After this is completed, please open the Ubuntu terminal from the start menu and execute:
```bash
sudo apt update && sudo apt install pipx
```


### Install aiidalab-launch

To install aiidalab-launch, please run the following command in your terminal:

```bash
pipx install aiidalab-launch
```



### Get the aiidalab-for-teaching image

At this point, you can decide to either use a pre-compiled image from the GitHub Container Registry (ghcr.io) or to build the image locally.
The latter approach is recommended if you run on a machine with a different architecture than `x86_64` (e.g. ARM, e.g. Macbook Pro with M* processor).

The following sub-sections require to enter the commands in a terminal (Mac/Linux) or in the Ubuntu WSL terminal (on Windows).

#### Option 1: Pull the pre-compiled image

You can configure aiidalab-launch to use the image that was built by us:
```bash
aiidalab-launch profile add teaching
```
the content will be similar to the following:
```
port = 8891  # in your case might be different, keep the automatically generated value
default_apps = []
system_user = "jovyan"
image = "ghcr.io/nanotech-empa/aiidalab-for-teaching:main" # make sure to use this link
home_mount = "aiidalab_teaching_home"
extra_mounts = []
```
For **ARM64** you can use the following value for ```image```
```
image = "ghcr.io/nanotech-empa/aiidalab-for-teaching:arm64"
```

> [!WARNING]
> The `docker pull` command might not work. To fix that, you need to authenticate to GitHub first:
> ```bash
> docker login ghcr.io -u <github-username>
> Password: <your-token>
> ```
> The access token can be created [here](https://github.com/settings/tokens).
> While creating it, please make sure to enable the following permissions:
> ```
> * write:packages
> * read:packages
> * delete:packages
> ```

#### Option 2: Build the image locally

First, make sure the Docker Desktop is running.
Enter a folder where you want to keep the aiidalab-for-teaching repository (`cd /path/to/your/folder`) and run the following command:

```bash
git clone https://github.com/nanotech-empa/aiidalab-for-teaching.git
```
Then enter the repository folder (`cd aiidalab-for-teaching`) and build the container by running the following command:
execute:

```bash
docker build -t aiidalab/teaching .
```

Once the image is built, create a new profile running

```bash
aiidalab-launch profile add teaching
```
the content will be similar to the following:
```
port = 8891  # in your case might be different, keep the automatically generated value
default_apps = []
system_user = "jovyan"
image = "aiidalab/teaching"  # make sure to use this link
home_mount = "aiidalab_teaching_home"
extra_mounts = []
```

### To start the container execute:
```bash
aiidalab-launch start --profile teaching
```
### To stop the container execute:
```bash
aiidalab-launch stop --profile teaching
```
### Clean-up (this will delete everything):

After the container is stopped, you can remove it by running the following command:
```bash
docker rm aiidalab_teaching
```
Also, you should remove the volume that contains all your data.
```bash
docker volume rm aiidalab_teaching_home
```
