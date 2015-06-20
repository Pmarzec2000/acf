# Introduction #

The ballistic system is used for all the bullet movement in ACF. It uses the ACF.Bullet table to store every BulletData table currently active (ie in flight) and iterates trough it every frame, calculating it's flightpath for a frame, doing a trace along it, and calling the functions defined in the RoundType file if the trace hits something.

The bullets are **NOT** props, they are simple table entries serverside, and effects clientside, as to minimise the network footprint.

# Serverside #

Serverside is governed by the sv\_ACFBallistics.lua file

## Bullet Creation ##

To fire a bullet, you need to call the ACF\_CreateBullet function, with a Bullet table. Said Bullet table is added to the ACF.Bullet table, and ACF.CurBulletIndex is incremented by 1.
The system uses ACF.CurBulletIndex with a fixed number of indexes to add new bullets instead of just adding them to the table as to avoid synchronisation issues between server and client side when the table is edited.

## Bullet Movement ##

The ACF\_ManageBullets hook iterates into the ACF.Bullet table and sends each Bullet Table it contains to the ACF\_CalcBulletFlight function so it's flight path can be determined.

### ACF\_CalcBulletFlight ###

This takes the Bullet table and calculates it's flight data, then using it to set the NextPos variable in the table, used as the end of the flight path for this frame.

It also moves the start point to a point behind the bullet relative to it's velocity and the last frame duration so as to catch any prop that moved toward the bullet after it moved last frame and got behind the start point. It then calls ACF\_DoBulletsFlight

### ACF\_DoBulletsFlight ###

This does a trace based on the StartPos and NextPos variables in the Bullet table.

If the trace hits :

Calls the appropriate function as defined in the RoundType file
It supports 3 return values :
  * false bool, where the code ends the bullet flight at this point, and destroys it's entry in the ACF.Bullet table
  * "Penetrated" string , where the code will run the same trace again.
  * "Ricochet" string , where the code will call ACF\_CalcBulletFlight to calculate a new flight path.

### ACF\_BulletClient ###

This is called each time there is a modification to the bullet path. Currently this is only called after an impact.
Used to update the clientside prediction model of the bullet, the Type var is used to tell the clientside system if this is a bullet creation or a path update, and the Hit var is used to indicate the type of impact, as to call the right effects.

This creates effects as a way of network communication, that way is now deprecated but it used to be the only way to have timely Server>Client communication.

# Clientside #

Clientside is governed by both the cl\_ACFBallistics.lua file and the ACF\_BulletEffect effect. The ACF\_BulletEffect is used as both an effect in itself and a means of communication, and is used to call every clientside function on the Bullet

## Bullet Creation ##

The Serverside ACF\_BulletClient creates a ACF\_BulletEffect. If the Hit variable is 0, that means it's a new bullet, so the effect gets added to the ACF.BulletEffect table and starts being moved every frame by ACF\_ManageBulletEffects

## Bullet Update ##

If the Hit variable transmited to a ACF\_BulletEffect is greated than 0 that means this effect is an update, so it updates the existing effect with new data and removes itself

## Bullet Movement ##

### ACF\_ManageBulletEffects ###

Barebones clientside copy of the ACF\_CreateBullet serverside function, this uses the ACF.BulletEffect table instead of ACF.Bullet, but uses the same indexes, transmitted over the network. Calls ACF\_SimBulletFlight every Think

### ACF\_SimBulletFlight ###

Does the same calculations as the serverside ACF\_CalcBulletFlight, but directly moves the clientside effect in a ballistic path without regard for any obstacles.


