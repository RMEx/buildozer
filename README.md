[Join us on Discord !](https://discord.gg/yRUZcdQ)

# [![RMEx](http://rmex.github.io/images/rmex-shortcut.png)](http://rmex.github.io) [scripts-externalizer](https://github.com/RMEx/OLD_RM_STYLE/blob/master/OLD_RM_STYLE.rb)
> Externalize all scripts from Scripts.rvdata2 (script for RMVXAce)
>
> **scripts-externalizer**, **scripts-loader** and **scripts-compiler** allow you to use your favorite IDE instead of the RPG Maker script editor!

TODO:
- [x] scripts-externalizer
- [x] scripts-loader
- [ ] scripts-compiler

---

***
## About using the default script editor


* The scripts in RMVXAce are **compiled** into **Scripts.rvdata2**, you are obliged to open the **script editor** to change things, or when you use your favorite IDE, you are obliged to copy/paste your work into the script editor.
* It's a pain in the ass to open/close the script editor each time you want to change a little thing in your script.
* When you want to see how the default scripts works, and what method to overwrite, you are obliged to open the script editor. It's akward when you are actually using your favorite IDE. (I'm used to copy/paste from the script editor to the IDE when I'm working on scripts)
* The script editor is limited when you are used to actual IDE, you miss a bunch of shortcut and a more readable interface
* Some scripts like [the great RME](https://github.com/RMEx/RME) are divided into multiple scripts (it's way clearer when the hole script is very big)... well, do you want to copy/paste like 14 scripts into the script editor one by one?

***
## What is externalization?

The **externalization** is the way of working with **external scripts**, they are **ruby files** (foo.rb). The project will load your scripts files and rock with them, even if your scripts aren't into the script editor!

To put it simply, you can externalize a script by yourself using the simple function:
```
Kernel.send(:load, 'yourpath/yourscript.rb')
```
or :
```
Kernel.send(:require, 'yourpath/yourscript.rb')
```

`Kernel.load` and `Kernel.require` exist in Ruby 1.9.2 but the RGSS3 privatized them... Lucky that we still can use the *SUPER TRICK* of `.send`!

The difference between `:load` and `:require` is that `:require` will not load two times the same script. `:require` is recommanded when you want to manage dependency between multiple scripts.

I propose to use those functions smartly, by using my scripts!

***
## What about the *scripts-externalizer*, *loader* and *compiler*?

**There is two way of utilising those scripts:**

* Externalize just the scripts you want with **scripts-loader**
* Externalize all scripts including the default scripts with **scripts-externalizer**
* Compiling the external scripts into the Scripts.rvdata2 (coming soon)
***
# Externalize just the scripts you want

It's quite simple:
* Copy/paste the **scripts-loader** into the script editor, in Materials.
* Create the folder "**Scripts**" in your project
* Create a "**_list.rb**" into the folder "**Scripts**"
* Create any "**mysuperscript.rb**" you want into the folder "**Scripts**" and add their names into the **_list.rb**

For example:
![screenshot](http://biloucorp.com/BCW/Joke/sample2.png)

![screenshot](http://biloucorp.com/BCW/Joke/sample1.png)

Into the "**_list.rb**, there is just:
```
Fullscreen++
orms
```
Those two scripts will be loaded at the same time of **scripts-loader**

If you want to **deactivate** Fullscreen++, just put a "**#**" above the name:
```
#Fullscreen++
orms
```
That's PERFECT for debugging!

The "**_list.rb**" is very important because it defines in which order your scripts will be loaded.

For example:
```
orms
Fullscreen++
```
**orms** will be loaded before **Fullscreen++** (what it is precisely NOT what to do since **orms** manages the compatibility between the two)

---
## Create sub-folders in "Scripts"

You can easily create any folder you want, even folders into folders

You must specify the folder by adding his name into the "**_list.rb**", with a "**/**" after (and not a "**\\**", be careful)
```
RME/
Fullscreen++
orms
```
Into your new folder, you have to create a new "**_list.rb**" to define the order of the scripts and the next sub-folders.
For example, in the folder "**RME**", you have this "**_list.rb**":
```
Event_printer
SDK.Sample
Samples
SDK
Database
Internal 
EvEx 
Commands 
Incubator
DocGenerator
Doc 
SDK.Gui 
Tools 
Process.Doc
```
***
# Externalize all scripts including the default scripts

Here come the best! 

> ***THE SCRIPT TO END ALL SCRIPTS***
*(Frogge on the RPGMaker.net discord server)*

You can externalize ALL scripts including the default scripts by using the **scripts-externalizer** instead of the **scripts-loader**!

It will create the "**Scripts**" folder, and make automatically the sub-folders respecting the categories defined by empty scripts like "**▼ Scenes**"

![screenshot](http://biloucorp.com/BCW/Joke/sample3.png)

Then launch the game:

![screenshot](http://biloucorp.com/BCW/Joke/sample4.png)

`battle_end_me.play`

![screenshot](http://biloucorp.com/BCW/Joke/sample5.png)

Close and open the project...

NOW THE SCRIPT EDITOR IS KILLED!!!

![screenshot](http://biloucorp.com/BCW/Joke/sample6.png)

Don't worry, you will retrieve all the scripts in your favorite IDE :) :

![screenshot](http://biloucorp.com/BCW/Joke/sample7.png)

## Security

* A backup of the Scripts.rvdata2 is created
* The scripts with no name will be also exported and named "untitled", "untitled (2)" and so on
* The scripts with the same name will be renamed "script (2)", script (3)" and so on

That's all, folks!

# Compiling the external scripts into the Scripts.rvdata2

Coming soon... :)