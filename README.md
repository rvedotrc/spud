spud
====

What is it?
-----------

A semi-interactive tool for helping to create and update AWS Cloudformation
stacks.

Some background
---------------

This tool already exists (I wrote about it here:
https://medium.com/@rvedotrc/managing-aws-cloudformation-templates-using-stack-fetcher-4d798d406fd0)
but it has, shall we say, "evolved". It would benefit from a rethink and a
rewrite before being opened up to the world.  So this is that rewrite.

For now at least, during development, it is called `spud` instead of
`stack-fetcher`.

Development status
------------------

Definitely not finished!

To see what it does so far:

 * `gem build spud.gemspec && gem install spud*.gem`
 * ensure your environment contains your AWS credentials if required
 * ensure you can access AWS without using a proxy (sorry, no proxy support yet)
 * `mkdir -p src/test`
 * copy some stack template to `src/test/template.json`
 * `spud prepare`
 * When prompted, enter the name of some stack that already exists in your account
 * `ls -l tmp/templates` and view the files with your favourite diff tool

