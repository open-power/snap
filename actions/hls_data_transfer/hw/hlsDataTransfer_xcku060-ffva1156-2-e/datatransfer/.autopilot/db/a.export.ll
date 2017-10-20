; ModuleID = '/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/actions/hls_data_transfer/hw/hlsDataTransfer_xcku060-ffva1156-2-e/datatransfer/.autopilot/db/a.o.2.bc'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@llvm_global_ctors_1 = appending global [1 x void ()*] [void ()* @_GLOBAL__I_a]
@llvm_global_ctors_0 = appending global [1 x i32] [i32 65535]
@hls_action_str = internal unnamed_addr constant [11 x i8] c"hls_action\00"
@p_str9 = private unnamed_addr constant [6 x i8] c"0x100\00", align 1
@p_str8 = private unnamed_addr constant [6 x i8] c"0x010\00", align 1
@p_str7 = private unnamed_addr constant [6 x i8] c"0x040\00", align 1
@p_str6 = private unnamed_addr constant [6 x i8] c"0x030\00", align 1
@p_str5 = private unnamed_addr constant [9 x i8] c"ctrl_reg\00", align 1
@p_str4 = private unnamed_addr constant [10 x i8] c"s_axilite\00", align 1
@p_str3 = private unnamed_addr constant [6 x i8] c"slave\00", align 1
@p_str2 = private unnamed_addr constant [9 x i8] c"host_mem\00", align 1
@p_str1 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@p_str = private unnamed_addr constant [6 x i8] c"m_axi\00", align 1

define internal fastcc i9 @process_action(i512* %din_gmem_V, i58 %din_gmem_V1, i58 %dout_gmem_V3, i64 %act_reg_Data_in_addr, i32 %act_reg_Data_in_size, i64 %act_reg_Data_out_add) {
  %act_reg_Data_out_add_1 = call i64 @_ssdm_op_Read.ap_auto.i64(i64 %act_reg_Data_out_add)
  %act_reg_Data_in_size_1 = call i32 @_ssdm_op_Read.ap_auto.i32(i32 %act_reg_Data_in_size)
  %act_reg_Data_in_addr_1 = call i64 @_ssdm_op_Read.ap_auto.i64(i64 %act_reg_Data_in_addr)
  %dout_gmem_V3_read = call i58 @_ssdm_op_Read.ap_auto.i58(i58 %dout_gmem_V3)
  %din_gmem_V1_read = call i58 @_ssdm_op_Read.ap_auto.i58(i58 %din_gmem_V1)
  call void (...)* @_ssdm_op_SpecInterface(i512* %din_gmem_V, [6 x i8]* @p_str, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 512, [9 x i8]* @p_str2, [6 x i8]* @p_str3, [1 x i8]* @p_str1, i32 16, i32 16, i32 64, i32 64, [1 x i8]* @p_str1, [1 x i8]* @p_str1)
  call void (...)* @_ssdm_op_SpecInterface(i512* %din_gmem_V, [6 x i8]* @p_str, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 512, [9 x i8]* @p_str2, [6 x i8]* @p_str3, [1 x i8]* @p_str1, i32 16, i32 16, i32 64, i32 64, [1 x i8]* @p_str1, [1 x i8]* @p_str1)
  %tmp = call i58 @_ssdm_op_PartSelect.i58.i64.i32.i32(i64 %act_reg_Data_in_addr_1, i32 6, i32 63)
  %i_idx_1_cast = zext i58 %tmp to i59
  %tmp_3 = call i58 @_ssdm_op_PartSelect.i58.i64.i32.i32(i64 %act_reg_Data_out_add_1, i32 6, i32 63)
  %o_idx_1_cast = zext i58 %tmp_3 to i59
  %tmp_4 = call i28 @_ssdm_op_PartSelect.i28.i32.i32.i32(i32 %act_reg_Data_in_size_1, i32 4, i32 31)
  %icmp = icmp eq i28 %tmp_4, 0
  br i1 %icmp, label %2, label %1

; <label>:1                                       ; preds = %0
  %din_gmem_V1_cast = zext i58 %din_gmem_V1_read to i59
  %sum = add i59 %din_gmem_V1_cast, %i_idx_1_cast
  %sum_cast = zext i59 %sum to i64
  %dout_gmem_V_addr = getelementptr i512* %din_gmem_V, i64 %sum_cast
  %buffer_in_V_req = call i1 @_ssdm_op_ReadReq.m_axi.i512P(i512* %dout_gmem_V_addr, i32 1)
  %buffer_in_V = call i512 @_ssdm_op_Read.m_axi.i512P(i512* %dout_gmem_V_addr)
  %tmp_beta = call i64 @_ssdm_op_PartSelect.i64.i512.i32.i32(i512 %buffer_in_V, i32 128, i32 191)
  %tmp_gamma = call i64 @_ssdm_op_PartSelect.i64.i512.i32.i32(i512 %buffer_in_V, i32 192, i32 255)
  %tmp_theta = call i64 @_ssdm_op_PartSelect.i64.i512.i32.i32(i512 %buffer_in_V, i32 256, i32 319)
  %beta = bitcast i64 %tmp_beta to double
  %gamma = bitcast i64 %tmp_gamma to double
  %theta = bitcast i64 %tmp_theta to double
  %tmp_1 = fmul double %beta, %gamma
  %product = fmul double %tmp_1, %theta
  %val_assign = bitcast double %product to i64
  %tmp_2 = call i192 @_ssdm_op_PartSelect.i192.i512.i32.i32(i512 %buffer_in_V, i32 128, i32 319)
  %tmp_i = call i320 @_ssdm_op_BitConcatenate.i320.i192.i64.i64(i192 %tmp_2, i64 1, i64 %val_assign)
  %p_Result_s = zext i320 %tmp_i to i512
  %dout_gmem_V3_cast = zext i58 %dout_gmem_V3_read to i59
  %sum3 = add i59 %dout_gmem_V3_cast, %o_idx_1_cast
  %sum3_cast = zext i59 %sum3 to i64
  %dout_gmem_V_addr_1 = getelementptr i512* %din_gmem_V, i64 %sum3_cast
  %dout_gmem_V_addr_1_r = call i1 @_ssdm_op_WriteReq.m_axi.i512P(i512* %dout_gmem_V_addr_1, i32 1)
  call void @_ssdm_op_Write.m_axi.i512P(i512* %dout_gmem_V_addr_1, i512 %p_Result_s, i64 -1)
  %dout_gmem_V_addr_1_r_1 = call i1 @_ssdm_op_WriteResp.m_axi.i512P(i512* %dout_gmem_V_addr_1)
  br label %2

; <label>:2                                       ; preds = %0, %1
  %act_reg_Control_Retc = phi i9 [ -254, %1 ], [ -252, %0 ]
  ret i9 %act_reg_Control_Retc
}

declare i992 @llvm.part.set.i992.i32(i992, i32, i32, i32) nounwind readnone

declare i992 @llvm.part.select.i992(i992, i32, i32) nounwind readnone

