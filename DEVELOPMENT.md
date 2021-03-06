Features (and whether or not to include them natively)
------------------------------------------------------

spud prepare:

 * Work out the stack name
   * Default stack name
     * External script
 * Make "generated"
   * Almost (?) entirely an external script
   * Should present credentials to that script
 * Get "current"
   * Needs to know how to get credentials 
   * Needs to know what region to use
   * Could be an external script
 * Normalise both
 * Compare "generated" and "current"
   * Batch mode: parseable output / exit status
   * Interactive mode: show summary with invite to edit

spud apply:

 * Check for missing params etc
 * Compare; show diffs; prompt to apply
 * Push stack change
   * Could be external tool
   * Wait for completion; show events
     * Could be external tool
   * Update `stack_names.json`

general:

 * Manage multiple stacks in a single run
 * How to do with multiple accounts / regions?
   * e.g. make the user represent each target stack in the source code?
   * e.g. one entry in source code, multiple entries in stacknames.json?
   * e.g. process all accounts/regions in a single run, or select one account/region per run?

Core vs externals
-----------------

This suggests the following things should be outside of the spud core:

 * given args + which stack, generate suggested stack name
   * it's fine not to have a default implementation of this
   * argv + which stack
   * output to stdout, for now
 * given args, make "generated"
   * no sensible default possible?  Or at least, default would be very modav-specific
   * output is to files, not stdout
   * initially generate just template; later we can add descriptor
   * would be advantageous to generate N stacks
    * since the script obviously has to emit json, maybe it makes sense for its input to be json too, viz:
    * `{ "argv": [ ... ], "stacks": { "resource": { "template": "somefile", "descriptor": "somefile" } } }`
 * given args, retrieve stack
   * s-f can provide an implementation of this, as long as we have credentials + region
   * must respect `$https_proxy`
   * again, input as json, output to files:
    * `{ "argv": [ ... ], "stacks": { "resource": { "name": "SomeStackName", "template": "somefile", "descriptor": "somefile" } } }`
 * given args + which stack (+ "next"), push stack change
   * s-f does all the diffing and prompting.  script does apply + progress / wait
   * s-f can provide an implementation of this, as long as we have credentials + region
   * must respect `$https_proxy`

What we need to plug in for (sufficient) compatibility with BBC modav stack-fetcher?

 * stack name suggester
 * generate (template.py / modav-generate-templates; generate-template; transform; cosmos-cloudformation-postproc.rb)
 * "register with Cosmos" - drop?  Or as some sort of wrapped hook around "push stack change"?

