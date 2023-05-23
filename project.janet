

(declare-project
  :name "prime-fun-janet" # required
  :description "Generate prime spirals" # some example metadata.

  # Optional urls to git repositories that contain required artifacts.
  :dependencies ["https://github.com/janet-lang/json.git"])


(declare-executable
  :name "prime-fun-janet"
  :entry "prime.janet"
  :install false)
