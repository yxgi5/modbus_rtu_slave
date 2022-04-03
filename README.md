# Modbus RTU Slave
design a ip implements Modbus RTU slave sub function 03 04 06

## uart tx and uart rx
done

## rx 3.5T and 1.5T interval detect
done

## rx slave address and frame check
done

## checksum if slave address check pass
done

## Exception handling
### checksum mismatch then do nothing
### illegal fuction code retrun 01
### illegal address return 02
### illegal quantity return 03

done

# read response frame
## rs485 tx en signal (before tx 1T enable, after tx 1T disable)
done
## tx crc
done

# fuction code 06
## write fail return 04
## write ok response frame
done

# read / write func logic
done

# top wrapper
todo

# wave
## func_code 03
![](pic/rx_03_normal.jpg)
assign code 03 reg 0001 value 0451
![](pic/repsonse_03_normal.jpg)
response is ok

## illegal exception response
![](pic/illigal_reg.jpg)
here 06 dosen't have reg 0002, so it's illegal
![](pic/illigal_reg_response.jpg)
response is ok

## func_code 04
![](pic/rx_04_normal.jpg)
read 4 regs from 0001
![](pic/repsonse_04_normal.jpg)
response is ok

## write fail exception
![](pic/write_failed.jpg)
after a write fail
![](pic/write_failed_response.jpg)
response is ok

## write ok response
![](pic/write_ok.jpg)
![](pic/write_ok_response.jpg)
response is ok

