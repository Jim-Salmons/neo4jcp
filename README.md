Neo4jCP
=======

__Project home__: http://jim-salmons.github.io/neo4jcp/ (including screencast overview)

__Neo4jCP__ is a compact and convenient Control Panel for *managing Neo4j databases* and *controlling a Neo4j Server Service*. It runs as a __tray icon utility__ under __Windows OS__. An executable is provided for those who just want to use it. Source for the __Autohotkey script__ is provided.

__Features__: You may start, stop, and restart the Neo4j Server Service from Neo4jCP as well as create, clone/copy, back-up, delete, and quickly switch between any databases available in your Neo4j 'data' storage folder/path.

__Intended Use__: Neo4j Control Panel is a lightweight, convenient utility primarily for PERSONAL use by individuals running Neo4j locally on a Windows machine for learning and development purposes. It is especially designed for 'learning by doing' using the many available sample databases referenced in Neo4j learning materials such as: http://www.neo4j.org/develop/example_data. (This is NOT a Control Panel intended for use by professional DBAs or sysadmins needing an admin tool for deployed Neo4j systems.)

__Current State__: "I've scratched my itch." This utility was developed initially to help me during personal learning of Neo4j. Its emphasis is on quickly and easily switching among, adding, cloning/copying, and backing up multiple databases. This utility has not been tested on anything other than my personal development box which is Windows 7 x64. YMMV.

### Enabling the Built-in Windows Administrator User Account

If you are running Windows Vista, 7, or 8, you may need to enable your built-in __Windows 'Administrator' User account__ for this Control Panel to function correctly. 

Neo4jCP must spawn processes that run as the built-in Windows 'Administator' User when controlling the Neo4j Server Service. Note that launching an application or command prompt 'As Administrator' under later Windows versions is NOT the same as having the 'Administrator' User account enabled.

It is easy to enable your built-in 'Administrator' User account if it is not already available. Simply open an administrator-elevated command prompt window and enter this command:

```
net user administrator /active:yes
```

Disabling is just as easy:

```
net user administrator /active:no
```

Here's a link to the helpful, illustrated article at HowToGeek.com that helped my understand/use this feature:

http://www.howtogeek.com/howto/windows-vista/enable-the-hidden-administrator-account-on-windows-vista/

### IMPORTANT: Once enabled...

You will need to go to the Manage User Accounts section of the Windows Control Panel for your version of Windows, select the newly visible Administrator User account, then set its password. Once the 'Administrator' password is set, you are ready to configure Neo4jCP for routine use with no or on-first-use privilege-elevation prompts. You may choose one of two methods to handle admin authentication:

1. You can enter the 'Administrator' password in your Neo4jCP.ini file so you won't have to enter it ever when using Neo4jCP.

2. Simply provide it once per application-run when first needed. Neo4jCP will remember your 'Administrator' password while it is active in memory, thereby eliminating the need to prompt for admin-elevation permissions during routine use of Neo4jCP.

### Other Bits

__Before Use__: Read through and edit the Neo4jCP.ini file to configure the Control Panel for your set-up and preferences. Be sure to adjust all paths to match your local configuration.

If you prefer to run Neo4jCP from its Autohotkey script source, simply install Autohotkey from http://www.autohotkey.com/ and run the Neo4jCP.ahk script together with its associated files found in the 'source' subfolder of the Neo4jCP repository or the project's zip file. Better yet, do you have an 'itch to scratch' that pushes Neo4jCP forward? Fork it! :-)

For your convenience, there is a batch file in the sources folder to compile the script so that the Neo4jCP icon is associated with the produced executable.

Feedback welcome through the Project's GitHub Issues at: https://github.com/Jim-Salmons/neo4jcp/issues

--Jim Salmons-- Cedar Rapids, Iowa USA
