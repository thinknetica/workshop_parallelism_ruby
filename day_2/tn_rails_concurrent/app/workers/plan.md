https://btihen.dev/posts/ruby/ruby_3_x_ractor/
https://dev.to/baweaver/introducing-patterns-in-parallelism-for-ruby-2f4a

Consider Adding Numbers

1 + 1 # => 2

# Patterns in the Numbers

## Pattern 1. Adding Numbers Returns a Number

Let's start with this: If you add two integers together, you're going to get back another integer.

(1 + 1).class # => Integer

## Pattern 2. Adding Zero to a Number Returns that Number

If you add zero to any other number you'll get back that same number:

1 + 0 # => 1

## Pattern 3. Grouping Numbers with Parens Doesn't Change Results

If you drop some parens in there you're going to get the same result:

1 + 2 + 3 == (1 + 2) + 3
(1 + 2) + 3 == 1 + (2 + 3)

## Pattern 4. Adding the Negative of a Number Returns Zero

If we add the negative version of any number to itself we're going to get back zero:

1 + -1 == 0

## Pattern 5. Actually, Order Doesn't Matter

1 + 2 + 3 == 3 + 2 + 1
3 + 2 + 1 == 1 + 3 + 2

## Patterns Become Rules

You see, those patterns are the basis of a few rules. Let's take another look at them and give them names.

## Rule 1. Closure

Множество, объединение, даёт тоже множество

For this rule to work we need a few things:

    A set of values (integers)
    A way to join them together (+)
    Joining them gives back something in that same set of values (integer)

## Rule 2. Identity

Identity is a value you can combine with any other value in a set to get back that exact same value.

It's the "empty" value. In the case of addition, zero:

1 + 0 == 0 + 1
0 + 1 == 1

But this value is dependent on the fact that we're adding two numbers together. If we were to multiply them instead and use that as our joining method we'd have issues because:

1 * 0 # => 0

When you change the operator you may also change what the identity element is. For multiplication it's one instead:

1 * 1 # => 1

Rule 3. Associativity

Associativity is our grouping property. It means that we can, with three or more numbers, group them with parens wherever we want and still get back the same value:

1 + 2 + 3 == (1 + 2) + 3
(1 + 2) + 3 == 1 + (2 + 3)

Rule 4. Inversion

Inversion means for every value you join you can join an inverted version of it to get back to empty, or identity. In addition that means n can be negated by -n for integers:

1 + -1 == 0
5 + -5 == 0

That doesn't work so well for multiplying integers, as to invert multiplying by n you would have to multiply by 1/n which isn't an integer. Looks like multiplication doesn't work with this rule.
Rule 5. Commutitivity

Commutitivity means that the order doesn't matter, if the values are all still joined by the same method you'll get back the same result:

1 + 2 + 3 == 3 + 2 + 1

The same works for multiplication if you try it:

1 * 2 * 3 == 3 * 2 * 1

Patterns are Everywhere

So why is any of that relevant you might ask?

Let's try a few more types real quick:
String Addition

    Closure: +
    Identity: ""
    Associativity: "a" + "b" + "c" == ("a" + "b") + "c"

Array Addition

    Closure: +
    Identity: []
    Associativity: [1] + [2] + [3] == [1, 2] + 3

Hash Merge

    Closure: merge
    Identity: {}
    Associativity: { a: 1 }.merge({ b: 1 }).merge({ c: 1 }) == { a: 1, b: 1 }).merge({ c: 1 })

Functions

    Closure: <<
    Identity: -> v { v }
    Associativity: a << b << c == (a << b) << c

ActiveRecord Queries

    Closure: .
    Identity: all
    Associativity: Model.where(**a).where(**b).where(**c) == Model.where(**a, **b).where(**c)

Frequent Patterns tend to be Named

Wait wait, that seems like it happens a lot! Well when something happens a lot we tend to give a name to that concept.

