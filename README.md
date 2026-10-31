# SHAlts

An alt manager for OctoWoW and other 1.12 clients. It keeps track of everything your characters own and lets you look at any of them from one window, no matter which character you are playing.

Made by Fayz, styled to match SHPlates.

## What it tracks

- **Bags**, with item counts and icons
- **Bank**, recorded each time you open the bank
- **Mailbox**, recorded each time you open a mailbox (items and money waiting)
- **Professions**, skill levels and every recipe you know
- **Gear**, what each character has equipped
- **Cooldowns**, for every alt at once: Salt Shaker, transmutes, Mooncloth, Shadowcloth and Spellcloth
- **Reputation, PvP rank, honor and time played**
- **Instance resets**, the 5 per hour limit, for each character
- **Raid lockouts**, so you can see at a glance which characters are locked

Everything is recorded automatically while you play. There is nothing to save and no command to run.

## Using it

Open the window with the minimap button or `/shalts`. Pick an alt from the dropdown at the top, then use the tabs down the right edge to switch between what you want to see. The search box looks through every alt at once, so you can find out who is holding that stack of Runecloth or who knows a recipe.

- Hover the minimap button for your reset timers, raid lockouts and any ready cooldowns.
- Hover an item for its tooltip.
- Shift-click an item to link it in chat.
- Ctrl-click an item to try it on.
- Drag the corner of the window to resize it, right-click the corner to reset.

## Instance resets and raid lockouts

The IRC tab is the Instance Reset Counter built into SHAlts. The server allows 5 instance resets per hour, and each character keeps its own five timers.

- Each timer counts down from 60:00. Reset 1 is always the oldest. When it runs out it clears and the rest move up.
- A timer starts only when the game confirms the reset, so a reset that fails because someone is still inside starts nothing.
- It also counts resets done by your group leader ("Blackrock Depths has been reset by Name"), so members get a timer too.
- One reset action is one timer, even if it resets several dungeons at once. All the dungeon names are shown on that one timer.
- Coin you loot inside the instance is added to the newest timer, and the Lockout total adds up all five.
- Timers keep counting while you are logged out.
- Pick any character from the dropdown to see its timers. The Reset dungeon and Reset all timers rows work for the character you are playing.
- The same list of timers shows when you hover the minimap button, counting down live.
- When a slot frees up or you hit the cap, you get a sound and the minimap button flashes. If you lead the group, the reset is announced in party or raid chat. Both can be turned off in Settings.

Raid lockouts are listed under the timers for the selected character, and the **All characters** list below shows who is locked and who is free. The minimap hover also lists everyone who is raid locked. A character's lockouts are recorded when you log in on it.

If you also have the separate IRC addon installed, turn one of them off. They would both count the same resets.

## Cooldown alerts

When a cooldown finishes on any of your characters, a small window tells you. If several are ready, they are all listed together. Each one is announced once. The alert waits while you are in combat or dead and never steals your keyboard focus.

If you run more than one game window, only one of them shows the alert.

## Using more than one account

The game keeps each account's data separate, so by itself an addon can only see the characters on the account you are logged into. With SuperWoW installed, SHAlts shares its data through a small text file in your game folder (`Imports\SHAltsSync.txt`). Every account that runs from the same game folder reads and writes the same file, so all of your alts show up everywhere.

Log in once on each account and the rest takes care of itself. Without SuperWoW the addon still works, it just shows the characters of the account you are on.

The file is plain text and is never run as code. It stays on your computer. Nothing is sent anywhere.

## Settings

Open the Settings tab (the gear) to:

- change the window opacity or reset its size
- sort alts by name or level
- show or hide the minimap button
- turn cooldown alerts on or off, or test one
- turn the reset sound alerts and the reset announcements on or off
- turn sharing between accounts on or off
- rescan the current character
- remove an alt: type the name and press Delete

A removed alt stays removed, even with the shared file, until you play that character again.

## Commands

| Command | What it does |
| --- | --- |
| `/shalts` or `/sha` | Open or close the window |
| `/shalts find <text>` | Search items and recipes on all alts |
| `/shalts cd` | List cooldowns in chat |

## Good to know

- The bank and the mailbox can only be read while they are open, so each is updated whenever you visit it. The window shows when it was last seen.
- Recipes are saved when you open that profession's window.
- Profession cooldowns are read from the recipe tooltip when you open the profession window, and started when you craft the item. If a cooldown was running before you installed the addon, open that profession once.
- Item tooltips come from your game's own item cache. An item no character on this install has seen yet shows its name and color until the game learns it.
- If you use SHAlts for a very long time it asks once, politely, whether you would like to star the project on GitHub. It never does this in combat, in a group, in an instance, or while you are busy, and it never asks again.

## Install

1. Download the addon and put the `SHAlts` folder in `Interface\AddOns`. If you downloaded a zip from GitHub, the folder must be named exactly `SHAlts`, so remove any `-main` from the end of its name.
2. Start the game and log in. The minimap button appears right away.

## Links

Source and updates: https://github.com/TheRealFayz/SHalts
