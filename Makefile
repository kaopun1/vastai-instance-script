# Makefile for instance

# Default target
.PHONY: all
all: help

# Variables
PYTHON_VERSION = 3.10
PROJECT_NAME = default
FOLDER_NAME = ai_01
JUPYTER_TOKEN = "my_custom_token"

.PHONY: init
init: update_system setup_gcloud download_from_gs
# removed pipenv_setup

.PHONY: update_system
update_system:
	echo "export LANG=en_US.UTF-8" >> ~/.bashrc
	sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get install -y git pipenv python3-pip bash-completion curl unzip software-properties-common

.PHONY: install_python_lib
install_python_lib:
	python3 -m pip install transformers tensorflow

.PHONY: install_python_library_and_jupyter
install_python_library_and_jupyter:
	python3 -m pip install jupyterlab transformers tensorflow[and-cuda] 
	python3 -m ipykernel install --user --name=my_env --display-name "my_env"
	@echo "==== To run jupyterlab==="
	# jupyter lab --allow-root --NotebookApp.token=$(JUPYTER_TOKEN) --NotebookApp.password=''


.PHONY: install_python_3.10
install_python_3.10:
	sudo add-apt-repository -y ppa:deadsnakes/ppa
	sudo apt-get update -qq
	sudo apt-get install -y python3.10 python3.10-venv python3.10-dev

	# update pip
	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
	sudo python3.10 get-pip.py
	sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

.PHONY: setup_gcloud
setup_gcloud:
	@echo "Installing Google Cloud SDK..."
	# Add the Cloud SDK distribution URI as a package source
	echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
	
	# Import the Google Cloud public key
	curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/cloud.google.gpg
	
	sudo apt-get update && sudo apt-get install -y google-cloud-sdk

	# Authenticate using the service account key file
	@echo "Authenticating using service account..."
	gcloud auth activate-service-account --key-file=./access_gs_cloud_instance.json

	# Set the default project for gcloud and gsutil
	@echo "Setting project ID..."
	gcloud config set project grand-karma-281915 --quiet

.PHONY: download_from_gs
download_from_gs:
	mkdir -p ./$(FOLDER_NAME)
	gsutil -m cp -r gs://cloud_instance/instances/$(FOLDER_NAME)/* ./$(FOLDER_NAME)

.PHONY: upload_to_gs
upload_to_gs:
	gsutil -m cp -r ./$(FOLDER_NAME)/* gs://cloud_instance/instances/$(FOLDER_NAME)/
	gsutil -m cp -r Makefile gs://cloud_instance/

.PHONY: pipenv_setup
pipenv_setup:	
	export LANG=en_US.UTF-8
	python3 -m pip install --upgrade pipenv
	@echo "Setting up pipenv with Python $(PYTHON_VERSION)..."
	# pipenv --python $(PYTHON_VERSION)
	pipenv --python python3
	# (disable) pipenv --python /usr/bin/python3.10
	pipenv install requests
	# pipenv shell

.PHONY: jupyter_setup
jupyter_setup:
	@echo "Installing Jupyter within the pipenv environment..."
	pipenv install jupyter
	@echo "Installing Jupyter kernel for the environment..."
	pipenv run python -m ipykernel install --user --name=${PROJECT_NAME}_env --display-name "$(PROJECT_NAME)"
	@echo "Jupyter kernel has been installed."
	@echo "Running Jupyter Notebook with token..."
	@echo "Jupyter Notebook Token: $(JUPYTER_TOKEN)"
	# Run Jupyter with the predefined token
	pipenv run jupyter notebook --allow-root --NotebookApp.token=$(JUPYTER_TOKEN) --NotebookApp.password=''

.PHONY: ollama_install
ollama_install:
	@echo "Checking if Ollama is installed..."
	if [ ! -f "/usr/local/bin/ollama" ]; then \
		echo "Ollama could not be found. Installing Ollama..."; \
		curl -fsSL https://ollama.com/install.sh | sh; \
	else \
		echo "Ollama is already installed."; \
	fi

	ollama serve &
	# ollama pull llama3.1
	# ollama pull llama3.2:3b

.PHONY: hf_install
hf_install:
	@echo "Installing Huggingface..."
	python3 -m pip install huggingface_hub[cli] huggingface_hub[hf_transfer]
	echo "export HF_HUB_ENABLE_HF_TRANSFER=1" >> ~/.bashrc
	@echo "Please run 'source ~/.bashrc' to apply environment changes."

	# DOWNLOAD MODEL
	# HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download lysandre/arxiv-nlp config.json
	# HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download Thanabordee/openthaigpt1.5-7b-instruct-Q4_K_M-GGUF

	# download mode, create Modelfile, ollama create model ...
	


.PHONY: help
help:
	@echo "  Available commands:"
	@echo "  make init                    # Initialize system, set up Google Cloud, and download from Google Storage"
	@echo "  make update_system           # Update the system packages and install dependencies"
	@echo "  make install_python_3.10     # Install Python 3.10 and set it as default"
	@echo "  make setup_gcloud            # Set up Google Cloud SDK and authenticate"
	@echo "  make download_from_gs        # Download files from Google Storage"
	@echo "  make upload_to_gs            # Upload files to Google Storage"
	@echo "  make pipenv_setup            # Set up the pipenv environment with Python $(PYTHON_VERSION)"
	@echo "  make jupyter_setup           # Set up Jupyter Notebook within the pipenv environment"
	@echo "  make ollama_install          # Check and install Ollama if not present"
	@echo "  make install_python_lib      # Install Python libraries (Transformers and TensorFlow)"
	@echo "  make install_python_library_and_jupyter  # Install JupyterLab and additional Python libraries"
