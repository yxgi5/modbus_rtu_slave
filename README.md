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

## legal fuction code 03 | 06 return response frame
### function code 03 recive handling
### function code 03 trasnfer handling