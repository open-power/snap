set C_TypeInfoList {{ 
"hls_action" : [[], { "return": [[], "void"]} , [{"ExternC" : 0}], [ {"din_gmem": [[],{ "pointer": "0"}] }, {"dout_gmem": [[],{ "pointer": "0"}] }, {"act_reg": [[],{ "pointer": "1"}] }, {"Action_Config": [[],{ "pointer": "2"}] }],[],""], 
"0": [ "snap_membus_t", {"typedef": [[[],"3"],""]}], 
"3": [ "ap_uint<512>", {"hls_type": {"ap_uint": [[[[], {"scalar": { "int": 512}}]],""]}}], 
"1": [ "action_reg", {"typedef": [[[],"4"],""]}], 
"4": [ "", {"struct": [[],[],[{ "Control": [[128], "5"]},{ "Data": [[256], "6"]},{ "padding": [[],  {"array": ["7", [76]]}]}],""]}], 
"5": [ "CONTROL", {"typedef": [[[],"8"],""]}], 
"8": [ "", {"struct": [[],[],[{ "sat": [[8], "9"]},{ "flags": [[8], "9"]},{ "seq": [[16], "10"]},{ "Retc": [[32], "11"]},{ "Reserved": [[64], "12"]}],""]}], 
"10": [ "snapu16_t", {"typedef": [[[],"13"],""]}], 
"13": [ "ap_uint<16>", {"hls_type": {"ap_uint": [[[[], {"scalar": { "int": 16}}]],""]}}], 
"2": [ "action_RO_config_reg", {"typedef": [[[],"14"],""]}], 
"14": [ "", {"struct": [[],[],[{ "action_type": [[32], "11"]},{ "release_level": [[32], "11"]}],""]}], 
"6": [ "doublemult_job_t", {"typedef": [[[],"15"],""]}], 
"15": [ "doublemult_job", {"struct": [[],[],[{ "in": [[], "16"]},{ "out": [[], "16"]}],""]}], 
"11": [ "snapu32_t", {"typedef": [[[],"17"],""]}], 
"17": [ "ap_uint<32>", {"hls_type": {"ap_uint": [[[[], {"scalar": { "int": 32}}]],""]}}], 
"12": [ "snapu64_t", {"typedef": [[[],"18"],""]}], 
"18": [ "ap_uint<64>", {"hls_type": {"ap_uint": [[[[], {"scalar": { "int": 64}}]],""]}}], 
"7": [ "uint8_t", {"typedef": [[[], {"scalar": "unsigned char"}],""]}], 
"16": [ "snap_addr", {"struct": [[],[],[{ "addr": [[64], "19"]},{ "size": [[32], "20"]},{ "type": [[16], "21"]},{ "flags": [[16], "22"]}],""]}], 
"19": [ "uint64_t", {"typedef": [[[], {"scalar": "long unsigned int"}],""]}], 
"20": [ "uint32_t", {"typedef": [[[], {"scalar": "unsigned int"}],""]}], 
"9": [ "snapu8_t", {"typedef": [[[],"23"],""]}], 
"23": [ "ap_uint<8>", {"hls_type": {"ap_uint": [[[[], {"scalar": { "int": 8}}]],""]}}], 
"21": [ "snap_addrtype_t", {"typedef": [[[],"24"],""]}], 
"24": [ "uint16_t", {"typedef": [[[], {"scalar": "unsigned short"}],""]}], 
"22": [ "snap_addrflag_t", {"typedef": [[[],"24"],""]}]
}}
set moduleName hls_action
set isCombinational 0
set isDatapathOnly 0
set isPipelined 0
set pipeline_type none
set FunctionProtocol ap_ctrl_hs
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set C_modelName {hls_action}
set C_modelType { void 0 }
set C_modelArgList {
	{ host_mem int 512 regular {axi_master 2}  }
	{ din_gmem_V int 64 regular {axi_slave 0}  }
	{ dout_gmem_V int 64 regular {axi_slave 0}  }
	{ act_reg int 992 regular {axi_slave 2}  }
	{ Action_Config int 64 regular {axi_slave 1}  }
}
set C_modelArgMapList {[ 
	{ "Name" : "host_mem", "interface" : "axi_master", "bitwidth" : 512, "direction" : "READWRITE", "bitSlice":[{"low":0,"up":511,"cElement": [{"cName": "din_gmem.V","cData": "uint512","bit_use": { "low": 0,"up": 511},"offset": { "type": "dynamic","port_name": "din_gmem_V","bundle": "ctrl_reg"},"direction": "READONLY","cArray": [{"low" : 0,"up" : 511,"step" : 1}]},{"cName": "dout_gmem.V","cData": "uint512","bit_use": { "low": 0,"up": 511},"offset": { "type": "dynamic","port_name": "dout_gmem_V","bundle": "ctrl_reg"},"direction": "WRITEONLY","cArray": [{"low" : 0,"up" : 511,"step" : 1}]}]}]} , 
 	{ "Name" : "din_gmem_V", "interface" : "axi_slave", "bundle":"ctrl_reg","type":"ap_none","bitwidth" : 64, "direction" : "READONLY", "offset" : {"in":48}, "offset_end" : {"in":59}} , 
 	{ "Name" : "dout_gmem_V", "interface" : "axi_slave", "bundle":"ctrl_reg","type":"ap_none","bitwidth" : 64, "direction" : "READONLY", "offset" : {"in":64}, "offset_end" : {"in":75}} , 
 	{ "Name" : "act_reg", "interface" : "axi_slave", "bundle":"ctrl_reg","type":"ap_ovld","bitwidth" : 992, "direction" : "READWRITE", "bitSlice":[{"low":0,"up":7,"cElement": [{"cName": "act_reg.Control.sat.V","cData": "uint8","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":8,"up":15,"cElement": [{"cName": "act_reg.Control.flags.V","cData": "uint8","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":16,"up":31,"cElement": [{"cName": "act_reg.Control.seq.V","cData": "uint16","bit_use": { "low": 0,"up": 15},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":32,"up":63,"cElement": [{"cName": "act_reg.Control.Retc.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":64,"up":127,"cElement": [{"cName": "act_reg.Control.Reserved.V","cData": "uint64","bit_use": { "low": 0,"up": 63},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":128,"up":191,"cElement": [{"cName": "act_reg.Data.in.addr","cData": "long unsigned int","bit_use": { "low": 0,"up": 63},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":192,"up":223,"cElement": [{"cName": "act_reg.Data.in.size","cData": "unsigned int","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":224,"up":239,"cElement": [{"cName": "act_reg.Data.in.type","cData": "unsigned short","bit_use": { "low": 0,"up": 15},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":240,"up":255,"cElement": [{"cName": "act_reg.Data.in.flags","cData": "unsigned short","bit_use": { "low": 0,"up": 15},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":256,"up":319,"cElement": [{"cName": "act_reg.Data.out.addr","cData": "long unsigned int","bit_use": { "low": 0,"up": 63},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":320,"up":351,"cElement": [{"cName": "act_reg.Data.out.size","cData": "unsigned int","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":352,"up":367,"cElement": [{"cName": "act_reg.Data.out.type","cData": "unsigned short","bit_use": { "low": 0,"up": 15},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":368,"up":383,"cElement": [{"cName": "act_reg.Data.out.flags","cData": "unsigned short","bit_use": { "low": 0,"up": 15},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":384,"up":391,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 0,"up" : 0,"step" : 2}]}]},{"low":392,"up":399,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 1,"up" : 1,"step" : 2}]}]},{"low":400,"up":407,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 2,"up" : 2,"step" : 2}]}]},{"low":408,"up":415,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 3,"up" : 3,"step" : 2}]}]},{"low":416,"up":423,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 4,"up" : 4,"step" : 2}]}]},{"low":424,"up":431,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 5,"up" : 5,"step" : 2}]}]},{"low":432,"up":439,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 6,"up" : 6,"step" : 2}]}]},{"low":440,"up":447,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 7,"up" : 7,"step" : 2}]}]},{"low":448,"up":455,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 8,"up" : 8,"step" : 2}]}]},{"low":456,"up":463,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 9,"up" : 9,"step" : 2}]}]},{"low":464,"up":471,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 10,"up" : 10,"step" : 2}]}]},{"low":472,"up":479,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 11,"up" : 11,"step" : 2}]}]},{"low":480,"up":487,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 12,"up" : 12,"step" : 2}]}]},{"low":488,"up":495,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 13,"up" : 13,"step" : 2}]}]},{"low":496,"up":503,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 14,"up" : 14,"step" : 2}]}]},{"low":504,"up":511,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 15,"up" : 15,"step" : 2}]}]},{"low":512,"up":519,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 16,"up" : 16,"step" : 2}]}]},{"low":520,"up":527,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 17,"up" : 17,"step" : 2}]}]},{"low":528,"up":535,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 18,"up" : 18,"step" : 2}]}]},{"low":536,"up":543,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 19,"up" : 19,"step" : 2}]}]},{"low":544,"up":551,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 20,"up" : 20,"step" : 2}]}]},{"low":552,"up":559,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 21,"up" : 21,"step" : 2}]}]},{"low":560,"up":567,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 22,"up" : 22,"step" : 2}]}]},{"low":568,"up":575,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 23,"up" : 23,"step" : 2}]}]},{"low":576,"up":583,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 24,"up" : 24,"step" : 2}]}]},{"low":584,"up":591,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 25,"up" : 25,"step" : 2}]}]},{"low":592,"up":599,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 26,"up" : 26,"step" : 2}]}]},{"low":600,"up":607,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 27,"up" : 27,"step" : 2}]}]},{"low":608,"up":615,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 28,"up" : 28,"step" : 2}]}]},{"low":616,"up":623,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 29,"up" : 29,"step" : 2}]}]},{"low":624,"up":631,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 30,"up" : 30,"step" : 2}]}]},{"low":632,"up":639,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 31,"up" : 31,"step" : 2}]}]},{"low":640,"up":647,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 32,"up" : 32,"step" : 2}]}]},{"low":648,"up":655,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 33,"up" : 33,"step" : 2}]}]},{"low":656,"up":663,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 34,"up" : 34,"step" : 2}]}]},{"low":664,"up":671,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 35,"up" : 35,"step" : 2}]}]},{"low":672,"up":679,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 36,"up" : 36,"step" : 2}]}]},{"low":680,"up":687,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 37,"up" : 37,"step" : 2}]}]},{"low":688,"up":695,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 38,"up" : 38,"step" : 2}]}]},{"low":696,"up":703,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 39,"up" : 39,"step" : 2}]}]},{"low":704,"up":711,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 40,"up" : 40,"step" : 2}]}]},{"low":712,"up":719,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 41,"up" : 41,"step" : 2}]}]},{"low":720,"up":727,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 42,"up" : 42,"step" : 2}]}]},{"low":728,"up":735,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 43,"up" : 43,"step" : 2}]}]},{"low":736,"up":743,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 44,"up" : 44,"step" : 2}]}]},{"low":744,"up":751,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 45,"up" : 45,"step" : 2}]}]},{"low":752,"up":759,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 46,"up" : 46,"step" : 2}]}]},{"low":760,"up":767,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 47,"up" : 47,"step" : 2}]}]},{"low":768,"up":775,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 48,"up" : 48,"step" : 2}]}]},{"low":776,"up":783,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 49,"up" : 49,"step" : 2}]}]},{"low":784,"up":791,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 50,"up" : 50,"step" : 2}]}]},{"low":792,"up":799,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 51,"up" : 51,"step" : 2}]}]},{"low":800,"up":807,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 52,"up" : 52,"step" : 2}]}]},{"low":808,"up":815,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 53,"up" : 53,"step" : 2}]}]},{"low":816,"up":823,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 54,"up" : 54,"step" : 2}]}]},{"low":824,"up":831,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 55,"up" : 55,"step" : 2}]}]},{"low":832,"up":839,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 56,"up" : 56,"step" : 2}]}]},{"low":840,"up":847,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 57,"up" : 57,"step" : 2}]}]},{"low":848,"up":855,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 58,"up" : 58,"step" : 2}]}]},{"low":856,"up":863,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 59,"up" : 59,"step" : 2}]}]},{"low":864,"up":871,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 60,"up" : 60,"step" : 2}]}]},{"low":872,"up":879,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 61,"up" : 61,"step" : 2}]}]},{"low":880,"up":887,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 62,"up" : 62,"step" : 2}]}]},{"low":888,"up":895,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 63,"up" : 63,"step" : 2}]}]},{"low":896,"up":903,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 64,"up" : 64,"step" : 2}]}]},{"low":904,"up":911,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 65,"up" : 65,"step" : 2}]}]},{"low":912,"up":919,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 66,"up" : 66,"step" : 2}]}]},{"low":920,"up":927,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 67,"up" : 67,"step" : 2}]}]},{"low":928,"up":935,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 68,"up" : 68,"step" : 2}]}]},{"low":936,"up":943,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 69,"up" : 69,"step" : 2}]}]},{"low":944,"up":951,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 70,"up" : 70,"step" : 2}]}]},{"low":952,"up":959,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 71,"up" : 71,"step" : 2}]}]},{"low":960,"up":967,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 72,"up" : 72,"step" : 2}]}]},{"low":968,"up":975,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 73,"up" : 73,"step" : 2}]}]},{"low":976,"up":983,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 74,"up" : 74,"step" : 2}]}]},{"low":984,"up":991,"cElement": [{"cName": "act_reg.padding","cData": "unsigned char","bit_use": { "low": 0,"up": 7},"cArray": [{"low" : 75,"up" : 75,"step" : 2}]}]}], "offset" : {"in":256, "out":384}, "offset_end" : {"in":383, "out":511}} , 
 	{ "Name" : "Action_Config", "interface" : "axi_slave", "bundle":"ctrl_reg","type":"ap_vld","bitwidth" : 64, "direction" : "WRITEONLY", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "Action_Config.action_type.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]},{"low":32,"up":63,"cElement": [{"cName": "Action_Config.release_level.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]}], "offset" : {"out":16}, "offset_end" : {"out":27}} ]}
