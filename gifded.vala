// script Q
// by cpbrown 2022

// todo next: finish assigning standard gtk icons

using Gtk;


// globals.................... andwhy

bool doup;					// used to block ui signals everywhere
GtkSource.View htmloutput;	// the output html, needed to show parser results, used everywhere
GtkSource.Buffer htmlbuff;	// the buffer for the above, needed to switch syntax, used everywhere
GtkSource.View datoutput;	// data output viewer, needed to show parser internals, used everywhere
ParserBox[] allt;			// the nodes, gets created & destroyed by the user, prodded & poked by everything
ParserBox[] tempallt;		// temp list for removing stuff from the above
Gtk.Box parserslist;		// the node container, used to contain allt, frequently hosed, rebuilt & re-ordered
int selectednode;			// currently selected node, used for add, remove, duplicate, move... super important
Gtk.Paned vdiv;				// the splitter, needed to reflow node params
Gtk.Stack outputstack;		// the output panels, needed to see what should be displayed by the node
//Gtk.WebView webrenderer;	// testing this... oh its 1 gen behind, try again with gtk5

// do python

string dopy (string[] a) {
	try {
		string o;
		Pid p;
		GLib.Process.spawn_sync (null,a,null,SpawnFlags.SEARCH_PATH,null,out o,null,out p);
		print("process %d started...\n", p);
		return o;

	} catch (SpawnError e) { print ("Error: %s\n", e.message); }
	return "";
}

// separate fn for the reeb, just in case...

string doreeb (string[] a) {
	try {
		string o;
		Pid p;
		// go reeeeeeb, you can do it mate...
		GLib.Process.spawn_sync (null,a,null,SpawnFlags.SEARCH_PATH,null,out o,null,out p);
		print("process %d started...\n", p);
		return o;

	} catch (SpawnError e) { print ("Error: %s\n", e.message); }
	return "";
}

// shell script

string dosh (string[] a) {
	try {
		foreach (string v in a) {
			print("dosh: \targ = %s\n",v);
		}
		//string[] env = Environ.get(); // has no effect
		//string here = GLib.Environment.get_current_dir(); // has no effect
		//here = here.concat("/");
		//print("here = %s\n", here);
		string o;
		Pid p;
		GLib.Process.spawn_sync (null,a,null,SpawnFlags.SEARCH_PATH,null,out o,null,out p);
		print("process %d started...\n", p);
		return o;
	} catch (SpawnError e) { print ("Error: %s\n", e.message); return "Error: %s\n".printf(e.message); }
	return "";
}

// some commonly used functions

string getfilenamefile (string f) {
	if (f != null) {
		if (f.strip() != "") { 
			string[] fp = f.strip().split("/");
			if (fp.length > 1) {
				string[] pp = fp[(fp.length - 1)].split(".");
				return pp[0];
			}
		}
	}
	return "";
}
string getfileext (string f) {
	if (f != null) {
		if (f.strip() != "") { 
			string[] fp = f.strip().split("/");
			if (fp.length > 1) {
				string[] pp = fp[(fp.length - 1)].split(".");
				return pp[(pp.length - 1)];
			}
		}
	}
	return "";
}
File getfiledir (string f) {
	string o = "";
	File x = File.new_for_path(o);
	if (f != null) {
		if (f.strip() != "") { 
			string[] fp = f.strip().split("/");
			if (fp.length > 1) {
				for (int l = 0; l < (fp.length - 1); l++) {
					o = o.concat(fp[l],"/");
				}
			}
			x = File.new_for_path(o);
			return x;
		}
	}
	return x;
}

// load ui from an org file... its stupid but funny

void spawnuifromorg (string o) {

// assumes allt and parsersbox have been hosed by the calling event

	string[] lines = o.split("\n");
	bool amnode = false;
	bool amprop = false;
	bool amsrc = false;
	bool amres = false;
	bool spoolsrc = false;
	bool spoolres = false;
	string nom = "";
	int idx = 0;
	int typ = 0;
	bool frz = false;
	bool hoi = true;
	bool pui = false;
	string pre = "";
	string lod = "";
	string rex = "";
	string cex = "";
	string lex = "";
	string src = "";
	string res = "";
	int nodecount = 0;
	int srcspooldepth = 0;
	int resspooldepth = 0;

// use a counter to add nodes
// exampled * and # should be prefixed with , for the highlighter and org itself
// +---------------------------+---------------------------------------------------------+
// | [A][C] LINE               | NOTE                                                    | 
// +---------------------------+---------------------------------------------------------+
// | [0][1] * node             |  ** node [C+=1]                                         |
// | [0][1] ** code            |                                                         |
// +--------------------+------+                                                         |
// | [0][1] ** result   |      |                                                         |
// | [1][2] * node      |//    |  END_OF_NODE AND C>A [A += NODE]  ** node [C+=1]        |
// | [1][2] ** code     |//    |                                                         |
// | [1][2] ** result   |//    |                                                         |
// | [2][3] * node      |////  |  END_OF_NODE AND C>A [A += NODE]  ** node [C+=1]        |
// | [2][3] ** code     |////  |                                                         |
// | [2][3] ** result   |////  |                                                         |
// | [3][3]             |//////|  END_OF_NODE AND C>A [A += NODE]                        |
// +--------------------+------+---------------------------------------------------------+

	foreach (string l in lines) {
		//if (amprop == false) { print("LINE=%s\n",l); }
		if (l.get_char(0) == '*' && l.get_char(1) == ' ') { 
			print("\nheadline found  : %s\n",l);
			print("\tamnode        = %s\n",amnode.to_string());
			print("\tamprop        = %s\n",amprop.to_string());
			print("\tamsrc         = %s\n",amsrc.to_string());
			print("\tspoolsrc      = %s\n",spoolsrc.to_string());
			print("\tsrcspooldepth = %d\n",srcspooldepth);
			print("\tamres         = %s\n",amres.to_string());
			print("\tspoolres      = %s\n",spoolres.to_string());
			print("\tresspooldepth = %d\n",resspooldepth);
			print("\tnodecount     = %d\n",nodecount);
			print("\tallt.length   = %d\n",allt.length);
			print("\n");
		}
		if (amnode == false && amres == false && amprop == false && amsrc == false && srcspooldepth == 0 && resspooldepth == 0 && spoolsrc == false && spoolres == false) {
			if (nodecount > allt.length) {
				print("ADD NODE %s\n",nom);
				ParserBox nn = new ParserBox(idx, nom, typ, frz, hoi, pui, pre, lod, cex, rex, lex, src, res);
				allt += nn;
				amnode = false;
				amprop = false;
				amsrc = false;
				amres = false;
				spoolsrc = false;
				spoolres = false;
				srcspooldepth = 0;
				resspooldepth = 0;
				nom = "";
				idx = 0;
				typ = 0;
				frz = false;
				hoi = true;
				pui = false;
				pre = "";
				lod = "";
				rex = "";
				lex = "";
				cex = "";
				src = "";
				res = "";
			}				
			if (l.get_char(0) == '*' && l.get_char(1) == ' ') {
				print("\n");
				nom = l.replace("*","").strip();
				print("\tnom = %s\n", nom);
				amnode = true;
				nodecount += 1;
				//print("\tnodecount     = %d\n",nodecount);
				//print("\n");
				continue;
			}
		}
		if (amnode) {
			if (l.strip() == ":PROPERTIES:") { amprop = true; }
			if (amprop) {
				if (l.length >= 5) {
					string chk = l.substring(0,5);
					// save order:
					//:PROPERTIES: :TYP: :FRZ: :HOI: :PUI: :LOD: :PRE: :LEX: :CEX: :REX: :END:
					if (chk == ":END:") { amprop = false; print("\n"); continue; }
					if (chk == ":TYP:") { string huh = l.substring(5,((l.length)) - 5).strip(); typ = int.parse(huh); print("\ttyp = %d\n",typ); }
					if (chk == ":FRZ:") { string huh = l.substring(5,((l.length)) - 5).strip(); frz = int.parse(huh) == 1; if (frz) { print("\tfrz = true\n"); } else { print("\tfrz = false\n"); } }
					if (chk == ":HOI:") { string huh = l.substring(5,((l.length)) - 5).strip(); hoi = int.parse(huh) == 1; if (hoi) { print("\thoi = true\n"); } else { print("\thoi = false\n"); } }
					if (chk == ":PUI:") { string huh = l.substring(5,((l.length)) - 5).strip(); pui = int.parse(huh) == 1; if (pui) { print("\tpui = true\n"); } else { print("\tpui = false\n"); } }
					if (chk == ":LOD:") { string huh = l.substring(5,((l.length)) - 5).strip(); lod = huh; print("\tlod = %s\n",lod); }
					if (chk == ":PRE:") { string huh = l.substring(5,((l.length)) - 5).strip(); pre = huh; print("\tpre = %s\n",pre); }
					if (chk == ":LEX:") { string huh = l.substring(5,((l.length)) - 5).strip(); lex = huh; print("\tlex = %s\n",lex); }
					if (chk == ":CEX:") { string huh = l.substring(5,((l.length)) - 5).strip(); cex = huh; print("\tcex = %s\n",cex); }
					if (chk == ":REX:") { string huh = l.substring(5,((l.length)) - 5).strip(); rex = huh; print("\trex = %s\n",rex); }
				} else { amprop = false; continue; }
			}
			if (spoolsrc == false && spoolres == false) {
				if (l.length >= 7) { 
					if (l.substring(0,7) == "** code") { amprop = false; amsrc = true; spoolsrc = false; amres = false; spoolres = false;  continue;}
				}
				if (l.length >= 9) { 
					if (l.substring(0,9) == "** result") { amprop = false; spoolsrc = false; amsrc = false; amres = true; spoolres = false;  continue; }
				}
			}
			if (amsrc) {

// using a counter to handle orgception
// exampled * and # should be prefixed with , for the highlighter and org itself
// +-----------------------+---------------------------------------------------------+
// | [S][R] LINE           | NOTE                                                    | 
// +-----------------------+---------------------------------------------------------+
// | [0][0] ** code        |  ** code AND S==0 [                                     |
// | [1][0] #+BEGIN        |      #+BEGIN [S+=1]  s==1 AND #+BEGIN [START_READ NEXT] |
// +--------------------+--+                                                         |
// | [1][1] ** code     |>>|                                                         |
// | [2][1] #+BEGIN     |>>|      #+BEGIN [S+=1]                                     |
// | [2][1] some code   |>>|                                                         |
// | [1][1] #+END       |>>|      #+END [S-=1]                                       |
// +--------------------+--+                                                         |
// | [0][0] #+END          |      #+END [S-=1]  #+END AND S==0 [STOP_READ]           |
// |                       |  ]                                                      |
// +-----------------------+---------------------------------------------------------+


				if (l.length >= 5) { 
					if (l.substring(0,5) == "#+BEG") {
						srcspooldepth += 1;
						if (srcspooldepth == 1) {
							spoolsrc = true; 
							continue;
						}
					}
					if (l.substring(0,5) == "#+END") { 
						srcspooldepth -= 1;
						if (srcspooldepth == 0) {
							spoolsrc = false; 
							amsrc = false;
							continue;
						}
					}
				}
				if (spoolsrc) {
					src = src.concat(l,"\n"); 
				}
			}
			if (amres) {
				if (l.length >= 5) { 
					if (l.substring(0,5) == "#+BEG") {
						resspooldepth += 1;
						if (resspooldepth == 1) {
							spoolres = true;
							continue;
						}
					}
					if (l.substring(0,5) == "#+END") {
						resspooldepth -= 1;
						if (resspooldepth == 0) {
							spoolres = false; 
							amres = false; 
// res is the last thing we need, so break out of the node, incrament to add a parser using collected data
							amnode = false;
							nodecount += 1;
							continue;
						}
					}
				}
				if (spoolres) {
					res = res.concat(l,"\n"); 
				}
			}
		}
	}
}

