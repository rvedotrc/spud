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

Installation
------------

You'll need a working modern Ruby, and bundler.

```
    bundle install
    rspec
    gem build spud.gemspec
    gem install *.gem
```

Walkthrough
-----------

First, install spud.  Also, ensure your environment has AWS credentials,
and (if required) `$https_proxy`.

In this example, we'll be working with a single stack, labelled the "main"
stack.  This is referred to as the "stack type".

Starting in the `spud` source directory,

```
  cd examples/single-stack
  cp src/main/template.1-topic-only.json src/main/template.default.json
  spud prepare
```

You will be prompted for the name and the region of the "main" stack.  Enter a
valid stack name, e.g. "MySpudTestStack", and pick a region (e.g. eu-west-1).

The output will then look a bit like this (don't worry if it's not absolutely
identical):

```
Retrieving stack "MySpudTestStack"

Generating target stacks

Normalising

  main : NEW

You should now edit the "next" files to suit, for example using the following
commands:

  vimdiff tmp/templates/template-main.{current,generated,next}.json ; vim tmp/templates/description-main.next.json

then run spud "apply".
```

For each stack, `spud` always works with three sets of templates:

 * "current": whatever is actually in AWS CloudFormation
 * "generated": whatever your source code says you want the stack to look like
 * "next": what is about to be pushed to AWS CloudFormation, if you run `spud apply`

For a new stack, "current" will basically be blank, since there is no existing
stack.

After running `spud prepare`, "next" will always be exactly the same as
"current" – i.e. by default, nothing will be changed, unless you ask for it.
The next step is to change the "next" file to include whatever changes you
want to be in CloudFormation – in this case, we can simply copy the
"generated" file over before running `spud apply`:

```
    cp tmp/templates/template-main.generated.json tmp/templates/template-main.next.json
    spud apply
```

You will be asked for confirmation that you want to create the new stack.
Enter "Y", and the stack should be created.  As CloudFormation does its work,
`spud` shows the stack events, and waits for the creation to finish:

```
2017-06-30T10:21:21Z AWS::CloudFormation::Stack CREATE_IN_PROGRESS MySpudTestStack arn:aws:cloudformation:eu-west-1:123456789012:stack/MySpudTestStack/dcd262c0-5d7d-11e7-9d9e-50a686335cd2 User Initiated
2017-06-30T10:21:26Z AWS::SNS::Topic CREATE_IN_PROGRESS MyTopic
2017-06-30T10:21:27Z AWS::SNS::Topic CREATE_IN_PROGRESS MyTopic arn:aws:sns:eu-west-1:123456789012:MySpudTestStack-MyTopic-REMC59UM6J8V Resource creation Initiated
2017-06-30T10:21:38Z AWS::SNS::Topic CREATE_COMPLETE MyTopic arn:aws:sns:eu-west-1:123456789012:MySpudTestStack-MyTopic-REMC59UM6J8V
2017-06-30T10:21:40Z AWS::CloudFormation::Stack CREATE_COMPLETE MySpudTestStack arn:aws:cloudformation:eu-west-1:123456789012:stack/MySpudTestStack/dcd262c0-5d7d-11e7-9d9e-50a686335cd2
```

Congratulations! You've now created your first stack with spud.

If you now re-run `spud prepare`, you'll notice that (a) you aren't asked for
the stack name, and (b) the summary now shows "same", whereas before it said
"NEW".

Now let's do an update.

First, let's give `spud` a new template, then re-run `prepare`:

```
    cp ./src/main/template.2-topic-and-queue.json ./src/main/template.default.json
    spud prepare
```

This time, the summary shows that the "main" stack has differences (i.e. that
"current" and "generated" are different):

```
  main : DIFFERENT (hunks: 1, lines: 3)
```

You can use whatever tool you like for viewing and resolving these
differences, but as an example, you can view the change with `diff`:

```
    diff -u tmp/templates/template-main.current.json tmp/templates/template-main.generated.json
```

and, assuming you have "vim" installed, you can use `vimdiff` to look compare
current / generated / next, and (ideally) make "next" be the same as
"generated".

For now let's just copy the generated file over, before running "apply" (note
that these are exactly the same commands we used earlier):

```
    cp tmp/templates/template-main.generated.json tmp/templates/template-main.next.json
    spud apply
```

This time, `spud` shows the changes we're about to apply, before asking if we want to proceed:

```
--- tmp/templates/template-main.current.json    2017-06-30 11:27:50.000000000 +0100
+++ tmp/templates/template-main.next.json    2017-06-30 11:31:49.000000000 +0100
@@ -2,6 +2,9 @@
   "AWSTemplateFormatVersion": "2010-09-09",
   "Description": "Trivial example stack",
   "Resources": {
+    "MyQueue": {
+      "Type": "AWS::SQS::Queue"
+    },
     "MyTopic": {
       "Type": "AWS::SNS::Topic"
     }

<then a CloudFormation change set is prepared, and displayed>...

INFO: Template has no parameters
Update the main stack MySpudTestStack? [y/N]:
```

