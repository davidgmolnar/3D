# 3D Log Analyzer


**3D Log Analyzer** is an application for analyzing measurement logs created by the 3D datalogger and its precursor 2D datalogger hardware, tailored for the BME Formula Racing Team. It provides a comprehensive suite of tools for importing, visualizing, and performing complex calculations on log data.



## Key features

* **Portable install**: No external SDKs or packages are required to run the application.
* **Log import**: Supports both 3D formatted binary logs and 2D formatted CSV logs.
* **Advanced charting**: The main chart allows for intuitive vertical (Y-axis) and horizontal (time) dragging and scaling.
* **Data markers**: Add absolute or delta markers to the chart to analyze specific data points, calculate derivatives, and find integrals between points.
* **Trace editor**: Easily select which signals to display, assign them to scaling groups, and choose custom colors.
* **Calculation engine**: Run custom calculation scripts (`.CAL` files) to add, remove, or edit signals using a wide range of mathematical and logical functions.
* **Chart grids**: Set up side-by-side views to compare signals from the same or different measurements, with shared markers and time duration.
* **Multiprocess design**: Functionally separate features open in their own responsive windows, ensuring a smooth experience on any resolution monitor.

## System requirements

The application has been tested and developed on the following Windows 10 22H2 configurations:

| Component | System 1 | System 2 |
| :--- | :--- | :--- |
| **OS** | Win 10 22H2 | Win 10 22H2 |
| **CPU** | Ryzen 7 5800H | i5 8300H |
| **RAM** | 16 GB RAM | 12 GB RAM |
| **Disk** | TEAM TM8FP6001T | WD10SPZX-24Z10 |


* **Memory (RAM)**: The application itself uses only about 100 MB of RAM. Additional memory is used to store the measurement data, so the amount of available RAM will influence the size and quantity of logs you can analyze simultaneously.
* **Disk**: A fast disk (like an SSD) will speed up the initial log import process, but other disk operations are too small to be noticeable.
* **OS**: The app is currently tested only on Windows, but a Linux build may be possible in the future.

## Intended workflow

1.  **Import a Log**: Use the **Import** button in the toolbar to load one or more log files (`.csv` or `.bin`). You can assign a custom alias to each measurement.
2.  **Select Signals**: Open the **Trace Editor** to choose which signals you want to visualize. Here, you can also assign colors and scaling groups. Signals in the same scaling group can be dragged and scaled together on the chart.
3.  **Analyze**: Interact with the **Main Chart** to zoom, pan, and add markers to inspect the data.
4.  **Perform Calculations**: Open the **Calculation** window to run `.CAL` script files on your measurements to generate new data channels or modify existing ones.
5.  **Create Custom Views**: For more complex analysis, use the **Custom Chart** options to set up Chart Grids or X-Y Characteristics views.

## Calculation engine

The application can execute calculation scripts (`.CAL` files) to perform complex operations on channel data. These files must be utf-8 encoded text files with a `.CAL` extension respecting the usual calfile syntax developed by 2D.

### Syntax rules

* Each instruction must be on a new line.
* Comments start with a `;` or `/` character.
* Operands that are channels must be prefixed with a `#`.
* Operands that do not start with a `#` are treated as constants or parameters.
* Scripts can be structured into blocks using `[Blockname]` syntax.

### Available functions

Below is a list of currently implemented calculation instructions.

#### Arithmetic and logical

* `/(#Channel1, #Channel2)`: Divides two channels or a channel and a constant.
* `*(#Channel1, #Channel2)`: Multiplies two channels or a channel and a constant.
* `Min(#Channel, Constant)`: Takes the sampling-wise minimum of two channels or a channel and a constant.
* `Max(#Channel, Constant)`: Takes the sampling-wise maximum of two channels or a channel and a constant.
* `And(#Channel1, #Channel2)`: Performs a bitwise AND operation.
* `Or(#Channel1, #Channel2)`: Performs a bitwise OR operation.
* `Nor(...)`: Performs a bitwise NOR operation.
* `Xnor(...)`: Performs a bitwise XNOR operation.
* `Not(#Channel)`: Performs a bitwise logical negation.
* `Mod(#Channel, Constant)`: Takes the modulo of a channel and a constant/channel.
* `Power(...)`: Takes the power of two channels.


#### Signal processing

* `Integrate(#Channel)`: Integrates a channel over time. The calculation for each point is: `PreviousValue + (Value1 + Value2) / 2 * (Timestamp2 - Timestamp1) / 1000`.
* `Shift(#Channel, Constant)`: Shifts a channel by a given time (in seconds) or number of samples.
* `Filter(FilterType, #Channel, FilterData)`: Runs a filter over a channel.
    * `FilterType`: `AVG`, `MIN`, or `MAX`.
    * `FilterData`: An integer window size or a duration (e.g., `0.5sec`).
