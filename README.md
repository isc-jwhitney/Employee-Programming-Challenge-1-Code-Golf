# InterSystems Employee Programming Challenge #1

## Goal

Produce a correct ObjectScript-only\* solution to the challenge, using a minimal number of characters.

\* System functions are allowed, but direct use of other languages/libraries/programs (eg. via `$zf`) is not.

## Usage

Clone this repository, and ensure that user id `51773` has write access to `./data/out` (eg. by running `sudo chown -R 51773:51773 ./data`).

| Call                                      | Description                                                                | Prerequisites                                                                  |
| ----------------------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `src/reset-environment.sh`                | Set up the Docker container.                                               | No prerequisites.                                                              |
| `src/test-cold-start.sh (num_iterations)` | Set up the Docker container, import `RunScript.mac`, and run the solution. | No prerequisites.                                                              |
| `src/test-warm-start.sh (num_iterations)` | Import `RunScript.mac` and run the solution.                               | Requires an already-set-up Docker container.                                   |
| `src/iris-session.sh`                     | Open up an IRIS session in the Docker container.                           | Requires an already-set-up Docker container.                                   | 
| - `Do ^RunScript`                         | Run the solution.                                                          | Requires an already-set-up Docker container with `src/RunScript.mac` imported. |             
| - `Do Reload^RunScript`                   | Import a new version of `RunScript.mac` into the IRIS instance.            | Requires an already-set-up Docker container with `src/RunScript.mac` imported. |
| `src/cat-output.sh`                       | Display the the contents of the output files (from `data/out`).            | Requires the solution to have been run, to produce output files.               |

## How it works

The following line of ObjectScript code in `^RunScript` processes the input files to produce output:
```objectscript
d $zu(168,"~/dev/data") s f=$zse("in/*") f{s o="out"_$e(f,3,*-3) o f:/GZIP,o:"WT" u o w "source_id,bp_min_flux,bp_max_flux,rp_min_flux,rp_max_flux,percentage_change" u f f i=1:1:367{r l} try{f{f i=2:1:3{s t=$vop("fromstring",$p(l,"[",i*5),"decimal"),a(i)=$vop("max",t),c(i)=$vop("min",t,$vop("!=",t,0)),b(i)=$s(c(i):a(i)-c(i)/c(i),1:0)} s:b(3)>b(2) b(2)=b(3) u o w:b(2)>1 !,$lts($lb($p(l,",",2),c(2),a(2),c(3),a(3),b(2)*100)) u f r l}}catch{c o,f} s f=$zse("") q:f=""}
```

An expanded version of that code, along with comments explaining how it works / why certain decisions were made, is included below:
```objectscript
  // Set the current working directory to "/home/irisowner/dev/data".
  // Equivalent to $System.Process.CurrentDirectory("~/dev/data")
  do $zu(168, "~/dev/data")
  
  // Set the input filename `f` to the path of the first file under /home/irisowner/dev/data/in/*
  set f = $zSearch("in/*")
  
  // Loop through all files
  for {
    
    // Construct the output filename `o` from the input filename `f`
    // Example: "in/EpochPhotometry_006602-007952.csv.gz" --> "out/EpochPhotometry_006602-007952.csv"
    set o = "out" _ $extract(f, 3, *-3)
    
    // Open the input file `f` ("GZIP"ed) and the output file `o` ("W"rite / "T"runcate-if-exists)
    open f:/GZIP, 
         o:"WT"
    
    // Write a CSV header to the output file `o`
    use o 
    write "source_id,bp_min_flux,bp_max_flux,rp_min_flux,rp_max_flux,percentage_change"
    
    // Read and discard commented lines + the header at the beginning of the input CSV file `f` (this always comes out to 367 lines)
    // Leave the first line of data in `l`
    use f 
    for i=1:1:367 {
      read l 
    } 
    
    // Loop until we hit the end of the current file
    try {
      for {
      
        // Loop twice: Once to process bp_flux (i=2), and once to process rp_flux (i=3)
        // - bp_flux is the 10th (i*5 = 10) '['-delimited part of the line
        // - rp_flux is the 15th (i*5 = 15) '['-delimited part of the line
        // 
        // Use i=2/3 instead of i=10/15 to save characters in the for loop (i=2:1:3 instead of i=10:5:15) and variable subscripts (b(2) instead of b(10)).
        // 
        for i=2:1:3 {
          
          // Convert bp_flux / rp_flux into a decimal vector `t`
          //   NaN will be treated as 0
          set t = $vectorOp("fromstring", $p(l, "[", i*5), "decimal"),
          
              // Set `a(i)` to the max value in the flux vector `t`
              a(i) = $vectorOp("max", t),
            
              // Set `c(i)` to the min non-zero value in the flux vector `t`
              c(i) = $vectorOp("min", t, $vectorOp("!=", t, 0)),
            
              // Set `b(i)` to the percent change value (max-min)/min, or 0 if min = 0
              b(i) = $select(c(i): a(i) - c(i) / c(i), 1: 0)
            
        }
        
        // We've processed bp_flux and rp_flux at this point, and have:
        // - a(2) = max bp_flux
        // - a(3) = max rp_flux
        // - b(2) = percent change bp_flux
        // - b(3) = percent change rp_flux
        // - c(2) = min bp_flux
        // - c(3) = min rp_flux
        
        // Set b(2) to the larger of b(2) (percent change bp_flux) and b(3) (percent change rp_flux)
        set:b(3)>b(2) b(2) = b(3)
        
        // If b(2) (max percent flux change) is greater than the threshold (1 = 100%),
        //   write <newline>source_id,min_bp_flux,max_bp_flux,min_rp_flux,max_rp_flux,percent_change*100
        // to the output file `o`
        // 
        // source_id is the 2nd ','-delimited part of the line
        // 
        // Use $listToString instead of writing out commas to save characters.
        // 
        use o 
        write:b(2)>1 !, $listToString($listBuild($piece(l, ",", 2), c(2), a(2), c(3), a(3), b(2) * 100))
        
        // Read the next line `l` from the input file `f`
        use f
        read l
      }
    
    // When we hit the end of the file, the read will throw an error
    } catch {
      
      // Close the input file `f` and the output file `o` (flushes data, and makes it easier to re-run the solution) 
      close o, f
    }
    
    // Set `f` to the path of the next file from under /home/irisowner/dev/data/in/*
    // If we've processed all of the files, exit the loop
    set f = $zSearch("")
    quit:f=""
 }   
```