If that pattern happens to match the rules of Closure, Identity, and Associativity we call it a Monoid (like one thing).

If we add inversion, it becomes a Group, and if we also add Commutitivity it becomes an Abelian Group. (This listing of Group-like structures may be useful)

In Ruby we also tend to call these patterns "reducible":

# values           identity       joining
#    V                 V             V
[1, 2, 3, 4, 5].reduce(0) { |a, i| a + i }

%w(some words here to join).reduce('') { |a, s| a + s }

[[1], [2], [3]].reduce([]) { |a, v| a + v }

Which is great and all, but why does any of this relate to parallelism?

Because none of those concepts rely on mutable state to function.
Going Parallel

Let's say you had billions of numbers in a batch system. Since we know that numbers, when joined with addition, have the properties of an Abelian Group that gives us some really nice benefits:

    We can shard them into whatever chunks we want across thousands of computers, irreverant of the order.
    We can filter out to only even numbers. If that filters all the numbers we just return back zero instead.
    If we know a batch was bad and we want to undo it we can resend the inverted version of those numbers ns.map { |v| -v } to undo it.

Knowing these patterns gives an intuition for how to work with asyncronous or parallel systems, and they can be really danged handy especially for an Actor model.
We Want Results

Great, but your job needs more than adding numbers, and I agree. That's a nice trick great for parties but we have serious programmer work to do no?

DryRB has a concept that's interesting, Result (wait to click for a moment), which is the sum of two types, Success and Failure:

def greater_result(a, b)
    a > b ? Success(a) : Failure('Error!')
end

greater_result(1, 2).fmap { |v| v + 10 } # => Failure('Error!')

greater_result(3, 2).fmap { |v| v + 10 } # => Success(13)

It allows us to represent distinct ideas of success or failure and wraps them into some nifty classes for us. The trick? fmap looks a whole lot like join or +, and returns something in the set of Result. Not exactly because these go a few steps beyond our frieldly little Monoid above.

If we call fmap on a Success the value keeps passing through to the function, if on a Failure it just ignores us. That means we have a safe way of handling errors in a parallel world.

You might notice that the link mentions Monads. You may also have heard the rather quipish "Monads are just Monoids in the Category of EndoFunctors" before as well.

Ignoring Monads for a second as a whole concept to learn they follow the same patterns as a Monoid plus a few extras. That means we get the same benefits, meaning Result is safe to use in a parallel system.

DryRB introduces a lot of these types, and of course it's a stretch from what we're used to, but so are Ractors so we're in fair game territory. It's time to change the way we play.
Wrapping Up

For additional resources I would strongly suggest looking into Railway Oriented Programming from here to continue building some ideas of what's possible in a parallel world with Ruby through Result-like types.

That video above? "Reducing Enumerable"? It's also a talk that's entirely about Monoids without ever mentioning Monoid, that was a fun trick. See if you can spot the patterns now watching it!

There's a lot here, and I may make a much more detailed post on this later, but a lot of fun things to consider nonetheless.

One day I may just write a Monad tutorial, but not quite today I reckon.


https://vimeo.com/113707214

Railway oriented programming: Error handling in functional languages by Scott Wlaschin

User udpate email:

Receive request
Success Error

Validate request
Success Error

Update existing user record
Success Error

Send verification email
Success Error

Return result


1. Optimistic Locking (VC — Version Column)

    Mechanism:
    version column `lock_version`
    Each time the record is updated, Active Record increments the `lock_version` column.
    If an update request is made with a lower value in the `lock_version` field that is currently in the `lock_version` column in the database, the update request will fail with an `ActiveRecord::StaleObjectError`..
    Benefits:
    Improved performance: No explicit locking on the database until a conflict occurs.
    User-friendly error handling: Conflict detection happens at the application layer, allowing for informative error messages to be presented to users.
    Drawbacks:
    Not ideal for scenarios with high conflict probability.
    Requires additional logic to handle conflicts and retry updates.
