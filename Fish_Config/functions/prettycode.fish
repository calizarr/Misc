function prettycode
  echo "pbpaste | highlight --syntax=scala -O rtf | pbcopy"
  pbpaste | highlight --syntax=scala -O rtf | pbcopy
end