// the parser 'node'

public class ParserBox : Gtk.Box {
	private Gtk.Box headbox;
	private Gtk.Entry nameentry;
	private Gtk.ScrolledWindow srcscroll;
	private Gtk.DropDown oplist;
	private Gtk.ToggleButton enableswitch;
	private Gtk.ToggleButton isotoggle;
	public GtkSource.View srctext;
	private Gtk.TextTagTable srctextbufftags;
	private GtkSource.Buffer srctextbuff;
	private Pango.TabArray srctab;
	private Gtk.Box scrollbox;
	private Gtk.Button evalbutton;
	private Gtk.Box headflow;
	private Gtk.Box firstbox;
	private Gtk.Box secondbox;
	private Gtk.Box thirdbox;
	private Gtk.Box firstrow;
	private Gtk.Box secondrow;
	private Gtk.Box thirdrow;
	private Gtk.Box filebox;
	private Gtk.Entry fileentry;
	private Gtk.MenuButton filebutton;
	private Gtk.Popover filepop;
	private Gtk.Box filepopbox;
	private Gtk.GestureClick fileclick;
	private Gtk.Box presetbox;
	private Gtk.Entry presetentry;
	private Gtk.MenuButton presetbutton;
	private Gtk.Popover presetpop;
	private Gtk.Box presetpopbox;
	private Gtk.Button presetsave;
	private Gtk.GestureClick presetclick;
	private Gtk.GestureClick thisclick;
	private GLib.Dir dcr;
	private Gtk.ToggleButton foldbutton;
	private Gtk.CssProvider fesp;
	private Gtk.CssProvider hosp;
	private string fess;
	private string hoss;
	private bool thf;
	private bool twf;
	private bool tnf;
	private string extname (string e) {
		string o = "html";
		switch (e) {
			case "txt"	: o = "text"; break;
			case "htm"	: o = "html"; break;
			case "py"	: o = "python"; break;
			case "r3"	: o = "rebol"; break;
			case "r"	: o = "rebol"; break;
			case "reb"	: o = "rebol"; break;
			case "sh"	: o = "sh"; break;
			case "xml"	: o = "xml"; break;
			case "org"	: o = "orgmode"; break;
			default		: o = "html"; break;
		}
		return o;
	}
	private string exttype (string e) {
		string o = "html";
		switch (e) {
			case "text"		: o = "txt"; break;
			case "html"		: o = "html"; break;
			case "python"	: o = "py"; break;
			case "rebol"	: o = "r3"; break;
			case "sh"		: o = "sh"; break;
			case "xml"		: o = "xml"; break;
			case "orgmode"	: o = "org"; break;
			default			: o = "html"; break;
		}
		return o;
	}
	private void evalnode (string l, int i, bool v) {
		print("\tevalnode: started: i = %d\n", i);
		print("\tevalnode:\tincoming source.length = %d\n", l.length);
		string rets = "";
		bool allgood = true;

// loaders are native hardcoded vala

		if (allt[i].typ == 0) {
			if (allt[i].lod != null) {
				if (allt[i].lod.strip() != "") {
					File lodfile = File.new_for_path(allt[i].lod);
					if (lodfile.query_exists() == true) {
						try {
							uint8[] c; string e;
							lodfile.load_contents (null, out c, out e);
							rets = (string) c;
							//allt[i].res = (string) c;
							print ("\tevalnode:\tload node successfully loaded file %s...\n",allt[i].lod);
							allgood = true;
						} catch (Error e) {
							print ("\tevalnode:\tfailed to read %s: %s\n", lodfile.get_path(), e.message);
						}
					} else { print("\tevalnode:\t%s doesn't exist, aborting...\n",allt[i].lod); }
				} else { print("\tevalnode:\tlod %s is empty, aborting...\n",allt[i].lod); }
			} else { print("\tevalnode:\tlod is null, aborting...\n"); }
		}

// savers are native hardcoded vala

		if (allt[i].typ == 1) {
			allgood = false;
			if (allt[i].lod != null) {
				if (allt[i].lod.strip() != "") {
					rets = l;
					File lodfile = File.new_for_path(allt[i].lod);
					File loddir = getfiledir(allt[i].lod);
					if (lodfile.query_exists() == true) {
						lodfile.delete();
					} else {
						try {
							loddir.make_directory_with_parents();
						} catch (Error e) { print("\tevalnode:\tmake_dir error: %s\n", e.message); }
					}
					if (loddir.query_exists() == true) {
						FileOutputStream lodstream = lodfile.replace(null, false, FileCreateFlags.PRIVATE);
						try {
							lodstream.write(l.data);
							allt[i].res = l;
							fess = ".xx { background: #00FF0020; }";
							fesp.load_from_data(fess.data);
						} catch (Error e) {
							rets = e.message;  print("\tevalnode:\tfilestream error: %s\n",rets);
						}
					} else { print("\tevalnode:\tlod file couldn't be created, aborting...\n"); }
				} else { print("\tevalnode:\tlod is empty, aborting...\n"); }
			} else { print("\tevalnode:\tlod is null, aborting...\n"); }			
		}
		if (allt[i].typ > 1) {
			if (allt[i].cex == "html" || allt[i].cex == "text" || allt[i].cex == "xml") {
				print("\tevalnode:\tinsert into html...\n");
				rets = allt[i].src.replace("<!--[lastres]-->",l);
				allgood = true;
			} else {
				if (allt[i].src != null) {
					if (allt[i].src.strip() != "") {
						if (l.length > 0) {
							bool doit = true;
							print("\tevalnode:\tsrc.length = %d\n", allt[i].src.length);
							var ddd = GLib.Environment.get_current_dir();
							string eee = exttype(allt[i].cex);
							string ttt = "temp.%s".printf(eee);
							print("\tevalnode:\ttempfilename is : %s\n", ttt);
							var ppp = Path.build_filename (ddd, ttt);
							File tempfile = File.new_for_path(ppp);
							if (tempfile.query_exists() == true) { 
								try { 
									tempfile.delete();
								}	catch (Error e) { 
									print("\tevalnode:\ttfailed to delete old tempfile: %s\n", ((string) tempfile.get_path()));
									doit = false;
								}
							}
							FileOutputStream tempstream = null;
							try {
								tempstream = tempfile.replace (null, false, FileCreateFlags.PRIVATE);
								tempstream.write(allt[i].src.data);
							} catch (Error e) {
								print("\tevalnode:\ttfailed to write filestream: %s\n", ttt);
								doit = false;
							}
							File temppath = File.new_for_path (ddd.concat("/temp/"));
							if (temppath.query_exists() == false) { 
								try { 
									temppath.make_directory_with_parents(); 
								}	catch (Error e) { 
									print("\tevalnode:\ttfailed to makedirs: %s\n", ((string) temppath.get_path()));
									doit = false;
								}
							}				
							string tmpn = allt[i].nom.replace(" ","_");
							string rrt = "%s.tmp".printf(tmpn);
							print("\tevalnode:\tlastres temp filename is : %s\n", rrt);
							var rrr = Path.build_filename (ddd.concat("/temp/"), rrt);
							File tempresfile = File.new_for_path(rrr);
							if (tempresfile.query_exists() == true) { 
								try { 
									tempresfile.delete();
								}	catch (Error e) { 
									print("\tevalnode:\ttfailed to delete old tempfile: %s\n", ((string) tempresfile.get_path()));
									doit = false;
								}
 							}
							FileOutputStream tempresstream = null;
							try {
								tempresstream = tempresfile.replace (null, false, FileCreateFlags.PRIVATE);
								tempresstream.write(l.data);
							} catch (Error e) {
								print("\tevalnode:\ttfailed to write filestream: %s\n", rrr);
								doit = false;
							}
							if (doit) {
								if (allt[i].cex == "python") {
									print("\tevalnode:\tcalling python...\n");
									string cmd = "".concat("python3 ", ppp, " ", rrr);
									string[] cmda = {"python3", ppp, rrr};
									rets = dopy(cmda);
									allgood = true;
								}
								if (allt[i].cex == "rebol") {
									print("\tevalnode:\tcalling the reeb...\n");
									string cmd = "".concat("./r3 ", ppp, " ", rrr);
									string[] cmda = {"./r3", ppp, rrr};
									rets = doreeb(cmda);
									allgood = true;
								}
								if (allt[i].cex == "sh") {
									print("\tevalnode:\tcalling the shell...\n");
									string cmd = "".concat("sh ", ppp, " ", rrr);
									string[] cmda = {"sh", ppp, rrr};
									rets = dosh(cmda);
									allgood = true;
								}
							} else { print("\tevalnode:\tfailed to write outputstreams...\n"); }
						} else { print("\tevalnode:\tno source in %s node %s...\n",allt[i].cex,allt[i].nom); }
					} else { print("\tevalnode:\tinput for %s node %s is empty...\n",allt[i].cex,allt[i].nom); }
				} else { print("\tevalnode:\tsource in %s node %s is null...\n",allt[i].cex,allt[i].nom); }
			}
		}
		if (allgood) {
			allt[i].res = "";
			if (rets != null) {
				if (rets.strip() != "") {
					allt[i].res = rets;
					string[] rtl = rets.split("\n");

// autodetect type of output, save they type to rex, which is used for org export of the scenario, and sytnax highlighting

					if (rtl.length >= 1) {
					print("\tevalnode:\twrote %d lines to %s.res\n",rtl.length,allt[i].nom);

// set fallback to text, then ransack returned strings for identifiers...

						print("\tevalnode:\tdetermining filetype of returned output...\n");
						allt[i].rex = "text";
						for(int j = 0; j < rtl.length; j++) {
							if (rtl[j].length > 7) {
								if (rtl[j].contains("<!DOCTYPE HTML")) { allt[i].rex = "html"; break; }
								if (rtl[j].contains("<?xml")) { allt[i].rex = "xml"; break; }
								if (rtl[j].substring(0,7) == "import ") { allt[i].rex = "python"; break; }
								if (rtl[j].substring(0,4) == "def ") { allt[i].rex = "python"; break; }
								if (rtl[j].substring(0,5) == "REBOL") { allt[i].rex = "rebol"; break; }
								if (rtl[j].contains("-*-")) { 
									if (rtl[j].contains("mode: org")) { allt[i].rex = "orgmode"; break; }
									if (rtl[j].contains("mode:org")) { allt[i].rex = "orgmode"; break; }
								}
							}

// break if nothing is found in the 1st 100 lines, suckshit if there's heaps of commentary

							if (j > 100) { break; }
						}
						print("\tevalnode:\toutput is probably %s\n", ((string) allt[i].rex));
						if (v) {
							if (allt[i].rex != null) {
								print("\tevalnode:\tsetting output syntax highlighter...\n");
								if (allt[i].rex == "orgmode") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-orgmode"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("orgmode"));
								}
								if (allt[i].rex == "rebol") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-gifded"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("rebol"));
								}
								if (allt[i].rex == "python") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("python"));
								}
								if (allt[i].rex == "sh") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("sh"));
								}
								if (allt[i].rex == "html") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("html"));
								}
								if (allt[i].rex == "xml") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("xml"));
								}
								if (allt[i].rex == "text") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("text"));
								}
								if (allt[i].rex.strip() == "") { 
									htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
									htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("html"));
								}
								print("\tevalnode:\twriting to output buffer...\n");
								htmloutput.buffer.text = rets;
								//if (allt[i].red == "html") { webrenderer.load_html(rets); }
								print("\tevalnode:\tdone.\n\n");
							}
						} else { print("\tevalnode:\t dont write unselected node output to output buffer...\n"); if (v) { htmloutput.buffer.text = ""; } }
					} else { print("\tevalnode:\teval returned empty string...\n"); if (v) { htmloutput.buffer.text = ""; } }
				} else { print("\tevalnode:\teval returned empty string...\n"); if (v) { htmloutput.buffer.text = ""; } }
			} else { print("\tevalnode:\teval returned null...\n"); if (v) { htmloutput.buffer.text = ""; } }
		} else { print("\tevalnode:\tnothing was evaluated...\n"); if (v) { htmloutput.buffer.text = ""; } }
		//print("\tevalnode: allt[%d].res = \n%s\n",i,((string) allt[i].res));
	}
	public void orgmydat () {
		if (idx == selectednode) {
			if (outputstack.visible_child_name == "data") {
				string odat = "* %s\n".printf((string) nom);
				odat = odat.concat(":PROPERTIES:\n");
				odat = odat.concat(":IDX: %s\n".printf(idx.to_string()));
				odat = odat.concat(":TYP: %s\n".printf(typ.to_string()));
				odat = odat.concat(":FRZ: %s\n".printf(frz.to_string()));
				odat = odat.concat(":HOI: %s\n".printf(hoi.to_string()));
				odat = odat.concat(":PUI: %s\n".printf(pui.to_string()));
				odat = odat.concat(":PRE: %s\n".printf((string) pre));
				odat = odat.concat(":LOD: %s\n".printf((string) lod));
				odat = odat.concat(":LEX: %s\n".printf((string) lex));
				odat = odat.concat(":CEX: %s\n".printf((string) cex));
				odat = odat.concat(":REX: %s\n".printf((string) rex));
				odat = odat.concat(":END:\n");

// something in here is causing a segfault

				odat = odat.concat("** code\n");
				odat = odat.concat("#+BEGIN_SRC %s\n".printf((string) cex));
				if (src != null) {
					if (src.strip() != "") {
						string[] srclines = src.split("\n");
						if (srclines.length > 1) {
							foreach (string sl in srclines) { odat = odat.concat("%s\n".printf(sl)); }
						} else { odat = odat.concat("%s\n".printf(src)); }
					}
				}
				odat = odat.concat("#+END_SRC\n");
				odat = odat.concat("** result\n");
				if (rex == "orgmode") {
					odat = odat.concat("#+BEGIN_EXAMPLE\n");
				} else {
					odat = odat.concat("#+BEGIN_SRC %s\n".printf(rex));
				}
				if (res != null) {
					if (res.strip() != "") {
						string[] reslines = res.split("\n");
						if (reslines.length > 1) {
							foreach (string rl in reslines) { odat = odat.concat("%s\n".printf(rl)); }
						} else { odat = odat.concat("%s\n".printf(res)); }
					}
				}
				if (rex == "orgmode") {
					odat = odat.concat("#+END_EXAMPLE\n");
				} else {
					odat = odat.concat("#+END_SRC\n");
				}
				datoutput.buffer.set_text(odat);
			}
		}
	}
	public void selectme(int ix) {
		foreach (ParserBox n in allt) {
			if (n.idx != ix) {
				n.myc = ".xx { background: #E0E0E010; box-shadow: 2px 2px 2px #00000066; }";
				n.myp.load_from_data(n.myc.data);
			 }	else {
				n.myc = ".xx { background: #88DDFF20; box-shadow: 2px 2px 2px #00000066; }";
				n.myp.load_from_data(n.myc.data);
			}
		}
// super fucking important to set this correctly
		selectednode = ix;
		//print("\nSELECTED NODE IS %d\n",selectednode);
	}
	public void reflowparams (int sx) {

// cause flowbox is just a shitty nxn grid

		if (thf) {
			if (sx > (thirdbox.width_request + secondbox.width_request)) {
				var th = thirdrow.get_last_child();
				thirdrow.remove(th);
				secondrow.append(th);
				thf = false;
			}
		}
		if (twf) {
			if (sx > (firstbox.width_request + secondbox.width_request)) {
				var tw = secondrow.get_first_child();
				secondrow.remove(tw);
				firstrow.append(tw);
				twf = false;
			}
		}
		if (tnf) {
			if (sx > (firstbox.width_request + secondbox.width_request + thirdbox.width_request)) {
				var tn = secondrow.get_first_child();
				secondrow.remove(tn);
				firstrow.append(tn);
				tnf = false;
			}
		}
		if ((sx - 40) < (firstbox.width_request + secondbox.width_request + thirdbox.width_request)) {
			if (tnf == false) {
				var tn = firstrow.get_last_child();
				firstrow.remove(tn);
				secondrow.append(tn);
				tnf = true;
			}
		}
		if ((sx - 40) < (firstbox.width_request + secondbox.width_request)) {
			if (twf == false) {
				var tn = firstrow.get_last_child();
				firstrow.remove(tn);
				tn.insert_before(secondrow,secondrow.get_first_child());
				twf = true;
			}
		}
		if ((sx - 40) < (secondbox.width_request + thirdbox.width_request)) {
			if (thf == false) {
				var tn = secondrow.get_last_child();
				secondrow.remove(tn);
				thirdrow.append(tn);
				thf = true;
			}
		}
	}
	public string nom;			// the node name					- used for the org headline on save, otherwise not important
	public int idx;				// the node index					- important for anything that needs a node selection
	public string src;			// the parser code					- gets evaluated
	public string res;			// result of node eval				- used by the next node
	public string cex;			// file type of code				- used for syntax highlighting, org-block type
	public string rex;			// file type of eval output 		- used for saving/export/viewing
	public int typ;				// sourceview file type menu index	- used to initialize ui
	public bool frz;			// freze node						- used to initialize ui, block changes, prevent eval
	public bool hoi;			// on/off							- used to initialize ui, skipped in eval stack
	public bool pui;			// fold/expand						- used to initialize ui, cosmetic
	public string pre;			// path to preset					- used to initialize ui, for quick save
	public string lod;			// file to load, if any				- used to initialize ui, used for load and save
	public string lex;			// file type of loaded file			- used for saving/export/viewing
	public string myc;			// my css string					- used for parser selection tint
	public Gtk.CssProvider myp; // my css provider					- gtk oop shitfuckery for the above
	//     ParserBox (idx, 	  nom,       typ,    frz,     hoi,     pui,     pre,       lod,       cex,       rex,       lex,       src,       res      );
	public ParserBox (int ii, string nn, int tt, bool ff, bool hh, bool pp, string ee, string oo, string cc, string xx, string ll, string ss, string rr) {

		nom = nn;
		idx = ii;
		typ = tt;
		frz = ff;
		hoi = hh;
		pui = pp;
		pre = ee;
		lod = oo;
		cex = cc;
		rex = xx;
		lex = ll;
		src = ss;
		res = rr;

		thf = true;
		twf = true;
		tnf = true;

		this.set_orientation(VERTICAL);
		this.spacing = 10;
		this.vexpand = false;

// selection tint

		myp = new Gtk.CssProvider();
		myc = ".xx { background: #E0E0E010; box-shadow: 2px 2px 2px #00000066; }";
		myp.load_from_data(myc.data);
		this.get_style_context().add_provider(myp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		this.get_style_context().add_class("xx");

		thisclick = new Gtk.GestureClick();
		this.add_controller(thisclick);
		thisclick.pressed.connect(() => {
			if (idx >= 0) {
				selectme(idx);
				orgmydat();
			}
		});	

// parser name

		nameentry = new Gtk.Entry();
		nameentry.changed.connect(() => {
			if (doup && frz != true) {
				doup = false;
				if (nameentry.text != null) {
					if (nameentry.text.strip() != "") {
						nom = nameentry.text;
					}
				}
				doup = true;
			}
		});

// parser type

		oplist = new Gtk.DropDown(null,null);

// Load and Save must come 1st...

		oplist.set_model(new Gtk.StringList({"Load", "Save", "html", "xml", "python", "rebol", "sh", "text"}));
		oplist.set_selected(tt);
		oplist.notify["selected"].connect(() => {
			if (doup && frz != true) {
				doup = false;
				var n = oplist.get_selected();
				cex = ((StringObject?) oplist.selected_item).string;
				typ = ((int) n);
				if (typ < 2) {
					scrollbox.visible = false;
					filebox.visible = true;
					presetbox.visible = false;
					res = null; rex = null;
					src = null;
					cex = "sh";
					lod = null;
					lex = null;
					pre = null;
					presetentry.text = "";
					fess = ".xx { background: #FF000020; }";
					fesp.load_from_data(fess.data);
					fileentry.text = "";
					orgmydat();
				} else {
					filebox.visible = false;
					scrollbox.visible = true;
					presetbox.visible = true;
					if (cex == "python") {
						srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
						srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("python"));
					}
					if (cex == "rebol") {
						srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-gifded"));
						srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("rebol"));
					}
					if (cex == "sh") {
						srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
						srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("sh"));
					}
					if (cex == "html") {
						srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
						srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("html"));
					}
					if (cex == "text") {
						srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
						srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("text"));
					}
					pre = null;
					presetentry.text = "";
					lod = null;
					lex = null;
					fileentry.text = "";
					res = null; rex = null;
					orgmydat();
				}
				doup = true;
			}
		});		

