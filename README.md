# OLS Logic Analyzer
You can find more information [here](https://sigrok.org/wiki/Openbench_Logic_Sniffer)

## Convert the FPGA to a Logic Analyzer
- Clone the repository
- Open the project with the VHDPlus IDE
- Compile the code (you can change the development board and pins with that the inputs are connected)
- Program the FPGA (select Extras/Long-Term Programming to save the program on the FPGA)

## Use the logic analyzer
- Download PulseView [here](https://sigrok.org/wiki/Downloads)
- Install the program
- Go to the device selection and select Openbench Logic Sniffer & SUMP compatibles (ols)
- Select the COM port of the FPGA Board, search for the device and select the logic analyzer
- Try out the functions of the program and start the logic analyzer in the upper left corner
- You should set the sample number to 10k or less and the sample rate to 100MHz or less (keep in mind that the sampling time increases with a smaller sample rate)
- Make sure to zoom in, so you can see the measurement