# RTL Port declarations: 
set portNum 65
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst_n sc_in sc_logic 1 reset -1 active_low_sync } 
	{ m_axi_host_mem_AWVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_host_mem_AWREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_host_mem_AWADDR sc_out sc_lv 64 signal 0 } 
	{ m_axi_host_mem_AWID sc_out sc_lv 1 signal 0 } 
	{ m_axi_host_mem_AWLEN sc_out sc_lv 8 signal 0 } 
	{ m_axi_host_mem_AWSIZE sc_out sc_lv 3 signal 0 } 
	{ m_axi_host_mem_AWBURST sc_out sc_lv 2 signal 0 } 
	{ m_axi_host_mem_AWLOCK sc_out sc_lv 2 signal 0 } 
	{ m_axi_host_mem_AWCACHE sc_out sc_lv 4 signal 0 } 
	{ m_axi_host_mem_AWPROT sc_out sc_lv 3 signal 0 } 
	{ m_axi_host_mem_AWQOS sc_out sc_lv 4 signal 0 } 
	{ m_axi_host_mem_AWREGION sc_out sc_lv 4 signal 0 } 
	{ m_axi_host_mem_AWUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_host_mem_WVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_host_mem_WREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_host_mem_WDATA sc_out sc_lv 512 signal 0 } 
	{ m_axi_host_mem_WSTRB sc_out sc_lv 64 signal 0 } 
	{ m_axi_host_mem_WLAST sc_out sc_logic 1 signal 0 } 
	{ m_axi_host_mem_WID sc_out sc_lv 1 signal 0 } 
	{ m_axi_host_mem_WUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_host_mem_ARVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_host_mem_ARREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_host_mem_ARADDR sc_out sc_lv 64 signal 0 } 
	{ m_axi_host_mem_ARID sc_out sc_lv 1 signal 0 } 
	{ m_axi_host_mem_ARLEN sc_out sc_lv 8 signal 0 } 
	{ m_axi_host_mem_ARSIZE sc_out sc_lv 3 signal 0 } 
	{ m_axi_host_mem_ARBURST sc_out sc_lv 2 signal 0 } 
	{ m_axi_host_mem_ARLOCK sc_out sc_lv 2 signal 0 } 
	{ m_axi_host_mem_ARCACHE sc_out sc_lv 4 signal 0 } 
	{ m_axi_host_mem_ARPROT sc_out sc_lv 3 signal 0 } 
	{ m_axi_host_mem_ARQOS sc_out sc_lv 4 signal 0 } 
	{ m_axi_host_mem_ARREGION sc_out sc_lv 4 signal 0 } 
	{ m_axi_host_mem_ARUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_host_mem_RVALID sc_in sc_logic 1 signal 0 } 
	{ m_axi_host_mem_RREADY sc_out sc_logic 1 signal 0 } 
	{ m_axi_host_mem_RDATA sc_in sc_lv 512 signal 0 } 
	{ m_axi_host_mem_RLAST sc_in sc_logic 1 signal 0 } 
	{ m_axi_host_mem_RID sc_in sc_lv 1 signal 0 } 
	{ m_axi_host_mem_RUSER sc_in sc_lv 1 signal 0 } 
	{ m_axi_host_mem_RRESP sc_in sc_lv 2 signal 0 } 
	{ m_axi_host_mem_BVALID sc_in sc_logic 1 signal 0 } 
	{ m_axi_host_mem_BREADY sc_out sc_logic 1 signal 0 } 
	{ m_axi_host_mem_BRESP sc_in sc_lv 2 signal 0 } 
	{ m_axi_host_mem_BID sc_in sc_lv 1 signal 0 } 
	{ m_axi_host_mem_BUSER sc_in sc_lv 1 signal 0 } 
	{ s_axi_ctrl_reg_AWVALID sc_in sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_AWREADY sc_out sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_AWADDR sc_in sc_lv 9 signal -1 } 
	{ s_axi_ctrl_reg_WVALID sc_in sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_WREADY sc_out sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_WDATA sc_in sc_lv 32 signal -1 } 
	{ s_axi_ctrl_reg_WSTRB sc_in sc_lv 4 signal -1 } 
	{ s_axi_ctrl_reg_ARVALID sc_in sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_ARREADY sc_out sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_ARADDR sc_in sc_lv 9 signal -1 } 
	{ s_axi_ctrl_reg_RVALID sc_out sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_RREADY sc_in sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_RDATA sc_out sc_lv 32 signal -1 } 
	{ s_axi_ctrl_reg_RRESP sc_out sc_lv 2 signal -1 } 
	{ s_axi_ctrl_reg_BVALID sc_out sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_BREADY sc_in sc_logic 1 signal -1 } 
	{ s_axi_ctrl_reg_BRESP sc_out sc_lv 2 signal -1 } 
	{ interrupt sc_out sc_logic 1 signal -1 } 
}
set NewPortList {[ 
	{ "name": "s_axi_ctrl_reg_AWADDR", "direction": "in", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "AWADDR" },"address":[{"name":"hls_action","role":"start","value":"0","valid_bit":"0"},{"name":"hls_action","role":"continue","value":"0","valid_bit":"4"},{"name":"hls_action","role":"auto_start","value":"0","valid_bit":"7"},{"name":"din_gmem_V","role":"data","value":"48"},{"name":"dout_gmem_V","role":"data","value":"64"},{"name":"act_reg","role":"data","value":"256"}] },
	{ "name": "s_axi_ctrl_reg_AWVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "AWVALID" } },
	{ "name": "s_axi_ctrl_reg_AWREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "AWREADY" } },
	{ "name": "s_axi_ctrl_reg_WVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "WVALID" } },
	{ "name": "s_axi_ctrl_reg_WREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "WREADY" } },
	{ "name": "s_axi_ctrl_reg_WDATA", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "WDATA" } },
	{ "name": "s_axi_ctrl_reg_WSTRB", "direction": "in", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "WSTRB" } },
	{ "name": "s_axi_ctrl_reg_ARADDR", "direction": "in", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "ARADDR" },"address":[{"name":"hls_action","role":"start","value":"0","valid_bit":"0"},{"name":"hls_action","role":"done","value":"0","valid_bit":"1"},{"name":"hls_action","role":"idle","value":"0","valid_bit":"2"},{"name":"hls_action","role":"ready","value":"0","valid_bit":"3"},{"name":"hls_action","role":"auto_start","value":"0","valid_bit":"7"},{"name":"Action_Config","role":"data","value":"16"}, {"name":"Action_Config","role":"valid","value":"24","valid_bit":"0"},{"name":"act_reg","role":"data","value":"384"}, {"name":"act_reg","role":"valid","value":"508","valid_bit":"0"}] },
	{ "name": "s_axi_ctrl_reg_ARVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "ARVALID" } },
	{ "name": "s_axi_ctrl_reg_ARREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "ARREADY" } },
	{ "name": "s_axi_ctrl_reg_RVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "RVALID" } },
	{ "name": "s_axi_ctrl_reg_RREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "RREADY" } },
	{ "name": "s_axi_ctrl_reg_RDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "RDATA" } },
	{ "name": "s_axi_ctrl_reg_RRESP", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "RRESP" } },
	{ "name": "s_axi_ctrl_reg_BVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "BVALID" } },
	{ "name": "s_axi_ctrl_reg_BREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "BREADY" } },
	{ "name": "s_axi_ctrl_reg_BRESP", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "BRESP" } },
	{ "name": "interrupt", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "ctrl_reg", "role": "interrupt" } }, 
 	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst_n", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst_n", "role": "default" }} , 
 	{ "name": "m_axi_host_mem_AWVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "AWVALID" }} , 
 	{ "name": "m_axi_host_mem_AWREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "AWREADY" }} , 
 	{ "name": "m_axi_host_mem_AWADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "host_mem", "role": "AWADDR" }} , 
 	{ "name": "m_axi_host_mem_AWID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "AWID" }} , 
 	{ "name": "m_axi_host_mem_AWLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "host_mem", "role": "AWLEN" }} , 
 	{ "name": "m_axi_host_mem_AWSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "host_mem", "role": "AWSIZE" }} , 
 	{ "name": "m_axi_host_mem_AWBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "host_mem", "role": "AWBURST" }} , 
 	{ "name": "m_axi_host_mem_AWLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "host_mem", "role": "AWLOCK" }} , 
 	{ "name": "m_axi_host_mem_AWCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "host_mem", "role": "AWCACHE" }} , 
 	{ "name": "m_axi_host_mem_AWPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "host_mem", "role": "AWPROT" }} , 
 	{ "name": "m_axi_host_mem_AWQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "host_mem", "role": "AWQOS" }} , 
 	{ "name": "m_axi_host_mem_AWREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "host_mem", "role": "AWREGION" }} , 
 	{ "name": "m_axi_host_mem_AWUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "AWUSER" }} , 
 	{ "name": "m_axi_host_mem_WVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "WVALID" }} , 
 	{ "name": "m_axi_host_mem_WREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "WREADY" }} , 
 	{ "name": "m_axi_host_mem_WDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":512, "type": "signal", "bundle":{"name": "host_mem", "role": "WDATA" }} , 
 	{ "name": "m_axi_host_mem_WSTRB", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "host_mem", "role": "WSTRB" }} , 
 	{ "name": "m_axi_host_mem_WLAST", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "WLAST" }} , 
 	{ "name": "m_axi_host_mem_WID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "WID" }} , 
 	{ "name": "m_axi_host_mem_WUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "WUSER" }} , 
 	{ "name": "m_axi_host_mem_ARVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "ARVALID" }} , 
 	{ "name": "m_axi_host_mem_ARREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "ARREADY" }} , 
 	{ "name": "m_axi_host_mem_ARADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "host_mem", "role": "ARADDR" }} , 
 	{ "name": "m_axi_host_mem_ARID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "ARID" }} , 
 	{ "name": "m_axi_host_mem_ARLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "host_mem", "role": "ARLEN" }} , 
 	{ "name": "m_axi_host_mem_ARSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "host_mem", "role": "ARSIZE" }} , 
 	{ "name": "m_axi_host_mem_ARBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "host_mem", "role": "ARBURST" }} , 
 	{ "name": "m_axi_host_mem_ARLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "host_mem", "role": "ARLOCK" }} , 
 	{ "name": "m_axi_host_mem_ARCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "host_mem", "role": "ARCACHE" }} , 
 	{ "name": "m_axi_host_mem_ARPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "host_mem", "role": "ARPROT" }} , 
 	{ "name": "m_axi_host_mem_ARQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "host_mem", "role": "ARQOS" }} , 
 	{ "name": "m_axi_host_mem_ARREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "host_mem", "role": "ARREGION" }} , 
 	{ "name": "m_axi_host_mem_ARUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "ARUSER" }} , 
 	{ "name": "m_axi_host_mem_RVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "RVALID" }} , 
 	{ "name": "m_axi_host_mem_RREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "RREADY" }} , 
 	{ "name": "m_axi_host_mem_RDATA", "direction": "in", "datatype": "sc_lv", "bitwidth":512, "type": "signal", "bundle":{"name": "host_mem", "role": "RDATA" }} , 
 	{ "name": "m_axi_host_mem_RLAST", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "RLAST" }} , 
 	{ "name": "m_axi_host_mem_RID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "RID" }} , 
 	{ "name": "m_axi_host_mem_RUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "RUSER" }} , 
 	{ "name": "m_axi_host_mem_RRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "host_mem", "role": "RRESP" }} , 
 	{ "name": "m_axi_host_mem_BVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "BVALID" }} , 
 	{ "name": "m_axi_host_mem_BREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "BREADY" }} , 
 	{ "name": "m_axi_host_mem_BRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "host_mem", "role": "BRESP" }} , 
 	{ "name": "m_axi_host_mem_BID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "BID" }} , 
 	{ "name": "m_axi_host_mem_BUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "host_mem", "role": "BUSER" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3"],
		"CDFG" : "hls_action",
		"VariableLatency" : "1",
		"AlignedPipeline" : "0",
		"UnalignedPipeline" : "0",
		"ProcessNetwork" : "0",
		"Combinational" : "0",
		"ControlExist" : "1",
		"Port" : [
		{"Name" : "host_mem", "Type" : "MAXI", "Direction" : "IO",
			"SubConnect" : [
			{"ID" : "3", "SubInstance" : "grp_process_action_fu_138", "Port" : "din_gmem_V"}]},
		{"Name" : "din_gmem_V", "Type" : "None", "Direction" : "I"},
		{"Name" : "dout_gmem_V", "Type" : "None", "Direction" : "I"},
		{"Name" : "act_reg", "Type" : "OVld", "Direction" : "IO"},
		{"Name" : "Action_Config", "Type" : "Vld", "Direction" : "O"}],
		"WaitState" : [
		{"State" : "ap_ST_fsm_state2", "FSM" : "ap_CS_fsm", "SubInstance" : "grp_process_action_fu_138"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.hls_action_ctrl_reg_s_axi_U", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.hls_action_host_mem_m_axi_U", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.grp_process_action_fu_138", "Parent" : "0", "Child" : ["4"],
		"CDFG" : "process_action",
		"VariableLatency" : "1",
		"AlignedPipeline" : "0",
		"UnalignedPipeline" : "0",
		"ProcessNetwork" : "0",
		"Combinational" : "0",
		"ControlExist" : "1",
		"Port" : [
		{"Name" : "din_gmem_V", "Type" : "MAXI", "Direction" : "IO",
			"BlockSignal" : [
			{"Name" : "din_gmem_V_blk_n_AR", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_R", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_AW", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_W", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_B", "Type" : "RtlSignal"}]},
		{"Name" : "din_gmem_V1", "Type" : "None", "Direction" : "I"},
		{"Name" : "dout_gmem_V3", "Type" : "None", "Direction" : "I"},
		{"Name" : "act_reg_Data_in_addr", "Type" : "None", "Direction" : "I"},
		{"Name" : "act_reg_Data_in_size", "Type" : "None", "Direction" : "I"},
		{"Name" : "act_reg_Data_out_add", "Type" : "None", "Direction" : "I"}]},
	{"ID" : "4", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_process_action_fu_138.hls_action_dmul_6bkb_U1", "Parent" : "3"}]}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "1", "Max" : "35"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "36"}
]}

set Spec2ImplPortList { 
	host_mem { m_axi {  { m_axi_host_mem_AWVALID VALID 1 1 }  { m_axi_host_mem_AWREADY READY 0 1 }  { m_axi_host_mem_AWADDR ADDR 1 64 }  { m_axi_host_mem_AWID ID 1 1 }  { m_axi_host_mem_AWLEN LEN 1 8 }  { m_axi_host_mem_AWSIZE SIZE 1 3 }  { m_axi_host_mem_AWBURST BURST 1 2 }  { m_axi_host_mem_AWLOCK LOCK 1 2 }  { m_axi_host_mem_AWCACHE CACHE 1 4 }  { m_axi_host_mem_AWPROT PROT 1 3 }  { m_axi_host_mem_AWQOS QOS 1 4 }  { m_axi_host_mem_AWREGION REGION 1 4 }  { m_axi_host_mem_AWUSER USER 1 1 }  { m_axi_host_mem_WVALID VALID 1 1 }  { m_axi_host_mem_WREADY READY 0 1 }  { m_axi_host_mem_WDATA DATA 1 512 }  { m_axi_host_mem_WSTRB STRB 1 64 }  { m_axi_host_mem_WLAST LAST 1 1 }  { m_axi_host_mem_WID ID 1 1 }  { m_axi_host_mem_WUSER USER 1 1 }  { m_axi_host_mem_ARVALID VALID 1 1 }  { m_axi_host_mem_ARREADY READY 0 1 }  { m_axi_host_mem_ARADDR ADDR 1 64 }  { m_axi_host_mem_ARID ID 1 1 }  { m_axi_host_mem_ARLEN LEN 1 8 }  { m_axi_host_mem_ARSIZE SIZE 1 3 }  { m_axi_host_mem_ARBURST BURST 1 2 }  { m_axi_host_mem_ARLOCK LOCK 1 2 }  { m_axi_host_mem_ARCACHE CACHE 1 4 }  { m_axi_host_mem_ARPROT PROT 1 3 }  { m_axi_host_mem_ARQOS QOS 1 4 }  { m_axi_host_mem_ARREGION REGION 1 4 }  { m_axi_host_mem_ARUSER USER 1 1 }  { m_axi_host_mem_RVALID VALID 0 1 }  { m_axi_host_mem_RREADY READY 1 1 }  { m_axi_host_mem_RDATA DATA 0 512 }  { m_axi_host_mem_RLAST LAST 0 1 }  { m_axi_host_mem_RID ID 0 1 }  { m_axi_host_mem_RUSER USER 0 1 }  { m_axi_host_mem_RRESP RESP 0 2 }  { m_axi_host_mem_BVALID VALID 0 1 }  { m_axi_host_mem_BREADY READY 1 1 }  { m_axi_host_mem_BRESP RESP 0 2 }  { m_axi_host_mem_BID ID 0 1 }  { m_axi_host_mem_BUSER USER 0 1 } } }
}

set busDeadlockParameterList { 
	{ host_mem { NUM_READ_OUTSTANDING 16 NUM_WRITE_OUTSTANDING 16 MAX_READ_BURST_LENGTH 64 MAX_WRITE_BURST_LENGTH 64 } } \
}

# RTL port scheduling information:
set fifoSchedulingInfoList { 
}

# RTL bus port read request latency information:
set busReadReqLatencyList { 
	{ host_mem 1 }
}

# RTL bus port write response latency information:
set busWriteResLatencyList { 
	{ host_mem 1 }
}

# RTL array port load latency information:
set memoryLoadLatencyList { 
}
