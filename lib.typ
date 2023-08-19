#let apa-bibliography = (() => {
let dict-from-entries = entries => {
	let result = (:)
	for (key, value) in entries {
		result.insert(key, value)
	}
	result
}

let n(x, default, f) = if x == none { default } else { f(x) }
let nid(x, default) = n(x, default, y => y)

let show-list(xs, commaStr: ",", andStr: "and") = {
	let len = xs.len()
	if len == 1 {
		xs.at(0)
	} else if len == 2 {
		xs.at(0) + " " + andStr + " " + xs.at(1)
	} else {
		xs.slice(0, -1).join(commaStr + " ") + commaStr + " " + andStr + " " + xs.at(-1)
	}
}

let get-value(x) = if type(x) == "string" { x } else { x.value }

let months = (
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
)

// idk how to convert an int into a char so this will do for now
let letters = ("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z")

let parse-date(x) = {
	if type(x) == "integer" {
		(y: x, monthNum: none, m: none, d: none)
	} else {
		let (y, m, d) = x.split("-").map(int)
		(y: y, monthNum: m, m: months.at(m - 1), d: d)
	}
}

(works, include-all: true) => {
	for (key, work) in works.pairs() {
		let authors = if type(work.author) == "array" { work.author } else { (work.author,) }.map(author => (
			name: if type(author) == "string" {
				author
			} else {
				author.name + if "given-name" in author {
					", " + author.given-name.at(0) + "." + if "middle-name" in author { " " + author.middle-name.at(0) + "." } else { "" }
				} else {
					""
				}
			},
			inline-name: if type(author) == "string" { author } else { author.name },
			short-name: if "short-name" in author { author.short-name } else { none }
		))
		works.insert(
			key,
			(
				..work,
				page-type: if "page-type" in work { work.page-type } else { none },
				title: get-value(work.title),
				authors: authors,
				author-str: if authors.len() >= 3 {
					authors.first().name + " et al."
				} else {
					show-list(andStr: "&", authors.map(author => author.name))
				},
				date: if "date" in work { parse-date(work.date) } else { none },
				url: (..work.url, date: parse-date(work.url.date)),
				parent: if "parent" in work and work.parent != none {
					(..work.parent, title: get-value(work.parent.title))
				} else { none },
			),
		)
	}
	let sorted-works = works.pairs()
		.sorted(key: ((_, work)) => work.title)
		.sorted(key: ((_, work)) => n(work.date, 0, x => nid(x.d, 0)))
		.sorted(key: ((_, work)) => n(work.date, 0, x => nid(x.monthNum, 0)))
		.sorted(key: ((_, work)) => n(work.date, 0, x => x.y))
		.sorted(key: ((_, work)) => work.author-str)

	// TODO: account for unused works
	let author-year-counts = (:)
	for (i, x) in sorted-works.enumerate() {
		let (_, work) = x
		let year-counts = author-year-counts.at(work.author-str, default: (:))
		let yearKey = n(work.date, "n.d.", x => str(x.y))
		let count = year-counts.at(yearKey, default: 0)
		if count >= 1 {
			if count == 1 { sorted-works.at(i - 1).at(1).dateLetter = "a" }
			sorted-works.at(i).at(1).dateLetter = letters.at(count)
		} else {
			sorted-works.at(i).at(1).dateLetter = none
		}
		year-counts.insert(yearKey, count + 1)
		author-year-counts.insert(work.author-str, year-counts)
	}

	let used-works = state("used-works", ())

	let use-work(key) = [#used-works.update(x => x + (key,))]
	let inline-date(work) = n(work.date, [n.d.#n(work.dateLetter, none, x => [-#x])], x => [#x.y#work.dateLetter])
	let inline-citation(key, work, extra) = [(#used-works.display(used => {
		let used-authors = used.map(k => works.at(k).authors.map(a => a.name)).flatten()
		let display-author(author) = if author.name in used-authors {
			nid(author.short-name, author.inline-name)
		} else {
			author.inline-name + n(author.short-name, none, x => [ [#x]])
		}
		if work.authors.len() >= 3 {
			[#display-author(work.authors.first()) et al.]
		} else {
			show-list(andStr: "&", work.authors.map(display-author))
		}}), #inline-date(work)#extra)#use-work(key)]

	(
		reference: dict-from-entries(sorted-works
			.map(((key, work)) => (
				key,
				inline-citation(key, work, [])
			))
		),
		reference-with-page: dict-from-entries(sorted-works
			.map(((key, work)) => (
				key,
				pageNum => inline-citation(key, work, [, #pageNum])
			))
		),
		reference-date-only: dict-from-entries(sorted-works
			.map(((key, work)) => (
				key,
				[(#inline-date(work))#use-work(key)]
			))
		),
		bibliography: {
			set par(hanging-indent: 0.5in, justify: false)
			locate(loc => {
				let used = used-works.final(loc)
				if include-all { sorted-works } else { sorted-works.filter(((key, _)) => used.contains(key)) }
					.map(((_, work)) => [
						#work.author-str
						(#n(
							work.date,
							[n.d.#n(work.dateLetter, none, x => [-#x])],
							date => [#date.y#work.dateLetter#if date.m != none { [, #date.m #date.d] }]
						)).
						#emph(work.title)#n(work.page-type, none, x => [ [#x]]).#n(work.parent, none, x => [ #x.title.])
						Retrieved #work.url.date.m #work.url.date.d, #work.url.date.y, from #link(work.url.value)
					])
					.join(parbreak())
			})
		},
		works: works,
	)
}
})()
