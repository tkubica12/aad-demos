# Azure Active Directory labs

This repo contains source files to reproduce various AAD/AD synchronization and authentication demos as presented on https://tomaskubica.cz

## AD to AAD lab (ad-aad-lab)
For testing various synchronization scenarios you might want to deploy simulated infrastructure. This ARM template and DSC scripts will automatically create testing environment consisting of one AD domain controller, one Windows VM joined to domain and one Windows VM not joined to VM.