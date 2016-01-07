# Galaxy-Pipeline
Wrappers, scripts and configuration files for running cluster and identification analysis on a Galaxy installation.

# Installation

## Galaxy and PostgreSQL

Create a new (non-root) user under which Galaxy, the different scripts, wrappers and all the relevant tools will be installed: `sudo useradd -d /home/galaxy -m galaxy`, and set the password with: `sudo passwd galaxy`. By installing Galaxy and the different tools under the same user it reduces potential problems with access rights and tool system paths.

The following folder structure should be followed to avoid problems with some of the reference databases and update scripts:
 - `/home/galaxy`: Main user folder.
 - `/home/galaxy/galaxy`: The cloned github repository of Galaxy.
 - `/home/galaxy/Tools`: Folder in which all the tools will be installed.
 - `/home/galaxy/GenBank`: Will contain the GenBank NT BLAST database.
 - `/home/galaxy/ExtraRef`: Additional databases are placed in this folder.
 - `/home/galaxy/Log`: Contains the log files from the automated update and galaxy management scripts.

Obtain a copy of Galaxy by cloning the Galaxy Git repository: https://github.com/galaxyproject/galaxy/.

Install the PostgreSQL server by running: `sudo apt-get install postgresql postgresql-contrib`.

Make sure PostgreSQL starts on boot by running: `sudo update-rc.d postgresql enable` and start it with: `sudo service postgresql start`.

Create a PostgreSQL user and database that Galaxy can use. First, swap to the Postgres user: `sudo su - postgres`, create a new database with: `createdb galaxydb` and connect to it with: `psql galaxybd`.
After connecting create a new user named galaxy with: `CREATE USER galaxy WITH PASSWORD 'galaxypass';` and set the privileges with: `GRANT ALL PRIVILEGES ON DATABASE galaxydb to galaxy;`.

When PostgreSQL has been set-up, swap back to the normal Galaxy account and continue downloading and installing the tools.

## Wrappers and scripts
Copy the Galaxy .XML wrappers and .SH scripts from the github `Wrappers` folder to the `galaxy/tools/identify/` folder (needs to created if not present).

## Galaxy configuration
Replace the `galaxy.ini`, `tool_conf.xml` and `datatype_conf.xml` files in the main Galaxy folder with the copies from the github `Galaxy_Configuration` folder.

Edit the `galaxy.ini` file so it contains the correct PostgreSQL database name, user and password under the `database_connection` setting, the correct smtp info under the `# -- Mail and notification` section and finally add additional admin users via the `admin_users` setting.

To disable the automatic ZIP extraction in Galaxy (thus allowing users and Galaxy to use ZIP files as input / output for scripts), replace the `galaxy/tools/data_source/upload.py` file with the `upload.py` file from the `Galaxy_Configuration` github folder.

To automatically start Galaxy after booting the system, add the `galaxy` file in the `Galaxy_configuration` folder to `/etc/init.d/`. Make sure the file is executable and add it to the startup scripts with: `sudo update-rc.d galaxy defaults`.

## Tools
The tools listed below that cannot be installed via `apt-get` should be installed in the `/home/galaxy/Tools` folder to avoid problems with paths.

### R
The `Visualize BLAST` and `Clustering` tools use packages that only work in R version 3.2 or higher. R can be installed from the Ubuntu repositories with: `sudo apt-get install r-base`. If the R version in the repositories is outdated add the CRAN repository to your sources list and reinstall.