Again, if we say yes, then spud applies the change for us, showing us the
stack events:

```
Update the main stack MySpudTestStack? [y/N]: y
Pushing stack arn:aws:cloudformation:eu-west-1:123456789012:stack/MySpudTestStack/dcd262c0-5d7d-11e7-9d9e-50a686335cd2 using update_stack via region "eu-west-1"

2017-06-30T10:33:15Z AWS::CloudFormation::Stack UPDATE_IN_PROGRESS MySpudTestStack arn:aws:cloudformation:eu-west-1:123456789012:stack/MySpudTestStack/dcd262c0-5d7d-11e7-9d9e-50a686335cd2 User Initiated
2017-06-30T10:33:20Z AWS::SQS::Queue CREATE_IN_PROGRESS MyQueue
2017-06-30T10:33:21Z AWS::SQS::Queue CREATE_IN_PROGRESS MyQueue https://sqs.eu-west-1.amazonaws.com/123456789012/MySpudTestStack-MyQueue-1QL7IAM2WMJTY Resource creation Initiated
2017-06-30T10:33:21Z AWS::SQS::Queue CREATE_COMPLETE MyQueue https://sqs.eu-west-1.amazonaws.com/123456789012/MySpudTestStack-MyQueue-1QL7IAM2WMJTY
2017-06-30T10:33:24Z AWS::CloudFormation::Stack UPDATE_COMPLETE_CLEANUP_IN_PROGRESS MySpudTestStack arn:aws:cloudformation:eu-west-1:123456789012:stack/MySpudTestStack/dcd262c0-5d7d-11e7-9d9e-50a686335cd2
2017-06-30T10:33:25Z AWS::CloudFormation::Stack UPDATE_COMPLETE MySpudTestStack arn:aws:cloudformation:eu-west-1:123456789012:stack/MySpudTestStack/dcd262c0-5d7d-11e7-9d9e-50a686335cd2
```

So the basic pattern is:

 * make `src/*/template.default.json` contain the desired stack template
 * "spud prepare"
 * Use vimdiff or whatever to resolve the differences between current / generated / next,
   making "next" contain whatever you want to push to CloudFormation
 * "spud apply"


Working with multiple stacks
----------------------------

In the walkthrough above, we used a single stack, referred to as the "main"
stack.  If you need to work with more stacks, just create more
directories in parallel.  For example, here's a "blue" and a "green" stack:

 * `./src/blue/template.default.json`
 * `./src/green/template.default.json`

`spud` will process all of the stacks.  `spud` always asks before making any
changes to CloudFormation.

Working with multiple AWS regions
---------------------------------

`stack_names.json` includes the region of each stack:

```
{
  "default": {
    "main": {
      "account_alias": null,
      "region": "eu-west-1",
      "stack_name": "MySpudTestStack"
    }
  }
}
```

`spud` switches region to deal with each stack as required.

Working with multiple AWS accounts
----------------------------------

There is a space in `stack_names.json` for the account alias associated with
each stack, but *this has no effect*, unless you extend spud (see below).

Extending spud
--------------

spud is designed to be extended in a few specific areas, referred to as the
"extensions":

 * the _generator_ is responsible for generating the desired stack template
   JSON
 * the _stack name suggester_ is responsible for suggesting names for new
   stacks
 * the _puller_ is responsible for retrieving the existing stack details from
   AWS CloudFormation
 * the _pusher_ is responsible for applying the "next" stack details to
   AWS CloudFormation

The intended way of extending spud is to create your own executable (e.g.
`my-custom-spud`) which would construct a `Spud::Context` object, override the
default extentions, then run `Spud::Main.new(args, context).run` .

```
# You don't have to override everything!
context = Spud::Context.new
context.extensions.stack_name_suggester = MyCustomSpud::NameSuggester.new
context.extensions.generator = MyCustomSpud::Generator.new
context.extensions.puller = MyCustomSpud::Puller.new
context.extensions.pusher = MyCustomSpud::Pusher.new

Spud::Main.new(ARGV, context).run
```

The extensions have to implement the same interface as the default, of course;
see `lib/spud/ext/default*` for a guide.

Development status
------------------

What it does:

 * Handle creation of new stacks
 * Handle updates to existing stacks

Changes I'm considering:

 * Delegate finding the list of stack types to an extension
   * This would allow much more easily for cases where an entire stack is not
     required in some contexts (e.g. a "test support" stack is not required in live)
   * Default implementation: effectively `ls src/`
 * Delegate the current function of the ```stack_names.json``` file to an
   extension
   * This would allow the site-local usage to be as simple or complex as
     required, e.g. store information about how to acquire credentials / how
     to select the region for each stack type
   * This would render the ```--config-set=KEY``` option redundant
   * Default implementation: exactly as ```stack_names.json``` currently is in
     the core

What it doesn't do, and probably never will:

 * Handle deletion of stacks
 * Any knowledge of how to acquire AWS credentials.  To handle this, extend
   spud, overriding the puller and pusher.