// parser lock/unlock

		isotoggle = new Gtk.ToggleButton();
		isotoggle.icon_name = "system-lock-screen";
		isotoggle.set_active(ff);
		isotoggle.toggled.connect(() => {
			print("%s.isotoggle.state is %s\n", nom, isotoggle.active.to_string());
			frz = isotoggle.active;
			print("%s.frz is %s\n", nom, frz.to_string());
			bool a = (frz != true);
			nameentry.set_sensitive(a);
			oplist.set_sensitive(a);
			enableswitch.set_sensitive(a);
			srctext.set_sensitive(a);
			evalbutton.set_sensitive(a);
			fileentry.set_sensitive(a);
			filebutton.set_sensitive(a);
			presetentry.set_sensitive(a);
			presetbutton.set_sensitive(a);
			presetsave.set_sensitive(a);
			orgmydat();
		});

// parser on/off

		enableswitch = new Gtk.ToggleButton();
		//enableswitch.icon_name = "media-playback-play";
		enableswitch.set_active(hh);
		hosp = new Gtk.CssProvider();
		hoss = ".xx { background: #00FF0020; }";
		enableswitch.get_style_context().add_provider(hosp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		enableswitch.get_style_context().add_class("xx");
		if (hh) { 
			hoss = ".xx { background: #00FF0020; }";
			hosp.load_from_data(hoss.data);
			enableswitch.icon_name = "media-playback-start";
		} else {
			hoss = ".xx { background: #AA000040; }";
			hosp.load_from_data(hoss.data);
			enableswitch.icon_name = "media-playback-pause";
		}	
		enableswitch.toggled.connect(() => {
			if (doup && frz != true) {
				doup = false;
				if (enableswitch.active) { 
					//enableswitch.set_label("HOI");
					hoss = ".xx { background: #00FF0020; }";
					hosp.load_from_data(hoss.data);
					enableswitch.icon_name = "media-playback-start";
				} else { 
					//enableswitch.set_label("OFF");
					hoss = ".xx { background: #AA000040; }";
					hosp.load_from_data(hoss.data);
					enableswitch.icon_name = "media-playback-pause";
				}
				print("%s.enableswitch.state is %s\n", nom, enableswitch.active.to_string());
				hoi = enableswitch.active;
				print("%s.hoi is %s\n", nom, hoi.to_string());
				orgmydat();
				doup = true;
			}
		});

// parser fold/unfold

		foldbutton = new Gtk.ToggleButton.with_label("-");
		foldbutton.set_active(pp);
		evalbutton = new Gtk.Button.with_label("evaluate");

		nameentry.text = nn;
		nameentry.hexpand = true;

// containers: params

		headbox = new Gtk.Box(HORIZONTAL,10);
		headbox.margin_top = 0;
		headbox.margin_end = 0;
		headbox.margin_start = 0;
		headbox.margin_bottom = 0;

		firstbox = new Gtk.Box(HORIZONTAL,0);
		secondbox = new Gtk.Box(HORIZONTAL,0);
		thirdbox = new Gtk.Box(HORIZONTAL,0);

		firstbox.append(nameentry);
		firstbox.append(evalbutton);

		thirdbox.append(isotoggle);
		thirdbox.append(enableswitch);
		thirdbox.append(foldbutton);

		secondbox.append(oplist);

		firstbox.width_request = 150;
		secondbox.width_request = 80;
		thirdbox.width_request = 150;

		firstrow = new Gtk.Box(HORIZONTAL,0);
		secondrow = new Gtk.Box(HORIZONTAL,0);
		thirdrow = new Gtk.Box(HORIZONTAL,0);

		firstrow.append(firstbox);
		secondrow.append(secondbox);
		thirdrow.append(thirdbox);	

		secondrow.margin_top = 0;
		secondrow.margin_end = 0;
		secondrow.margin_start = 0;
		secondrow.margin_bottom = 0;

		thirdrow.margin_top = 0;
		thirdrow.margin_end = 0;
		thirdrow.margin_start = 0;
		thirdrow.margin_bottom = 0;

		headflow = new Gtk.Box(VERTICAL,0);
		headflow.append(firstrow);
		headflow.append(secondrow);
		headflow.append(thirdrow);
		headbox.append(headflow);

		headflow.margin_top = 10;
		headflow.margin_end = 10;
		headflow.margin_start = 10;
		headflow.margin_bottom = 10;

// containers: file for load/save

		filebox = new Gtk.Box(HORIZONTAL,5);
		fileentry = new Gtk.Entry();
		fileentry.hexpand = true;
		fileentry.text = lod;
		fesp = new Gtk.CssProvider();
		fess = ".xx { background: #00000010; }";
		fesp.load_from_data(fess.data);
		fileentry.get_style_context().add_provider(fesp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		fileentry.get_style_context().add_class("xx");	
		fileentry.changed.connect(() => {
			if (doup && frz != true) {
				doup = false;
				cex = "sh";
				File lodfile = getfiledir(fileentry.text);
				print("lodfile is %s\n",lodfile.get_path());
				if (lodfile.query_exists() == true) {
					lod = fileentry.text;
					lex = getfileext(fileentry.text);
					rex = lex;
					orgmydat();
					fess = ".xx { background: #00FF0020; }";
					fesp.load_from_data(fess.data);
				} else {
					fess = ".xx { background: #FF000020; }";
					fesp.load_from_data(fess.data);	
				}
				doup = true;
			}
		});
		filebutton = new Gtk.MenuButton();
		filebutton.icon_name = "document-open-symbolic";
		filepop = new Gtk.Popover();
		filepopbox = new Gtk.Box(VERTICAL,5);
		filepopbox.margin_top = 5;
		filepopbox.margin_end = 5;
		filepopbox.margin_start = 5;
		filepopbox.margin_bottom = 5;
		filepop.set_child(filepopbox);
		filebutton.popover = filepop;
		fileclick = new Gtk.GestureClick();
		filebutton.add_controller(fileclick);
		fileclick.pressed.connect(() => {
			if (doup && frz != true) {
				doup = false;
				while (filepopbox.get_first_child() != null) {
					filepopbox.remove(filepopbox.get_first_child());
				}
				string scandir = "source";
				if (typ == 1) { scandir = "output"; }
				string pth = GLib.Environment.get_current_dir();
				File srcpath = File.new_for_path (pth.concat("/",scandir,"/"));
				if (srcpath.query_exists() == false) { srcpath.make_directory_with_parents(); }
				bool allgood = true;
				try { dcr = Dir.open (srcpath.get_path(), 0); } catch (Error e) { print("%s\n",e.message); allgood = false; }
				if (allgood) {
					string? name = null;
					while ((name = dcr.read_name ()) != null) {
						string[] exts = name.split(".");
						if (exts.length == 2) {
							if (exts[1].strip() != "" ) {
								Gtk.Button muh = new Gtk.Button.with_label (name);
								filepopbox.append(muh);
								muh.clicked.connect ((buh) => {
									string nm = buh.label;
									string fff = "./".concat(scandir,"/", nm);
									File og = File.new_for_path(fff);
									fileentry.text = fff;
									lod = fff;
									lex = extname(exts[1]);
									src = "cat %s".printf(fff);
									cex = "sh";
									rex = lex;
									try {
										uint8[] c; string e;
										og.load_contents (null, out c, out e);
										res = ((string) c);
										fess = ".xx { background: #00FF0020; }";
										fesp.load_from_data(fess.data);
										orgmydat();
									} catch (Error e) {
										print ("failed to read %s: %s\n", og.get_path(), e.message);
										fess = ".xx { background: #FF000020; }";
										fesp.load_from_data(fess.data);	
									}
									filepop.popdown();
								});
							}
						}
					}
				}
				doup = true;
			}
		});
		filebox.append(fileentry);
		filebox.append(filebutton);
		filebox.margin_top = 10;
		filebox.margin_end = 10;
		filebox.margin_start = 10;
		filebox.margin_bottom = 10;

// containers: preset

		presetbox = new Gtk.Box(HORIZONTAL,5);
		presetentry = new Gtk.Entry();
		presetentry.hexpand = true;
		presetentry.text = getfilenamefile(pre);
		presetbutton = new Gtk.MenuButton();
		presetbutton.icon_name = "document-open-symbolic";
		presetsave = new Gtk.Button();
		presetsave.icon_name = "document-save-symbolic";
		presetsave.clicked.connect(() => {
			if (presetentry.text.strip() != "") {
				var pth = GLib.Environment.get_current_dir();
				var prepth = File.new_for_path (pth.concat("/presets/"));
				if (prepth.query_exists() == false) { prepth.make_directory_with_parents(); }
				bool allgood = true;
				if (prepth.query_exists() == false) { allgood = false; print("error: couldn't make presets dir...\n"); }
				if (allgood) {
					string lll = "sh";
					cex = ((StringObject?) oplist.selected_item).string;
					print("selected preset type is: %s\n", cex);
					lll = exttype(cex);
					string nm = presetentry.text.strip().replace(" ","_");
					string nme = nm.concat(".",lll);
					string fff = Path.build_filename ("./presets/",nme);
					pre = fff;
					File ooo = File.new_for_path(fff);
					FileOutputStream sss = ooo.replace(null, false, FileCreateFlags.PRIVATE);
					sss.write(srctext.buffer.text.data);
					if (lll == "html") {
						print("copying html preset to txt...\n");
						nme = nm.concat(".","txt");
						string ggg = Path.build_filename ("./presets/",nme);
						File yyy = File.new_for_path(ggg);
						try {
							ooo.copy (yyy, OVERWRITE, null, null);
						} catch  (Error e) { print("html to txt copy failed: %s\n",e.message); }
					}
				} else { pre = ""; }
			}
		});
		presetpop = new Gtk.Popover();
		presetpopbox = new Gtk.Box(VERTICAL,5);
		presetpopbox.margin_top = 5;
		presetpopbox.margin_end = 5;
		presetpopbox.margin_start = 5;
		presetpopbox.margin_bottom = 5;
		presetpop.set_child(presetpopbox);
		presetbutton.popover = presetpop;
		presetclick = new Gtk.GestureClick();
		presetbutton.add_controller(presetclick);
		presetclick.pressed.connect(() => {
			if (doup && frz != true) {
				doup = false;
				while (presetpopbox.get_first_child() != null) {
					presetpopbox.remove(presetpopbox.get_first_child());
				}
				cex = ((StringObject?) oplist.selected_item).string;
				print("selected preset type is: %s\n", cex);
				string presetext = exttype(cex);
				var pth = GLib.Environment.get_current_dir();
				var prepth = File.new_for_path (pth.concat("/presets/"));
				if (prepth.query_exists() == false) { prepth.make_directory_with_parents(); }
				bool allgood = true;
				try { dcr = Dir.open (prepth.get_path(), 0); } catch (Error e) { print("%s\n",e.message); allgood = false; }
				if (allgood) {
					string? name = null;
					print("searching for files in %s\n",((string) prepth.get_path()));
					while ((name = dcr.read_name ()) != null) {
						var exts = name.split(".");
						if (exts.length == 2) {
							print("checking file: %s\n", name);
							if (exts[1] == presetext) {
								Gtk.Button muh = new Gtk.Button.with_label (name);
								presetpopbox.append(muh);
								muh.clicked.connect ((buh) => {
									var nm = buh.label;
									string fff = Path.build_filename ("./presets/", nm);
									File og = File.new_for_path(fff);
									print("selected file is: %s\n",fff);
									string[] nameparts = nm.split(".");
									presetentry.text = nameparts[0];
									try {
										uint8[] c; string e;
										og.load_contents (null, out c, out e);
										srctext.buffer.text = (string) c;
										src = ((string) c);
										pre = fff;
										orgmydat();
									} catch (Error e) {
										print ("failed to read %s: %s\n", og.get_path(), e.message);
									}
									presetpop.popdown();
								});
							}
						}
					}
				}
				doup = true;
			}
		});
		presetbox.append(presetbutton);
		presetbox.append(presetentry);
		presetbox.append(presetsave);
		presetbox.hexpand = true;

		presetbox.margin_top = 10;
		presetbox.margin_end = 10;
		presetbox.margin_start = 10;
		presetbox.margin_bottom = 10;

// containers: source code editor

		scrollbox = new Gtk.Box(VERTICAL,10);
		srcscroll = new Gtk.ScrolledWindow();
		srcscroll.height_request = 200;
		srctextbufftags = new Gtk.TextTagTable();
		srctextbuff = new GtkSource.Buffer(srctextbufftags);
		srctext = new GtkSource.View.with_buffer(srctextbuff);
		srctext.buffer.set_text(src);
		srctext.accepts_tab = true;
		srctext.set_monospace(true);

		srctextbuff.set_highlight_syntax(true);	
		srctext.buffer.changed.connect(() => {
			if (doup && frz != true) {
				doup = false;
				src = srctext.buffer.text;
				//print("style size is: %s\n",srctextbuff.style_scheme.get_style("text").scale);
				srcscroll.height_request = int.min(500,int.max(200,((int) (srctext.buffer.get_line_count() * 11) + 60)));
				orgmydat();
				doup = true;
			}
		});	

		srctext.tab_width = 2;
		srctext.indent_on_tab = true;
		srctext.indent_width = 2;
		srctext.show_line_numbers = true;
		srctext.highlight_current_line = true;
		srctext.vexpand = true;
		srctext.top_margin = 10;
		srctext.left_margin = 10;
		srctext.right_margin = 10;
		srctext.bottom_margin = 10;
		srctext.space_drawer.enable_matrix = true;

		srctext.opacity = 0.8;

		srcscroll.set_child(srctext);
		scrollbox.append(srcscroll);
		scrollbox.vexpand = true;
		scrollbox.margin_top = 0;
		scrollbox.margin_end = 0;
		scrollbox.margin_start = 0;
		scrollbox.margin_bottom = 0;

// containers: assemble it all...

		this.margin_top = 5;
		this.margin_end = 40;
		this.margin_start = 10;
		this.margin_bottom = 5;
		
		filebox.visible = false;

		this.append(headbox);
		this.append(filebox);
		this.append(scrollbox);
		this.append(presetbox);

// this had to go way down here as it was accessing stuff that wasn't created yet

		foldbutton.toggled.connect(() => {
			print("foldbutton.active = %s\n",foldbutton.get_active().to_string());
			if (doup) {
				if (foldbutton.get_active()) {
					scrollbox.visible = false;
					presetbox.visible = false;
					filebox.visible = false;
					foldbutton.set_label("+");
				} else {
					if (typ > 1) { scrollbox.visible = true; presetbox.visible = true; filebox.visible = false; }
					if (typ <= 1) { filebox.visible = true; scrollbox.visible = false; presetbox.visible = false; }
					foldbutton.set_label("-");
				}
				pui = foldbutton.get_active();
				orgmydat();
				print("pui is %s\n", pui.to_string());
			}
		});

// initialize ui

		doup = false;

		if (typ >= 0) {
			cex = ((StringObject?) oplist.selected_item).string;
			if (typ < 2 && frz != true) {
				srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
				srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("sh"));

// auto-load loaders	
			
				if (typ <= 1) {
					if (lod != null) {
						if (lod.strip() != "") {
							bool allgood = false;
							File og = File.new_for_path(lod);
							if (og.query_exists() == true) {
								try {
									uint8[] c; string e;
									og.load_contents (null, out c, out e);
									res = ((string) c);
									allgood = true;
								} catch (Error e) {
									print ("failed to read %s: %s\n", og.get_path(), e.message);
								}
							}
							if (allgood) {
								if(typ == 0) { src = "cat %s".printf(lod); } else { src = null; }
								fess = ".xx { background: #00FF0020; }";
								string lext = getfileext(lod);
								if (lext != "") { lex = extname(lext); rex = lex; }
								cex = "sh";
							} else {
								fess = ".xx { background: #FF000020; }";	
							}
							fesp.load_from_data(fess.data);
						}
					}
				}
			} else {

// syntax highlighting

				if (frz != true) { lod = null; lex = null; }
				if (cex == "rebol") {
					srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-gifded"));
					srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("rebol"));
				}
				if (cex == "html") {
					srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
					srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("html"));
				}
				if (cex == "python") {
					srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
					srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("python"));
				}
				if (cex == "xml") {
					srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
					srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("xml"));
				}
				if (cex == "sh") {
					srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
					srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("sh"));
				}
				if (cex == "text") {
					srctextbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
					srctextbuff.set_language(GtkSource.LanguageManager.get_default().get_language("text"));
				}
			}
		} else { print("provided type was null, nothing was initialized...\n"); }

