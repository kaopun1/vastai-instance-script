# Makefile for instance

# Default target
.PHONY: all
all: help

# Variables
PYTHON_VERSION = 3.10
PROJECT_NAME = default
JUPYTER_TOKEN = "my_custom_token"

.PHONY: init
init: update_system setup_gcloud download_from_gs pipenv_setup

.PHONY: update_system
update_system:
	sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get install -y git pipenv python3-pip bash-completion curl unzip software-properties-common
	# install python 3.10
	sudo add-apt-repository -y ppa:deadsnakes/ppa
	sudo apt-get update -qq
	sudo apt-get install -y python3.10 python3.10-venv python3.10-dev

	# update pip
	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
	sudo python3.10 get-pip.py
	export LANG=en_US.UTF-8

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
	mkdir -p ./ai_01
	gsutil -m cp -r gs://cloud_instance/instances/ai_01/* ./ai_01

.PHONY: upload_to_gs
upload_to_gs:
	gsutil -m cp -r ./ai_01/* gs://cloud_instance/instances/ai_01/
	gsutil -m cp -r Makefile gs://cloud_instance/

.PHONY: pipenv_setup
pipenv_setup:
	sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
	python3 pip install --upgrade pipenv
	@echo "Setting up pipenv with Python $(PYTHON_VERSION)..."
	# pipenv --python $(PYTHON_VERSION)
	pipenv --python /usr/bin/python3.10
	pipenv install requests
	pipenv shell

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

.PHONY: ollama
ollama:
	@echo "Checking if Ollama is installed..."
	if [ ! -f "/usr/local/bin/ollama" ]; then \
		echo "Ollama could not be found. Installing Ollama..."; \
		curl -fsSL https://ollama.com/install.sh | sh; \
	else \
		echo "Ollama is already installed."; \
	fi

	# ollama serve
	# ollama pull llama3.1

.PHONY: help
help:
	@echo "  Available commands:"
	@echo "  make initialize              # Set up Python environment with pipenv and Jupyter"
	@echo "  make ollama      # Install Ollama and pull llama3.1 model"
	@echo ""
	@echo "  Example usage:"
	@echo "  make setup"
	@echo "  make ollama"
