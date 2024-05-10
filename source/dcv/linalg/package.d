module dcv.linalg;

/++
    Since kaleidic.lubeck requires some linker settings depending on OS and backends,
    Client code is responsable for the required linkage.
    See https://github.com/libmir/mir-lapack/wiki/Link-with-CBLAS-&-LAPACK
+/
public {
    import kaleidic.lubeck;
    import kaleidic.lubeck2;
    
    import dcv.linalg.homography;
}