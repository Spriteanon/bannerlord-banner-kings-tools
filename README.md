# Banner Kings Tools
The purpose of this project is to create some visual tools for building compatibility with Banner Kings for modders, relying on the GODOT engine for visual aid. 

Features:

## Importing and browsing basic Encyclopedia data relating to Clans and Settlements
By providing the program with the file paths to they key (xml) files defining settlements in game, the program will display summaries of key data regarding all read in settlements that can be sorted in a number of ways for easy reference.
The program supports multiple languages if needed, by allowing Language xmls to be loaded as well, and will automatically display the correct text the same way as Bannerlord would. (If no localization is present for a term, the program will attempt to display the basic localization for it in the source xml, if any, and append it with "(ML!)" for 'Missing Localization!')
Additionaly, xslt overrides for clans, localizations and settlements are supported, however the override files must be loaded AFTER the files whose entries they override, or they won't take effect.

## Visual Titles Editor
After importing settlements, in the "Map" tab, a map can be generated of the in-game settlements. The program will generate a random colour for each settlement.


## Used External Libraries:

### [GDScript Delaunay + Voronoi by bartekd97](https://github.com/bartekd97/gdDelaunay)
GDScript implementation of the Bowyer-Watson algorithm for computing Delaunay triangulation and from that a Voronoi diagram.
This is used to visually represent the territories associated with titles in the program.

"# bannerlord-banner-kings-tools" 
