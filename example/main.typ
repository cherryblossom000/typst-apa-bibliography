#import "@local/apa-bibliography:0.0.1": apa-bibliography

#set page(height: auto)

#let (reference: r, reference-with-page: rp, reference-date-only: rd, bibliography) = apa-bibliography(yaml("works.yml"))

Typst is really cool #r.typst-is-cool.

Here's another sentence where I'm going to reference another article with a specific page number #(rp.company-report)[p. 3].

What about if two references have the same author and year? #r.same-year1 #r.same-year2

According to Smith #rd.typst-is-cool, this is just an example to show how you can cite just the date.

Multiple authors: #r.multiple-authors. This is also an example with no date.

You can use an acronym for an author. Here's the first time I'm going to reference the author #r.long-author1.

Now when I reference the same author again, it's going to show the acronym #r.long-author2.

= References

#bibliography