// sourceview container height

		srcscroll.height_request = int.min(500,int.max(200,((int) (srctext.buffer.get_line_count() * 11) + 60)));

// folding

		if (pp) {
			scrollbox.visible = false;
			presetbox.visible = false;
			filebox.visible = false;
			foldbutton.set_label("+");
		} else {
			if (typ > 1) { scrollbox.visible = true; presetbox.visible = true; filebox.visible = false; }
			if (typ <= 1) { filebox.visible = true; presetbox.visible = false; scrollbox.visible = false;}
			foldbutton.set_label("-");
		}

// locking

		if (ff == true) {
			nameentry.set_sensitive(false);
			oplist.set_sensitive(false);
			enableswitch.set_sensitive(false);
			srctext.set_sensitive(false);
			evalbutton.set_sensitive(false);
			fileentry.set_sensitive(false);
			filebutton.set_sensitive(false);
			presetentry.set_sensitive(false);
			presetbutton.set_sensitive(false);
			presetsave.set_sensitive(false);
		}

		doup = true;

// the eval button, this is what its all about...

		evalbutton.clicked.connect(() => {

// sync ids if they are busted for some reason

			int j = 0;
			foreach (ParserBox n in allt) {
				if (n.idx != j) {
					print("node idx (%d) reset to array index : %d\n",n.idx,j);
					n.idx = j;
				}
				j = j + 1;
			}

//  L = lastres, F = frz, H = hoi, R = result to pass-on to lastres
// +--------------------+-----+---------+------+---------------------------------------+---------------------+
// | [L][node][F][H][R] | buf | cmd     | type | sample SRC code                       | sample RES result   |
// +--------------------+-----+----------------+---------------------------------------+---------------------+
// | [A][LOAD][ ][X][A] |AAAAA| LOD RES | send | "cat ./source/test.org"               | "-*- mode: org -*-" |
// | [G][PYTH][X][X][G] |GGGGG| GET RES | swap | "print('lol wut')"                    | "lol wut"           |
// | [G][REEB][ ][X][H] |HHHHH| EVL RES | eval | "take split system/script/args ^" ^"" | "lol"               |
// | [ ][PYTH][ ][ ][ ] |HHHHH| SKP     | skip |                                       | "lol"               |
// | [H][REEB][ ][X][I] |IIIII| EVL RES | eval | "uppercase system/script/args"        | "LOL"               |
// | [I][SAVE][ ][X][I] |IIIII| SAV RES | save | (hardcoded vala write)                | "LOL"               |
// +--------------------+-----+----------------+---------------------------------------+---------------------+

			print("\n[EVALBUTTON] cex = %s\n",cex);
			if (cex != null) {
				string rebex = "REBOL []\n";
				string lastres = "";
				print("\n[EVALBUTTON] evaluating the stack...\n");
				if (nom != null) {
					if (hoi) {
						for (int i = 0; i < idx; i++) {
							//print("[EVALBUTTON] \tlastres is \n%s\n",lastres);
							print("[EVALBUTTON] checking node %s (%d)...\n",allt[i].nom,i);
							if (allt[i].frz == true) {
								if (allt[i].res != null) {
									if (allt[i].res.strip() != "") {
										lastres = allt[i].res;
									}
								}
								print("[EVALBUTTON] \t%s.frz is true, getting its (valid) res without evaluating...\n",allt[i].nom);
								continue;
							} else {
								print("[EVALBUTTON] \t%s.frz is false...\n",allt[i].nom);
								if ( allt[i].hoi) {
									print("[EVALBUTTON] \t%s.hoi is true...\n",allt[i].nom);
									if (allt[i].typ > 1) {
										if (allt[i].src != null) {
											print("[EVALBUTTON] \t%s.src is not null...\n",allt[i].nom);
											if (allt[i].cex == "rebol") {
												string rebin = allt[i].src;
												rebin = rebin.replace("REBOL []\n", "");
												rebin = rebin.replace("REBOL [ ]\n", "");
												rebin = rebin.replace("print l", "either ((length? l) > 0) [append parsed split l \"^/\"] [append parsed l]");
												rebin = rebin.replace("print ", "append parsed ");
												rebin = rebin.replace("lines: read/lines to-file system/script/args", "lines: copy parsed\nparsed: copy []");
												rebex = rebex.concat(rebin, "\n");
												//print("[EVALBUTTON] \tcaptured src:\n%s",rebin);
											}
											if (allt[i].cex == "html" || allt[i].cex == "text" || allt[i].cex == "xml") {
												string rebin = allt[i].src;
												string[] rebparts = rebin.split("<!--[lastres]-->");
												if (rebparts.length == 2) {
													rebex = rebex.concat("lines: copy parsed\nparsed: copy []\n","insert lines {", rebparts[0], "}\n", "append lines {", rebparts[1], "}\n", "parsed: copy lines\n");
												}
											}
											evalnode (lastres, i, false);
											lastres = allt[i].res;
										} else { print("[EVALBUTTON]\tnode has no source code, skipping...\n"); }
									} else {
										print("[EVALBUTTON] \t%s.typ is %d\n",allt[i].nom,allt[i].typ);
										if (allt[i].lod != null) {
											if (allt[i].lod.strip() != "") {
												if( allt[i].typ == 0) { 
													rebex = rebex.concat("parsed: read/lines %","%s\n".printf(allt[i].lod));
													evalnode ("", i, false); 
												} else {
													rebex = rebex.concat("write/lines %","%s parsed\n".printf(allt[i].lod));
													evalnode (lastres, i, false);
												}
												lastres = allt[i].res;
												//print("[EVALBUTTON] \t%s.res is \n%s\n",allt[i].nom,lastres);
											} else { print("[EVALBUTTON]\tlod is an empty string, skipping...\n"); }
										} else { print("[EVALBUTTON]\tlod is null, skipping...\n"); }
									}
								} else { print("[EVALBUTTON]\tnode isn't enabled, skipping...\n"); }
							}
						}
						if (lastres.strip() == "" && typ != 0) {
							if (typ > 1) { 
								print("[EVALBUTTON] couldn't find a valid source for %s, attempting eval anyway...\n",nom);
								evalnode(src,idx,true);
							}
						} else {
							print("[EVALBUTTON] current index is: %d, evaluating it...\n", idx);
							if (typ == 0) { evalnode("",idx,true); } else { evalnode(lastres, idx, true); }
						}
					} else { print("[EVALBUTTON] current node is not enabled, aborting...\n"); }
				} else { print("[EVALBUTTON] node name not set, aborting...\n"); }
				if (rebex != "") {
					var ddd = GLib.Environment.get_current_dir();
					string nnn = ("export.r3");
					string fff = Path.build_filename (ddd, nnn);
					File ffff = File.new_for_path (fff);
					FileOutputStream ooo = null;
					try {
						ooo = ffff.replace (null, false, FileCreateFlags.PRIVATE);
						ooo.write(rebex.data);
					} catch (Error e) {
						print ("[EVALBUTTON] \tError: couldn't make outputstream.\n\t%s\n", e.message);
					}
				}
			} else { print("[EVALBUTTON] cex is null, aborting...\n"); }
			orgmydat();
		});
	}		
}

