# SANDMAN
Fatigue modeling for *Command: Modern Operations*

<p align="center"><img src="https://github.com/musurca/SANDMAN/raw/main/img/sandman.jpg" /></p>

### What is SANDMAN?
**SANDMAN** models the current fatigue level of your pilots using a realistic model based on their sustained activity, sleep debt, and circadian rhythms, then degrades their proficiency accordingly. With **SANDMAN**, you may also see exhausted pilots taking short, dangerous "micronaps" in which their plane goes out of comms, and becomes vulnerable to enemy action. Extremely exhausted pilots may even begin to bolter/go-around on landings, or even (under very rare conditions) crash.

Using the *Fatigue Avoidance Scheduling Tool* (available from the Special Actions menu), you can monitor the effectiveness of your pilots, and attempt to stand down particularly exhausted pilots for rest.

### How do I add it to my scenario?
1) Download the [latest release](https://github.com/musurca/SANDMAN/releases/download/v0.1.1/SANDMAN_v0.1.1.zip).
2) Open your scenario in the Scenario Editor.
2) Go to Editor -> Lua Script Console
3) Paste the contents of the file `sandman_min.lua` into the white box, then click **Run**.
4) Complete the **SANDMAN** wizard and voila! You now have sleepy pilots.

### If I want to tweak the model, how do I build it from source?

You'll need the following installed on your system:
* A Bash shell (on Windows 10, install the [WSL](https://www.howtogeek.com/249966/how-to-install-and-use-the-linux-bash-shell-on-windows-10/))
* [luamin](https://github.com/mathiasbynens/luamin)
* [Python 3](https://www.python.org/downloads/)

#### Quick prerequisite install instructions on Windows 10

Assuming you've installed the [WSL](https://www.howtogeek.com/249966/how-to-install-and-use-the-linux-bash-shell-on-windows-10/) and Ubuntu, run the following commands from the shell:
```
sudo apt-get install python3 npm
sudo npm install -g luamin
```

#### How to compile

##### Release
```
./build.sh
```

The compiled, minified Lua code will be placed in `release/sandman_min.lua`. This is suitable for converting scenarios by pasting it into the Lua Code Editor and clicking RUN as the final step in the scenario creation process.
 
#### Debug
```
./build.sh debug
```

This will produce compiled but unminified Lua code in `debug/sandman_debug.lua`. _Do not use this in a released scenario._ This is mostly useful while debugging your code.

#### Why is the build process so complicated?
**SANDMAN** works by injecting its own code into a *CMO* LuaScript event action which is executed upon every scenario load. The build process converts the **SANDMAN** source into a minified, escaped string which is then re-embedded into its own code.

### Version History
v0.2.0 (????):
* added: reserve crews
* added: reserve display and replacement thresholds
* added: global timezones
* added: multicrew model
* changed: FAST shows peak awareness time for pilot
* changed: FAST shows actual proficiency based on effectiveness
* changed: proficiency drop now an absolute delta
* changed: calling Enable/Disable() adds & removes special actions
* fixed: implemented custom PRNG to replace math.random()

v0.1.1 (2/10/2022):
* added: API functions for scenario authors
* changed: increased micronap risk
* fixed: reinstalling SANDMAN resets proficiencies 

v0.1.0 (2/9/2022):
* Initial release.