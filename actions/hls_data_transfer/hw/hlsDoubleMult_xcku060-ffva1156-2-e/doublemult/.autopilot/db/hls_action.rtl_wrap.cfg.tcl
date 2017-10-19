set lang "C++"
set moduleName "hls_action"
set moduleIsExternC "0"
set rawDecl ""
set globalVariable ""
set PortList ""
set PortName0 "din_gmem"
set BitWidth0 "64"
set ArrayOpt0 ""
set Const0 "0"
set Volatile0 "0"
set Pointer0 "1"
set Reference0 "0"
set Dims0 [list 0]
set Interface0 "wire"
set DataType0 "[list ap_uint 512 ]"
set Port0 [list $PortName0 $Interface0 $DataType0 $Pointer0 $Dims0 $Const0 $Volatile0 $ArrayOpt0]
lappend PortList $Port0
set PortName1 "dout_gmem"
set BitWidth1 "64"
set ArrayOpt1 ""
set Const1 "0"
set Volatile1 "0"
set Pointer1 "1"
set Reference1 "0"
set Dims1 [list 0]
set Interface1 "wire"
set DataType1 "[list ap_uint 512 ]"
set Port1 [list $PortName1 $Interface1 $DataType1 $Pointer1 $Dims1 $Const1 $Volatile1 $ArrayOpt1]
lappend PortList $Port1
set PortName2 "act_reg"
set BitWidth2 "64"
set ArrayOpt2 ""
set Const2 "0"
set Volatile2 "0"
set Pointer2 "1"
set Reference2 "0"
set Dims2 [list 0]
set Interface2 "wire"
set structMem2 ""
set PortName20 "Control"
set BitWidth20 "128"
set ArrayOpt20 ""
set Const20 "0"
set Volatile20 "0"
set Pointer20 "0"
set Reference20 "0"
set Dims20 [list 0]
set Interface20 "wire"
set structMem20 ""
set PortName200 "sat"
set BitWidth200 "8"
set ArrayOpt200 ""
set Const200 "0"
set Volatile200 "0"
set Pointer200 "0"
set Reference200 "0"
set Dims200 [list 0]
set Interface200 "wire"
set DataType200 "[list ap_uint 8 ]"
set Port200 [list $PortName200 $Interface200 $DataType200 $Pointer200 $Dims200 $Const200 $Volatile200 $ArrayOpt200]
lappend structMem20 $Port200
set PortName201 "flags"
set BitWidth201 "8"
set ArrayOpt201 ""
set Const201 "0"
set Volatile201 "0"
set Pointer201 "0"
set Reference201 "0"
set Dims201 [list 0]
set Interface201 "wire"
set DataType201 "[list ap_uint 8 ]"
set Port201 [list $PortName201 $Interface201 $DataType201 $Pointer201 $Dims201 $Const201 $Volatile201 $ArrayOpt201]
lappend structMem20 $Port201
set PortName202 "seq"
set BitWidth202 "16"
set ArrayOpt202 ""
set Const202 "0"
set Volatile202 "0"
set Pointer202 "0"
set Reference202 "0"
set Dims202 [list 0]
set Interface202 "wire"
set DataType202 "[list ap_uint 16 ]"
set Port202 [list $PortName202 $Interface202 $DataType202 $Pointer202 $Dims202 $Const202 $Volatile202 $ArrayOpt202]
lappend structMem20 $Port202
set PortName203 "Retc"
set BitWidth203 "32"
set ArrayOpt203 ""
set Const203 "0"
set Volatile203 "0"
set Pointer203 "0"
set Reference203 "0"
set Dims203 [list 0]
set Interface203 "wire"
set DataType203 "[list ap_uint 32 ]"
set Port203 [list $PortName203 $Interface203 $DataType203 $Pointer203 $Dims203 $Const203 $Volatile203 $ArrayOpt203]
lappend structMem20 $Port203
set PortName204 "Reserved"
set BitWidth204 "64"
set ArrayOpt204 ""
set Const204 "0"
set Volatile204 "0"
set Pointer204 "0"
set Reference204 "0"
set Dims204 [list 0]
set Interface204 "wire"
set DataType204 "[list ap_uint 64 ]"
set Port204 [list $PortName204 $Interface204 $DataType204 $Pointer204 $Dims204 $Const204 $Volatile204 $ArrayOpt204]
lappend structMem20 $Port204
set structParameter20 [list ]
set structArgument20 [list ]
set NameSpace20 [list ]
set structIsPacked20 "0"
set DataType20 [list "CONTROL" "struct " $structMem20 0 0 $structParameter20 $structArgument20 $NameSpace20 $structIsPacked20]
set Port20 [list $PortName20 $Interface20 $DataType20 $Pointer20 $Dims20 $Const20 $Volatile20 $ArrayOpt20]
lappend structMem2 $Port20
set PortName21 "Data"
set BitWidth21 "256"
set ArrayOpt21 ""
set Const21 "0"
set Volatile21 "0"
set Pointer21 "0"
set Reference21 "0"
set Dims21 [list 0]
set Interface21 "wire"
set structMem21 ""
set PortName210 "in"
set BitWidth210 "128"
set ArrayOpt210 ""
set Const210 "0"
set Volatile210 "0"
set Pointer210 "0"
set Reference210 "0"
set Dims210 [list 0]
set Interface210 "wire"
set structMem210 ""
set PortName2100 "addr"
set BitWidth2100 "64"
set ArrayOpt2100 ""
set Const2100 "0"
set Volatile2100 "0"
set Pointer2100 "0"
set Reference2100 "0"
set Dims2100 [list 0]
set Interface2100 "wire"
set DataType2100 "long unsigned int"
set Port2100 [list $PortName2100 $Interface2100 $DataType2100 $Pointer2100 $Dims2100 $Const2100 $Volatile2100 $ArrayOpt2100]
lappend structMem210 $Port2100
set PortName2101 "size"
set BitWidth2101 "32"
set ArrayOpt2101 ""
set Const2101 "0"
set Volatile2101 "0"
set Pointer2101 "0"
set Reference2101 "0"
set Dims2101 [list 0]
set Interface2101 "wire"
set DataType2101 "unsigned int"
set Port2101 [list $PortName2101 $Interface2101 $DataType2101 $Pointer2101 $Dims2101 $Const2101 $Volatile2101 $ArrayOpt2101]
lappend structMem210 $Port2101
set PortName2102 "type"
set BitWidth2102 "16"
set ArrayOpt2102 ""
set Const2102 "0"
set Volatile2102 "0"
set Pointer2102 "0"
set Reference2102 "0"
set Dims2102 [list 0]
set Interface2102 "wire"
set DataType2102 "unsigned short"
set Port2102 [list $PortName2102 $Interface2102 $DataType2102 $Pointer2102 $Dims2102 $Const2102 $Volatile2102 $ArrayOpt2102]
lappend structMem210 $Port2102
set PortName2103 "flags"
set BitWidth2103 "16"
set ArrayOpt2103 ""
set Const2103 "0"
set Volatile2103 "0"
set Pointer2103 "0"
set Reference2103 "0"
set Dims2103 [list 0]
set Interface2103 "wire"
set DataType2103 "unsigned short"
set Port2103 [list $PortName2103 $Interface2103 $DataType2103 $Pointer2103 $Dims2103 $Const2103 $Volatile2103 $ArrayOpt2103]
lappend structMem210 $Port2103
set structParameter210 [list ]
set structArgument210 [list ]
set NameSpace210 [list ]
set structIsPacked210 "0"
set DataType210 [list "snap_addr" "struct snap_addr" $structMem210 1 0 $structParameter210 $structArgument210 $NameSpace210 $structIsPacked210]
set Port210 [list $PortName210 $Interface210 $DataType210 $Pointer210 $Dims210 $Const210 $Volatile210 $ArrayOpt210]
lappend structMem21 $Port210
set PortName211 "out"
set BitWidth211 "128"
set ArrayOpt211 ""
set Const211 "0"
set Volatile211 "0"
set Pointer211 "0"
set Reference211 "0"
set Dims211 [list 0]
set Interface211 "wire"
set structMem211 ""
set PortName2110 "addr"
set BitWidth2110 "64"
set ArrayOpt2110 ""
set Const2110 "0"
set Volatile2110 "0"
set Pointer2110 "0"
set Reference2110 "0"
set Dims2110 [list 0]
set Interface2110 "wire"
set DataType2110 "long unsigned int"
set Port2110 [list $PortName2110 $Interface2110 $DataType2110 $Pointer2110 $Dims2110 $Const2110 $Volatile2110 $ArrayOpt2110]
lappend structMem211 $Port2110
set PortName2111 "size"
set BitWidth2111 "32"
set ArrayOpt2111 ""
set Const2111 "0"
set Volatile2111 "0"
set Pointer2111 "0"
set Reference2111 "0"
set Dims2111 [list 0]
set Interface2111 "wire"
set DataType2111 "unsigned int"
set Port2111 [list $PortName2111 $Interface2111 $DataType2111 $Pointer2111 $Dims2111 $Const2111 $Volatile2111 $ArrayOpt2111]
lappend structMem211 $Port2111
set PortName2112 "type"
set BitWidth2112 "16"
set ArrayOpt2112 ""
set Const2112 "0"
set Volatile2112 "0"
set Pointer2112 "0"
set Reference2112 "0"
set Dims2112 [list 0]
set Interface2112 "wire"
set DataType2112 "unsigned short"
set Port2112 [list $PortName2112 $Interface2112 $DataType2112 $Pointer2112 $Dims2112 $Const2112 $Volatile2112 $ArrayOpt2112]
lappend structMem211 $Port2112
set PortName2113 "flags"
set BitWidth2113 "16"
set ArrayOpt2113 ""
set Const2113 "0"
set Volatile2113 "0"
set Pointer2113 "0"
set Reference2113 "0"
set Dims2113 [list 0]
set Interface2113 "wire"
set DataType2113 "unsigned short"
set Port2113 [list $PortName2113 $Interface2113 $DataType2113 $Pointer2113 $Dims2113 $Const2113 $Volatile2113 $ArrayOpt2113]
lappend structMem211 $Port2113
set structParameter211 [list ]
set structArgument211 [list ]
set NameSpace211 [list ]
set structIsPacked211 "0"
set DataType211 [list "snap_addr" "struct snap_addr" $structMem211 1 0 $structParameter211 $structArgument211 $NameSpace211 $structIsPacked211]
set Port211 [list $PortName211 $Interface211 $DataType211 $Pointer211 $Dims211 $Const211 $Volatile211 $ArrayOpt211]
lappend structMem21 $Port211
set structParameter21 [list ]
set structArgument21 [list ]
set NameSpace21 [list ]
set structIsPacked21 "0"
set DataType21 [list "doublemult_job_t" "struct doublemult_job" $structMem21 0 0 $structParameter21 $structArgument21 $NameSpace21 $structIsPacked21]
set Port21 [list $PortName21 $Interface21 $DataType21 $Pointer21 $Dims21 $Const21 $Volatile21 $ArrayOpt21]
lappend structMem2 $Port21
set PortName22 "padding"
set BitWidth22 "608"
set ArrayOpt22 ""
set Const22 "0"
set Volatile22 "0"
set Pointer22 "0"
set Reference22 "0"
set Dims22 [list  76]
set Interface22 "wire"
set DataType22 "unsigned char"
set Port22 [list $PortName22 $Interface22 $DataType22 $Pointer22 $Dims22 $Const22 $Volatile22 $ArrayOpt22]
lappend structMem2 $Port22
set structParameter2 [list ]
set structArgument2 [list ]
set NameSpace2 [list ]
set structIsPacked2 "0"
set DataType2 [list "action_reg" "struct " $structMem2 0 0 $structParameter2 $structArgument2 $NameSpace2 $structIsPacked2]
set Port2 [list $PortName2 $Interface2 $DataType2 $Pointer2 $Dims2 $Const2 $Volatile2 $ArrayOpt2]
lappend PortList $Port2
set PortName3 "Action_Config"
set BitWidth3 "64"
set ArrayOpt3 ""
set Const3 "0"
set Volatile3 "0"
set Pointer3 "1"
set Reference3 "0"
set Dims3 [list 0]
set Interface3 "wire"
set structMem3 ""
set PortName30 "action_type"
set BitWidth30 "32"
set ArrayOpt30 ""
set Const30 "0"
set Volatile30 "0"
set Pointer30 "0"
set Reference30 "0"
set Dims30 [list 0]
set Interface30 "wire"
set DataType30 "[list ap_uint 32 ]"
set Port30 [list $PortName30 $Interface30 $DataType30 $Pointer30 $Dims30 $Const30 $Volatile30 $ArrayOpt30]
lappend structMem3 $Port30
set PortName31 "release_level"
set BitWidth31 "32"
set ArrayOpt31 ""
set Const31 "0"
set Volatile31 "0"
set Pointer31 "0"
set Reference31 "0"
set Dims31 [list 0]
set Interface31 "wire"
set DataType31 "[list ap_uint 32 ]"
set Port31 [list $PortName31 $Interface31 $DataType31 $Pointer31 $Dims31 $Const31 $Volatile31 $ArrayOpt31]
lappend structMem3 $Port31
set structParameter3 [list ]
set structArgument3 [list ]
set NameSpace3 [list ]
set structIsPacked3 "0"
set DataType3 [list "action_RO_config_reg" "struct " $structMem3 0 0 $structParameter3 $structArgument3 $NameSpace3 $structIsPacked3]
set Port3 [list $PortName3 $Interface3 $DataType3 $Pointer3 $Dims3 $Const3 $Volatile3 $ArrayOpt3]
lappend PortList $Port3
set globalAPint "" 
set returnAPInt "" 
set hasCPPAPInt 1 
set argAPInt "" 
set hasCPPAPFix 0 
set hasSCFix 0 
set hasCBool 0 
set hasCPPComplex 0 
set isTemplateTop 0
set hasHalf 0 
set dataPackList ""
set module [list $moduleName $PortList $rawDecl $argAPInt $returnAPInt $dataPackList]
