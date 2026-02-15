#this script convert hex file to binary file
# -*- coding: utf-8 -*-
import sys

def hex_to_binary_32bit(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            hex_value = line.strip()

           #clean of 0x if exist
            if hex_value.startswith("0x"):
                hex_value = hex_value[2:]
           
            if hex_value == '0':
                hex_value = '00000000'

           #bin convertor and 0 fill to 32 bit
            binary_value = bin(int(hex_value, 16))[2:].zfill(32)

            outfile.write(binary_value + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python hex2bin_convertor.py <input_file.hex> <output_file.mem>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    hex_to_binary_32bit(input_file, output_file)
    print(f"Conversion complete! Binary data saved to '{output_file}'")

