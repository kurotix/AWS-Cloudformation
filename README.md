# Tutorial: Héberger un blog WordPress sur Amazon Linux 2 

Ce TP, a pour objectif de synthétiser l'installation de wordpress sur une instance, mais aussi l'installation de wp-cli. De plus, à travers les autres fichiers présent sur ce projet. Nous pouvons y trouver un fichier yaml accompagné d'un script pour l'instancier.

**Important**  
Ces procédures sont destinées à être utilisées avec Amazon Linux 2. 

**Topics**
+ [Pre-requis](#hosting-wordpress-prereqs)
+ [Installation de wordpress](#install-wordpress)

## Pre-requis<a name="hosting-wordpress-prereqs"></a>

Ce tuto admet que vous avez lancé une instance Amazon Linux 2 avec un serveur Web fonctionnel prenant en charge PHP et une base de données (MySQL ou MariaDB) en suivant toutes les étapes du didacticiel : Installer un serveur Web LAMP sur l'AMI Amazon Linux pour le didacticiel : Installez un serveur Web LAMP sur Amazon Linux 2 pour Amazon Linux 2. Ce didacticiel contient également des étapes de configuration d'un groupe de sécurité pour autoriser le trafic HTTP et HTTPS, ainsi que plusieurs étapes pour garantir que les autorisations de fichiers sont correctement définies pour votre serveur Web. 

## Installation de Wordpress<a name="install-wordpress"></a>

**Pour télécharger et décompresser le package d'installation de WordPress**

1. Téléchargez le dernier package d'installation de WordPress avec la commande wget. La commande suivante doit toujours télécharger la dernière version.

   ```
   [ec2-user ~]$ wget https://wordpress.org/latest.tar.gz
   ```

2. Décompressez et désarchivez le package d'installation\. Le dossier d'installation est décompressé dans un dossier appelé `wordpress`\.

   ```
   [ec2-user ~]$ tar -xzf latest.tar.gz
   ```<a name="create_user_and_database"></a>
   
**Pour créer un utilisateur de base de données et une base de données pour votre installation WordPress**
Votre installation WordPress doit stocker des informations, telles que des articles de blog et des commentaires d'utilisateurs, dans une base de données\. Cette procédure vous aide à créer la base de données de votre blog et un utilisateur autorisé à lire et à enregistrer des informations sur celle-ci\.
1. Démarrage du serveur de base de donnée\.
   + 
     ```
     [ec2-user ~]$ sudo systemctl start mariadb
     ```
1. Connectez-vous au serveur de base de données en tant qu'utilisateur `root`\. Entrez le mot de passe "root" de votre base de données lorsque vous y êtes invité ; celui-ci peut être différent de votre mot de passe système `root`, ou il peut même être vide si vous n'avez pas sécurisé votre serveur de base de données\.
   
   ```
   [ec2-user ~]$ mysql -u root -p
   ```
1. <a name="create_database_user"></a>Créez un utilisateur et un mot de passe pour votre base de données MySQL\. L'installation WordPress utilise ces valeurs pour communiquer avec la base de données MySQL\. Entrez la commande suivante, en remplaçant un nom d'utilisateur et un mot de passe uniques d\.
   ```
   CREATE USER 'wordpress-user'@'localhost' IDENTIFIED BY 'your_strong_password';
   ```
   Make sure that you create a strong password for your user\. Do not use the single quote character \( ' \) in your password, because this will break the preceding command\. For more information about creating a secure password, go to [http://www\.pctools\.com/guides/password/](http://www.pctools.com/guides/password/)\. Do not reuse an existing password, and make sure to store this password in a safe place\.
1. <a name="create_database"></a>Creation de la base de donnée\. Give your database a descriptive, meaningful name, such as `wordpress-db`\.

   ```
   CREATE DATABASE `wordpress-db`;
   ```
1. Grant full privileges for your database to the WordPress user that you created earlier\.
   ```
   GRANT ALL PRIVILEGES ON `wordpress-db`.* TO "wordpress-user"@"localhost";
   ```
1. Flush the database privileges to pick up all of your changes\.
   ```
   FLUSH PRIVILEGES;
   ```
1. Exit the `mysql` client\.
   ```
   exit
   ```
**Pour créer et éditer wp\-config\.php file**

Le dossier d'installation de WordPress contient un exemple de fichier de configuration appelé `wp-config-sample.php`\. Dans cette procédure, nous allons copier ce fichier et le modifiez pour l'adapter à votre configuration spécifique\.

1. Copier le fichier `wp-config-sample.php` dans un fichier nommé `wp-config.php`\. Cela crée un nouveau fichier de configuration et conserve intact le fichier d'exemple d'origine en tant que fichier de sauvegarde\.
   ```
   [ec2-user ~]$ cp wordpress/wp-config-sample.php wordpress/wp-config.php
   ```
2. Modifier le fichier `wp-config.php` avec un éditeur de texte \(tel que nano ou vim\) et entrer les valeurs pour votre installation\.
   ```
   [ec2-user ~]$ nano wordpress/wp-config.php
   ```
   1. Identifier la ligne qui définit `DB_NAME` et remplacer `database_name_here` par le nom de la base de données que nous avons créée auparavant (#create_user_and_database)\.
      ```
      define('DB_NAME', 'wordpress-db');
      ```
   2. Identifier la ligne qui définit `DB_USER` et remplacer `username_here` par l'utilisateur de base de données que nous avons créé à précédemment\.
      ```
      define('DB_USER', 'wordpress-user');
      ```
   3. Identifier la ligne qui définit `DB_PASSWORD` et remplacer `password_here` par le mot de passe fort que nous avons créé précédemment\.
      ```
      define('DB_PASSWORD', 'your_strong_password');
      ```
   4. Sauvegarder le fichier et quitter l'éditeur de texte\.

**Autoriser WordPress à utiliser des permaliens**

Les permaliens WordPress doivent utiliser les fichiers Apache `.htaccess` pour fonctionner correctement, mais cela n'est pas activé par défaut sur Amazon Linux\. Nous allons de ce fait, suivre la procédure ci-dessous\.

1. Ouvrez le fichier `httpd.conf` avec votre éditeur de texte préféré \(tel que nano ou vim\)\. Si vous n'avez pas d'éditeur de texte favori, "nano" convient aux débutants\.

   ```
   [ec2-user ~]$ sudo vim /etc/httpd/conf/httpd.conf
   ```

2. Identifier la section qui commence par `<Directory "/var/www/html">`\.

   ```
   <Directory "/var/www/html">
       #
       # Possible values for the Options directive are "None", "All",
       # or any combination of:
       #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
       #
       # Note that "MultiViews" must be named *explicitly* --- "Options All"
       # doesn't give it to you.
       #
       # The Options directive is both complicated and important.  Please see
       # http://httpd.apache.org/docs/2.4/mod/core.html#options
       # for more information.
       #
       Options Indexes FollowSymLinks
   
       #
       # AllowOverride controls what directives may be placed in .htaccess files.
       # It can be "All", "None", or any combination of the keywords:
       #   Options FileInfo AuthConfig Limit
       #
       AllowOverride None
   
       #
       # Controls who can get stuff from this server.
       #
       Require all granted
   </Directory>
   ```

3.Changer `AllowOverride None` ligne dans la section par ceci `AllowOverride All`\.
**Note**  
Il y a plusieurs `AllowOverride` lignes dans ce fichier ; il faut s'assurer de changer la ligne dans le
 `<Directory "/var/www/html">` section\.

   ```
   AllowOverride All
   ```

4. Enregistrez le fichier et quittez votre éditeur de texte\.

**Mise en place de l'installation de la librairie PHP sur Amazon Linux 2**  
La bibliothèque GD pour PHP nous permet de modifier des images\. \.

Utilisez la commande suivante pour installer la librairie PHP sur Amazon Linux 2\. 

```
[ec2-user ~]$ sudo yum install php-gd
```

Pour vérifier la dernière version, utiliser la commande suivante:

```
[ec2-user ~]$ php80-php-gd.x86_64                     8.0.17-1.el7.remi                     remi
```

Voici un exemple de sortie:

```
php-gd.x86_64                     7.2.30-1.amzn2             @amzn2extra-php7.2
```

**Exécutez le script d'installation de WordPress avec Amazon Linux 2**

Nous sommes prêt à installer WordPress\. Les commandes que nous utilisions dépendent du système d'exploitation\. Les commandes de cette procédure sont à utiliser avec
Amazon Linux 2\.

1. Utiliser la commande systemctl pour s'assurer que les services "httpd" et de base de données démarrent à chaque démarrage du système\.

   ```
   [ec2-user ~]$ sudo systemctl enable httpd && sudo systemctl enable mariadb
   ```

2. Vérifier que le serveur de base de données est en cours d'exécution\.

   ```
   [ec2-user ~]$ sudo systemctl status mariadb
   ```

   Si le service de base de données n'est pas en cours d'exécution, le démarrer\.

   ```
   [ec2-user ~]$ sudo systemctl start mariadb
   ```

3. Vérifier que notre serveur Web Apache \(`httpd`\) est en cours d'exécution\.

   ```
   [ec2-user ~]$ sudo systemctl status httpd
   ```

  Si le service `httpd` n'est pas en cours d'exécution, le démarrer\.

   ```
   [ec2-user ~]$ sudo systemctl start httpd
   ```

**Installation du wp\-cli**

1. S'authentifier à son  instance EC2 avec SSH\. 

  1. Installation du wp-cli\.
   ```
   [ec2-user ~]$ curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  
   ```
  2. Checker la version pour confirmer que son installation a bien était réalisé via la commande suivante:
  
  ```
   [ec2-user ~]$ php wp-cli.phar --info  
  ```
  3. Pour utiliser WP-CLI à partir de la ligne de commande en tapant wp, rendez le fichier exécutable et déplacez-le quelque part dans votre PATH. Par exemple:
    ```
   [ec2-user ~]$ chmod +x wp-cli.phar
   [ec2-user ~]$ sudo mv wp-cli.phar /usr/local/bin/wp  
  ```
  4. Si WP-CLI a été installé correctement, nous devons obtenir le résultat suivant quand nous executons: wp --info
    ```
   [ec2-user ~]$ wp --info
  OS:	Ubuntu 20.04
  Shell:	/bin/zsh
  PHP binary:    /usr/local/bin/php
  PHP version:    8.1.0
  php.ini used:   /etc/local/etc/php/php.ini
  WP-CLI root dir:        /home/wp-cli/.wp-cli/vendor/wp-cli/wp-cli
  WP-CLI vendor dir:	    /home/wp-cli/.wp-cli/vendor
  WP-CLI packages dir:    /home/wp-cli/.wp-cli/packages/
  WP-CLI global config:   /home/wp-cli/.wp-cli/config.yml
  WP-CLI project config:
  WP-CLI version: 2.6.0
  ```
  
  # Annexes
  ![image](https://user-images.githubusercontent.com/35796644/175831211-18e75a21-9399-4b30-958f-04350a4a3fca.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831220-41f339db-4b96-4463-9871-4a43044ed0f3.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831221-0e9d5822-f29f-40e1-945d-66f3f91215e3.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831226-9050e2c1-8956-4fde-b251-4e7c945477db.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831232-a2d4abce-6ed6-4420-a58c-6e80663ff9f8.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831239-329dc58a-54ec-4b37-a7f4-2f0a3e1287cb.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831245-bfefa8c3-e5af-4823-9ca3-1a0dee78216e.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831248-9864b6f4-6ea8-47bc-949d-b27e3f88a568.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831256-88e42edd-1481-47db-9748-8715d765a3d5.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831260-2c04ce4d-d643-440e-b9c0-1143ae5a9545.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831263-260a4138-5aea-40bf-851c-62dce18221f1.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831268-a8553dfa-5dad-4ccb-a440-970172f81602.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831271-f2ac2cef-8d80-4109-b9ac-c38cdcd1e0a5.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831274-dee10ef2-7ea5-4b89-af6f-9f193e60b9d3.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831277-5f7505d7-2970-44d9-9062-1a20ada2c8b7.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831284-e9bd83a0-eb77-425d-8ba7-33adf6b7fb8e.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831287-7bef58ca-7e0f-451f-8a2b-37289a043889.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831290-a4716f7a-4392-413c-8a99-57ebd0e89259.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831297-2da7c32e-ec43-4053-806d-a307cc02a377.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831300-2c7f5720-f194-4c82-a53f-7a8438630e68.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831311-c0dc6e60-a3f7-4259-bacd-30c3b5734e3e.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831313-0aa5b6fe-23ba-4d7c-8059-32d0b5aca46c.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831315-b1892c93-e40e-4ac5-9743-667f41ff6c1e.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831317-509f4690-9381-4fef-81cd-cceff12be822.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831319-43e0151b-bfe4-4cf1-afff-6a407235b226.png)
  ![image](https://user-images.githubusercontent.com/35796644/175831321-ddfa1a59-2609-49a3-81d5-57f9dbe813d1.png)





Author: Ilyes, Aurélie, Brandon
