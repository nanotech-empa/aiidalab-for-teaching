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



* **Git** and **Python**.
Instead of installing Git and Python separately, we recommend installing the Windows Subsystem for Linux (WSL) and using the Ubuntu distribution.
First, you should make sure that you have [WSL 2 running](https://docs.docker.com/desktop/wsl/).
Once this is set, open PowerShell as an administrator and run the following commands:
```bash
wsl --set-default-version 2
wsl --install -d ubuntu
```

There is an important step when working on **Windows**: after downloading and installing Docker (note: Docker Desktop may prompt you to turn on WSL 2 during installation. Read the information displayed on the screen and turn on the WSL 2 feature to continue), open Docker.app, select "without login", skip a couple of survey questions and then move to the settings, Resources, Advanced, check that "You are using the WSL2 backend" is there, then in "Resources --> WSL integration" activate the "Ubuntu" flag.


After this is completed, please open the Ubuntu terminal from the start menu and execute:
```bash
sudo apt update && sudo apt install pipx
```


### Install aiidalab-launch

To install aiidalab-launch, please run the following command in your terminal. **Note the pipx command**

```bash
pipx install aiidalab-launch && pipx ensurepath
```

**NOTE: IF YOU HAVE PROBLEMS OF ANY KIND WITH AIIDALAB-LAUNCH, THERE IS A PROCEDURE TO LAUNCH THE IMAGE ENTIRELY FROM THE DOCKER DESKTOP. CONTACT US**


### Get the aiidalab-for-teaching image

At this point, you can decide to either use a pre-compiled image from the GitHub Container Registry (ghcr.io) or to build the image locally.
The latter approach is recommended if you run on a machine with a different architecture than `x86_64/amd64` and ARM (Macbook Pro with M* processor), in case that the precompiled images don't work.

The following sub-sections require to enter the commands in a terminal (Mac/Linux) or in the Ubuntu WSL terminal (on Windows).

#### Option 1: Download the pre-compiled image using aiidalab-launch and load it to docker



You can configure aiidalab-launch to use the image:
```bash
aiidalab-launch profile add teaching
```

This is for the ** win/linux ** case:
```
port = 8891  # Better to use a different port wrt 8888 which is the default of jupyter-notebook local (if you have it)
default_apps = []
system_user = "jovyan"
image = "ghcr.io/nanotech-empa/aiidalab-for-teaching:latest" # if you have a linux/win intel computer
home_mount = "aiidalab_teaching_home"
extra_mounts = []
```
For **ARM64** you can use the following value for ```image```
```
image = "ghcr.io/nanotech-empa/aiidalab-for-teaching:arm64" # ** M* processor image **
```


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
port = 8891  # Better to use a different port wrt 8888 which is the default of jupyter-notebook local (if you have it)
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
Perfect — here is the clean English version, ready to copy & paste.

---

# Procedure to Create a Multi-Architecture `:main` Image (amd64 + arm64)

## Scenario

* GitHub Actions automatically builds and pushes:

  ```
  ghcr.io/nanotech-empa/aiidalab-for-teaching:main
  ```

  → **amd64 only**

* arm64 is built locally on an Apple Silicon Mac.

* Then both images are merged into a proper multi-architecture manifest.

---

# 1️⃣ Login to GHCR (only once)

```bash
docker login ghcr.io
```

Enter:

* **Username** → your GitHub username
* **Password** → your Personal Access Token (must include `write:packages` and `read:packages`)

If you see:

```
Login Succeeded
```

authentication is correct.

---

# 2️⃣ Wait for GitHub Build to Finish

Wait until GitHub Actions has finished building and pushing:

```
:main   (amd64)
```

Do not proceed before it completes.

---

# 3️⃣ Build and Push arm64 from Your Mac

From the root of the repository:

```bash
docker buildx build \
  --platform linux/arm64 \
  -t ghcr.io/nanotech-empa/aiidalab-for-teaching:main-arm64 \
  --push .
```

This creates and publishes:

```
:main-arm64
```

---

# 4️⃣ Create the Multi-Arch Manifest

Once both images exist:

* `:main` (amd64)
* `:main-arm64` (arm64)

Run:

```bash
docker buildx imagetools create \
  -t ghcr.io/nanotech-empa/aiidalab-for-teaching:main \
  ghcr.io/nanotech-empa/aiidalab-for-teaching:main \
  ghcr.io/nanotech-empa/aiidalab-for-teaching:main-arm64
```

This replaces `:main` with a proper multi-architecture manifest.

---

# 5️⃣ Final Verification

```bash
docker buildx imagetools inspect ghcr.io/nanotech-empa/aiidalab-for-teaching:main
```

You must see:

```
Platform: linux/amd64
Platform: linux/arm64
```

If both platforms are listed, the image is correctly multi-architecture.

---

# 🔁 Repeat After Every Push to `main`

Each time you push to `main`:

1. Wait for GitHub to finish (amd64 build)
2. Build and push `:main-arm64`
3. Recreate the manifest with `imagetools create`
4. Verify

---

This approach keeps the GitHub workflow unchanged and avoids QEMU-based arm64 builds.

## Software attribution and scientific acknowledgements

Please credit [aiidalab-for-teaching](https://github.com/nanotech-empa/aiidalab-for-teaching) and its
[contributors](https://github.com/nanotech-empa/aiidalab-for-teaching/graphs/contributors),
and identify the release or immutable commit used. Existing author,
contributor and funding acknowledgements remain authoritative.

Preserve the copyright and permission notices in [LICENSE](LICENSE)
when copying or distributing copies or substantial portions of MIT-licensed
code. Separately licensed components retain their own notices. A name or
repository link does not replace the applicable licence notices.

For research carried out using this environment or the resulting workflows,
acknowledge [AiiDA](https://github.com/nanotech-empa/.github/blob/main/CITATION_GUIDANCE.md#aiida) and [AiiDAlab](https://github.com/nanotech-empa/.github/blob/main/CITATION_GUIDANCE.md#aiidalab)
when each platform was actually used, following their respective citation
guidance. Cite the scientific software and methods actually used as well.

Credit this teaching environment separately from the AiiDAlab distribution, included apps, teaching material and calculation codes actually used.

The [shared credit guide](https://github.com/nanotech-empa/.github/blob/main/CITATION_GUIDANCE.md) keeps software attribution, licence
compliance and scientific citation requests separate. Scientific citation
requests are not additional MIT licence conditions.
