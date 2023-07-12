# Python LDAP Scripts - Retrieve Server Information

This repository contains two Python scripts that allow you to retrieve information from an LDAP server. The first script is used to test the connection to an LDAP server, while the second script retrieves all groups and exports them to an LDIF file.

## Prerequisites

Before running the scripts, make sure you have the following dependencies installed:

- Python 3.x
- The `ldap3` module (install it by running `pip install ldap3`)

Also, ensure that you have the LDAP server connection information available, including the server URL, credentials (username and password), and the base DN for the search.

## Configuration

Before running the scripts, you need to configure the appropriate settings. Here are the steps to follow:

1. Open the `config.py` file in a text editor.

2. Modify the values of the following variables according to your configuration:

   - `ldap_url`: the URL of the LDAP server (e.g., `ldap://localhost:389`).
   - `ldap_user`: the username to connect to the LDAP server.
   - `ldap_password`: the password to connect to the LDAP server.
   - `ldap_base_dn`: the base DN for retrieving groups (e.g., `ou=groups,dc=example,dc=com`).

Save the changes.

## Script 1: Test LDAP Server Connection