* `RCLP(#Channel, CrossFrequency)`: Applies a digital lowpass filter.

#### Conditionals

* `IfExists(#Channel)`: If the specified channel does not exist, the script skips all remaining instructions in the current block.
* `If(Condition, TrueResult, FalseResult)`: A sampling-wise conditional function to create a new output channel.
* `Delete(#Channel)`: Removes a channel from memory (not from the original log file).
* `FillFromBool(#Channel, #EnableChannel)`: Returns a subset of an input channel where an "enable" channel is greater than 0.

#### Trigonometric

* `Sin(#Channel)`
* `Cos(#Channel)`
* `Tan(#Channel)`
* `Arcsin(#Channel)`
* `Arccos(#Channel)`
* `Arctan(#Channel)`
* `Arctan2(#Channel1, #Channel2)`

#### Misc

* `Limit(#Channel, LowerLimit, UpperLimit)`: Clamps a channel's values to the given limits.
* `Word(#Channel, ADC_MIN, ADC_MAX)`: Clamps a channel to fit `[ADC_MIN, ADC_MAX]` and remaps it to `[0, 65535]`.
* `Const(Value, Rate)`: Creates a constant value channel with a specified sampling rate in Hz. Use of this is discouraged as other instructions can handle constants directly

## Changelog

### **v0.1.4** - 2024.08.23
* **Main window**:
    * Implemented min, max, delta marker types.
    * All markers now show their timestamp in the marker box. If the marker is a delta marker it also shows the time difference from its pair.
    * Marker box widths can now be adjusted.
    * Bottom overview signals can now be selected.
    * Implemented a preset system for the main chart.
    * Marker box height is now dynamic.
    * In XY plot mode, X channel related displays are no longer time formatted.
    * The bottom overview was removed in XY plot mode.
    * Moving/Zooming into the negative X-axis was re-enabled in XY plot mode.
* **General**:
    * IPC is regained on error.

### **v0.1.2** - 2024.08.11
* **Main window**:
    * Added a dedicated lap marker for visual clarity. Using normal markers to set lap markers is no longer possible.
    * You can place temporary lap markers using double click over the chart area, and activate them using the Laptime Editor.
    * Implemented a separate Laptime Editor window.

### **v0.1.1** - 2024.07.28
* **Main window**:
    * The top marker bar will now default to show the marker functions.
* **Calculation**:
    * Fixed an issue where a signal’s integral, and the integrated channel’s maximum will now correctly be equal.
* **Statistics View**:
    * Laptimes can be selected in the main window, and in the statistics window stats can now be run on only the duration of certain laps.
    * Completed a preset save/load system.

### **v0.1.0** - 2024.06.30
* **General**:
    * The app's log file at `Logs/3D.log` will be erased on startup. The contents of this log will only refer to the last session.
    * Theme can be changed to bright by setting a value in `settings.json`.
* **Main window**:
    * Vertical drag over the chart area is an alternative to mouse wheel zooming in time.
    * Horizontal drag over the chart scaler area is an alternative to mouse wheel scaling of y axis.

### **v0.0.4** - 2024.05.26
* **Main window**:
    * Added a dialog to set up custom charts.
* **Custom chart views**:
    * Added chart grids, with shown duration and marker sharing.
* **Trace Editor window**:
    * Added a color picker to each channel.
* **Calculation**:
    * A script not opening a block can now be run.

### **v0.0.3** - 2024.04.28
* **Main window**:
    * Chart rescaling is now using SIMD operations, and is therefore more performant on large datasets.
* **Calculation**:
    * Added IF, SHIFT, FILLFROMBOOL, POWER, MOD, SET, F, SQRT, SIN, COS, TAN, ARCSIN, ARCCOS, ARCTAN, ARCTAN2, WORD, CONST, LIMIT and RCLP calculation operations.

### **v0.0.2** - 2024.03.23
* **General**:
    * Fixed issue #3, The communication between processes was made more robust.
    * The memory usage of imported logs was reduced.

### **v0.0.1** - 2024.02.24
* **Initial Release**
    * Multiprocess design with functionally separate features opening a separate windows.
    * Portable install.
    * Main chart with vertical(y) and horizontal(t) drag and scale.
    * Markers with limited marker functions.
    * 3D formatted binary log import.
    * 2D formatted csv log import.
    * A way to select signals in a measurement to show in the main window.
    * A way to compile and run calfiles on the previously imported measurement.
    * Previously compiled calfiles are cached locally until the original file is modified.
    * A way to add/remove/edit locally stored parameters.

## Credits

* **Author**: Dávid Gergely Molnár
* **Organization**: BME Formula Racing Team
* **2D datalogger**: 2D is a product of [2D-Datarecording](https://2d-datarecording.com/)