// application dresscode

public class gifded : Gtk.Application {
	construct {
		application_id = "com.gifded.gifded";
		flags = ApplicationFlags.FLAGS_NONE;
	}
}

// the window

public class qwin : Gtk.ApplicationWindow {
	public qwin (Gtk.Application gifded) {Object (application: gifded);}
	construct {

		int winx = 0;
		int winy = 0;
		doup = false;
		this.title = "gifded";
		this.close_request.connect((e) => { return false; } );
		Gtk.Label titlelabel = new Gtk.Label("gifded");
		Gtk.HeaderBar iobar = new Gtk.HeaderBar();
		iobar.show_title_buttons = false;
		iobar.set_title_widget(titlelabel);
		this.set_titlebar(iobar);
		this.set_default_size(360, (720 - 46));

// headerbar load and save popmenus

		Gtk.MenuButton savemenu = new Gtk.MenuButton();
		Gtk.MenuButton loadmenu = new Gtk.MenuButton();

		Gtk.GestureClick loadmenuclick = new Gtk.GestureClick();
		loadmenu.add_controller(loadmenuclick);

		savemenu.icon_name = "document-save-symbolic";
		loadmenu.icon_name = "document-open-symbolic";

		Gtk.Button savebutton = new Gtk.Button.with_label("save");
		Gtk.Popover savepop = new Gtk.Popover();
		Gtk.Popover loadpop = new Gtk.Popover();
		Gtk.Box savepopbox = new Gtk.Box(VERTICAL,5);
		Gtk.Box loadpopbox = new Gtk.Box(VERTICAL,5);
		savepopbox.margin_end = 5;
		savepopbox.margin_top = 5;
		savepopbox.margin_start = 5;
		savepopbox.margin_bottom = 5;
		loadpopbox.margin_end = 5;
		loadpopbox.margin_top = 5;
		loadpopbox.margin_start = 5;
		loadpopbox.margin_bottom = 5;
		Gtk.Entry saveentry = new Gtk.Entry();
		saveentry.text = "default";
		savepopbox.append(saveentry);
		savepopbox.append(savebutton);
		savepop.set_child(savepopbox);
		loadpop.set_child(loadpopbox);
		savemenu.popover = savepop;
		loadmenu.popover = loadpop;
		iobar.pack_start(loadmenu);
		iobar.pack_end(savemenu);

// save it

		savebutton.clicked.connect (() =>  {
			if (saveentry.text != null) {
				if (saveentry.text.strip() != "") {
					bool allgood = false;
					var dd = GLib.Environment.get_current_dir();
					string nn = (saveentry.text.strip() + ".org");
					string ff = Path.build_filename (dd, nn);
					File fff = File.new_for_path (ff);
					FileOutputStream ooo = null;
					try {
						ooo = fff.replace (null, false, FileCreateFlags.PRIVATE);
						allgood = true;
					} catch (Error e) {
						print ("Error: couldn't make outputstream.\n\t%s\n", e.message);
					}
					if (allgood) {
						if (allt.length > 0) {
							foreach (ParserBox n in allt) {

// export the scenario as an orgfile, cause shizzas & gizzas...

								string o = "";
								string t = n.rex;
								if ( n.rex == "Load" || n.rex == "Save" ) { t = n.lex; }
								o = o.concat("* %s\n".printf(n.nom));
								o = o.concat(":PROPERTIES:\n:TYP: %d\n:FRZ: %d\n:HOI: %d\n:PUI: %d\n:LOD: %s\n:PRE: %s\n:LEX: %s\n:CEX: %s\n:REX: %s\n:END:\n".printf(((int) n.typ),((int) n.frz),((int) n.hoi),((int) n.pui),((string) n.lod),((string) n.pre),((string) n.lex),((string) n.cex), ((string) n.rex)));
								if (n.src != null) {
									o = o.concat("** code\n#+BEGIN_SRC %s\n%s\n#+END_SRC\n".printf(n.cex,((string) n.src.strip())));
								} else {
									o = o.concat("** code\n#+BEGIN_SRC %s\n#+END_SRC\n".printf(n.cex));
								}
								if ( n.rex == "orgmode" ) {
									o = o.concat("** result\n#+BEGIN_EXAMPLE\n");
									string ores = "";

// only save res if the parser is frozen

									if (n.res != null && n.frz == true) {
										if (n.res.strip() != "") {
											string[] olines = n.res.split("\n");
											if (olines.length > 1) {
												foreach (string oln in olines) {
													if (oln.get_char(0) == '*') {
														ores = ores.concat(",",oln,"\n");
													} else {
														if (oln.get_char(0) == '#') {
															ores = ores.concat(",",oln,"\n");
														} else {
															ores = ores.concat(oln,"\n");
														}
													}
												}
											}
										}
									}
									o = o.concat("%s\n#+END_EXAMPLE\n".printf(ores));
								} else {

// only save res if the parser is frozen

									if (n.res != null && n.frz == true) {
										o = o.concat("** result\n#+BEGIN_SRC %s\n%s\n#+END_SRC\n".printf(t,((string) n.res)));
									} else {
										o = o.concat("** result\n#+BEGIN_SRC %s\n\n#+END_SRC\n".printf(t));
									}
								}
								ooo.write(o.data);
							}
						}
					}
					savepop.popdown();
				}
			}
		});

// load it:

		loadmenuclick.pressed.connect(() => {
			if (doup) {
				doup = false;
				while (loadpopbox.get_first_child() != null) {
					loadpopbox.remove(loadpopbox.get_first_child());
				}
				var pth = GLib.Environment.get_current_dir();
				bool allgood = true;
				GLib.Dir dcr = null;
				try { dcr = Dir.open (pth, 0); } catch (Error e) { print("%s\n",e.message); allgood = false; }
				if (allgood) {
					string? name = null;
					print("searching for org files in %s\n",((string) pth));
					while ((name = dcr.read_name ()) != null) {
						var exts = name.split(".");
						if (exts.length == 2) {
							print("checking file: %s\n", name);
							if (exts[1] == "org") {
								Gtk.Button muh = new Gtk.Button.with_label (name);
								loadpopbox.append(muh);
								muh.clicked.connect ((buh) => {
									var nm = buh.label;
									string ff = Path.build_filename ("./", nm);
									File og = File.new_for_path(ff);
									print("selected file is: %s\n",ff);
									string orgf = "";
									try {
										uint8[] c; string e;
										og.load_contents (null, out c, out e);
										orgf = (string) c;
									} catch (Error e) {
										print ("failed to read %s: %s\n", og.get_path(), e.message);
									}
									if (orgf.strip() != "") {
										while (parserslist.get_first_child() != null) {
											parserslist.remove(parserslist.get_first_child());
										}
										allt = {};
										spawnuifromorg(orgf);
										print("allt.length = %d\n",allt.length);
										if (allt.length > 0) {
// fix ids, this also happens on node create and eval
											int j = 0;
											foreach (ParserBox n in allt) {
												if (n.idx != j) { n.idx = j; }
												j = j + 1;
											}
											foreach (ParserBox b in allt) { parserslist.append(b); }
											allt[0].selectme(0);
											allt[0].orgmydat();
										}
									} else { print("nothing to load, aborting.\n"); }
									loadpop.popdown();
								});
							}
						}
					}
				}
				doup = true;
			}			
		});

// the list of parsers

		Gtk.ScrolledWindow parsersscroll = new Gtk.ScrolledWindow();
		parserslist = new Gtk.Box(VERTICAL,0);
		parserslist.vexpand = true;
		parsersscroll.set_child(parserslist);

// parser controlbox

		Gtk.Box nodecontrolbox = new Gtk.Box(HORIZONTAL,0);
		Gtk.Button addnodebutton = new Gtk.Button.with_label("+");
		Gtk.Button removenodebutton = new Gtk.Button.with_label("-");
		Gtk.Button upbutton = new Gtk.Button.with_label("▼");
		Gtk.Button downbutton = new Gtk.Button.with_label("▲");

		downbutton.clicked.connect(() => {
			int osl = selectednode;
			int mdx = allt[selectednode].idx;
			if (selectednode != mdx) {
				print("shouldntbeseeingthis: array index is out of sync with parser index, fixing it...\n");
				int xx = 0;
				foreach (ParserBox n in allt) { n.idx = xx; xx += 1; }
			}
			if (selectednode == mdx) {
				mdx = selectednode - 1;
				if (mdx >= 0) {
					allt[osl].idx = mdx;
					allt[mdx].idx = osl;
					parserslist.reorder_child_after(allt[mdx],allt[osl]);

					ParserBox holdbox = allt[osl];
					allt[osl] = allt[mdx];
					allt[mdx] = holdbox;
					selectednode = mdx;
					allt[selectednode].orgmydat();
				}
			} else { print("the selection index is busted, aborting...\n"); }
		});

		upbutton.clicked.connect(() => {
			int osl = selectednode;
			int mdx = allt[selectednode].idx;
			if (selectednode != mdx) { 
				print("shouldntbeseeingthis: array index is out of sync with parser index, fixing it...\n");
				int xx = 0;
				foreach (ParserBox n in allt) { n.idx = xx; xx += 1; }
			}
			if (selectednode == mdx) {
				mdx = selectednode + 1;
				if (mdx <= (allt.length - 1)) {
					allt[osl].idx = mdx;
					allt[mdx].idx = osl;
					parserslist.reorder_child_after(allt[osl],allt[mdx]);

					ParserBox holdbox = allt[osl];
					allt[osl] = allt[mdx];
					allt[mdx] = holdbox;
					selectednode = mdx;
					allt[selectednode].orgmydat();
				}
			} else { print("the selection index is busted, aborting...\n"); }
		});

		addnodebutton.clicked.connect(() => {
			ParserBox newparser = new ParserBox(allt.length, "new parser", 4, false, true, false, "", "", "", "html", "rebol", "", "");
			allt = allt + newparser;
			parserslist.append(allt[(allt.length - 1)]);
			int wx, wy = 0;
			this.get_default_size(out wx,out wy);
			if (vdiv.get_orientation() == VERTICAL) {
				foreach(ParserBox b in allt) { b.reflowparams(wx - 95); }
			} else {
				foreach(ParserBox b in allt) { b.reflowparams((wx - 95) - vdiv.position); }
			}			
		});
		removenodebutton.clicked.connect(() => {
			doup = false;
			tempallt = {};
			foreach (ParserBox n in allt) {
				if (n.idx != selectednode) {
					tempallt += n;
				}
			}
			while (parserslist.get_first_child() != null) {
				parserslist.remove(parserslist.get_first_child());
			}
			selectednode = int.max(0, (selectednode - 1));
			allt = {};
			foreach (ParserBox n in tempallt) { allt += n; }
			int xx = 0;
			foreach (ParserBox n in allt) { n.idx = xx; xx += 1; parserslist.append(n); }
			tempallt = {};
			int wx, wy = 0;
			this.get_default_size(out wx,out wy);
			if (vdiv.get_orientation() == VERTICAL) {
				foreach(ParserBox b in allt) { b.reflowparams(wx - 95); }
			} else {
				foreach(ParserBox b in allt) { b.reflowparams((wx - 95) - vdiv.position); }
			}
			doup = true;
		});
	
		nodecontrolbox.append(addnodebutton);
		nodecontrolbox.append(removenodebutton);
		nodecontrolbox.append(upbutton);
		nodecontrolbox.append(downbutton);
		nodecontrolbox.vexpand = false;
		nodecontrolbox.hexpand = true;
		nodecontrolbox.margin_top = 10;
		nodecontrolbox.margin_end = 0;
		nodecontrolbox.margin_start = 10;
		nodecontrolbox.margin_bottom = 10;		

		Gtk.Box nodepane = new Gtk.Box(VERTICAL,0);
		nodepane.append(parsersscroll);
		nodepane.append(nodecontrolbox);

// the output pane

		Gtk.TextTagTable htmlbufftags = new Gtk.TextTagTable();
		htmlbuff = new GtkSource.Buffer(htmlbufftags);
		htmloutput = new GtkSource.View.with_buffer(htmlbuff);
		htmlbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
		htmlbuff.set_language(GtkSource.LanguageManager.get_default().get_language("html"));
		htmlbuff.set_highlight_syntax(true);		

		htmloutput.buffer.set_text("parser output goes here");
		htmloutput.accepts_tab = true;
		htmloutput.set_monospace(true);
		htmloutput.tab_width = 2;
		htmloutput.indent_on_tab = true;
		htmloutput.indent_width = 4;
		htmloutput.show_line_numbers = true;
		htmloutput.highlight_current_line = true;
		htmloutput.vexpand = true;
		htmloutput.top_margin = 10;
		htmloutput.left_margin = 10;
		htmloutput.right_margin = 10;
		htmloutput.bottom_margin = 10;
		htmloutput.space_drawer.enable_matrix = true;

		htmloutput.vexpand = true;
		Gtk.ScrolledWindow htmlscroll = new Gtk.ScrolledWindow();
		Gtk.Box htmlscrollbox = new Gtk.Box(VERTICAL,10);
		htmlscroll.set_child(htmloutput);
		htmlscrollbox.append(htmlscroll);

// reference pane

		Gtk.TextTagTable refbufftags = new Gtk.TextTagTable();
		GtkSource.Buffer refbuff = new GtkSource.Buffer(refbufftags);
		GtkSource.View refoutput = new GtkSource.View.with_buffer(refbuff);
		refbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-dark"));
		refbuff.set_language(GtkSource.LanguageManager.get_default().get_language("html"));
		refbuff.set_highlight_syntax(true);		

		refoutput.buffer.set_text("reference code goes here");
		refoutput.accepts_tab = true;
		refoutput.set_monospace(true);
		refoutput.tab_width = 2;
		refoutput.indent_on_tab = true;
		refoutput.indent_width = 4;
		refoutput.show_line_numbers = true;
		refoutput.highlight_current_line = true;
		refoutput.vexpand = true;
		refoutput.top_margin = 10;
		refoutput.left_margin = 10;
		refoutput.right_margin = 10;
		refoutput.bottom_margin = 10;
		refoutput.space_drawer.enable_matrix = true;

		Gtk.DropDown reftypelist = new Gtk.DropDown(null,null);
		reftypelist.set_model(new Gtk.StringList({"reference", "presets", "source", "output"}));
		reftypelist.set_selected(0);

		Gtk.Entry reffileentry = new Gtk.Entry();
		reffileentry.hexpand = true;
		Gtk.CssProvider rfsp = new Gtk.CssProvider();
		string rfss = ".xx { background: #00000010; }";
		rfsp.load_from_data(rfss.data);
		reffileentry.get_style_context().add_provider(rfsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		reffileentry.get_style_context().add_class("xx");	
		reffileentry.changed.connect(() => {
			if (doup) {
				doup = false;
				File lodfile = getfiledir(reffileentry.text);
				print("lodfile is %s\n",lodfile.get_path());
				if (lodfile.query_exists() == true) {
					rfss = ".xx { background: #00FF0020; }";
					rfsp.load_from_data(rfss.data);
				} else {
					rfss = ".xx { background: #FF000020; }";
					rfsp.load_from_data(rfss.data);	
				}
				doup = true;
			}
		});
		reffileentry.editing_done.connect(() => {
			if (doup) {
				doup = false;
				bool allgood = false;
				if (reffileentry.text != null) {
					if (reffileentry.text.strip() != "") {
						File og = getfiledir(reffileentry.text.strip());
						print("og is %s\n",og.get_path());
						if (og.query_exists() == true) {
							bool dobuff = false;
							string rets = "";
							try {
								uint8[] c; string e;
								og.load_contents (null, out c, out e);
								rets = ((string) c);
								rfss = ".xx { background: #00FF0020; }";
								rfsp.load_from_data(rfss.data);
								dobuff = true; allgood = true;
							} catch (Error e) {
								print ("failed to read %s: %s\n", og.get_path(), e.message);
								rfss = ".xx { background: #FF000020; }";
								rfsp.load_from_data(rfss.data);	
							}
							if (dobuff) {
								string fex = getfileext(og.get_path());
								if (fex != null) {
									if (fex.strip() != "") { 
										string sch = "Adwaita-dark";
										string lng = "text";
										if (fex == "py") { lng = "python"; }
										if (fex == "r3" || fex == "r")  { lng = "rebol"; sch = "Adwaita-gifded"; }
										if (fex == "sh") { lng = "sh"; }
										if (fex == "html" || fex == "htm") { lng = "html"; }
										if (fex == "org") { lng = "orgmode"; sch = "Adwaita-orgmode"; }
										if (fex == "txt") { lng = "text"; }
										refbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme(sch));
										refbuff.set_language(GtkSource.LanguageManager.get_default().get_language(lng));
										refoutput.buffer.text = rets;
									} else { allgood = false; print("file extension is empty: %s\n", og.get_path()); }
								} else { allgood = false; print("file extension is null: %s\n", og.get_path()); }
							}
						}
					}
				} 
				if (allgood == false) { rfss = ".xx { background: #FF000020; }"; rfsp.load_from_data(rfss.data); }
				doup = true;
			}
		});
		Gtk.MenuButton reffilebutton = new Gtk.MenuButton();
		reffilebutton.icon_name = "document-open-symbolic";
		Gtk.Popover reffilepop = new Gtk.Popover();
		Gtk.Box reffilepopbox = new Gtk.Box(VERTICAL,2);
		Gtk.ScrolledWindow refpopscroll = new Gtk.ScrolledWindow();
		reffilepopbox.margin_top = 5;
		reffilepopbox.margin_end = 5;
		reffilepopbox.margin_start = 5;
		reffilepopbox.margin_bottom = 5;
		refpopscroll.set_child(reffilepopbox);
		//reffilepopbox.vexpand = true;
		//reffilepopbox.hexpand = true;
		reffilepop.width_request = 300;
		int wwx, wwy = 0;
		this.get_default_size(out wwx,out wwy);
		reffilepop.height_request = (wwy - 200);
		reffilepop.set_child(refpopscroll);
		reffilebutton.popover = reffilepop;
		reffilepop.set_position(TOP);
		Gtk.GestureClick reffileclick = new Gtk.GestureClick();
		reffilebutton.add_controller(reffileclick);
		reffileclick.pressed.connect(() => {
			if (doup) {
				doup = false;
				while (reffilepopbox.get_first_child() != null) {
					reffilepopbox.remove(reffilepopbox.get_first_child());
				}
				string scandir = "reference";
				if (reftypelist.selected == 1) { scandir = "presets"; }
				if (reftypelist.selected == 2) { scandir = "source"; }
				if (reftypelist.selected == 3) { scandir = "output"; }
				string pth = GLib.Environment.get_current_dir();
				File srcpath = File.new_for_path (pth.concat("/",scandir,"/"));
				if (srcpath.query_exists() == false) { srcpath.make_directory_with_parents(); }
				bool allgood = true;
				GLib.Dir dcr = null;
				try { dcr = Dir.open (srcpath.get_path(), 0); } catch (Error e) { print("%s\n",e.message); allgood = false; }
				if (allgood) {
					string? name = null;
					while ((name = dcr.read_name ()) != null) {
						string[] exts = name.split(".");
						if (exts.length == 2) {
							if (exts[1].strip() != "" ) {
								Gtk.Button muh = new Gtk.Button.with_label (name);
								reffilepopbox.append(muh);
								muh.clicked.connect ((buh) => {
									string nm = buh.label;
									string fff = "./".concat(scandir,"/", nm);
									File og = File.new_for_path(fff);
									reffileentry.text = fff;
									bool dobuff = false;
									string rets = "";
									try {
										uint8[] c; string e;
										og.load_contents (null, out c, out e);
										rets = ((string) c);
										rfss = ".xx { background: #00FF0020; }";
										rfsp.load_from_data(rfss.data);
										dobuff = true;
									} catch (Error e) {
										print ("failed to read %s: %s\n", og.get_path(), e.message);
										rfss = ".xx { background: #FF000020; }";
										rfsp.load_from_data(rfss.data);	
									}
									if (dobuff) {
										string fex = getfileext(og.get_path());
										if (fex != null) {
											if (fex.strip() != "") { 
												string sch = "Adwaita-dark";
												string lng = "text";
												if (fex == "py") { lng = "python"; }
												if (fex == "r3" || fex == "r")  { lng = "rebol"; sch = "Adwaita-gifded"; }
												if (fex == "sh") { lng = "sh"; }
												if (fex == "html" || fex == "htm") { lng = "html"; }
												if (fex == "org") { lng = "orgmode"; sch = "Adwaita-orgmode"; }
												if (fex == "txt") { lng = "text"; }
												refbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme(sch));
												refbuff.set_language(GtkSource.LanguageManager.get_default().get_language(lng));
												refoutput.buffer.text = rets;
											}
										}
									}
									reffilepop.popdown();
								});
							}
						}
					}
				}
				doup = true;
			}
		});

