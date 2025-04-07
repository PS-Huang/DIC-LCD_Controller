# Digital IC Design-LCD Controller
This is the second homework for DIC course.

## Introduction
The task requires completing the Image Display Control Circuit (LCD_CTRL 
circuit). The input grayscale image is stored in the input image ROM module 
(IROM) on the Host side. The LCD_CTRL circuit must read grayscale image 
data from the IROM memory module on the Host side and perform the following 
operations as required:  

I. Shift – Horizontal and vertical translation  
II. Max – Retrieve the maximum value of the image data  
III. Min – Retrieve the minimum value of the image data  
IV. Average – Compute the average of the image data  

After processing, the results must be written to the output image RAM module 
(IRAM) on the Host side. Once the entire image processing is complete, the done 
signal should be set High, and the system will then verify the correctness of the 
processed image data. The circuit signal definitions and LCD_CTRL operation 
methods are detailed in the following sections.

## Specification

### System I/O Interface

| Signal Name | I/O   | Width | Description |
|-------------|-------|-------|-------------|
| clk         | Input | 1     | System clock signal. System should be triggered by the positive edge of clock. |
| rst         | Input | 1     | System reset signal. Active high, asynchronous reset. |
| cmd         | Input | 4     | Command input signal. This controller supports a total of eight command inputs. A command input is considered valid only when "cmd_valid" is high and "busy" is low. |
| cmd_valid   | Input | 1     | When this signal is high, it indicates the "cmd" input is valid. |
| IROM_rd     | Output| 1     | Image ROM memory read enable signal. When high, indicates the LCD_CTRL requests data from the Host. |
| IROM_A      | Output| 6     | Image ROM address bus. The LCD_CTRL uses this bus to request grayscale image data from the corresponding address in the Host's ROM. |
| IROM_Q      | Input | 8     | Image ROM data bus. Host uses this bus to send grayscale image data from ROM to LCD_CTRL. |
| IRAM_ceb    | Output| 1     | Image RAM chip enable signal. When high, indicates the Image RAM is available for read/write. |
| IRAM_A      | Output| 6     | Image RAM address bus. Specifies the address in the Host's IRAM for read/write. |
| IRAM_D      | Output| 8     | Image RAM input data bus. Used to write data into the Host's IRAM. |
| IRAM_web    | Output| 1     | Image RAM read/write select signal. High = read from IRAM; Low = write to IRAM. |
| IRAM_Q      | Input | 8     | Image RAM output data bus. Used by Host to send image data from IRAM to LCD_CTRL. |
| busy        | Output| 1     | System busy signal. High = controller is executing and cannot accept new commands. Low = ready for new commands. |
| done        | Output| 1     | Set high when the controller completes writing to IRAM to indicate completion. |

### Function Description
The controller must process user input commands to determine the display coordinates (origin) and data parameters, enabling functions such as shifting and averaging. The original 8*8 grayscale image is stored in the off-chip IROM, the LCD controller can fetch the image from IROM through related buses. Once the image processing operations are completed, the processed image data is written to the off-chip IRAM through related buses and pull done signal high to let Host know the task is completed. 

![image](https://github.com/user-attachments/assets/2bee0756-22cc-4ae2-ab64-62a553b82271)

### Command Description

| Command | Definition |
|---------|------------|
| 0 (0000) | **Write**: Write the processed image data to IRAM from left to right and top to bottom. |
| 1 (0001) | **Shift Up**: Decrease the Y-coordinate of the operating point by 1 (min = 2). No change if already at Y = 2. |
| 2 (0010) | **Shift Down**: Increase the Y-coordinate of the operating point by 1 (max = 6). No change if already at Y = 6. |
| 3 (0011) | **Shift Left**: Decrease the X-coordinate of the operating point by 1 (min = 2). No change if already at X = 2. |
| 4 (0100) | **Shift Right**: Increase the X-coordinate of the operating point by 1 (max = 6). No change if already at X = 6. |
| 5 (0101) | **Max**: Replace the 4×4 pixels around the current operating point with the maximum value among them. |
| 6 (0110) | **Min**: Replace the 4×4 pixels around the current operating point with the minimum value among them. |
| 7 (0111) | **Average**: Replace the 4×4 pixels around the current operating point with the average value among them. |

### Timing Specification

* When `IROM_rd` is high (e.g. T1 and T2 time periods), the IROM will immediately send the data from the address specified by the `IROM_A` signal to the LCD_CTRL via the `IROM_Q` bus.
* When `IROM_rd` is low (e.g. T3 time periods), the IROM will not perform any action. In addition, no read delay is considered for this memory.

![image](https://github.com/user-attachments/assets/d68eaadd-905d-4e4a-ac35-fb500eeaddb8)

* When `IRAM_ceb` is high (e.g. T4 time periods), the IRAM will determine the operation based on the `IRAM_web` signal.
* The Host will trigger the read/write operation **on the falling edge** of the clock signal at T5 and stop when `IRAM_ceb` be pulled down at T6.

![image](https://github.com/user-attachments/assets/35326334-e340-4bd4-9388-8615e6191548)

* During any processing operation, the `busy` signal remains high to indicate that the controller is actively executing a command and cannot accept new inputs. Once the operation is completed, `busy` is deasserted (set low), signaling that the controller is ready to receive the next command. 
  
![image](https://github.com/user-attachments/assets/d6d00597-7d43-41ed-a355-a14f4179cb9d)

* When `IRAM_ceb` is high and `IRAM_web` is low, it indicates a write operation to IRAM. At this moment, the address signal can be provided to store the image data into IRAM.
* After the write operation is completed, the `done` signal is set to high at T7, indicating that the write process is finished. At this point, the test fixture will compare the data written to IRAM with the golden pattern for verification.

![image](https://github.com/user-attachments/assets/eb445847-d6a5-4a5f-abaf-ede7b1a2e0cd)

