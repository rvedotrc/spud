stack-fetcher
=============

What is it?
-----------

A semi-interactive tool for helping to create and update AWS Cloudformation
stacks.

Features (and whether or not to include them natively)
------------------------------------------------------

stack-fetcher:

 * Work out the stack name
   * Default stack name
     * External script
 * Make "generated"
   * Almost (?) entirely an external script
 * Get "current"
   * Needs to know how to get credentials 
   * Needs to know what region to use
   * Could be an external script
 * Normalise both
 * Compare "generated" and "current"
   * Batch mode: parseable output / exit status
   * Interactive mode: show summary with invite to edit

stack-updater:

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

This suggests the following things should be outside of the stack-fetcher
core:

 * given args + which stack, generate suggested stack name
   * it's fine not to have a default implementation of this
 * given args + which stack, make "generated"
   * no sensible default possible?  Or at least, default would be very modav-specific
 * given args + which stack (+ stored metadata), retrieve stack
   * s-f can provide an implementation of this, as long as we have credentials + region
 * given args + which stack (+ "next"), push stack change
   * s-f can provide an implementation of this, as long as we have credentials + region