declare i64 @llvm.part.select.i64(i64, i32, i32) nounwind readnone

declare i512 @llvm.part.select.i512(i512, i32, i32) nounwind readnone

declare i32 @llvm.part.select.i32(i32, i32, i32) nounwind readnone

declare void @llvm.dbg.value(metadata, i64, metadata) nounwind readnone

define void @hls_action(i512* %host_mem, i64 %din_gmem_V, i64 %dout_gmem_V, i992* %act_reg, i64* %Action_Config) {
  %dout_gmem_V_read = call i64 @_ssdm_op_Read.s_axilite.i64(i64 %dout_gmem_V)
  %din_gmem_V_read = call i64 @_ssdm_op_Read.s_axilite.i64(i64 %din_gmem_V)
  %dout_gmem_V3 = call i58 @_ssdm_op_PartSelect.i58.i64.i32.i32(i64 %dout_gmem_V_read, i32 6, i32 63)
  %din_gmem_V1 = call i58 @_ssdm_op_PartSelect.i58.i64.i32.i32(i64 %din_gmem_V_read, i32 6, i32 63)
  call void (...)* @_ssdm_op_SpecBitsMap(i512* %host_mem), !map !65
  call void (...)* @_ssdm_op_SpecBitsMap(i992* %act_reg), !map !72
  call void (...)* @_ssdm_op_SpecBitsMap(i64* %Action_Config), !map !492
  call void (...)* @_ssdm_op_SpecTopModule([11 x i8]* @hls_action_str) nounwind
  call void (...)* @_ssdm_op_SpecInterface(i512* %host_mem, [6 x i8]* @p_str, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 512, [9 x i8]* @p_str2, [6 x i8]* @p_str3, [1 x i8]* @p_str1, i32 16, i32 16, i32 64, i32 64, [1 x i8]* @p_str1, [1 x i8]* @p_str1) nounwind
  call void (...)* @_ssdm_op_SpecInterface(i64 %din_gmem_V, [10 x i8]* @p_str4, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 0, [9 x i8]* @p_str5, [6 x i8]* @p_str6, [1 x i8]* @p_str1, i32 0, i32 0, i32 0, i32 0, [1 x i8]* @p_str1, [1 x i8]* @p_str1) nounwind
  call void (...)* @_ssdm_op_SpecInterface(i64 %dout_gmem_V, [10 x i8]* @p_str4, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 0, [9 x i8]* @p_str5, [6 x i8]* @p_str7, [1 x i8]* @p_str1, i32 0, i32 0, i32 0, i32 0, [1 x i8]* @p_str1, [1 x i8]* @p_str1) nounwind
  call void (...)* @_ssdm_op_SpecInterface(i64* %Action_Config, [10 x i8]* @p_str4, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 0, [9 x i8]* @p_str5, [6 x i8]* @p_str8, [1 x i8]* @p_str1, i32 0, i32 0, i32 0, i32 0, [1 x i8]* @p_str1, [1 x i8]* @p_str1) nounwind
  call void (...)* @_ssdm_op_SpecInterface(i992* %act_reg, [10 x i8]* @p_str4, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 0, [9 x i8]* @p_str5, [6 x i8]* @p_str9, [1 x i8]* @p_str1, i32 0, i32 0, i32 0, i32 0, [1 x i8]* @p_str1, [1 x i8]* @p_str1) nounwind
  call void (...)* @_ssdm_op_SpecInterface(i32 0, [10 x i8]* @p_str4, i32 0, i32 0, [1 x i8]* @p_str1, i32 0, i32 0, [9 x i8]* @p_str5, [1 x i8]* @p_str1, [1 x i8]* @p_str1, i32 0, i32 0, i32 0, i32 0, [1 x i8]* @p_str1, [1 x i8]* @p_str1) nounwind
  %act_reg_read = call i992 @_ssdm_op_Read.s_axilite.i992P(i992* %act_reg)
  %act_reg_Control_flag = call i8 @_ssdm_op_PartSelect.i8.i992.i32.i32(i992 %act_reg_read, i32 8, i32 15)
  %cond = icmp eq i8 %act_reg_Control_flag, 0
  br i1 %cond, label %1, label %2

; <label>:1                                       ; preds = %0
  call void @_ssdm_op_Write.s_axilite.i64P(i64* %Action_Config, i64 142003671050)
  br label %3

; <label>:2                                       ; preds = %0
  %act_reg_Data_in_addr = call i64 @_ssdm_op_PartSelect.i64.i992.i32.i32(i992 %act_reg_read, i32 128, i32 191)
  %act_reg_Data_in_size = call i32 @_ssdm_op_PartSelect.i32.i992.i32.i32(i992 %act_reg_read, i32 192, i32 223)
  %act_reg_Data_out_add = call i64 @_ssdm_op_PartSelect.i64.i992.i32.i32(i992 %act_reg_read, i32 256, i32 319)
  %tmp_6 = call fastcc i9 @process_action(i512* %host_mem, i58 %din_gmem_V1, i58 %dout_gmem_V3, i64 %act_reg_Data_in_addr, i32 %act_reg_Data_in_size, i64 %act_reg_Data_out_add)
  %storemerge_trunc_ext = zext i9 %tmp_6 to i14
  br label %3

; <label>:3                                       ; preds = %2, %1
  %storemerge = phi i14 [ %storemerge_trunc_ext, %2 ], [ -8177, %1 ]
  %storemerge_cast5 = sext i14 %storemerge to i16
  %storemerge_cast1 = zext i16 %storemerge_cast5 to i32
  %act_reg_read_1 = call i992 @_ssdm_op_Read.s_axilite.i992P(i992* %act_reg)
  %act_reg11_part_set = call i992 @llvm.part.set.i992.i32(i992 %act_reg_read_1, i32 %storemerge_cast1, i32 32, i32 63)
  call void @_ssdm_op_Write.s_axilite.i992P(i992* %act_reg, i992 %act_reg11_part_set)
  ret void
}

define weak i1 @_ssdm_op_WriteResp.m_axi.i512P(i512*) {
entry:
  ret i1 true
}

define weak i1 @_ssdm_op_WriteReq.m_axi.i512P(i512*, i32) {
entry:
  ret i1 true
}

define weak void @_ssdm_op_Write.s_axilite.i992P(i992*, i992) {
entry:
  store i992 %1, i992* %0
  ret void
}

define weak void @_ssdm_op_Write.s_axilite.i64P(i64*, i64) {
entry:
  store i64 %1, i64* %0
  ret void
}

define weak void @_ssdm_op_Write.m_axi.i512P(i512*, i512, i64) {
entry:
  ret void
}

define weak void @_ssdm_op_SpecTopModule(...) {
entry:
  ret void
}

define weak void @_ssdm_op_SpecInterface(...) nounwind {
entry:
  ret void
}

define weak void @_ssdm_op_SpecBitsMap(...) {
entry:
  ret void
}

define weak i1 @_ssdm_op_ReadReq.m_axi.i512P(i512*, i32) {
entry:
  ret i1 true
}

