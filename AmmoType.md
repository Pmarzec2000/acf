# RoundXX.lua #

We start in /ACF/Shared/Round/. These files are AmmoType specific and determine every aspect of the round. All of the functions in there get called at different times, it's definitely not linear.

First we define a local table, per ammo type, so the code can call up the right functions for that AmmoType. These are :

guicreate : This is called when the player clicks on the AmmoType name in the ACF Menu, and builds the GUI used for customization.

guiupdate : This is called when one of the customization sliders in the GUI is changed

create : This is called when an AmmoCrate is spawned, to convert raw customization data into the table that'll define the Round.

propimpact : This is called serverside  when a Bullet impacts a prop, and is used to define both the ACF Damage dealt to the prop and the ballistic behavior of the round after the impact.

worldimpact : This is called serverside  when a Bullet impacts the world.

endflight : This is called serverside when the ballistic code determines the Bullet has come to a stop.

pierceeffect : Called clientside when the Bullet penetrates something, can be the world or a prop. Mostly used to draw Effects

ricocheteffect : Called clientside when the Bullet ricochets. Mostly used to draw Effects

endeffect : Called clientside when the Bullet stops. Mostly used to draw Effects