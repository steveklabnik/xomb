// This implements a console (text-mode) VGA driver.

module kernel.dev.console;

// Import system info
import kernel.system.info;

import architecture.cpu;

// This contains the hexidecimal values for various colors for printing to the screen.
enum Color : ubyte {
	Black		  = 0x00,
	Blue		  = 0x01,
	Green	      = 0x02,
	Cyan		  = 0x03,
	Red           = 0x04,
	Magenta       = 0x05,
	Yellow        = 0x06,
	LightGray     = 0x07,
	Gray          = 0x08,
	LightBlue     = 0x09,
	LightGreen    = 0x0A,
	LightCyan     = 0x0B,
	LightRed      = 0x0C,
	LightMagenta  = 0x0D,
	LightYellow   = 0x0E,
	White         = 0x0F
}

// This is the true interface to the console
struct Console {
static:
public:

	// The number of columns and lines on the screen.
	const uint COLUMNS = 80;
	const uint LINES = 25;

	// The default color.
	const ubyte DEFAULTCOLORS = Color.LightGray;

	// The cursor position
	private int xpos = 0;
	private int ypos = 0;

	// The current color
	private ubyte colorAttribute = DEFAULTCOLORS;

	// The width of a tab
	const auto TABSTOP = 4;

	// This will init the console driver
	void initialize() {
		videoMemoryLocation = cast(ubyte*)0xB8000;
		videoMemoryLocation += cast(ulong)System.kernel.virtualStart;

		uint temp = LINES * COLUMNS;
		temp++;

		Cpu.ioOut!(ushort, "0x3D4")(14);
		Cpu.ioOut!(ushort, "0x3D5")(temp >> 8);
		Cpu.ioOut!(ushort, "0x3D4")(15);
		Cpu.ioOut!(ushort, "0x3D5")(temp);
	}

	// This method will clear the screen and return the cursor to (0,0).
	void clearScreen() {
		int i;

		for (i=0; i < COLUMNS * LINES * 2; i++) {
			*(videoMemoryLocation + i) = 0;
		}

		xpos = 0;
		ypos = 0;
	}

	// This method will return the current location of the cursor
	void getPosition(out int x, out int y) {
		x = xpos;
		y = ypos;
	}

	// This method will set the current location of the cursor to the x and y given.
	void setPosition(int x, int y) {
		if (x < 0) { x = 0; }
		if (y < 0) { y = 0; }
		if (x >= COLUMNS) { x = COLUMNS - 1; }
		if (y >= LINES) { y = LINES - 1; }

		xpos = x;
		ypos = y;
	}

	// This method will post the character to the screen at the current location.
	void putChar(char c) {
		if (c == '\t') {
			// Insert a tab.
			xpos += TABSTOP;
		}
		else if (c != '\n' && c != '\r') {
			ubyte* videoAddress = videoMemoryLocation;
			videoAddress += (xpos + (ypos * COLUMNS)) * 2;

			// Set the current piece of video memory to the character to print.
			*(videoAddress) = c & 0xFF;
			*(videoAddress + 1) = colorAttribute;

			// increase the cursor position
			xpos++;
		}

		// if you have reached the end of the line, or printing a newline, increase the y position
		if (c == '\n' || c == '\r' || xpos >= COLUMNS) {
			xpos = 0;
			ypos++;

			if (ypos >= LINES) {
				scrollDisplay(1);
			}
		}
	}

	// This mehtod will post a string to the screen at the current location.
	void putString(char[] s) {
		foreach(c; s) {
			putChar(c);
		}
	}

	// This function sets the console colors back to their defaults.
	void resetColors() {
		colorAttribute = DEFAULTCOLORS;
	}

	// This function will set the text foreground to a new color.
	void setForeColor(Color newColor) {
		colorAttribute = (colorAttribute & 0xf0) | newColor;
	}

	// This function will set the text background to a new color.
	void setBackColor(Color newColor) {
		colorAttribute = (colorAttribute & 0x0f) | (newColor << 4);
	}

	// This function will set both the foreground and background colors.
	void setColors(Color foreColor, Color backColor) {
		colorAttribute = (foreColor & 0x0f) | (backColor << 4);
	}

	// This function will scroll the entire screen.
	void scrollDisplay(uint numLines) {
		// obviously, scrolling all lines results in a cleared display. Use the faster function.
		if (numLines >= LINES) {
			clearScreen();
			return;
		}

		int cury = 0;
		int offset1 = 0;
		int offset2 = numLines * COLUMNS;

		// Go through and shift the correct amount.
		for ( ; cury <= LINES - numLines; cury++) {
			for (int curx = 0; curx < COLUMNS; curx++) {
				*(videoMemoryLocation + (curx + offset1) * 2) = *(videoMemoryLocation + (curx + offset1 + offset2) * 2);
				*(videoMemoryLocation + (curx + offset1) * 2 + 1) = *(videoMemoryLocation + (curx + offset1 + offset2) * 2 + 1);
			}

			offset1 += COLUMNS;
		}

		// clear the remaining lines
		for (; cury <= LINES; cury++) {
			for (int curx = 0; curx < COLUMNS; curx++) {
				*(videoMemoryLocation + (curx + offset1) * 2) = 0x00;
				*(videoMemoryLocation + (curx + offset1) * 2 + 1) = 0x00;
			}
		}

		ypos -= numLines;

		if (ypos < 0) {
			ypos = 0;
		}
	}

	void* physicalLocation() {
		return videoMemoryPhysLocation;
	}

	uint width() {
		return COLUMNS;
	}

	uint height() {
		return LINES;
	}

private:

	// Where the video memory lives (can be changed)
	ubyte* videoMemoryLocation = cast(ubyte*)0xB8000UL;
	const ubyte* videoMemoryPhysLocation = cast(ubyte*)0xB8000UL;
}
