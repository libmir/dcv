module dcv.example.video.app;

/** 
 * Video i/o example using dcv library.
 */

import dcv.example.video.gui;

import std.stdio;

import gtk.Main;


void main(string [] args) {

	// set default video if invalid argument set is given.
	if (args.length != 2) {
		args = [args[0], "../data/centaur_1.mpg"];
	}

	Main.init(args);

	VideoPlayer player = new VideoPlayer(args);
	player.show();

	Main.run();
}