define weak i992 @_ssdm_op_Read.s_axilite.i992P(i992*) {
entry:
  %empty = load i992* %0
  ret i992 %empty
}

define weak i64 @_ssdm_op_Read.s_axilite.i64(i64) {
entry:
  ret i64 %0
}

define weak i512 @_ssdm_op_Read.m_axi.i512P(i512*) {
entry:
  %empty = load i512* %0
  ret i512 %empty
}

define weak i64 @_ssdm_op_Read.ap_auto.i64(i64) {
entry:
  ret i64 %0
}

define weak i58 @_ssdm_op_Read.ap_auto.i58(i58) {
entry:
  ret i58 %0
}

define weak i32 @_ssdm_op_Read.ap_auto.i32(i32) {
entry:
  ret i32 %0
}

define weak i8 @_ssdm_op_PartSelect.i8.i992.i32.i32(i992, i32, i32) nounwind readnone {
entry:
  %empty = call i992 @llvm.part.select.i992(i992 %0, i32 %1, i32 %2)
  %empty_13 = trunc i992 %empty to i8
  ret i8 %empty_13
}

define weak i64 @_ssdm_op_PartSelect.i64.i992.i32.i32(i992, i32, i32) nounwind readnone {
entry:
  %empty = call i992 @llvm.part.select.i992(i992 %0, i32 %1, i32 %2)
  %empty_14 = trunc i992 %empty to i64
  ret i64 %empty_14
}

define weak i64 @_ssdm_op_PartSelect.i64.i512.i32.i32(i512, i32, i32) nounwind readnone {
entry:
  %empty = call i512 @llvm.part.select.i512(i512 %0, i32 %1, i32 %2)
  %empty_15 = trunc i512 %empty to i64
  ret i64 %empty_15
}

define weak i58 @_ssdm_op_PartSelect.i58.i64.i32.i32(i64, i32, i32) nounwind readnone {
entry:
  %empty = call i64 @llvm.part.select.i64(i64 %0, i32 %1, i32 %2)
  %empty_16 = trunc i64 %empty to i58
  ret i58 %empty_16
}

define weak i32 @_ssdm_op_PartSelect.i32.i992.i32.i32(i992, i32, i32) nounwind readnone {
entry:
  %empty = call i992 @llvm.part.select.i992(i992 %0, i32 %1, i32 %2)
  %empty_17 = trunc i992 %empty to i32
  ret i32 %empty_17
}

define weak i28 @_ssdm_op_PartSelect.i28.i32.i32.i32(i32, i32, i32) nounwind readnone {
entry:
  %empty = call i32 @llvm.part.select.i32(i32 %0, i32 %1, i32 %2)
  %empty_18 = trunc i32 %empty to i28
  ret i28 %empty_18
}

define weak i192 @_ssdm_op_PartSelect.i192.i512.i32.i32(i512, i32, i32) nounwind readnone {
entry:
  %empty = call i512 @llvm.part.select.i512(i512 %0, i32 %1, i32 %2)
  %empty_19 = trunc i512 %empty to i192
  ret i192 %empty_19
}

define weak i320 @_ssdm_op_BitConcatenate.i320.i192.i64.i64(i192, i64, i64) nounwind readnone {
entry:
  %empty = zext i64 %1 to i128
  %empty_20 = zext i64 %2 to i128
  %empty_21 = shl i128 %empty, 64
  %empty_22 = or i128 %empty_21, %empty_20
  %empty_23 = zext i192 %0 to i320
  %empty_24 = zext i128 %empty_22 to i320
  %empty_25 = shl i320 %empty_23, 128
  %empty_26 = or i320 %empty_25, %empty_24
  ret i320 %empty_26
}

declare void @_GLOBAL__I_a() nounwind section ".text.startup"

!opencl.kernels = !{!0, !7, !13, !13, !7, !7, !19, !22, !28, !32, !34, !34, !7, !37, !43, !43, !47, !7, !7, !53, !13, !13, !7}
!hls.encrypted.func = !{}
!llvm.map.gv = !{!55}
!axi4.master.portmap = !{!62}
!axi4.slave.bundlemap = !{!63, !64}

