# Galaxy-Pipeline
Wrappers, scripts and configuration files for running cluster and identification analysis on a Galaxy installation.

# Installation

## Galaxy and PostgreSQL

Create a new (non-root) user under which Galaxy, the different scripts, wrappers and all the relevant tools will be installed: `sudo useradd -d /home/galaxy -m galaxy`, and set the password with: `sudo passwd galaxy`. By installing Galaxy and the different tools under the same user it reduces potential problems with access rights and system paths.

Obtain a copy of Galaxy by cloning the Galaxy Git repository: https://github.com/galaxyproject/galaxy/.

Install the PostgreSQL server by running: `sudo apt-get install postgresql postgresql-contrib`.

Make sure PostgreSQL starts on boot by running: `sudo update-rc.d postgresql enable` and start it with: `sudo service postgresql start`.

Create a PostgreSQL user and database that Galaxy can use. First, swap to the Postgres user: `sudo su - postgres`, create a new database with: `createdb galaxydb` and connect to it with: `psql galaxybd`.
After connecting create a new user named galaxy with: `CREATE USER galaxy WITH PASSWORD 'galaxypass';` and set the privileges with: `GRANT ALL PRIVILEGES ON DATABASE galaxydb to galaxy;`. When PostgreSQL has been set-up, swap back to the normal Galaxy account and continue downloading and installing the tools.

## Wrappers and scripts
Copy the Galaxy .XML wrappers and .SH scripts from the github `Wrappers` folder to the `galaxy-dist/tools/identify/` folder (needs to created if not present).

## Galaxy configuration
Replace the `galaxy.ini`, `tool_conf.xml` and `datatype_conf.xml` files in the main Galaxy directory with the copies from the github `Galaxy_Configuration` folder.

Edit the `galaxy.ini` file so it contains the correct PostgreSQL database name, user and password under the `database_connection` setting, the correct smtp info under the `# -- Mail and notification` section and finally add additional admin users via the `admin_users` setting.

To disable the automatic ZIP extraction in Galaxy (thus allowing users and Galaxy to use ZIP files as input / output for scripts), replace the `galaxy-dist/tools/data_source/upload.py` file with the `upload.py` file from the `Galaxy_Configuration` github folder.

To automatically start Galaxy after booting the system, add the `galaxy` file in the `Galaxy_configuration` folder to `/etc/init.d/`. Make sure the file is executable and add it to the startup scripts with: `sudo update-rc.d galaxy defaults`.

## R
The `Visualize BLAST` and `Clustering` wrappers use R (version 3.2 or higher) and the following packages:
 - ggplot2
 - [phyloseq (1.7.6 or higher)](http://joey711.github.io/phyloseq/) (The Bioconductor version might be outdated, the github version is prefered.)
Make sure these (and the dependencies are installed).

## CD-HIT-EST
CD-HIT-EST is present in the Ubuntu repositories and can be installed with: `sudo apt-get install cd-hit`.

## PRINSEQ
Download the standalone version from http://prinseq.sourceforge.net. Install the perl modules that are required for the GRAPHS version (see PRINSEQ installation manual). Create symbolic links for the `prinseq-lite` and `prinseq-graphs` scripts in the `/usr/local/bin` directory.

## NCBI-BLAST+ (2.2.28 or higher)
NCBI-BLAST+ 2.2.28 is available in the Ubuntu repositories (14.04 or higher) and can be installed with: `sudo apt-get install ncbi-blast+`.

## Additional scripts
The following Git repositories contain script for filtering and manipulating data and are used by the Galaxy wrappers. Clone the Git repositories and create symbolic links to the `/usr/local/bin` directory for the relevant script.
 - https://github.com/Y-Lammers/BLAST_wrapper, create a symbolic link for `BLAST_wrapper.py`.
 - https://github.com/Y-Lammers/Add_taxonomy, create a symbolic link for `Add_taxonomy.py`.
 - https://github.com/naturalis/HTS-barcode-checker, create a symbolic link for `HTS-barcode-checker`.
 - https://github.com/Y-Lammers/Abundance_Filter, create a symbolic link for `Abundance_filter.py`.
 - https://github.com/Y-Lammers/CD-HIT-Filter, create a symbolic link for `CD-HIT-Filter.py`.
 - https://github.com/Y-Lammers/Compare_BLAST, create a symbolic link for `Compare_BLAST.py`.
 - https://github.com/Y-Lammers/Resize_nonChimera, create a symbolic link for `Resize_nonChimera.py`.
 - https://github.com/naturalis/Split_on_Primer, create a symbolic link for `Split_on_Primer.py`.
 - https://github.com/Y-Lammers/Expand_BLAST, create a symbolic link for `Expand_BLAST.py`.

## uchime / usearch
Get a copy of usearch from http://www.drive5.com/usearch/download.html (tested for version 7.\*, though newer versions should work). Create a symbolic link for usearch to `/usr/local/bin`.

## Krona Tools
Download Krona Tools from https://github.com/marbl/Krona/wiki/Downloads, after unpacking run the `install.pl` script.

## Trans-Abyss
Download Trans-Abyss from http://www.bcgsc.ca/platform/bioinfo/software/trans-abyss, install by following the isntallation instruction in the package.

## SOAPdenovo-trans
Download SOAPdenovo-trans from http://soap.genomics.org.cn/SOAPdenovo-Trans.html, unpack the files and create a symbolic link for `SOAPdenovo-Trans-127mer` to the `/usr/local/bin` folder.

# Starting Galaxy
Even though Galaxy has been set-up to automatically start at boot, it is wise to start it manually the first time. When starting Galaxy for the first time it will automatically download and configure some of the files that require it to run properly, manually starting will allow you to catch any errors that might occur. You can start Galaxy by running the `run.sh` script in the Galaxy folder.
