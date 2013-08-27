neo4jcp_private
===============

Neo4jCP is a compact and convenient Control Panel for managing Neo4j databases and controlling a Neo4j Server Service. It runs as a tray icon utility under Windows OS. An executable is provided for those who just want to use it. Source for the Autohotkey script is provided.

Enabling the Built-in Windows Adminstrator User Account
=======================================================

If you are running Windows Vista, 7, or 8, you may need to enable your built-in Windows 'Administrator' User account for this Control Panel to function correctly. 

Neo4jCP must spawn processes that run as the built-in Windows 'Administator' User when controlling the Neo4j Server Service. Note that launching an application or command prompt 'As Administrator' under later Windows versions is NOT the same as having the 'Administrator' User account enabled.

It is easy to enable your built-in 'Administrator' user account if it is not already available. Simply open an adminstrator-elevated command prompt window and enter this command:

```
net user administrator /active:yes
```

Disabling is just as easy:

```
net user administrator /active:no
```

Here's a link to the helpful, illustrated article at HowToGeek.com that scratched this itch for me:

http://www.howtogeek.com/howto/windows-vista/enable-the-hidden-administrator-account-on-windows-vista/

IMPORTANT: Once enabled...
==========================

You will need to go to the Manage User Accounts section of the Windows Control Panel, select the newly visible Administrator User account, then set its password. Once the 'Administrator' password is set, you may configure Neo4jCP to use it:

1. You can enter the 'Administrator' password in your Neo4jCP.ini file so you won't have to enter it ever when using Neo4jCP.

2. Simply provide it once per application-run when first needed. Neo4jCP will remember your 'Administrator' password while it is active in memory, thereby eliminating the need to prompt for admin-elevation permissions during routine use of Neo4jCP.

Other Bits
==========

Edit the Neo4jCP.ini file to configure it for your set-up and preferences. Be sure to adjust all paths to match your local configuration.

If you prefer to run Neo4jCP from its Autohotkey script source, simply install Autohotkey from http://www.autohotkey.com/ and use the Neo4jCP.ahk script and associated files found in the 'source' subfolder of the Neo4jCP repository or the project's zip file. Better yet, do you have an 'itch to scratch' that pushes Neo4jCP forward? Fork it! :-)

--Jim Salmons-- Cedar Rapids, Iowa USA
