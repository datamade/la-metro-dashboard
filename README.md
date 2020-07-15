# la-metro-dashboard
An Airflow-based dashboard for LA Metro

## Running the app locally

### Requirements

- [Docker](https://hub.docker.com/search/?type=edition&offering=community)

### Getting started

Perform the following steps from your terminal.

1. Clone this repository and its submodule, then `cd` into the superproject.

    ```bash
    git clone --recursive https://github.com/datamade/la-metro-dashboard.git
    cd la-metro-dashboard
    ```
2. Build and run the la-metro-dashboard applicaton.

    ```bash
    docker-compose build
    ```

3. Once the command exits, follow the instructions to build the [LA Metro Councilmatic application](https://github.com/datamade/la-metro-councilmatic#setup)

4. In order to run the la-metro-dashboard application, the la-metro-councilmatic app must already be running. Open a new shell, move into the la-metro-councilmatic application, and run it.

	```bash
    cd la-metro-councilmatic && docker-compose up app
    ```

	Once la-metro-councilmatic is running, in your first shell, run the la-metro-dashboard application.

	```bash
	docker-compose up
	```

5. Finally, to visit the dashboard app, go to http://localhost:8080/admin/. The councilmatic app runs on http://localhost:8000/.

### Managing dependency secrets

The dashboard runs DAGs from two application images stored in Dockerhub:

- [`scrapers-us-municipal`](https://hub.docker.com/repository/docker/datamade/scrapers-us-municipal)
- [LA Metro Councilmatic](https://hub.docker.com/repository/docker/datamade/la-metro-councilmatic)

When DAGs are run, [our custom Docker operator](operators/blackbox_docker_operator.py)
tries to decrypt the bundled application secrets using your local GPG keyring.
This does not seem to work for GPG keys with a passphrase, i.e., your personal
GPG key. If decryption fails, the dashboard will fall back to using the example
settings files. (See [`scripts/concat_settings.sh`](scripts/concat_settings.sh).)

#### `scrapers-us-municipal`

Scrapes will run with the default settings file. **Note that running the bill
scrape without the encrypted token will not capture private bills,** however it
should provide enough signal to test whether scrapes are working unless you are
specifically trying to test private bill logic. (I would recommend pulling down
[our fork](https://github.com/datamade/scrapers-us-municipal/) and running the
scrapers locally, rather than via the dashboard, for that type of development.)

#### LA Metro Councilmatic

Metro processing requires AWS credentials and a SmartLogic API token, i.e.,
**Metro DAGs will fail locally without decrypted secrets.**

If you need to test the Metro ETL pipeline, I would suggest manually deploying
your branch to staging and running the DAGs there, as the server has the
appropriate keys to decrypt Metro application secrets.

If you must work locally, you can follow steps 1-5 in our instructions for
[moving keys between servers](https://github.com/datamade/how-to/blob/master/shell/moving-keys-between-servers.md)
to export the public key, then log out of the server and `scp` it down to your
computer:

```bash
scp ubuntu@lametro-upgrade.datamade.us:/home/ubuntu/pubkey.txt .
gpg --import pubkey.txt
```

Don't forget to remove `pubkey.txt` from the server and from your local machine
after you've imported the keys successfully.

Now you can run Metro DAGs locally using decrypted secrets.
