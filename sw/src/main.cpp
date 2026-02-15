
#include <cstddef>
#include <cstdint>

// MMIO read/write macros
#define READ_FROM_ADDRESS(addr) (*(volatile uint32_t*)(addr))
#define WRITE_TO_ADDRESS(addr, value) (*(volatile uint32_t*)(addr) = (value))

// Maximum number of reads to store
#define MAX_READS 256

int main(void);

int main() {
  const uint32_t riscv_select_addr  = 0x80F1000c;  //riscv_mem_wr\done address
  const uint32_t riscv_wr_addr      = 0x80F10008;  //riscv_select address      
  const uint32_t res_addr     = 0x80F10014;  //riscv_status address
  const uint32_t data_addr    = 0x80001000;  // MMIO data address
  const uint32_t poll_addr    = 0x80000040;  // Polling address
  const uint32_t scratch_addr    = 0x80F00010;  // scratch address
  //Prefixes 
  const uint32_t P            = 0x80000000;   
  const uint32_t P_EOM        = 0xa0000000; 
  const uint32_t NP           = 0xc0000000;
  const uint32_t NP_EOM       = 0xe0000000;
  //write transaction  
  const uint32_t data_value0  = 0x0000aabb;   
  const uint32_t data_value1  = 0x0301aabb;   
  const uint32_t data_value2  = 0xa0c000ff;   
  const uint32_t data_value3  = 0xa6ffba78;   
  const uint32_t data_value4  = 0xb0325680; 
  //read transaction 
  const uint32_t data_value_1  = 0x0300aabb;
  //read complition
  const uint32_t data_value_c0  = 0x0000bbaa;
  const uint32_t data_value_c1  = 0x0321bbaa;
  
  uint32_t res           = 0;
  uint32_t is_equal      = 0;  
  uint32_t read_data_array[MAX_READS];       // Storage for multiple read values

  //Write a value to the data address (write transaction)
  WRITE_TO_ADDRESS(data_addr, data_value0);
  WRITE_TO_ADDRESS(data_addr+4, P);
  WRITE_TO_ADDRESS(data_addr, data_value1);
  WRITE_TO_ADDRESS(data_addr+4, P);
  WRITE_TO_ADDRESS(data_addr, data_value2);
  WRITE_TO_ADDRESS(data_addr+4, P);
  WRITE_TO_ADDRESS(data_addr, data_value3);
  WRITE_TO_ADDRESS(data_addr+4, P);
  WRITE_TO_ADDRESS(data_addr, data_value4);
  WRITE_TO_ADDRESS(data_addr+4, P_EOM);
  //Write a value to the data address (write transaction)
  WRITE_TO_ADDRESS(data_addr, data_value0);
  WRITE_TO_ADDRESS(data_addr+4, NP);
  WRITE_TO_ADDRESS(data_addr, data_value_1);
  WRITE_TO_ADDRESS(data_addr+4, NP);
  WRITE_TO_ADDRESS(data_addr, data_value2);
  WRITE_TO_ADDRESS(data_addr+4, NP_EOM);


  //Wait for polling register to become non-zero
  uint32_t poll_value = 0;
  while ((poll_value = READ_FROM_ADDRESS(poll_addr)) == 0) {
    // Do nothing (polling)
  }

  //Clamp poll_value to MAX_READS to avoid overflow
  if (poll_value > MAX_READS)
    poll_value = MAX_READS;

  //Perform poll_value number of reads from data_addr
  for (uint32_t i = 0; i < poll_value; i++) {
    read_data_array[i] = READ_FROM_ADDRESS(data_addr);
  }

  if(is_equal) res = 0x80000003;
  else res = 0x80000000;
  
  WRITE_TO_ADDRESS(res_addr, res);

  // Infinite loop to stay alive
  while (1) {
    ; // do nothing
  }

  return 0;
}
