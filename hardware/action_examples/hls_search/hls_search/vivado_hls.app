<project xmlns="com.autoesl.autopilot.project" top="hls_action" name="hls_search">
    <files>
        <file name="hls_search.cpp" sc="0" tb="false" cflags="-I../include -I../../../software/include -I../../../software/examples"/>
        <file name="../../hls_search.cpp" sc="0" tb="1" cflags="-DNO_SYNTH -I../../../include -I../../../../../software/include -I../../../../../software/examples"/>
    </files>
    <includePaths/>
    <libraryPaths/>
    <Simulation>
        <SimFlow name="csim" csimMode="0" lastCsimMode="2" compiler="true"/>
    </Simulation>
    <solutions xmlns="">
        <solution name="solution1" status="active"/>
    </solutions>
</project>