		Gtk.Box refcontrolbox = new Gtk.Box(HORIZONTAL,0);
	
		refcontrolbox.append(reftypelist);
		refcontrolbox.append(reffilebutton);
		refcontrolbox.append(reffileentry);
		refcontrolbox.vexpand = false;
		refcontrolbox.hexpand = true;
		refcontrolbox.margin_top = 10;
		refcontrolbox.margin_end = 0;
		refcontrolbox.margin_start = 10;
		refcontrolbox.margin_bottom = 10;		

		Gtk.ScrolledWindow refscroll = new Gtk.ScrolledWindow();
		Gtk.Box refscrollbox = new Gtk.Box(VERTICAL,10);
		refscroll.set_child(refoutput);
		refscrollbox.append(refscroll);

		//Gtk.WebView webrenderer = new Gtk.WebView();
		//webscrollbox.append(webrenderer);

		Gtk.Box refpane = new Gtk.Box(VERTICAL,0);
		refpane.append(refscrollbox);
		refpane.append(refcontrolbox);
		

		Gtk.TextTagTable datbufftags = new Gtk.TextTagTable();
		GtkSource.Buffer datbuff = new GtkSource.Buffer(datbufftags);
		datoutput = new GtkSource.View.with_buffer(datbuff);
		datbuff.set_style_scheme(GtkSource.StyleSchemeManager.get_default().get_scheme("Adwaita-orgmode"));
		datbuff.set_language(GtkSource.LanguageManager.get_default().get_language("orgmode"));
		datbuff.set_highlight_syntax(true);		
		string sampleorg = """# -*- org-todo-keyword-faces: (("[0_TODO]" . "orange") ("[1_IP..]" . "yellow") ("[2_FIX.]" . "red") ("[3_WAIT]" . "blue") ("[4_NOPE]" . "black") ("[5_DONE]" . "green")); -*-
#+STARTUP: indent overview
#+STARTUP: align
#+OPTIONS:\n:t
* loader
:PROPERTIES:
:IDX: 0
:TYP: 0
:FRZ: false
:HOI: true
:PUI: true
:PRE: 
:LOD: 
:LEX: 
:CEX:
:REX: Load
:DEADLINE: <2022-08-08 13:00>
:FILE: ./exportme.txt
:END:
** [#A] code
#+BEGIN_SRC Load
some code goes in here
#+END_SRC
** [TODO] result
some normal text goes here
and maybe some checks
- [ ] one
- [X] two
and a list?
- something
  - something else
#+BEGIN_SRC html
#+END_SRC
** one
:PROPERTIES:
:COLUMNS: %HUH %WUT
:END:
*** test :test:tag:
[[www.alink.com.au][alink]]
** [DONE] test again :moretags:
\begin{verbatim}
#+BEGIN_TABLE
		| name     | qty | val | sub |
		|----------+-----+-----+-----|
		| [[one]]  | 2   | 3   | 6   |
#+END_TABLE
\end{verbatim}
\clearpage
""";
		datoutput.buffer.set_text(sampleorg);
		datoutput.accepts_tab = true;
		datoutput.set_monospace(true);
		datoutput.tab_width = 2;
		datoutput.indent_on_tab = true;
		datoutput.indent_width = 4;
		datoutput.show_line_numbers = true;
		datoutput.highlight_current_line = true;
		datoutput.vexpand = true;
		datoutput.top_margin = 10;
		datoutput.left_margin = 10;
		datoutput.right_margin = 10;
		datoutput.bottom_margin = 10;
		datoutput.space_drawer.enable_matrix = true;
		datoutput.vexpand = true;

