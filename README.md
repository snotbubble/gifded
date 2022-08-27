# gifded
Get It Fucking Done EDitor  

- process stuff by daisychaining Rebol3, Python and Shell-scripts... whatever works  
- quickly cache, bypass, reorder scripts  
- save and load projects as an orgfile, cause shizzas & gizzas...  

# usage
- do not use this program, its here for demonstration purposes only

# testing
- extract install `lz4 -d install.tar.lz4 | tar xvf -`, copy `.local` to to home
- get [Rebol3](https://github.com/Oldes/Rebol3/releases/tag/3.9.0), copy to project dir, rename it to `r3`  
- copy gifded.vala to the project dir, run `clear && valac gifded.vala --pkg gtk4 --pkg gtksourceview-5 -X -lm`
- install whatever the above complains about until it works, probably: valac, gcc, gtk4-dev, gtksourceview5

# screenie
![screenie](./screenies/220828_gifded_screenie.png)
