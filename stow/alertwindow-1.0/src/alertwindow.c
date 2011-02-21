/*
 * This stolen from http://en.literateprograms.org/Special:Downloadcode/Hello_World_(C,_Xlib)
 * I made a simple change to support taking messages to display from the command line
 */
#include <X11/Xlib.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  Display *dpy;
  Window rootwin;
  Window win;
  Colormap cmap;
  XEvent e;
  int scr;
  GC gc;

  if(argc < 2) {
    fprintf(stderr, "ERROR: must provide a message to display\n");
    exit(1);
  }
  
  
  if(!(dpy=XOpenDisplay(NULL))) {
    fprintf(stderr, "ERROR: could not open display\n");
    exit(1);
  }
  
  
  scr = DefaultScreen(dpy);
  rootwin = RootWindow(dpy, scr);
  cmap = DefaultColormap(dpy, scr);
  
  
  win=XCreateSimpleWindow(dpy, rootwin, 1, 1, 400, 70, 0, 
                          BlackPixel(dpy, scr), BlackPixel(dpy, scr));
  
  
  XStoreName(dpy, win, "Alert!");
  
  gc=XCreateGC(dpy, win, 0, NULL);
  XSetForeground(dpy, gc, WhitePixel(dpy, scr));
  
  XSelectInput(dpy, win, ExposureMask|ButtonPressMask);
   
  XMapWindow(dpy, win);
  
  while(1) {
    XNextEvent(dpy, &e);
    if(e.type==Expose && e.xexpose.count<1)
      XDrawString(dpy, win, gc, 10, 10, argv[1], strlen(argv[1]));
    else if(e.type==ButtonPress) break;
  }
  
  
  XCloseDisplay(dpy);
  
  return 0;
}
