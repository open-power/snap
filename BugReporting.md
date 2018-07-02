# SNAP Framework Bug Reporting

For bugs, questions or requests for enhancements, please use Github issues: 
https://github.com/open-power/snap/issues

All issues should have one of the labels
* `bug`
* `question`
* `enhancement`

The default is normal priority. Add the `blocker` or `nice to have` labels for highest or lower priority.

After opening an issue, assign it to people to work on, preferrably a single person. 
Once the assigned person has reviewed the issue, they can assign the `in progress` label to show that they are working on the issue.
After fixing the issue, assign the `verify` label to indicate that the fix is ready for testing. Once testing completed successfully, the tester or originator of the issue close the issue again.
In some cases the issue may be rejected because it is `invalid`, a `duplicate` of another issue, or it was decided `wont fix`, and closed.


# SNAP Framework Bug Reporting Template

Please make sure to include sufficient information in the bug to understand and recreate it. 
* Detailed instructions how to recreate the issue
* Where applicable, also include 
  * The SNAP design or bitstream version
  * Git SHA ID
  * Name of the release and/or branch
  * Configuration used during make config, e.g. DDR3_USED=TRUE
  * The accelerated action used and its version
* In case of hardware issues, include
  * which FPGA card was used
  * the image name and where the tester can retrieve it
  * FPGA timing info, in particular negative slack