		Gtk.ScrolledWindow datscroll = new Gtk.ScrolledWindow();
		datscroll.set_child(datoutput);
		Gtk.Box datscrollbox = new Gtk.Box(VERTICAL,10);
		datscrollbox.append(datscroll);

// swishbox for: output html, output render, data view

		outputstack = new Gtk.Stack();
		outputstack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

		outputstack.add_titled(htmlscrollbox,"result","result");
		outputstack.add_titled(refpane,"ref","ref");
		outputstack.add_titled(datscrollbox,"data","data");
		outputstack.margin_top = 10;
		outputstack.margin_end = 10;
		outputstack.margin_start = 10;
		outputstack.margin_bottom = 10;	

		outputstack.notify["visible_child"].connect(() => {
			if (outputstack.visible_child_name == "data") { allt[selectednode].orgmydat(); }
		});

		Gtk.StackSwitcher outputswish = new Gtk.StackSwitcher();
		outputswish.set_stack(outputstack);
		outputswish.margin_top = 0;
		outputswish.margin_end = 10;
		outputswish.margin_start = 10;
		outputswish.margin_bottom = 10;			

		Gtk.Box outputswishbox = new Gtk.Box(VERTICAL,0);
		outputswishbox.append(outputstack);
		outputswishbox.append(outputswish);

// toplevel ui

