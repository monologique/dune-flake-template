(lang dune 3.16)

(name hello)

(generate_opam_files true)

(source
 (github monologique/dune-flake-template))

(authors "Paul-Mathias Logue")
(maintainers "Paul-Mathias Logue")
(license MIT)

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html

(package
 (name hello)
 (synopsis "A short greeting")
 (depends ocaml dune))