open Alcotest

let test_say_hello () =
  let result = Hello.say "World!" in
  check string "should return hello message" "Hello, Worldd!" result

let () =
  run "Hello, World!"
    [ ("say_hello", [ test_case "basic greeting" `Quick test_say_hello ]) ]
