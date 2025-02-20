# Copyright 2022 Intel Corporation
# SPDX-License-Identifier: MIT

# TCL File Generated by Component Editor 12.1
# Wed Jun 13 15:44:31 PDT 2012
# DO NOT MODIFY


# 
# irq_ctrl "IRQ CONTROLER" v1.0
# null 2012.06.13.15:44:31
# 
# 

# 
# request TCL package from ACDS 12.1
# 
package require -exact qsys 12.1


# 
# module irq_ctrl
# 
set_module_property NAME irq_ctrl
set_module_property GROUP "Stratix10 BSP Components"
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property DISPLAY_NAME "IRQ CTRL"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL irq_ctrl
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file irq_ctrl.v VERILOG PATH irq_ctrl.v
add_fileset_file irq_ena.v VERILOG PATH irq_ena.v
add_fileset_file irq_bridge.v VERILOG PATH irq_bridge.v

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL irq_ctrl
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file irq_ctrl.v VERILOG PATH irq_ctrl.v
add_fileset_file irq_ena.v VERILOG PATH irq_ena.v
add_fileset_file irq_bridge.v VERILOG PATH irq_bridge.v

# 
# parameters
# 


# 
# display items
# 


# 
# connection point IRQ Bridge Port
# 
add_interface IRQ_Read_Slave avalon end
set_interface_property IRQ_Read_Slave addressUnits WORDS
set_interface_property IRQ_Read_Slave associatedClock Clock
set_interface_property IRQ_Read_Slave associatedReset Resetn
set_interface_property IRQ_Read_Slave burstOnBurstBoundariesOnly false
set_interface_property IRQ_Read_Slave burstcountUnits WORDS
set_interface_property IRQ_Read_Slave explicitAddressSpan 0
set_interface_property IRQ_Read_Slave holdTime 0
set_interface_property IRQ_Read_Slave isMemoryDevice false
set_interface_property IRQ_Read_Slave isNonVolatileStorage false
set_interface_property IRQ_Read_Slave linewrapBursts false
set_interface_property IRQ_Read_Slave maximumPendingReadTransactions 0
set_interface_property IRQ_Read_Slave printableDevice false
set_interface_property IRQ_Read_Slave readLatency 0
set_interface_property IRQ_Read_Slave readWaitTime 1
set_interface_property IRQ_Read_Slave setupTime 0
set_interface_property IRQ_Read_Slave timingUnits Cycles
set_interface_property IRQ_Read_Slave writeWaitTime 0
set_interface_property IRQ_Read_Slave ENABLED true

add_interface_port IRQ_Read_Slave IrqRead_i read Input 1
add_interface_port IRQ_Read_Slave IrqReadData_o readdata Output 32

# 
# connection point IRQ Mask Ports
# 
add_interface IRQ_Mask_Slave avalon end
set_interface_property IRQ_Mask_Slave addressUnits WORDS
set_interface_property IRQ_Mask_Slave associatedClock Clock
set_interface_property IRQ_Mask_Slave associatedReset Resetn
set_interface_property IRQ_Mask_Slave burstOnBurstBoundariesOnly false
set_interface_property IRQ_Mask_Slave burstcountUnits WORDS
set_interface_property IRQ_Mask_Slave explicitAddressSpan 0
set_interface_property IRQ_Mask_Slave holdTime 0
set_interface_property IRQ_Mask_Slave isMemoryDevice false
set_interface_property IRQ_Mask_Slave isNonVolatileStorage false
set_interface_property IRQ_Mask_Slave linewrapBursts false
set_interface_property IRQ_Mask_Slave maximumPendingReadTransactions 0
set_interface_property IRQ_Mask_Slave printableDevice false
set_interface_property IRQ_Mask_Slave readLatency 0
set_interface_property IRQ_Mask_Slave readWaitTime 1
set_interface_property IRQ_Mask_Slave setupTime 0
set_interface_property IRQ_Mask_Slave timingUnits Cycles
set_interface_property IRQ_Mask_Slave writeWaitTime 0
set_interface_property IRQ_Mask_Slave ENABLED true

add_interface_port IRQ_Mask_Slave MaskWrite_i write Input 1
add_interface_port IRQ_Mask_Slave MaskWritedata_i writedata Input 32
add_interface_port IRQ_Mask_Slave MaskByteenable_i byteenable Input 4
add_interface_port IRQ_Mask_Slave MaskRead_i read Input 1
add_interface_port IRQ_Mask_Slave MaskReaddata_o readdata Output 32
add_interface_port IRQ_Mask_Slave MaskWaitrequest_o waitrequest Output 1


# 
# connection point Clock
# 
add_interface Clock clock end
set_interface_property Clock clockRate 0
set_interface_property Clock ENABLED true

add_interface_port Clock Clk_i clk Input 1


# 
# connection point Resetn
# 
add_interface Resetn reset end
set_interface_property Resetn associatedClock Clock
set_interface_property Resetn synchronousEdges DEASSERT
set_interface_property Resetn ENABLED true

add_interface_port Resetn Rstn_i reset_n Input 1


# 
# connection point interrupt_receiver
# 
add_interface interrupt_receiver interrupt start
set_interface_property interrupt_receiver associatedClock Clock
set_interface_property interrupt_receiver associatedReset Resetn
set_interface_property interrupt_receiver irqScheme INDIVIDUAL_REQUESTS
set_interface_property interrupt_receiver ENABLED true

add_interface_port interrupt_receiver Irq_i irq Input 32

# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedClock Clock
set_interface_property interrupt_sender associatedReset Resetn
set_interface_property interrupt_sender ENABLED true

add_interface_port interrupt_sender Irq_o irq Output 1
