spud
====

What is it?
-----------

A semi-interactive tool for helping to create and update AWS CloudFormation
stacks.

Some background
---------------

This tool already exists (I wrote about it here:
https://medium.com/@rvedotrc/managing-aws-cloudformation-templates-using-stack-fetcher-4d798d406fd0)
but it has, shall we say, "evolved". It would benefit from a rethink and a
rewrite before being opened up to the world.  So this is that rewrite.

For now at least, during development, it is called `spud` instead of
`stack-fetcher`.

Basic usage example
-------------------

Given the following files:

 * `./src/blue/template.default.json`
 * `./src/green/template.default.json`

which are AWS CloudFormation template files, then running `spud prepare` (with
appropriate AWS credentials) will:

 * ask you for the name of the "blue" and "green" stacks
 * retrieve the "blue" and "green" stacks from AWS CloudFormation
 * generate the desired "blue" and "green" stack templates (which just means copying the above files)
 * show you a summary of how the retrieved stacks compare to the generated stacks
 * leave some JSON files in `./tmp/templates/*.json`
 * prompt you to edit the "next" files, then apply the changes using `spud apply`

In the above example, "blue" and "green" are said to be the _stack types_.
The stack types are discovered by listing the `./src` directory.  Each stack
type corresponds to one stack.  You need to have at least one stack type,
otherwise `spud` will have no work to do.

After making any edits to the "next" files in `./tmp/templates`, running `spud
apply` will:

 * check the stack parameters, warning you about added or removed parameters,
   or parameters which don't yet have a value
 * for each stack,
   * if there's a change to make,
     * shows a preview of the changes
     * asks for confirmation that the changes should be applied to AWS CloudFormation
     * (if confirmed) applies the changes

Extending spud
--------------

`spud` delegates some of its work separate executables: the "scripts".  A
default implementation of each one is provided, but you can provide your own
via the `--scripts-dir=DIR` option.  If you do this, you can find the default
scripts directory via the `$SPUD_DEFAULT_SCRIPTS_DIR` environment variable.

__The `get-stack-name-suggestion` script__

Used to get the suggested name of a stack (if the actual name is not yet
known, or e.g. if the stack has not yet been created).

ARGV will be the stack type, plus any arguments that you passed to `spud
prepare`.  The script should emit an (optional) syntactically-valid stack
name, followed by an (optional) newline, to stdout.  It should exit with
status 0.

__The `retrieve-stacks` script__

Used to retrieve the existing stacks, if any, from AWS CloudFormation.  The
default script is probably perfectly good enough for you, unless you want to
switch regions or accounts (in which case, see below).

The work to do is presented on stdin as JSON, of the following structure:

```
    {
        "argv": [ ... ],
        "stacks": {
            "blue": { "name": "NameOfBlue", "template": "...", "description": "..." },
            "green": { "name": "NameOfGreen", "template": "...", "description": "..." }
        }
    }
```

`argv` is a possibly-empty array of strings - the arguments given to `spud
prepare`.  `stacks` has one entry per stack type, where each stack type has a
`name` (the name of the stack to retrieve), `template` (filename to write the
stack's template to) and `description` (filename to write the stack's
description to).

The description written should be of the structure:

```
    {
        "Stacks": [ {
            "Capabilities": ...,
            "Description": ...
        } ]
    }
```

i.e. with a `Stacks` array wrapper, and using `TitleCase` keys (not ```snake_case```).

stdout and stderr are unchanged (i.e. they're probably the terminal), and
ARGV is not used.

If you want to do things like switch AWS regions or credentials, you could
override `retrieve-stacks` with your own script which does those things, then
runs the default `retrieve-stacks` via $SPUD_DEFAULT_SCRIPTS_DIR.

__The `generate-stacks` script__

Much like `retrieve-stacks`, `generate-stacks` gets its work as JSON on stdin,
and doesn't use stdout, stderr, and ARGV.

`generate-stacks` should generate the desired JSON template for each stack,
and write them to the given file.  (Currently it is not asked to generate the
description - only the template).

The default implementation of `generate-stacks` just copies the stack template
from the `./src` directory.  This may be sufficient for you - as long as you
make sure the template(s) are generated and in place before you run `spud`.

__The `push-stacks` script__

Much like `retrieve-stacks`, `push-stacks` gets its work as JSON on stdin,
and doesn't use stdout, stderr, and ARGV.

`push-stacks` should update the stacks in AWS CloudFormation according to the
given description and template.

The default implementation of `push-stacks` calls AWS CloudFormation to update
the stack; then, it uses `cfn-events` (if available) to show stack events and
wait for the update to complete.  `cfn-events` is available from
<https://github.com/rvedotrc/cloudsaw/>.

If you want to do things like switch AWS regions or credentials, you could
override `push-stacks` with your own script which does those things, then
runs the default `push-stacks` via $SPUD_DEFAULT_SCRIPTS_DIR.

Walkthrough
-----------

Preparation:

 * ```gem build spud.gemspec && gem install spud*.gem```
 * ensure your environment contains your AWS credentials if required
 * ensure your environment contains $https_proxy if required

Updating an existing stack:

 * `mkdir /somewhere/you/want/to/work`
 * `cd /somewhere/you/want/to/work`
 * `mkdir -p src/test`
 * copy some stack template to `src/test/template.json`
 * `spud prepare`
 * When prompted, enter the name of some stack that already exists in your account
 * `spud` now retrieves the existing stack from AWS CloudFormation, generates
   the target template (just a file copy), and summarises any differences
 * Make some changes to `./tmp/templates/template-test.next.json` (for example: add a resource)
   * If you have `vim` installed, you can use the example command that `spud`
     shows on screen to do the editing
 * `spud apply`
 * Review and apply the changes

Development status
------------------

What it does:

 * Handle updates to existing stacks

What it doesn't yet do, but will:

 * Handle creation of new stacks

What it doesn't do, and probably never will:

 * Handle deletion of stacks
 * Any knowledge of AWS credentials or regions.  To handle this, override
   `retrieve-stacks` and `push-stacks`