		vdiv = new Gtk.Paned(VERTICAL);
		vdiv.start_child = outputswishbox;
		vdiv.end_child = nodepane;
		vdiv.position = 360;
		vdiv.wide_handle = true;

		var fch = (Gtk.Widget) vdiv.get_start_child();
		var sep = (Gtk.Widget) fch.get_next_sibling();

// reflow node params when vdiv is moved, or selected, or whatever
// gesturedrag doesnt work with paned so have to use a catchall...

		vdiv.notify.connect(() => {
			int wx, wy = 0;
			this.get_default_size(out wx,out wy);
			if (vdiv.get_orientation() == VERTICAL) {
				foreach(ParserBox b in allt) { b.reflowparams(wx - 95); }
			} else {
				foreach(ParserBox b in allt) { b.reflowparams((wx - 95) - vdiv.position); }
			}
		});

// style

		Gtk.CssProvider htsp = new Gtk.CssProvider();
		string htss = ".xx { box-shadow: 2px 2px 2px #00000066; }";
		htsp.load_from_data(htss.data);
		htmloutput.get_style_context().add_provider(htsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		htmloutput.get_style_context().add_class("xx");

		Gtk.CssProvider pcsp = new Gtk.CssProvider();
		string pcss = ".wide { min-width: 20px; min-height: 20px; border-width: 4px; border-color: #202020; border-style: solid; background: repeating-linear-gradient( -45deg, #181818, #181818 4px, #202020 5px, #202020 9px);}";
		pcsp.load_from_data(pcss.data);
		sep.get_style_context().add_provider(pcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		sep.get_style_context().add_class("wide");

		Gtk.CssProvider pbsp = new Gtk.CssProvider();
		string pbcss = ".xx { background: #00000000; }";
		pbsp.load_from_data(pbcss.data);
		parserslist.get_style_context().add_provider(pbsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		parserslist.get_style_context().add_class("xx");

		Gtk.CssProvider ncsp = new Gtk.CssProvider();
		string nccss = ".xx { background: #00000000; }";
		ncsp.load_from_data(nccss.data);
		nodecontrolbox.get_style_context().add_provider(ncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		nodecontrolbox.get_style_context().add_class("xx");

		Gtk.CssProvider npsp = new Gtk.CssProvider();
		string npcss = ".xx { background: #00000080; }";
		npsp.load_from_data(npcss.data);
		nodepane.get_style_context().add_provider(npsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		nodepane.get_style_context().add_class("xx");

		Gtk.CssProvider ossp = new Gtk.CssProvider();
		string oscss = ".xx { background: #00000000; }";
		ossp.load_from_data(oscss.data);
		outputswish.get_style_context().add_provider(ossp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		outputswish.get_style_context().add_class("xx");

		Gtk.CssProvider obsp = new Gtk.CssProvider();
		string obcss = ".xx { background: #00000080; }";
		obsp.load_from_data(obcss.data);
		outputswishbox.get_style_context().add_provider(obsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		outputswishbox.get_style_context().add_class("xx");

		Gtk.CssProvider oksp = new Gtk.CssProvider();
		string okcss = ".xx { background: #00000000; }";
		oksp.load_from_data(okcss.data);
		outputstack.get_style_context().add_provider(oksp, Gtk.STYLE_PROVIDER_PRIORITY_USER);	
		outputstack.get_style_context().add_class("xx");


// dummy parsers

		ParserBox test = new ParserBox(0, "loader", 0, false, true, true, "", "", "", "text", "Load", "", "");
		allt = allt + test;
		ParserBox testb = new ParserBox(1, "pythonparser", 3, false, true, false, "", "", "", "html", "python", "", "");
		allt = allt + testb;
		ParserBox testc = new ParserBox(1, "rebolparser", 4, true, true, false, "", "", "", "html", "rebol", "", "");
		allt = allt + testc;

// fix ids, if they are out of order, as above
// this should be done whenever allt is changed

		int j = 0;
		foreach (ParserBox n in allt) {
			if (n.idx != j) { n.idx = j; }
			j = j + 1;
		}

		for (int i = 0; i < allt.length; i++) {
			parserslist.append(allt[i]);
		}
		
		this.set_child(vdiv);

				
		doup = true;

// window resizing
// this had to be done with a catchall, since there's no 'resize' signal (same as paned)

		this.notify.connect(() => {
			int wx, wy = 0;
			this.get_default_size(out wx,out wy);
			if (wx != winx || wy != winy) {
				print("this.notify: window size changed...\n");
				winx = wx; winy = wy;
				if ((wx < 720) && (wx < wy)) {
					if (vdiv.get_orientation() == HORIZONTAL) {
						vdiv.set_orientation(VERTICAL);
						vdiv.set_shrink_end_child(false);
						this.get_default_size(out wx,out wy);
						htmloutput.tab_width = 2;
						htmloutput.indent_width = 2;
						for (int i = 0; i < allt.length; i++) {
							allt[i].srctext.tab_width = 2;
							allt[i].srctext.indent_width = 2;
						}
						vdiv.position = (wy - 200);
					}
				} 
				if ((wx > 720) && (wx > wy)) {
					if (vdiv.get_orientation() == VERTICAL) {
						vdiv.set_orientation(HORIZONTAL);
						htmloutput.tab_width = 4;
						htmloutput.indent_width = 4;
						for (int i = 0; i < allt.length; i++) {
							allt[i].srctext.tab_width = 4;
							allt[i].srctext.indent_width = 4;
						}
						vdiv.position = (wx - 400);
					}
				}
				if (vdiv.get_orientation() == VERTICAL) {
					foreach(ParserBox b in allt) { b.reflowparams(wx - 95); }
				} else {
					foreach(ParserBox b in allt) { b.reflowparams((wx - 95) - vdiv.position); }
				}
			}	
		});
	}
}

// mainloop dresscode

int main (string[] args) {
	var app = new gifded();
	app.activate.connect (() => {
		var win = new qwin(app);
		win.present ();
	});
	return app.run (args);
}