!0 = metadata !{null, metadata !1, metadata !2, metadata !3, metadata !4, metadata !5, metadata !6}
!1 = metadata !{metadata !"kernel_arg_addr_space", i32 1, i32 1, i32 1, i32 1}
!2 = metadata !{metadata !"kernel_arg_access_qual", metadata !"none", metadata !"none", metadata !"none", metadata !"none"}
!3 = metadata !{metadata !"kernel_arg_type", metadata !"snap_membus_t*", metadata !"snap_membus_t*", metadata !"action_reg*", metadata !"action_RO_config_reg*"}
!4 = metadata !{metadata !"kernel_arg_type_qual", metadata !"", metadata !"", metadata !"", metadata !""}
!5 = metadata !{metadata !"kernel_arg_name", metadata !"din_gmem", metadata !"dout_gmem", metadata !"act_reg", metadata !"Action_Config"}
!6 = metadata !{metadata !"reqd_work_group_size", i32 1, i32 1, i32 1}
!7 = metadata !{null, metadata !8, metadata !9, metadata !10, metadata !11, metadata !12, metadata !6}
!8 = metadata !{metadata !"kernel_arg_addr_space"}
!9 = metadata !{metadata !"kernel_arg_access_qual"}
!10 = metadata !{metadata !"kernel_arg_type"}
!11 = metadata !{metadata !"kernel_arg_type_qual"}
!12 = metadata !{metadata !"kernel_arg_name"}
!13 = metadata !{null, metadata !14, metadata !15, metadata !16, metadata !17, metadata !18, metadata !6}
!14 = metadata !{metadata !"kernel_arg_addr_space", i32 0}
!15 = metadata !{metadata !"kernel_arg_access_qual", metadata !"none"}
!16 = metadata !{metadata !"kernel_arg_type", metadata !"int"}
!17 = metadata !{metadata !"kernel_arg_type_qual", metadata !""}
!18 = metadata !{metadata !"kernel_arg_name", metadata !"val"}
!19 = metadata !{null, metadata !14, metadata !15, metadata !20, metadata !17, metadata !21, metadata !6}
!20 = metadata !{metadata !"kernel_arg_type", metadata !"const ap_uint<32> &"}
!21 = metadata !{metadata !"kernel_arg_name", metadata !"op2"}
!22 = metadata !{null, metadata !23, metadata !24, metadata !25, metadata !26, metadata !27, metadata !6}
!23 = metadata !{metadata !"kernel_arg_addr_space", i32 1, i32 1, i32 1}
!24 = metadata !{metadata !"kernel_arg_access_qual", metadata !"none", metadata !"none", metadata !"none"}
!25 = metadata !{metadata !"kernel_arg_type", metadata !"snap_membus_t*", metadata !"snap_membus_t*", metadata !"action_reg*"}
!26 = metadata !{metadata !"kernel_arg_type_qual", metadata !"", metadata !"", metadata !""}
!27 = metadata !{metadata !"kernel_arg_name", metadata !"din_gmem", metadata !"dout_gmem", metadata !"act_reg"}
!28 = metadata !{null, metadata !29, metadata !2, metadata !30, metadata !4, metadata !31, metadata !6}
!29 = metadata !{metadata !"kernel_arg_addr_space", i32 0, i32 0, i32 0, i32 0}
!30 = metadata !{metadata !"kernel_arg_type", metadata !"double", metadata !"double", metadata !"double", metadata !"double"}
!31 = metadata !{metadata !"kernel_arg_name", metadata !"val", metadata !"beta", metadata !"gamma", metadata !"theta"}
!32 = metadata !{null, metadata !14, metadata !15, metadata !33, metadata !17, metadata !18, metadata !6}
!33 = metadata !{metadata !"kernel_arg_type", metadata !"ulong long"}
!34 = metadata !{null, metadata !14, metadata !15, metadata !35, metadata !17, metadata !36, metadata !6}
!35 = metadata !{metadata !"kernel_arg_type", metadata !"ap_ulong"}
!36 = metadata !{metadata !"kernel_arg_name", metadata !"op"}
!37 = metadata !{null, metadata !38, metadata !39, metadata !40, metadata !41, metadata !42, metadata !6}
!38 = metadata !{metadata !"kernel_arg_addr_space", i32 0, i32 0}
!39 = metadata !{metadata !"kernel_arg_access_qual", metadata !"none", metadata !"none"}
!40 = metadata !{metadata !"kernel_arg_type", metadata !"int", metadata !"int"}
!41 = metadata !{metadata !"kernel_arg_type_qual", metadata !"", metadata !""}
!42 = metadata !{metadata !"kernel_arg_name", metadata !"Hi", metadata !"Lo"}
!43 = metadata !{null, metadata !44, metadata !24, metadata !45, metadata !26, metadata !46, metadata !6}
!44 = metadata !{metadata !"kernel_arg_addr_space", i32 1, i32 0, i32 0}
!45 = metadata !{metadata !"kernel_arg_type", metadata !"ap_int_base<512, false>*", metadata !"int", metadata !"int"}
!46 = metadata !{metadata !"kernel_arg_name", metadata !"bv", metadata !"h", metadata !"l"}
!47 = metadata !{null, metadata !48, metadata !49, metadata !50, metadata !51, metadata !52, metadata !6}
!48 = metadata !{metadata !"kernel_arg_addr_space", i32 0, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1}
!49 = metadata !{metadata !"kernel_arg_access_qual", metadata !"none", metadata !"none", metadata !"none", metadata !"none", metadata !"none", metadata !"none", metadata !"none", metadata !"none", metadata !"none", metadata !"none"}
!50 = metadata !{metadata !"kernel_arg_type", metadata !"snap_membus_t", metadata !"ulong*", metadata !"double*", metadata !"double*", metadata !"double*", metadata !"int*", metadata !"int*", metadata !"int*", metadata !"int*", metadata !"int*"}
!51 = metadata !{metadata !"kernel_arg_type_qual", metadata !"", metadata !"", metadata !"", metadata !"", metadata !"", metadata !"", metadata !"", metadata !"", metadata !"", metadata !""}
!52 = metadata !{metadata !"kernel_arg_name", metadata !"mem", metadata !"ptr_array_addr", metadata !"ptr_beta", metadata !"ptr_gamma", metadata !"ptr_theta", metadata !"ptr_cycles", metadata !"ptr_N", metadata !"ptr_M", metadata !"ptr_alpha", metadata !"ptr_padding"}
!53 = metadata !{null, metadata !14, metadata !15, metadata !54, metadata !17, metadata !21, metadata !6}
!54 = metadata !{metadata !"kernel_arg_type", metadata !"const ap_uint<512> &"}
!55 = metadata !{metadata !56, [1 x i32]* @llvm_global_ctors_0}
!56 = metadata !{metadata !57}
!57 = metadata !{i32 0, i32 31, metadata !58}
!58 = metadata !{metadata !59}
!59 = metadata !{metadata !"llvm.global_ctors.0", metadata !60, metadata !"", i32 0, i32 31}
!60 = metadata !{metadata !61}
!61 = metadata !{i32 0, i32 0, i32 1}
!62 = metadata !{metadata !"host_mem", metadata !"din_gmem.V", metadata !"READONLY", metadata !"dout_gmem.V", metadata !"WRITEONLY"}
!63 = metadata !{metadata !"din_gmem.V", metadata !"ctrl_reg"}
!64 = metadata !{metadata !"dout_gmem.V", metadata !"ctrl_reg"}
!65 = metadata !{metadata !66}
!66 = metadata !{i32 0, i32 511, metadata !67}
!67 = metadata !{metadata !68, metadata !71}
!68 = metadata !{metadata !"din_gmem.V", metadata !69, metadata !"uint512", i32 0, i32 511}
!69 = metadata !{metadata !70}
!70 = metadata !{i32 0, i32 511, i32 1}
!71 = metadata !{metadata !"dout_gmem.V", metadata !69, metadata !"uint512", i32 0, i32 511}
!72 = metadata !{metadata !73, metadata !76, metadata !79, metadata !82, metadata !85, metadata !88, metadata !91, metadata !94, metadata !97, metadata !100, metadata !103, metadata !106, metadata !109, metadata !112, metadata !117, metadata !122, metadata !127, metadata !132, metadata !137, metadata !142, metadata !147, metadata !152, metadata !157, metadata !162, metadata !167, metadata !172, metadata !177, metadata !182, metadata !187, metadata !192, metadata !197, metadata !202, metadata !207, metadata !212, metadata !217, metadata !222, metadata !227, metadata !232, metadata !237, metadata !242, metadata !247, metadata !252, metadata !257, metadata !262, metadata !267, metadata !272, metadata !277, metadata !282, metadata !287, metadata !292, metadata !297, metadata !302, metadata !307, metadata !312, metadata !317, metadata !322, metadata !327, metadata !332, metadata !337, metadata !342, metadata !347, metadata !352, metadata !357, metadata !362, metadata !367, metadata !372, metadata !377, metadata !382, metadata !387, metadata !392, metadata !397, metadata !402, metadata !407, metadata !412, metadata !417, metadata !422, metadata !427, metadata !432, metadata !437, metadata !442, metadata !447, metadata !452, metadata !457, metadata !462, metadata !467, metadata !472, metadata !477, metadata !482, metadata !487}
!73 = metadata !{i32 0, i32 7, metadata !74}
!74 = metadata !{metadata !75}
!75 = metadata !{metadata !"act_reg.Control.sat.V", metadata !60, metadata !"uint8", i32 0, i32 7}
!76 = metadata !{i32 8, i32 15, metadata !77}
!77 = metadata !{metadata !78}
!78 = metadata !{metadata !"act_reg.Control.flags.V", metadata !60, metadata !"uint8", i32 0, i32 7}
!79 = metadata !{i32 16, i32 31, metadata !80}
!80 = metadata !{metadata !81}
!81 = metadata !{metadata !"act_reg.Control.seq.V", metadata !60, metadata !"uint16", i32 0, i32 15}
!82 = metadata !{i32 32, i32 63, metadata !83}
!83 = metadata !{metadata !84}
!84 = metadata !{metadata !"act_reg.Control.Retc.V", metadata !60, metadata !"uint32", i32 0, i32 31}
!85 = metadata !{i32 64, i32 127, metadata !86}
!86 = metadata !{metadata !87}
!87 = metadata !{metadata !"act_reg.Control.Reserved.V", metadata !60, metadata !"uint64", i32 0, i32 63}
!88 = metadata !{i32 128, i32 191, metadata !89}
!89 = metadata !{metadata !90}
!90 = metadata !{metadata !"act_reg.Data.in.addr", metadata !60, metadata !"long unsigned int", i32 0, i32 63}
!91 = metadata !{i32 192, i32 223, metadata !92}
!92 = metadata !{metadata !93}
!93 = metadata !{metadata !"act_reg.Data.in.size", metadata !60, metadata !"unsigned int", i32 0, i32 31}
!94 = metadata !{i32 224, i32 239, metadata !95}
!95 = metadata !{metadata !96}
!96 = metadata !{metadata !"act_reg.Data.in.type", metadata !60, metadata !"unsigned short", i32 0, i32 15}
!97 = metadata !{i32 240, i32 255, metadata !98}
!98 = metadata !{metadata !99}
!99 = metadata !{metadata !"act_reg.Data.in.flags", metadata !60, metadata !"unsigned short", i32 0, i32 15}
!100 = metadata !{i32 256, i32 319, metadata !101}
!101 = metadata !{metadata !102}
!102 = metadata !{metadata !"act_reg.Data.out.addr", metadata !60, metadata !"long unsigned int", i32 0, i32 63}
!103 = metadata !{i32 320, i32 351, metadata !104}
!104 = metadata !{metadata !105}
!105 = metadata !{metadata !"act_reg.Data.out.size", metadata !60, metadata !"unsigned int", i32 0, i32 31}
!106 = metadata !{i32 352, i32 367, metadata !107}
!107 = metadata !{metadata !108}
!108 = metadata !{metadata !"act_reg.Data.out.type", metadata !60, metadata !"unsigned short", i32 0, i32 15}
!109 = metadata !{i32 368, i32 383, metadata !110}
!110 = metadata !{metadata !111}
!111 = metadata !{metadata !"act_reg.Data.out.flags", metadata !60, metadata !"unsigned short", i32 0, i32 15}
!112 = metadata !{i32 384, i32 391, metadata !113}
!113 = metadata !{metadata !114}
!114 = metadata !{metadata !"act_reg.padding", metadata !115, metadata !"unsigned char", i32 0, i32 7}
!115 = metadata !{metadata !116}
!116 = metadata !{i32 0, i32 0, i32 2}
!117 = metadata !{i32 392, i32 399, metadata !118}
!118 = metadata !{metadata !119}
!119 = metadata !{metadata !"act_reg.padding", metadata !120, metadata !"unsigned char", i32 0, i32 7}
!120 = metadata !{metadata !121}
!121 = metadata !{i32 1, i32 1, i32 2}
!122 = metadata !{i32 400, i32 407, metadata !123}
!123 = metadata !{metadata !124}
!124 = metadata !{metadata !"act_reg.padding", metadata !125, metadata !"unsigned char", i32 0, i32 7}
!125 = metadata !{metadata !126}
!126 = metadata !{i32 2, i32 2, i32 2}
!127 = metadata !{i32 408, i32 415, metadata !128}
!128 = metadata !{metadata !129}
!129 = metadata !{metadata !"act_reg.padding", metadata !130, metadata !"unsigned char", i32 0, i32 7}
!130 = metadata !{metadata !131}
!131 = metadata !{i32 3, i32 3, i32 2}
!132 = metadata !{i32 416, i32 423, metadata !133}
!133 = metadata !{metadata !134}
!134 = metadata !{metadata !"act_reg.padding", metadata !135, metadata !"unsigned char", i32 0, i32 7}
!135 = metadata !{metadata !136}
!136 = metadata !{i32 4, i32 4, i32 2}
!137 = metadata !{i32 424, i32 431, metadata !138}
!138 = metadata !{metadata !139}
!139 = metadata !{metadata !"act_reg.padding", metadata !140, metadata !"unsigned char", i32 0, i32 7}
!140 = metadata !{metadata !141}
!141 = metadata !{i32 5, i32 5, i32 2}
!142 = metadata !{i32 432, i32 439, metadata !143}
!143 = metadata !{metadata !144}
!144 = metadata !{metadata !"act_reg.padding", metadata !145, metadata !"unsigned char", i32 0, i32 7}
!145 = metadata !{metadata !146}
!146 = metadata !{i32 6, i32 6, i32 2}
!147 = metadata !{i32 440, i32 447, metadata !148}
!148 = metadata !{metadata !149}
!149 = metadata !{metadata !"act_reg.padding", metadata !150, metadata !"unsigned char", i32 0, i32 7}
!150 = metadata !{metadata !151}
!151 = metadata !{i32 7, i32 7, i32 2}
!152 = metadata !{i32 448, i32 455, metadata !153}
!153 = metadata !{metadata !154}
!154 = metadata !{metadata !"act_reg.padding", metadata !155, metadata !"unsigned char", i32 0, i32 7}
!155 = metadata !{metadata !156}
!156 = metadata !{i32 8, i32 8, i32 2}
!157 = metadata !{i32 456, i32 463, metadata !158}
!158 = metadata !{metadata !159}
!159 = metadata !{metadata !"act_reg.padding", metadata !160, metadata !"unsigned char", i32 0, i32 7}
!160 = metadata !{metadata !161}
!161 = metadata !{i32 9, i32 9, i32 2}
!162 = metadata !{i32 464, i32 471, metadata !163}
!163 = metadata !{metadata !164}
!164 = metadata !{metadata !"act_reg.padding", metadata !165, metadata !"unsigned char", i32 0, i32 7}
!165 = metadata !{metadata !166}
!166 = metadata !{i32 10, i32 10, i32 2}
!167 = metadata !{i32 472, i32 479, metadata !168}
!168 = metadata !{metadata !169}
!169 = metadata !{metadata !"act_reg.padding", metadata !170, metadata !"unsigned char", i32 0, i32 7}
!170 = metadata !{metadata !171}
!171 = metadata !{i32 11, i32 11, i32 2}
!172 = metadata !{i32 480, i32 487, metadata !173}
!173 = metadata !{metadata !174}
!174 = metadata !{metadata !"act_reg.padding", metadata !175, metadata !"unsigned char", i32 0, i32 7}
!175 = metadata !{metadata !176}
!176 = metadata !{i32 12, i32 12, i32 2}
!177 = metadata !{i32 488, i32 495, metadata !178}
!178 = metadata !{metadata !179}
!179 = metadata !{metadata !"act_reg.padding", metadata !180, metadata !"unsigned char", i32 0, i32 7}
!180 = metadata !{metadata !181}
!181 = metadata !{i32 13, i32 13, i32 2}
!182 = metadata !{i32 496, i32 503, metadata !183}
!183 = metadata !{metadata !184}
!184 = metadata !{metadata !"act_reg.padding", metadata !185, metadata !"unsigned char", i32 0, i32 7}
!185 = metadata !{metadata !186}
!186 = metadata !{i32 14, i32 14, i32 2}
!187 = metadata !{i32 504, i32 511, metadata !188}
!188 = metadata !{metadata !189}
!189 = metadata !{metadata !"act_reg.padding", metadata !190, metadata !"unsigned char", i32 0, i32 7}
!190 = metadata !{metadata !191}
!191 = metadata !{i32 15, i32 15, i32 2}
!192 = metadata !{i32 512, i32 519, metadata !193}
!193 = metadata !{metadata !194}
!194 = metadata !{metadata !"act_reg.padding", metadata !195, metadata !"unsigned char", i32 0, i32 7}
!195 = metadata !{metadata !196}
!196 = metadata !{i32 16, i32 16, i32 2}
!197 = metadata !{i32 520, i32 527, metadata !198}
!198 = metadata !{metadata !199}
!199 = metadata !{metadata !"act_reg.padding", metadata !200, metadata !"unsigned char", i32 0, i32 7}
!200 = metadata !{metadata !201}
!201 = metadata !{i32 17, i32 17, i32 2}
!202 = metadata !{i32 528, i32 535, metadata !203}
!203 = metadata !{metadata !204}
!204 = metadata !{metadata !"act_reg.padding", metadata !205, metadata !"unsigned char", i32 0, i32 7}
!205 = metadata !{metadata !206}
!206 = metadata !{i32 18, i32 18, i32 2}
!207 = metadata !{i32 536, i32 543, metadata !208}
!208 = metadata !{metadata !209}
!209 = metadata !{metadata !"act_reg.padding", metadata !210, metadata !"unsigned char", i32 0, i32 7}
!210 = metadata !{metadata !211}
!211 = metadata !{i32 19, i32 19, i32 2}
!212 = metadata !{i32 544, i32 551, metadata !213}
!213 = metadata !{metadata !214}
!214 = metadata !{metadata !"act_reg.padding", metadata !215, metadata !"unsigned char", i32 0, i32 7}
!215 = metadata !{metadata !216}
!216 = metadata !{i32 20, i32 20, i32 2}
!217 = metadata !{i32 552, i32 559, metadata !218}
!218 = metadata !{metadata !219}
!219 = metadata !{metadata !"act_reg.padding", metadata !220, metadata !"unsigned char", i32 0, i32 7}
!220 = metadata !{metadata !221}
!221 = metadata !{i32 21, i32 21, i32 2}
!222 = metadata !{i32 560, i32 567, metadata !223}
!223 = metadata !{metadata !224}
!224 = metadata !{metadata !"act_reg.padding", metadata !225, metadata !"unsigned char", i32 0, i32 7}
!225 = metadata !{metadata !226}
!226 = metadata !{i32 22, i32 22, i32 2}
!227 = metadata !{i32 568, i32 575, metadata !228}
!228 = metadata !{metadata !229}
!229 = metadata !{metadata !"act_reg.padding", metadata !230, metadata !"unsigned char", i32 0, i32 7}
!230 = metadata !{metadata !231}
!231 = metadata !{i32 23, i32 23, i32 2}
!232 = metadata !{i32 576, i32 583, metadata !233}
!233 = metadata !{metadata !234}
!234 = metadata !{metadata !"act_reg.padding", metadata !235, metadata !"unsigned char", i32 0, i32 7}
!235 = metadata !{metadata !236}
!236 = metadata !{i32 24, i32 24, i32 2}
!237 = metadata !{i32 584, i32 591, metadata !238}
!238 = metadata !{metadata !239}
!239 = metadata !{metadata !"act_reg.padding", metadata !240, metadata !"unsigned char", i32 0, i32 7}
!240 = metadata !{metadata !241}
!241 = metadata !{i32 25, i32 25, i32 2}
!242 = metadata !{i32 592, i32 599, metadata !243}
!243 = metadata !{metadata !244}
!244 = metadata !{metadata !"act_reg.padding", metadata !245, metadata !"unsigned char", i32 0, i32 7}
!245 = metadata !{metadata !246}
!246 = metadata !{i32 26, i32 26, i32 2}
!247 = metadata !{i32 600, i32 607, metadata !248}
!248 = metadata !{metadata !249}
!249 = metadata !{metadata !"act_reg.padding", metadata !250, metadata !"unsigned char", i32 0, i32 7}
!250 = metadata !{metadata !251}
!251 = metadata !{i32 27, i32 27, i32 2}
!252 = metadata !{i32 608, i32 615, metadata !253}
!253 = metadata !{metadata !254}
!254 = metadata !{metadata !"act_reg.padding", metadata !255, metadata !"unsigned char", i32 0, i32 7}
!255 = metadata !{metadata !256}
!256 = metadata !{i32 28, i32 28, i32 2}
!257 = metadata !{i32 616, i32 623, metadata !258}
!258 = metadata !{metadata !259}
!259 = metadata !{metadata !"act_reg.padding", metadata !260, metadata !"unsigned char", i32 0, i32 7}
!260 = metadata !{metadata !261}
!261 = metadata !{i32 29, i32 29, i32 2}
!262 = metadata !{i32 624, i32 631, metadata !263}
!263 = metadata !{metadata !264}
!264 = metadata !{metadata !"act_reg.padding", metadata !265, metadata !"unsigned char", i32 0, i32 7}
!265 = metadata !{metadata !266}
!266 = metadata !{i32 30, i32 30, i32 2}
!267 = metadata !{i32 632, i32 639, metadata !268}
!268 = metadata !{metadata !269}
!269 = metadata !{metadata !"act_reg.padding", metadata !270, metadata !"unsigned char", i32 0, i32 7}
!270 = metadata !{metadata !271}
!271 = metadata !{i32 31, i32 31, i32 2}
!272 = metadata !{i32 640, i32 647, metadata !273}
!273 = metadata !{metadata !274}
!274 = metadata !{metadata !"act_reg.padding", metadata !275, metadata !"unsigned char", i32 0, i32 7}
!275 = metadata !{metadata !276}
!276 = metadata !{i32 32, i32 32, i32 2}
!277 = metadata !{i32 648, i32 655, metadata !278}
!278 = metadata !{metadata !279}
!279 = metadata !{metadata !"act_reg.padding", metadata !280, metadata !"unsigned char", i32 0, i32 7}
!280 = metadata !{metadata !281}
!281 = metadata !{i32 33, i32 33, i32 2}
!282 = metadata !{i32 656, i32 663, metadata !283}
!283 = metadata !{metadata !284}
!284 = metadata !{metadata !"act_reg.padding", metadata !285, metadata !"unsigned char", i32 0, i32 7}
!285 = metadata !{metadata !286}
!286 = metadata !{i32 34, i32 34, i32 2}
!287 = metadata !{i32 664, i32 671, metadata !288}
!288 = metadata !{metadata !289}
!289 = metadata !{metadata !"act_reg.padding", metadata !290, metadata !"unsigned char", i32 0, i32 7}
!290 = metadata !{metadata !291}
!291 = metadata !{i32 35, i32 35, i32 2}
!292 = metadata !{i32 672, i32 679, metadata !293}
!293 = metadata !{metadata !294}
!294 = metadata !{metadata !"act_reg.padding", metadata !295, metadata !"unsigned char", i32 0, i32 7}
!295 = metadata !{metadata !296}
!296 = metadata !{i32 36, i32 36, i32 2}
!297 = metadata !{i32 680, i32 687, metadata !298}
!298 = metadata !{metadata !299}
!299 = metadata !{metadata !"act_reg.padding", metadata !300, metadata !"unsigned char", i32 0, i32 7}
!300 = metadata !{metadata !301}
!301 = metadata !{i32 37, i32 37, i32 2}
!302 = metadata !{i32 688, i32 695, metadata !303}
!303 = metadata !{metadata !304}
!304 = metadata !{metadata !"act_reg.padding", metadata !305, metadata !"unsigned char", i32 0, i32 7}
!305 = metadata !{metadata !306}
!306 = metadata !{i32 38, i32 38, i32 2}
!307 = metadata !{i32 696, i32 703, metadata !308}
!308 = metadata !{metadata !309}
!309 = metadata !{metadata !"act_reg.padding", metadata !310, metadata !"unsigned char", i32 0, i32 7}
!310 = metadata !{metadata !311}
!311 = metadata !{i32 39, i32 39, i32 2}
!312 = metadata !{i32 704, i32 711, metadata !313}
!313 = metadata !{metadata !314}
!314 = metadata !{metadata !"act_reg.padding", metadata !315, metadata !"unsigned char", i32 0, i32 7}
!315 = metadata !{metadata !316}
!316 = metadata !{i32 40, i32 40, i32 2}
!317 = metadata !{i32 712, i32 719, metadata !318}
!318 = metadata !{metadata !319}
!319 = metadata !{metadata !"act_reg.padding", metadata !320, metadata !"unsigned char", i32 0, i32 7}
!320 = metadata !{metadata !321}
!321 = metadata !{i32 41, i32 41, i32 2}
!322 = metadata !{i32 720, i32 727, metadata !323}
!323 = metadata !{metadata !324}
!324 = metadata !{metadata !"act_reg.padding", metadata !325, metadata !"unsigned char", i32 0, i32 7}
!325 = metadata !{metadata !326}
!326 = metadata !{i32 42, i32 42, i32 2}
!327 = metadata !{i32 728, i32 735, metadata !328}
!328 = metadata !{metadata !329}
!329 = metadata !{metadata !"act_reg.padding", metadata !330, metadata !"unsigned char", i32 0, i32 7}
!330 = metadata !{metadata !331}
!331 = metadata !{i32 43, i32 43, i32 2}
!332 = metadata !{i32 736, i32 743, metadata !333}
!333 = metadata !{metadata !334}
!334 = metadata !{metadata !"act_reg.padding", metadata !335, metadata !"unsigned char", i32 0, i32 7}
!335 = metadata !{metadata !336}
!336 = metadata !{i32 44, i32 44, i32 2}
!337 = metadata !{i32 744, i32 751, metadata !338}
!338 = metadata !{metadata !339}
!339 = metadata !{metadata !"act_reg.padding", metadata !340, metadata !"unsigned char", i32 0, i32 7}
!340 = metadata !{metadata !341}
!341 = metadata !{i32 45, i32 45, i32 2}
!342 = metadata !{i32 752, i32 759, metadata !343}
!343 = metadata !{metadata !344}
!344 = metadata !{metadata !"act_reg.padding", metadata !345, metadata !"unsigned char", i32 0, i32 7}
!345 = metadata !{metadata !346}
!346 = metadata !{i32 46, i32 46, i32 2}
!347 = metadata !{i32 760, i32 767, metadata !348}
!348 = metadata !{metadata !349}
!349 = metadata !{metadata !"act_reg.padding", metadata !350, metadata !"unsigned char", i32 0, i32 7}
!350 = metadata !{metadata !351}
!351 = metadata !{i32 47, i32 47, i32 2}
!352 = metadata !{i32 768, i32 775, metadata !353}
!353 = metadata !{metadata !354}
!354 = metadata !{metadata !"act_reg.padding", metadata !355, metadata !"unsigned char", i32 0, i32 7}
!355 = metadata !{metadata !356}
!356 = metadata !{i32 48, i32 48, i32 2}
!357 = metadata !{i32 776, i32 783, metadata !358}
!358 = metadata !{metadata !359}
!359 = metadata !{metadata !"act_reg.padding", metadata !360, metadata !"unsigned char", i32 0, i32 7}
!360 = metadata !{metadata !361}
!361 = metadata !{i32 49, i32 49, i32 2}
!362 = metadata !{i32 784, i32 791, metadata !363}
!363 = metadata !{metadata !364}
!364 = metadata !{metadata !"act_reg.padding", metadata !365, metadata !"unsigned char", i32 0, i32 7}
!365 = metadata !{metadata !366}
!366 = metadata !{i32 50, i32 50, i32 2}
!367 = metadata !{i32 792, i32 799, metadata !368}
!368 = metadata !{metadata !369}
!369 = metadata !{metadata !"act_reg.padding", metadata !370, metadata !"unsigned char", i32 0, i32 7}
!370 = metadata !{metadata !371}
!371 = metadata !{i32 51, i32 51, i32 2}
!372 = metadata !{i32 800, i32 807, metadata !373}
!373 = metadata !{metadata !374}
!374 = metadata !{metadata !"act_reg.padding", metadata !375, metadata !"unsigned char", i32 0, i32 7}
!375 = metadata !{metadata !376}
!376 = metadata !{i32 52, i32 52, i32 2}
!377 = metadata !{i32 808, i32 815, metadata !378}
!378 = metadata !{metadata !379}
!379 = metadata !{metadata !"act_reg.padding", metadata !380, metadata !"unsigned char", i32 0, i32 7}
!380 = metadata !{metadata !381}
!381 = metadata !{i32 53, i32 53, i32 2}
!382 = metadata !{i32 816, i32 823, metadata !383}
!383 = metadata !{metadata !384}
!384 = metadata !{metadata !"act_reg.padding", metadata !385, metadata !"unsigned char", i32 0, i32 7}
!385 = metadata !{metadata !386}
!386 = metadata !{i32 54, i32 54, i32 2}
!387 = metadata !{i32 824, i32 831, metadata !388}
!388 = metadata !{metadata !389}
!389 = metadata !{metadata !"act_reg.padding", metadata !390, metadata !"unsigned char", i32 0, i32 7}
!390 = metadata !{metadata !391}
!391 = metadata !{i32 55, i32 55, i32 2}
!392 = metadata !{i32 832, i32 839, metadata !393}
!393 = metadata !{metadata !394}
!394 = metadata !{metadata !"act_reg.padding", metadata !395, metadata !"unsigned char", i32 0, i32 7}
!395 = metadata !{metadata !396}
!396 = metadata !{i32 56, i32 56, i32 2}
!397 = metadata !{i32 840, i32 847, metadata !398}
!398 = metadata !{metadata !399}
!399 = metadata !{metadata !"act_reg.padding", metadata !400, metadata !"unsigned char", i32 0, i32 7}
!400 = metadata !{metadata !401}
!401 = metadata !{i32 57, i32 57, i32 2}
!402 = metadata !{i32 848, i32 855, metadata !403}
!403 = metadata !{metadata !404}
!404 = metadata !{metadata !"act_reg.padding", metadata !405, metadata !"unsigned char", i32 0, i32 7}
!405 = metadata !{metadata !406}
!406 = metadata !{i32 58, i32 58, i32 2}
!407 = metadata !{i32 856, i32 863, metadata !408}
!408 = metadata !{metadata !409}
!409 = metadata !{metadata !"act_reg.padding", metadata !410, metadata !"unsigned char", i32 0, i32 7}
!410 = metadata !{metadata !411}
!411 = metadata !{i32 59, i32 59, i32 2}
!412 = metadata !{i32 864, i32 871, metadata !413}
!413 = metadata !{metadata !414}
!414 = metadata !{metadata !"act_reg.padding", metadata !415, metadata !"unsigned char", i32 0, i32 7}
!415 = metadata !{metadata !416}
!416 = metadata !{i32 60, i32 60, i32 2}
!417 = metadata !{i32 872, i32 879, metadata !418}
!418 = metadata !{metadata !419}
!419 = metadata !{metadata !"act_reg.padding", metadata !420, metadata !"unsigned char", i32 0, i32 7}
!420 = metadata !{metadata !421}
!421 = metadata !{i32 61, i32 61, i32 2}
!422 = metadata !{i32 880, i32 887, metadata !423}
!423 = metadata !{metadata !424}
!424 = metadata !{metadata !"act_reg.padding", metadata !425, metadata !"unsigned char", i32 0, i32 7}
!425 = metadata !{metadata !426}
!426 = metadata !{i32 62, i32 62, i32 2}
!427 = metadata !{i32 888, i32 895, metadata !428}
!428 = metadata !{metadata !429}
!429 = metadata !{metadata !"act_reg.padding", metadata !430, metadata !"unsigned char", i32 0, i32 7}
!430 = metadata !{metadata !431}
!431 = metadata !{i32 63, i32 63, i32 2}
!432 = metadata !{i32 896, i32 903, metadata !433}
!433 = metadata !{metadata !434}
!434 = metadata !{metadata !"act_reg.padding", metadata !435, metadata !"unsigned char", i32 0, i32 7}
!435 = metadata !{metadata !436}
!436 = metadata !{i32 64, i32 64, i32 2}
!437 = metadata !{i32 904, i32 911, metadata !438}
!438 = metadata !{metadata !439}
!439 = metadata !{metadata !"act_reg.padding", metadata !440, metadata !"unsigned char", i32 0, i32 7}
!440 = metadata !{metadata !441}
!441 = metadata !{i32 65, i32 65, i32 2}
!442 = metadata !{i32 912, i32 919, metadata !443}
!443 = metadata !{metadata !444}
!444 = metadata !{metadata !"act_reg.padding", metadata !445, metadata !"unsigned char", i32 0, i32 7}
!445 = metadata !{metadata !446}
!446 = metadata !{i32 66, i32 66, i32 2}
!447 = metadata !{i32 920, i32 927, metadata !448}
!448 = metadata !{metadata !449}
!449 = metadata !{metadata !"act_reg.padding", metadata !450, metadata !"unsigned char", i32 0, i32 7}
!450 = metadata !{metadata !451}
!451 = metadata !{i32 67, i32 67, i32 2}
!452 = metadata !{i32 928, i32 935, metadata !453}
!453 = metadata !{metadata !454}
!454 = metadata !{metadata !"act_reg.padding", metadata !455, metadata !"unsigned char", i32 0, i32 7}
!455 = metadata !{metadata !456}
!456 = metadata !{i32 68, i32 68, i32 2}
!457 = metadata !{i32 936, i32 943, metadata !458}
!458 = metadata !{metadata !459}
!459 = metadata !{metadata !"act_reg.padding", metadata !460, metadata !"unsigned char", i32 0, i32 7}
!460 = metadata !{metadata !461}
!461 = metadata !{i32 69, i32 69, i32 2}
!462 = metadata !{i32 944, i32 951, metadata !463}
!463 = metadata !{metadata !464}
!464 = metadata !{metadata !"act_reg.padding", metadata !465, metadata !"unsigned char", i32 0, i32 7}
!465 = metadata !{metadata !466}
!466 = metadata !{i32 70, i32 70, i32 2}
!467 = metadata !{i32 952, i32 959, metadata !468}
!468 = metadata !{metadata !469}
!469 = metadata !{metadata !"act_reg.padding", metadata !470, metadata !"unsigned char", i32 0, i32 7}
!470 = metadata !{metadata !471}
!471 = metadata !{i32 71, i32 71, i32 2}
!472 = metadata !{i32 960, i32 967, metadata !473}
!473 = metadata !{metadata !474}
!474 = metadata !{metadata !"act_reg.padding", metadata !475, metadata !"unsigned char", i32 0, i32 7}
!475 = metadata !{metadata !476}
!476 = metadata !{i32 72, i32 72, i32 2}
!477 = metadata !{i32 968, i32 975, metadata !478}
!478 = metadata !{metadata !479}
!479 = metadata !{metadata !"act_reg.padding", metadata !480, metadata !"unsigned char", i32 0, i32 7}
!480 = metadata !{metadata !481}
!481 = metadata !{i32 73, i32 73, i32 2}
!482 = metadata !{i32 976, i32 983, metadata !483}
!483 = metadata !{metadata !484}
!484 = metadata !{metadata !"act_reg.padding", metadata !485, metadata !"unsigned char", i32 0, i32 7}
!485 = metadata !{metadata !486}
!486 = metadata !{i32 74, i32 74, i32 2}
!487 = metadata !{i32 984, i32 991, metadata !488}
!488 = metadata !{metadata !489}
!489 = metadata !{metadata !"act_reg.padding", metadata !490, metadata !"unsigned char", i32 0, i32 7}
!490 = metadata !{metadata !491}
!491 = metadata !{i32 75, i32 75, i32 2}
!492 = metadata !{metadata !493, metadata !496}
!493 = metadata !{i32 0, i32 31, metadata !494}
!494 = metadata !{metadata !495}
!495 = metadata !{metadata !"Action_Config.action_type.V", metadata !60, metadata !"uint32", i32 0, i32 31}
!496 = metadata !{i32 32, i32 63, metadata !497}
!497 = metadata !{metadata !498}
!498 = metadata !{metadata !"Action_Config.release_level.V", metadata !60, metadata !"uint32", i32 0, i32 31}