Once the correct version of R is installed the following packages need to be added:
 - ggplot2
 - [phyloseq (1.7.6 or higher)](http://joey711.github.io/phyloseq/) (The Bioconductor version might be outdated, the github version is prefered.)
Make sure that the listed packages (and their dependencies) are installed.

### CD-HIT-EST
CD-HIT-EST is present in the Ubuntu repositories and can be installed with: `sudo apt-get install cd-hit`.

### PRINSEQ
Download the standalone version from http://prinseq.sourceforge.net. Install the perl modules that are required for the GRAPHS version (see PRINSEQ installation manual). Create symbolic links for the `prinseq-lite` and `prinseq-graphs` scripts in the `/usr/local/bin` directory.

### NCBI-BLAST+ (2.2.28 or higher)
NCBI-BLAST+ 2.2.28 is available in the Ubuntu repositories (14.04 or higher) and can be installed with: `sudo apt-get install ncbi-blast+`.

### Additional scripts
The following Git repositories contain script for filtering and manipulating data and are used by the Galaxy wrappers. Clone the Git repositories and create symbolic links to the `/usr/local/bin` directory for the relevant script.
 - https://github.com/Y-Lammers/BLAST_wrapper, create a symbolic link for `BLAST_wrapper.py`.
 - https://github.com/Y-Lammers/Add_taxonomy, create a symbolic link for `Add_taxonomy.py`.
 - https://github.com/naturalis/HTS-barcode-checker, create a symbolic link for `HTS-barcode-checker`. If the HTS-barcode-checker tools is not cloned into the `Tools` folder the path for the `Retrieve_CITES.py` script needs to be updated in the `HTS-barcode-checker.sh` Galaxy wrapper.
 - https://github.com/Y-Lammers/Abundance_Filter, create a symbolic link for `Abundance_filter.py`.
 - https://github.com/Y-Lammers/CD-HIT-Filter, create a symbolic link for `CD-HIT-Filter.py`.
 - https://github.com/Y-Lammers/Compare_BLAST, create a symbolic link for `Compare_BLAST.py`.
 - https://github.com/Y-Lammers/Resize_nonChimera, create a symbolic link for `Resize_nonChimera.py`.
 - https://github.com/naturalis/Split_on_Primer, create a symbolic link for `Split_on_Primer.py`.
 - https://github.com/Y-Lammers/Expand_BLAST, create a symbolic link for `Expand_BLAST.py`.

### uchime / usearch
Get a copy of usearch from http://www.drive5.com/usearch/download.html (tested for version 7.\*, though newer versions should work). Create a symbolic link for usearch to `/usr/local/bin`.

### Krona Tools
Download Krona Tools from https://github.com/marbl/Krona/wiki/Downloads, after unpacking run the `install.pl` script.

### Trans-Abyss
Download Trans-Abyss from http://www.bcgsc.ca/platform/bioinfo/software/trans-abyss, install by following the installation instructions on the webpage / readme files.

### SOAPdenovo-trans
Download SOAPdenovo-trans from http://soap.genomics.org.cn/SOAPdenovo-Trans.html, unpack the files and create a symbolic link for `SOAPdenovo-Trans-127mer` to the `/usr/local/bin` folder.

# Databases
By default the wrappers and scripts assume that the following local databases are available:
 - A copy of the NCBI GenBank NT BLAST database.
 - The NCBI taxonomy database.
 - BoLD BLAST databases (filtered and unfiltered).
 - UNITE Fungal ITS BLAST database.
 - SILVA LSU and SSU ribosomal BLAST database.

Scripts are available to automatically download and update both NCBI datasets (GenBank and taxonomy) and the BoLD databases. Create a folder called `GetUpdate` in the `/home/galaxy/Tools` folder. Copy the files from the `Data_Scripts` github folder to the `GetUpdate` folder. Run the `GetTax.sh` script to download the taxonomy database (make sure that the `/home/galaxy/ExtraRef` folder exists). Run the `GetNT.sh` script to download a new copy of the NCBI GenBank NT BLAST database (The `/home/galaxy/GenBank` folder needs to be present). To make sure that the NCBI-BLAST+ tool can find the NT database copy the `ncbirc` file from the `Galaxy_Configuration` folder to the following location: `/home/galaxy/.ncbirc`. Finally, run the `Scrape_BOLD.sh` script to obtain two copies (filtered and unfiltered) of the BoLD database.

The UNITE and SILVA databases must be downloaded and configured manually.

The UNITE data can be downloaded from: https://unite.ut.ee/repository.php. Download the annotated FASTA dataset (including singletons) and place it in the `/home/galaxy/ExtraRef` folder, run the following command to create the BLAST database: `makeblastdb -in [UNITE fasta file] -dbtype nucl`. If the makeblastdb program returns an error, clean the UNITE fasta file with the `Clean_FASTA.py` script in the `Data_Scripts` folder.

The SILVA data can be downloaded from: http://www.arb-silva.de/no_cache/download/archive/. Navigate to the latest SILVA release and open the "Exports" folder. Download the "LSURef_tax_silva_trunc.fasta.gz" and "SSURef_tax_silva_trunc.fasta.gz" files into the `/home/galaxy/ExtraRef` folder. Decompress the files and run the `Clean_FASTA.py` script from the `Data_Scripts` folder to clean the headers and sequences. To create the BLAST databases run the makeblastdb program separately for each of the two SILVA files (`makeblastdb -in [SILVA fasta file] -dbtype nucl`). 

# Starting Galaxy
Even though Galaxy has been set-up to automatically start at boot, it is wise to start it manually the first time. When starting Galaxy for the first time it will automatically download and configure some of the files that require it to run properly, manually starting will allow you to catch any errors that might occur. You can start Galaxy by running the `run.sh` script in the Galaxy folder.

# Managing the Galaxy installation
Once Galaxy, tools and wrappers have been installed several scripts can be planned to run at certain times to update the reference databases and clean outdated user data.

Updating the NCBI GenBank, Taxonomy and BoLD databases can be done with the `GetNT.sh`, `GetTax.sh` and `Scrape_BOLD.sh` scripts mentioned before. Galaxy already comes with several scripts for cleaning the user data, these can be found in the following folder: `/home/galaxy/galaxy/scripts/cleanup_datasets` (assuming that Galaxy was installed in the home folder of the galaxy user). A detailed description on how these scripts work can be found on the [Galaxy wiki page](https://wiki.galaxyproject.org/Admin/Config/Performance/Purge%20Histories%20and%20Datasets).

Automatically running the Galaxy and database scripts can be done by setting up cron jobs. A cronfile for the Galaxy and database scripts can be found in the `Galaxy_Configuration` github folder, under the name: `crontab`. To setup cronjobs edit the installed cronfile with the following command: `crontab -e`. The commands from the github cronfile can be copy-pasted into the installed cronfile assuming that the paths to Galaxy, databases and the scripts are correct, if not edit the paths and check if the start times for the scripts are suitable.

