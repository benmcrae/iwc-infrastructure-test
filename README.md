# Technical test - Ben McRae

Steps of  workflow / implementation.

1. Exploratory testing of server
2. Write remote server spec test

## 1. Exploratory testing

Below are some of my initial findings from navigating the server (this will be updated when new actions are found).

* **[FIX]** Directory owned by root (No apache user)
* **[FIX]** Directory access permissions are set to RWX for 'everyone'
* **[NOTE]** Apache looks to be installed from source
