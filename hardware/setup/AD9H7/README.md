# Add family support to PSL9 ZIP package:

9H7 cards contains VU37P with an HBM.
Note : 
capi-flash mecanism is not working yet, so only JTAG programmation is available for this card
Factory / user switching mecanism is not working yet

The following URL defines how to get the PSL 
[image-and-model-build](../../../hardware/README.md#power9)

However current PSL9 ZIP package doesn't contain the new HBM library reference.

Until a new file is provided, it is possible to add this library reference manually with the following procedure :


Unzip the package, do the modifications, and zip
them back again.

$ unzip ibm.com_CAPI_PSL9_WRAP_2.00.zip

(modify component.xml to add new a new FPGA family "virtexuplushbm", search "supportedFamilies")

$ zip -r ibm.com_CAPI_PSL9_WRAP_2.01.zip component.xml src/ xgui/

$ rm -fr component.xml src/ xgui/
