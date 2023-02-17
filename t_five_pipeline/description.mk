# Name: description.mk
# Author: Lucas Schneider
# 07/2020

# Name of all components in priority order
CPNT_LIST := txt_util alu alu_control mux4x1 mux2x1 mux2x1_1b reg reg_file sign_ext control ram rom fetch decode execute_alu execute_mem1 execute_mem2 execute fu_id_sel reg_status rs_encode rs rs_reg issue commit t_five_pipeline

# Name of the component to be tested
CPNT ?= t_five_pipeline

# Commands to prepare test files
PREPARE_TEST :=
